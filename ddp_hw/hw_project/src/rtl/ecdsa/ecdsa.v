module ecdsa (
    input  wire          clk,
    input  wire          resetn,
    output wire   [ 3:0] leds,

    // input registers                     // output registers
    input  wire   [31:0] rin0,             output wire   [31:0] rout0,
    input  wire   [31:0] rin1,             output wire   [31:0] rout1,
    input  wire   [31:0] rin2,             output wire   [31:0] rout2,
    input  wire   [31:0] rin3,             output wire   [31:0] rout3,
    input  wire   [31:0] rin4,             output wire   [31:0] rout4,
    input  wire   [31:0] rin5,             output wire   [31:0] rout5,
    input  wire   [31:0] rin6,             output wire   [31:0] rout6,
    input  wire   [31:0] rin7,             output wire   [31:0] rout7,

    // dma signals
    input  wire [1023:0] dma_rx_data,      output wire [1023:0] dma_tx_data,
    output wire [  31:0] dma_rx_address,   output wire [  31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );

  //////////////////////////////////////////////////////////////////////////////
  // Register map
  //////////////////////////////////////////////////////////////////////////////
  //
  // SW -> HW
  //   rin0[3:0]  command   0 = CMD_IDLE
  //                        1 = CMD_LOAD_M   read the modulus M from RXADDR
  //                        2 = CMD_MONTMUL  read {B, A} from RXADDR, compute
  //                                         A*B*R^-1 mod M, write it to TXADDR
  //   rin1       RXADDR    address of the 1024-bit word the FPGA reads
  //   rin2       TXADDR    address of the 1024-bit word the FPGA writes
  //
  // HW -> SW
  //   rout0      status    bit 0     done  (waiting for CMD_IDLE)
  //                        bit 1     idle  (ready for a command)
  //                        bit 2     dma error (address not 128-byte aligned)
  //                        bit [7:4] FSM state, for debugging
  //   rout1      RXADDR    echo
  //   rout2      TXADDR    echo
  //   rout3      number of clock cycles the last multiplication took
  //
  // Layout of the 1024-bit words
  //   CMD_LOAD_M  in : M      in bits [376:0]
  //   CMD_MONTMUL in : A      in bits [376:0]    (uint32 words  0..11)
  //                    B      in bits [888:512]  (uint32 words 16..27)
  //   CMD_MONTMUL out: result in bits [376:0], all higher bits zero

  localparam
    CMD_IDLE    = 4'd0,
    CMD_LOAD_M  = 4'd1,
    CMD_MONTMUL = 4'd2;

  wire [3:0] command = rin0[3:0];
  assign dma_rx_address = rin1;
  assign dma_tx_address = rin2;

  wire isCmdIdle    = (command == CMD_IDLE);
  wire isCmdLoadM   = (command == CMD_LOAD_M);
  wire isCmdMontMul = (command == CMD_MONTMUL);

  //////////////////////////////////////////////////////////////////////////////
  // State machine
  //////////////////////////////////////////////////////////////////////////////

  localparam
    STATE_IDLE      = 4'd0,
    STATE_RX        = 4'd1,
    STATE_RX_WAIT   = 4'd2,
    STATE_MUL_START = 4'd3,
    STATE_MUL_WAIT  = 4'd4,
    STATE_TX        = 4'd5,
    STATE_TX_WAIT   = 4'd6,
    STATE_DONE      = 4'd7;

  reg [3:0] state = STATE_IDLE;
  reg [3:0] next_state;

  // The command is sampled when leaving IDLE, so that the rest of the
  // execution does not depend on what the CPU does with rin0 in the meantime.
  reg [3:0] r_command = CMD_IDLE;
  always @(posedge clk)
    if (~resetn)                  r_command <= CMD_IDLE;
    else if (state == STATE_IDLE) r_command <= command;

  wire mont_done;

  always @(*) begin
    next_state = STATE_IDLE;

    case (state)
      // Wait for a known command. Unknown commands are ignored.
      STATE_IDLE:
        next_state = (isCmdLoadM | isCmdMontMul) ? STATE_RX : STATE_IDLE;

      // Keep dma_rx_start high until the dma leaves its idle state.
      STATE_RX:
        next_state = (~dma_idle) ? STATE_RX_WAIT : STATE_RX;

      // Wait for the data. LOAD_M is finished once the data has arrived.
      STATE_RX_WAIT:
        next_state = (~dma_done)                  ? STATE_RX_WAIT :
                     (r_command == CMD_LOAD_M)    ? STATE_DONE    :
                                                    STATE_MUL_START;

      // One-cycle start pulse for the multiplier.
      STATE_MUL_START:
        next_state = STATE_MUL_WAIT;

      STATE_MUL_WAIT:
        next_state = (mont_done) ? STATE_TX : STATE_MUL_WAIT;

      // Keep dma_tx_start high until the dma leaves its idle state.
      STATE_TX:
        next_state = (~dma_idle) ? STATE_TX_WAIT : STATE_TX;

      STATE_TX_WAIT:
        next_state = (dma_done) ? STATE_DONE : STATE_TX_WAIT;

      // Stay here until the CPU writes CMD_IDLE. Otherwise the command that
      // is still in rin0 would be executed a second time.
      STATE_DONE:
        next_state = (isCmdIdle) ? STATE_IDLE : STATE_DONE;

      default:
        next_state = STATE_IDLE;
    endcase
  end

  always @(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;

  always @(posedge clk) begin
    dma_rx_start <= 1'b0;
    dma_tx_start <= 1'b0;
    case (state)
      STATE_RX: dma_rx_start <= 1'b1;
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////
  // Data registers
  //////////////////////////////////////////////////////////////////////////////

  // The modulus stays loaded until the next CMD_LOAD_M.
  reg [376:0] r_m = 377'h0;

  // r_data first holds the operands {B, A} and then the result. The operands
  // are stable for the whole multiplication, because r_data is only
  // overwritten when the multiplier is done.
  reg [1023:0] r_data = 1024'h0;

  wire [376:0] mont_a = r_data[376:0];
  wire [376:0] mont_b = r_data[888:512];
  wire [376:0] mont_result;

  wire rx_valid = (state == STATE_RX_WAIT) & dma_done;

  always @(posedge clk) begin
    if (rx_valid & (r_command == CMD_LOAD_M))
      r_m <= dma_rx_data[376:0];

    if (rx_valid & (r_command == CMD_MONTMUL))
      r_data <= dma_rx_data;
    else if ((state == STATE_MUL_WAIT) & mont_done)
      r_data <= {647'b0, mont_result};
  end

  assign dma_tx_data = r_data;

  //////////////////////////////////////////////////////////////////////////////
  // Montgomery multiplier
  //////////////////////////////////////////////////////////////////////////////

  wire mont_start = (state == STATE_MUL_START);

  montgomery montgomery_instance (
    .clk    (clk         ),
    .resetn (resetn      ),
    .start  (mont_start  ),
    .in_a   (mont_a      ),
    .in_b   (mont_b      ),
    .in_m   (r_m         ),
    .result (mont_result ),
    .done   (mont_done   ));

  // Count the cycles of the last multiplication, for debugging and reporting.
  reg [31:0] r_mul_cycles = 32'h0;
  always @(posedge clk)
    if (~resetn)                      r_mul_cycles <= 32'h0;
    else if (state == STATE_MUL_START) r_mul_cycles <= 32'h1;
    else if (state == STATE_MUL_WAIT)  r_mul_cycles <= r_mul_cycles + 32'h1;

  //////////////////////////////////////////////////////////////////////////////
  // Status
  //////////////////////////////////////////////////////////////////////////////

  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);

  assign rout0 = {24'b0, state, 1'b0, dma_error, isStateIdle, isStateDone};
  assign rout1 = rin1;
  assign rout2 = rin2;
  assign rout3 = r_mul_cycles;
  assign rout4 = 32'b0;
  assign rout5 = 32'b0;
  assign rout6 = 32'b0;
  assign rout7 = 32'b0;

  assign leds = state;

endmodule

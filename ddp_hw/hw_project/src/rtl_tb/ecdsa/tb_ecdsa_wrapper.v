`timescale 1ns / 1ps

`define HUGE_WAIT   300
`define LONG_WAIT   100
`define RESET_TIME   25
`define CLK_PERIOD   10
`define CLK_HALF      5

module tb_ecdsa_wrapper();
    
  reg           clk         ;
  reg           resetn      ;
  wire          leds        ;

  reg  [16:0]   mem_addr    = 'b0 ;
  reg  [1023:0] mem_din     = 'b0 ;
  wire [1023:0] mem_dout    ;
  reg  [127:0]  mem_we      = 'b0 ;

  reg  [ 11:0] axil_araddr  ;
  wire         axil_arready ;
  reg          axil_arvalid ;
  reg  [ 11:0] axil_awaddr  ;
  wire         axil_awready ;
  reg          axil_awvalid ;
  reg          axil_bready  ;
  wire [  1:0] axil_bresp   ;
  wire         axil_bvalid  ;
  wire [ 31:0] axil_rdata   ;
  reg          axil_rready  ;
  wire [  1:0] axil_rresp   ;
  wire         axil_rvalid  ;
  reg  [ 31:0] axil_wdata   ;
  wire         axil_wready  ;
  reg  [  3:0] axil_wstrb   ;
  reg          axil_wvalid  ;
      
  tb_ecdsa_project_wrapper dut (
    .clk                 ( clk           ),
    .leds                ( leds          ),
    .resetn              ( resetn        ),
    .s_axi_csrs_araddr   ( axil_araddr   ),
    .s_axi_csrs_arready  ( axil_arready  ),
    .s_axi_csrs_arvalid  ( axil_arvalid  ),
    .s_axi_csrs_awaddr   ( axil_awaddr   ),
    .s_axi_csrs_awready  ( axil_awready  ),
    .s_axi_csrs_awvalid  ( axil_awvalid  ),
    .s_axi_csrs_bready   ( axil_bready   ),
    .s_axi_csrs_bresp    ( axil_bresp    ),
    .s_axi_csrs_bvalid   ( axil_bvalid   ),
    .s_axi_csrs_rdata    ( axil_rdata    ),
    .s_axi_csrs_rready   ( axil_rready   ),
    .s_axi_csrs_rresp    ( axil_rresp    ),
    .s_axi_csrs_rvalid   ( axil_rvalid   ),
    .s_axi_csrs_wdata    ( axil_wdata    ),
    .s_axi_csrs_wready   ( axil_wready   ),
    .s_axi_csrs_wstrb    ( axil_wstrb    ),
    .s_axi_csrs_wvalid   ( axil_wvalid   ),
    .mem_clk             ( clk           ), 
    .mem_addr            ( mem_addr      ),     
    .mem_din             ( mem_din       ), 
    .mem_dout            ( mem_dout      ), 
    .mem_en              ( 1'b1          ), 
    .mem_rst             (~resetn        ), 
    .mem_we              ( mem_we        ));
      
  // Generate Clock
  initial begin
      clk = 0;
      forever #`CLK_HALF clk = ~clk;
  end

  // Initialize signals to zero
  initial begin
    axil_araddr  <= 'b0;
    axil_arvalid <= 'b0;
    axil_awaddr  <= 'b0;
    axil_awvalid <= 'b0;
    axil_bready  <= 'b0;
    axil_rready  <= 'b0;
    axil_wdata   <= 'b0;
    axil_wstrb   <= 'b0;
    axil_wvalid  <= 'b0;
  end

  // Reset the circuit
  initial begin
      resetn = 0;
      #`RESET_TIME
      resetn = 1;
  end

  // Read from specified register
  task reg_read;
    input [11:0] reg_address;
    output [31:0] reg_data;
    begin
      // Channel AR
      axil_araddr  <= reg_address;
      axil_arvalid <= 1'b1;
      wait (axil_arready);
      #`CLK_PERIOD;
      axil_arvalid <= 1'b0;
      // Channel R
      axil_rready  <= 1'b1;
      wait (axil_rvalid);
      reg_data <= axil_rdata;
      #`CLK_PERIOD;
      axil_rready  <= 1'b0;
      $display("[READ]  reg[%x] <= %x", reg_address, reg_data);
      #`CLK_PERIOD;
      #`RESET_TIME;
    end
  endtask

  // Write to specified register
  task reg_write;
    input [11:0] reg_address;
    input [31:0] reg_data;
    begin
      // Channel AW
      axil_awaddr <= reg_address;
      axil_awvalid <= 1'b1;
      // Channel W
      axil_wdata  <= reg_data;
      axil_wstrb  <= 4'b1111;
      axil_wvalid <= 1'b1;
      // Channel AW
      wait (axil_awready);
      #`CLK_PERIOD;
      axil_awvalid <= 1'b0;
      // Channel W
      wait (axil_wready);
      #`CLK_PERIOD;
      axil_wvalid <= 1'b0;
      // Channel B
      axil_bready <= 1'b1;
      wait (axil_bvalid);
      #`CLK_PERIOD;
      axil_bready <= 1'b0;
      $display("[WRITE] reg[%x] <= %x", reg_address, reg_data);
      #`CLK_PERIOD;
      #`RESET_TIME;
    end
  endtask

  // Write to given address in memory
  task mem_write;
    input [  16:0] address;
    input [1024:0] data;
    begin
      mem_addr <= address;
      mem_din  <= data;
      mem_we   <= {128{1'b1}};
      #`CLK_PERIOD;
      mem_we   <= {128{1'b0}};
      $display("[WRITE] mem[%x] <= %x", address, data);
      #`CLK_PERIOD;
    end
  endtask

  // Read from given address in memory
  task mem_read;
    input [  16:0] address;
    begin
      mem_addr <= address;
      #`CLK_PERIOD;
      #`CLK_PERIOD;
      #`CLK_PERIOD;
      $display("[READ]  mem[%x] => %x", address, mem_dout);
    end
  endtask

  // Byte Addresses of 32-bit input registers (SW to HW)
  localparam  COMMAND = 0, // r0
              RXADDR  = 4, // r1
              TXADDR  = 8; // r2

  // Byte Addresses of 32-bit output registers (HW to SW)
  localparam  STATUS     = 0,   // r0
              MUL_CYCLES = 12;  // r3

  // Commands
  localparam  CMD_IDLE    = 32'd0,
              CMD_LOAD_M  = 32'd1,
              CMD_MONTMUL = 32'd2;

  // Byte Addresses of 1024-bit distant memory locations
  localparam  MEM0_ADDR  = 16'h000,  // modulus
              MEM1_ADDR  = 16'h080,  // operands {B, A}
              MEM2_ADDR  = 16'h100;  // result

  reg [31:0] reg_status;
  reg [31:0] reg_cycles;

  // Write a command, wait until the FPGA is done, and release the command
  task run_command;
    input [31:0] cmd;
    begin
      reg_write(COMMAND, cmd);
      reg_read(STATUS, reg_status);
      while (reg_status[0]==1'b0)
      begin
        #`LONG_WAIT;
        reg_read(STATUS, reg_status);
      end
      reg_write(COMMAND, CMD_IDLE);
    end
  endtask

  // Same testvector as tb_montgomery.v
  // You can generate your own with the testvector generator python script
  reg [376:0] in_a     = 377'h01b8a55b0f9f0ec9a380d9663d7e16cd96fe122a8b4f1e212c00772de94d88c20060be12d6c3abb0a05600685e8916a;
  reg [376:0] in_b     = 377'h0d07020c5b8695ee00b13b98bfb7aa172c5f3f5702915d66a6ab12f5f5fb7048142eb8c8837de3d99f8364b9bbd7275;
  reg [376:0] in_m     = 377'h108fdf501b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5;
  reg [376:0] expected = 377'h05752257d8d92ab267903ab686f246ef68c9e433d3ec09cfb625deb2c101d25f04b770b72b0e9c66ee79cf720168b8a;

  initial begin

    #`LONG_WAIT

    // Memory contents, as the software would prepare them:
    // every 377-bit value is padded with zeros to 512 bits
    mem_write(MEM0_ADDR, {647'b0, in_m});
    mem_write(MEM1_ADDR, {135'b0, in_b, 135'b0, in_a});
    mem_write(MEM2_ADDR, 1024'b0);

    // Load the modulus
    reg_write(RXADDR, MEM0_ADDR);
    run_command(CMD_LOAD_M);

    // Multiply
    reg_write(RXADDR, MEM1_ADDR);
    reg_write(TXADDR, MEM2_ADDR);
    run_command(CMD_MONTMUL);

    reg_read(MUL_CYCLES, reg_cycles);
    mem_read(MEM2_ADDR);

    $display("result calculated=%x", mem_dout[376:0]);
    $display("result expected  =%x", expected);
    $display("multiplier cycles=%0d", reg_cycles);
    if (mem_dout === {647'b0, expected})
      $display("PASS");
    else if (mem_dout[376:0] === {377{1'b1}})
      $display("FAIL: result is all ones, is montgomery.v still the empty template?");
    else
      $display("FAIL");

    $finish;

  end
endmodule

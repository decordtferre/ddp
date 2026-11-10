`timescale 1ns / 1ps

// Montgomery multiplier: result = in_a * in_b * R^-1 mod in_m, with R = 2^377
//
// PLACEHOLDER IMPLEMENTATION
// Straightforward bit-serial version of MontMul in testvectors/HW.py, written
// to get the interface working. It is correct but not optimised: every bit of
// in_a takes two additions, so one multiplication takes about 760 cycles.
//
// Requirements:
//   - in_a and in_b are smaller than in_m, and in_m is odd
//   - start is high for one cycle
//   - in_b and in_m stay stable until done (in_a is sampled at start)
// done is high for one cycle. The result stays valid until the next start.
//
// The result register of the adder is used as the accumulator C, so there is
// no separate register for it:
//
//   S_INIT : C = 0
//   repeat 377 times
//     S_ADD_B : C = (C >> 1) + (a[0] ? B : 0)       a = a >> 1
//     S_ADD_M : C =  C       + (C[0] ? M : 0)
//   S_SUB  : keep C >> 1 as the result, compute (C >> 1) - M
//   S_FIN  : if the subtraction is not negative, it replaces the result

module montgomery(
  input           clk,
  input           resetn,
  input           start,
  input  [376:0] in_a,
  input  [376:0] in_b,
  input  [376:0] in_m,
  output [376:0] result,
  output          done
    );

  localparam
    S_IDLE  = 3'd0,
    S_INIT  = 3'd1,
    S_ADD_B = 3'd2,
    S_ADD_M = 3'd3,
    S_SUB   = 3'd4,
    S_FIN   = 3'd5;

  reg [2:0]   state;
  reg [376:0] r_a;        // shifts right, r_a[0] is the current bit of A
  reg [8:0]   r_count;    // number of processed bits of A
  reg [376:0] r_result;
  reg         r_done;

  // Adder
  reg          add_start;
  reg          add_subtract;
  reg  [379:0] add_in_a;
  reg  [379:0] add_in_b;
  wire [380:0] add_result;
  wire         add_done;

  adder adder_instance (
    .clk      (clk          ),
    .resetn   (resetn       ),
    .start    (add_start    ),
    .subtract (add_subtract ),
    .in_a     (add_in_a     ),
    .in_b     (add_in_b     ),
    .result   (add_result   ),
    .done     (add_done     ));

  // C stays below 2M + B < 2^379 in every step, so it fits in the 380-bit
  // adder inputs and C >> 1 is below 2M at the end.
  wire [379:0] c         = add_result[379:0];
  wire [379:0] c_shifted = add_result[380:1];

  always @(*) begin
    add_start    = 1'b0;
    add_subtract = 1'b0;
    add_in_a     = 380'b0;
    add_in_b     = 380'b0;

    case (state)
      S_INIT: begin
        add_start = 1'b1;                    // 0 + 0, clears C
      end
      S_ADD_B: begin
        add_start = 1'b1;
        add_in_a  = c_shifted;
        add_in_b  = r_a[0] ? {3'b0, in_b} : 380'b0;
      end
      S_ADD_M: begin
        add_start = 1'b1;
        add_in_a  = c;
        add_in_b  = c[0] ? {3'b0, in_m} : 380'b0;
      end
      S_SUB: begin
        add_start    = 1'b1;
        add_subtract = 1'b1;
        add_in_a     = c_shifted;
        add_in_b     = {3'b0, in_m};
      end
      default: ;
    endcase
  end

  always @(posedge clk) begin
    if (!resetn) begin
      state    <= S_IDLE;
      r_a      <= 377'b0;
      r_count  <= 9'd0;
      r_result <= 377'b0;
      r_done   <= 1'b0;
    end else begin
      r_done <= 1'b0;

      case (state)
        S_IDLE: begin
          if (start) begin
            r_a     <= in_a;
            r_count <= 9'd0;
            state   <= S_INIT;
          end
        end

        S_INIT: begin
          state <= S_ADD_B;
        end

        S_ADD_B: begin
          r_a   <= {1'b0, r_a[376:1]};
          state <= S_ADD_M;
        end

        S_ADD_M: begin
          r_count <= r_count + 9'd1;
          state   <= (r_count == 9'd376) ? S_SUB : S_ADD_B;
        end

        // c_shifted is the result if it is smaller than M
        S_SUB: begin
          r_result <= c_shifted[376:0];
          state    <= S_FIN;
        end

        // add_result[380] is the sign of (C >> 1) - M
        S_FIN: begin
          if (!add_result[380])
            r_result <= add_result[376:0];
          r_done <= 1'b1;
          state  <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

  assign result = r_result;
  assign done   = r_done;

endmodule

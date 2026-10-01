`timescale 1ns / 1ps

module adder(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire [379:0] in_a,
  input  wire [379:0] in_b,
  output reg  [380:0] result,
  output reg          done    
  );
  
  // Invert in_b bitwise when subtract is 1, pass as-is when 0
  wire [380:0] b_operand = {1'b0, in_b} ^ {381{subtract}};

  always @(posedge clk or negedge resetn) begin: addition
    if (!resetn) begin
        result <= 381'b0;
        done <= 1'b0;
    end else begin
    
        done <= 1'b0;
        if (start) begin
            // Single adder: A + (~B or B) + carry_in
            result <= {1'b0, in_a} + {1'b0, b_operand} + subtract;
            done   <= 1'b1;
        end
    end
end

endmodule

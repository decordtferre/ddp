`timescale 1ns / 1ps

/*
Modular adder/subtractor using 2's complement:
- If subtract == 0: out = (in_a + in_b) mod in_m
- If subtract == 1: out = (in_a - in_b) mod in_m

TIP! You can assume that in_a and in_b are smaller than in_m
-> in_a mod in_m = in_a
-> in_b mod in_m = in_b
*/


module modadder(
    input  wire [376:0] in_a,
    input  wire [376:0] in_b,
    input  wire [376:0] in_m,
    input  wire         subtract,
    input  wire         start,
    input  wire         clk,
    input  wire         resetn,
    output reg [376:0] result,
    output reg         done
); 

    // initiate adder we wrote previously
    wire [380:0] add_result;
    wire         add_done;
    
    adder my_adder (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .subtract(subtract),
        .in_a({3'b0, in_a}), // Explicitly pad 377-bit input to match adder's 380-bit width
        .in_b({3'b0, in_b}), // idem padding
        .result(add_result),
        .done(add_done)
    );

  always @(posedge clk or negedge resetn) begin: addition
    if (!resetn) begin
        result <= 377'b0;
        done <= 1'b0;
    end else begin
    
        done <= 1'b0;
        if (add_done) begin
            if (subtract) begin
                // Subtraction: if a < b, add modulus to wrap around to positive range
                if (in_a < in_b) begin
                    result <= in_m - (in_b - in_a); // better to avoid underflow
                end else begin
                    result <= in_a - in_b;
                end
            end else begin
                // Addition: if sum >= modulus, subtract modulus once because in_a and in_b are smaller than in_m
                if (add_result >= {3'b0, in_m}) begin
                    result <= add_result[376:0] - in_m;
                end else begin
                    result <= add_result[376:0];
                end
            end
        done <= 1'b1;
        end
    end
end
endmodule


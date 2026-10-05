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

    output reg  [376:0] result,
    output reg          done
);

    // ADDER 1: primary operation
    //
    // subtract = 0 -> A + B
    // subtract = 1 -> A - B
    

    wire [380:0] primary_result;
    wire         primary_done;

    adder primary_adder (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .subtract(subtract),

        .in_a({3'b000, in_a}),
        .in_b({3'b000, in_b}),

        .result(primary_result),
        .done(primary_done)
    );


  
    // ADDER 2: calculate B - A
    //
    // Only needed when doing modular subtraction AND A < B
    //
    

    wire [380:0] reverse_result;
    wire         reverse_done;

    adder reverse_adder (
        .clk(clk),
        .resetn(resetn),

        .start(start && subtract && (in_a < in_b)),

        .subtract(1'b1),

        .in_a({3'b000, in_b}),
        .in_b({3'b000, in_a}),

        .result(reverse_result),
        .done(reverse_done)
    );


    // ADDER 3: modular correction
    //
    // This adder is used for:
    //
    // Addition:
    //     (A+B) - M
    //
    // Subtraction when A<B:
    //     M - (B-A)
    

    reg          correction_start;
    reg  [379:0] correction_a;
    reg  [379:0] correction_b;

    wire [380:0] correction_result;
    wire         correction_done;

    adder correction_adder (
        .clk(clk),
        .resetn(resetn),

        .start(correction_start),

        // Both corrections are subtraction
        .subtract(1'b1),

        .in_a(correction_a),
        .in_b(correction_b),

        .result(correction_result),
        .done(correction_done)
    );


    // CONTROL LOGIC
    

    always @(posedge clk or negedge resetn) begin

        if (!resetn) begin

            result           <= 377'b0;
            done             <= 1'b0;

            correction_start <= 1'b0;
            correction_a     <= 380'b0;
            correction_b     <= 380'b0;

        end else begin

            // Default values: one-cycle pulses
            done             <= 1'b0;
            correction_start <= 1'b0;


            // First adder has finished
          

            if (primary_done) begin

                // MODULAR ADDITION
             
                if (!subtract) begin

                    // A + B >= M ?
                    if (primary_result >= {4'b0000, in_m}) begin

                        // Need:
                        // (A+B) - M
                        //
                        // Send this operation to correction_adder

                        correction_a <= primary_result[379:0];
                        correction_b <= {3'b000, in_m};

                        correction_start <= 1'b1;

                    end else begin

                        // Already smaller than M
                        result <= primary_result[376:0];
                        done   <= 1'b1;

                    end

                end


                // MODULAR SUBTRACTION
                
                else begin

                    if (in_a >= in_b) begin

                        // A-B is already positive
                        result <= primary_result[376:0];
                        done   <= 1'b1;

                    end else begin

                        // A < B
                        //
                        // reverse_adder calculated:
                        // B-A
                        //
                        // Now calculate:
                        // M - (B-A)

                        correction_a <= {3'b000, in_m};
                        correction_b <= reverse_result[379:0];

                        correction_start <= 1'b1;

                    end
                end
            end


            
            // Modular correction has finished
           

            if (correction_done) begin

                result <= correction_result[376:0];
                done   <= 1'b1;

            end

        end
    end

endmodule
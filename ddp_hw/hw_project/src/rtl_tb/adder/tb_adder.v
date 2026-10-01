`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_adder();

    // Define internal regs and wires
    reg          clk;
    reg          resetn;
    reg  [379:0] in_a;
    reg  [379:0] in_b;
    reg          start;
    reg          subtract;
    wire [380:0] result;
    wire         done;

    reg  [380:0] expected;
    reg          result_ok;

    // Instantiating adder
    adder dut (
        .clk      (clk     ),
        .resetn   (resetn  ),
        .start    (start   ),
        .subtract (subtract),
        .in_a     (in_a    ),
        .in_b     (in_b    ),
        .result   (result  ),
        .done     (done    ));

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // Initialize signals to zero
    initial begin
        in_a     <= 0;
        in_b     <= 0;
        subtract <= 0;
        start    <= 0;
    end

    // Reset the circuit
    initial begin
        resetn = 0;
        #`RESET_TIME
        resetn = 1;
    end

    task perform_add;
        input [379:0] a;
        input [379:0] b;
        begin
            in_a <= a;
            in_b <= b;
            start <= 1'd1;
            subtract <= 1'd0;
            #`CLK_PERIOD;
            start <= 1'd0;
            wait (done==1);
            #`CLK_PERIOD;
        end
    endtask

    task perform_sub;
        input [379:0] a;
        input [379:0] b;
        begin
            in_a <= a;
            in_b <= b;
            start <= 1'd1;
            subtract <= 1'd1;
            #`CLK_PERIOD;
            start <= 1'd0;
            wait (done==1);
            #`CLK_PERIOD;
        end
    endtask

    initial begin

    #`RESET_TIME

    /*************TEST ADDITION*************/
    
    $display("\nAddition with testvector 1");
    
    // Check if 1+1=2
    #`CLK_PERIOD;
    perform_add(380'h1, 
                380'h1);
    expected  = 381'h2;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;   
    
    
    $display("\nAddition with testvector 2");

    // Test addition with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_add(380'h9755ecd8db1754f63381348a186830b94099854e437b771da4ff8729d1c94111df165994d43f2799ca5dc7c28f61a50,
                380'h82ac1a181197e5234a7a93e37eb77b2c8d57b5512764d4440939423fe9c5f969fb0b980098b4ac0518fe0bb5c40e421);
    expected  = 381'h11a0206f0ecaf3a197dfbc86d971fabe5cdf13a9f6ae04b61ae38c969bb8f3a7bda21f1956cf3d39ee35bd378536fe71;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;     
    
    /*************TEST SUBTRACTION*************/

    $display("\nSubtraction with testvector 1");
    
    // Check if 1-1=0
    #`CLK_PERIOD;
    perform_sub(380'h1, 
                380'h1);
    expected  = 381'h0;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;    


    $display("\nSubtraction with testvector 2");

    // Test subtraction with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_sub(380'he276a81cdfcd2a40f8b3c863a3aab61ff227d6daa1bd7f1c606f42f536f6053f2e95251a315d2f0ee18f9b78e4bdc5f,
                380'h9112caf9377f1ba914e1339a824d28fcb6a79f152a83cd5330ac236a6d8a592c3de20bc5d99cabb52e3f66df09a8ba9);
    expected  = 381'h5163dd23a84e0e97e3d294c9215d8d233b8037c57739b1c92fc31f8ac96bac12f0b3195457c08359b3503499db150b6;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;    
    
    $finish;

    end

endmodule

`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_modadder();
// Define internal regs and wires
    reg          clk;
    reg          resetn;
    reg  [376:0] in_a;
    reg  [376:0] in_b;
    reg  [376:0] in_m;
    reg          start;
    reg          subtract;
    wire [376:0] result;
    wire         done;

    reg  [376:0] expected;
    reg          result_ok;

    // Instantiating adder
    modadder dut (
        .clk      (clk     ),
        .resetn   (resetn  ),
        .start    (start   ),
        .subtract (subtract),
        .in_a     (in_a    ),
        .in_b     (in_b    ),
        .in_m     (in_m    ),
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
        in_m     <= 0;
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
        input [376:0] a;
        input [376:0] b;
        input [376:0] m;
        begin
            in_a <= a;
            in_b <= b;
            in_m <= m;
            start <= 1'd1;
            subtract <= 1'd0;
            #`CLK_PERIOD;
            start <= 1'd0;
            wait (done==1);
            #`CLK_PERIOD;
        end
    endtask

    task perform_sub;
        input [376:0] a;
        input [376:0] b;
        input [376:0] m;
        begin
            in_a <= a;
            in_b <= b;
            in_m <= m;
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
    
    #`CLK_PERIOD;
    perform_add(377'h1b8a55b0f9f0ec9a380d9663d7e16cd96fe122a8b4f1e212c00772de94d88c20060be12d6c3abb0a05600685e8916a, 
                377'hd07020c5b8695ee00b13b98bfb7aa172c5f3f5702915d66a6ab12f5f5fb7048142eb8c8837de3d99f8364b9bbd7275,
                377'h108fdf501b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5);
    expected  = 377'hebfa7676b25a4b7a43214fefd35c0e4c35d51818de07b87d2ab8a23df48f90a148f76db5a418f8a3fd965221a603df;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;   
    
    
    $display("\nAddition with testvector 2");

    // Test addition with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_add(377'h12225959377f1ba914e1339a824d28fcb6a79f152a83cd5330ac236a6d8a592c3de20bc5d99cabb52e3f66df09a8ba9,
                377'h1a18a38ca5b2a1449dac9000db71fd4a5709e7c893c06f4dfc55f452df01ff7034721ec7b7ad1b81a9fcbb8fa9d363b,
                377'h1c4ed50cdfcd2a40f8b3c863a3aab61ff227d6daa1bd7f1c606f42f536f6053f2e95251a315d2f0ee18f9b78e4bdc5f);
    expected  = 377'hfec27d8fd6492acb9d9fb37ba1470271b89b0031c86bd84cc92d4c81596535d43bf05735fec9827f6ac86f5cebe585;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;     
    
    /*************TEST SUBTRACTION*************/

    $display("\nSubtraction with testvector 1");
    
    #`CLK_PERIOD;
    perform_sub(377'h1, 
                377'h2,
                377'h5);
    expected  = 377'h4;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;    


    $display("\nSubtraction with testvector 2");

    // Test subtraction with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_sub(377'h5490c6172f2b9bae5265e2e13d5fed4c2a3f4842294a32d0150b93eed13d89307dbcff8e281402ef58724464a560ff,
                377'h12f539c282453ed761673cfb46c5888613e0e7a897a39c6422d677095b1faa0fb6ca2c6f98f36b6669029b8e8c736b,
                377'h13a1972f3591330bc22aeaac665a5bffeb22885db7c833ff4d06003c67c404c453e004403c0719364df923a47507a9f);
    expected  = 377'h419b8c54ace65cd6f0fea5e5f69a64c6165e609991a6966bf2351ce5761ddf20c6f2d31e8f209788ef6fa8d618ed94;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;    
    
    $finish;

    end

endmodule

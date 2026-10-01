`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_montgomery();
    
    reg          clk;
    reg          resetn;
    reg          start;
    reg  [376:0] in_a;
    reg  [376:0] in_b;
    reg  [376:0] in_m;
    wire [376:0] result;
    wire         done;

    reg  [376:0] expected;
    reg          result_ok;
    
    //Instantiating montgomery module
    montgomery montgomery_instance( .clk    (clk    ),
                                    .resetn (resetn ),
                                    .start  (start  ),
                                    .in_a   (in_a   ),
                                    .in_b   (in_b   ),
                                    .in_m   (in_m   ),
                                    .result (result ),
                                    .done   (done   ));

    //Generate a clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end
    
    //Reset
    initial begin
        resetn = 0;
        #`RESET_TIME resetn = 1;
    end
    
    // Test data
    initial begin

        #`RESET_TIME
        
        // You can generate your own with test vector generator python script
        in_a        <= 377'h01b8a55b0f9f0ec9a380d9663d7e16cd96fe122a8b4f1e212c00772de94d88c20060be12d6c3abb0a05600685e8916a;
        in_b        <= 377'h0d07020c5b8695ee00b13b98bfb7aa172c5f3f5702915d66a6ab12f5f5fb7048142eb8c8837de3d99f8364b9bbd7275;
        in_m        <= 377'h108fdf501b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5;
        expected    <= 377'h05752257d8d92ab267903ab686f246ef68c9e433d3ec09cfb625deb2c101d25f04b770b72b0e9c66ee79cf720168b8a;
        start<=1;
        #`CLK_PERIOD;
        start<=0;
        
        wait (done==1);
        
        $display("result calculated=%x", result);
        $display("result expected  =%x", expected);
        $display("error            =%x", expected-result);
        result_ok = (expected==result);
        #`CLK_PERIOD;   
        
        $finish;
    end
           
endmodule
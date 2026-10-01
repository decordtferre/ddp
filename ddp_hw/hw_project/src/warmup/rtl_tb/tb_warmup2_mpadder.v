`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/22/2018 10:43:00 AM
// Design Name:
// Module Name: tb_adder
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_warmup2_mpadder();

    // Define internal regs and wires
    reg          clk;
    reg          resetn;
    reg          start;
    reg  [127:0] inA;
    reg  [127:0] inB;
    wire [128:0] outC;
    reg  [128:0] result;
    wire         done;
    reg          done_expected;
    wire         resultOk;   

    assign resultOk = ~done || ((outC == result) && (done == done_expected));          

    warmup2_mpadder dut(
        clk,
        resetn,
        start,
        inA,
        inB,
        outC,
        done);

    // Generate Clock
    initial begin
        clk = 1;
        forever #`CLK_HALF clk = ~clk;
    end

    // INPUTS and OUTPUTS
    initial begin
        resetn        <= 1'b0;
        start         <= 1'b0;
        inA           <= 128'h0;
        inB           <= 128'h0;
        result        <= 129'h0;
        done_expected <= 1'b0;

        #`RESET_TIME

        resetn <= 1'b1;
        
        #`RESET_TIME
        
        
        start  <= 1'b1;
        inA    <= 128'h0;
        inB    <= 128'h0;
        #`CLK_PERIOD;
        start  <= 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        result <= 129'h0;
        done_expected <= 1'b1;
        #`CLK_PERIOD;
        done_expected <= 1'b0;
        #`CLK_PERIOD;
        
        
        start  <= 1'b1;
        inA    <= 128'h1;
        inB    <= 128'h1;
        #`CLK_PERIOD;
        start  <= 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        result <= 129'h2;
        done_expected <= 1'b1;
        #`CLK_PERIOD;
        done_expected <= 1'b0;
        #`CLK_PERIOD;
        
        
        start         <= 1'b1;
        inA           <= 128'hd71558130b537e7c7a65f0407a6e75f5;
        inB           <= 128'hb0b0321bdb4ffcbb6eec116e1df61006;
        #`CLK_PERIOD;
        start         <= 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        result        <= 129'h187c58a2ee6a37b37e95201ae986485fb;
        done_expected <= 1'b1;
        #`CLK_PERIOD;
        done_expected <= 1'b0;
        #`CLK_PERIOD;

        
        start         <= 1'b1;
        inA           <= 128'hf974a928a315d2f0ee18f9b78e4bdc5f;
        inB           <= 128'hff913eb6aa1bd7f1c606f42f536f6053;
        #`CLK_PERIOD;
        start         <= 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        result        <= 129'h1f905e7df4d31aae2b41fede6e1bb3cb2;
        done_expected <= 1'b1;
        #`CLK_PERIOD;
        done_expected <= 1'b0;
        #`CLK_PERIOD;
        
        
        start         <= 1'b1;
        inA           <= 128'h1df165994d43f2799ca5dc7c28f61a51;
        inB           <= 128'h94099854e437b771da4ff8729d1c9412;
        #`CLK_PERIOD;
        start         <= 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        result        <= 129'h0b1fafdee317ba9eb76f5d4eec612ae63;
        done_expected <= 1'b1;
        #`CLK_PERIOD;
        done_expected <= 1'b0;
        #`CLK_PERIOD;


        $finish;
    end

endmodule

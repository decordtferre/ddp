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

module tb_warmup3_pipelined_adder();

    // Define internal regs and wires
    reg          clk;
    reg          resetn;
    reg          start;
    reg          Cin;
    reg  [379:0] inA;
    reg  [379:0] inB;
    wire [380:0] outC;
    reg  [380:0] result;
    wire         done;
    reg          done_expected;
    wire         resultOk;   

    assign resultOk = ((outC == result) && (done == done_expected));          

    warmup3_pipelined_adder dut(
        clk,
        resetn,
        start,
        Cin,
        inA,
        inB,
        outC,
        done);

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // INPUTS
    initial begin
        resetn <= 1'b0;
        start  <= 1'b0;
        Cin    <= 1'h0;
        inA    <= 380'h0;
        inB    <= 380'h0;

        #`RESET_TIME

        resetn <= 1'b1;
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 380'h0;
        inB    <= 380'h0;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 380'h847efa901b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5;
        inB    <= 380'h9244252b2b32f5080a47c1aaec4e4793ad045598404ee9d81ac18e0fc8ae892ce30bc0738bfb937846b50470057075f;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h1;
        inA    <= 380'he276a81cdfcd2a40f8b3c863a3aab61ff227d6daa1bd7f1c606f42f536f6053f2e95251a315d2f0ee18f9b78e4bdc5f;
        inB    <= 380'h9112caf9377f1ba914e1339a824d28fcb6a79f152a83cd5330ac236a6d8a592c3de20bc5d99cabb52e3f66df09a8ba9;

        #`CLK_PERIOD;
        
        start  <= 1'b1;
        Cin    <= 1'h0;
        inA    <= 380'hf8344a375ab5ab92c9ee54847f82416bb50e83608fec0dd3f762367b09e0c884572ed8795610452768dbec3de25019d;
        inB    <= 380'hca577535e02357147d62e56964cfa32d680119e4529e1fc0c3638aece6cc1950e40b78d91c11d28ab4193e78093aaca;

        #`CLK_PERIOD;
        start  <= 1'b0;
    end

    // CHECK OUTPUTS
    initial begin
        result = 381'h0;
        done_expected = 1'b0;
        // Copy delays before we start computations by raising resetn to high
        #`RESET_TIME

        // Start of computation, now delay as long as the dut
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;

        // We expect the first output now
        result = 381'h0;
        done_expected = 1'b1;
        #`CLK_PERIOD;
        // The second output now
        result = 381'h116c31fbb46c6db46710ea9ef9b1e7859c30a9905f54eb58f0982a4f1a80f8997c5b6c2d441337b3fed140877ac57d54;
        done_expected = 1'b1;
        #`CLK_PERIOD;
        // And so on...
        result = 381'h173897316174c45ea0d94fbfe25f7df1ca8cf75efcc414c6f911b665fa4805e6b6c7730e00af9dac40fcf0257ee66809;
        done_expected = 1'b1;
        #`CLK_PERIOD;

        result = 381'h1c28bbf6d3ad902a7475139ede451e4991d0f9d44e28a2d94bac5c167f0ace1d53b3a5152722217b21cf52ab5eb8ac67;
        done_expected = 1'b1;
        #`CLK_PERIOD;

        done_expected = 1'b0;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        $finish;
    end

endmodule

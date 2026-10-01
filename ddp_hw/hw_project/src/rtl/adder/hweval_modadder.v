`timescale 1ns / 1ps

module hweval_modadder (
    input   clk     ,
    input   resetn  ,
    output  data_ok );

    reg           start;
    reg           subtract;
    reg  [376:0] in_a;
    reg  [376:0] in_b;
    reg  [376:0] in_m;
    wire [376:0] result;
    wire          done;
       
    // Instantiate the adder    
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

    reg [1:0] state;

    always @(posedge(clk)) begin
    
        if (!resetn) begin
            in_a     <= 377'b1;
            in_b     <= 377'b1;
            in_m     <= 377'h1ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001;
            subtract <= 1'b0;
                    
            start    <= 1'b0;           
            
            state    <= 2'b00;
        end else begin
    
            if (state == 2'b00) begin
                in_a     <= in_a;
                in_b     <= in_b;
                in_m     <= in_m;
                subtract <= subtract;
                
                start    <= 1'b1;            
                
                state    <= 2'b01;        
            
            end else if(state == 2'b01) begin
                in_a     <= in_a;
                in_b     <= in_b;
                in_m     <= in_m;
                subtract <= subtract;
                        
                start    <= 1'b0;           
                
                state    <= done ? 2'b10 : 2'b01;
            end
            
            else begin
                in_a     <= in_b ^ result[376:0];
                in_b     <= result[376:0];
                in_m     <= result[376:0] ^ 377'h1ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001;
                subtract <= result[376] & result[375];
                                    
                start    <= 1'b0;
                            
                state    <= 2'b00;
            end
        end
    end    
    
    assign data_ok = done & result[376] & result[375];
    
endmodule

module RegFile(
    input wire clk,
    input wire [4:0] regA, regB, regW,
    input wire [31:0] dataIn,
    input wire we, re,
    output wire [31:0] outA, outB
);
    reg [31:0] regs[31:0];
    reg [4:0] A, B;
    
    always @(posedge clk) begin
        if(we) begin
            if(regW != 0) begin
                regs[regW] <= dataIn;
                $display("written data (%d) to register $%d", dataIn, regW);
            end
        end else if(re) begin
            A <= regA;
            B <= regB;
            $display("read register $%d and $%d, data (%d) and (%d)", regA, regB, regs[regA], regs[regB]);
        end
    end

    assign outA = A == 5'd0 ? 32'd0 : regs[A];
    assign outB = B == 5'd0 ? 32'd0 : regs[B];
endmodule // RegFile
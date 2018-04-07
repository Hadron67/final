module CP0Regs(
    input wire clk,
    input wire we,
    input wire [5:0] regNum,
    input wire [31:0] dataIn,
    output wire [31:0] dataOut
);
    reg [31:0] regs[38:0];
    assign dataOut = regs[regNum];
    always @(posedge clk) begin
        if(we)
            regs[regNum] <= dataIn;
    end
endmodule
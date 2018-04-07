module CP0Regs(
    input wire clk,
    input wire we, re,
    input wire [4:0] rd,
    input wire [2:0] sel,
    input wire [31:0] dataIn,
    output wire [31:0] dataOut
);
    reg [31:0] regs[38:0];
    wire [5:0] regNum;
    reg [5:0] A;

    assign dataOut = regs[A];
    CP0RegNum num (
        .rd(rd),
        .sel(sel),
        .regNum(regNum)
    );
    always @(posedge clk) begin
        if(we)
            regs[regNum] <= dataIn;
        else if(re)
            A <= regNum;
    end
endmodule
module InstructionFetcher(
    input wire [31:0] pc,
    input wire branch,
    input wire jmp,
    input wire z,
    input wire [25:0] target,
    input wire [15:0] imm,

    output reg [31:0] nextpc
);
    logic [29:0] pc1, addedpc1, nextpc1;

    assign pc1 = pc[31:2];
    assign addedpc1 = pc1 + 30'd1;
    assign nextpc1 = 
        jmp ? { pc1[29:26], target } :
        branch && ~z ? $signed(addedpc1) + $signed(imm) :
        addedpc1;

    assign nextpc = {nextpc1, 2'd0};

endmodule // InstructionMem
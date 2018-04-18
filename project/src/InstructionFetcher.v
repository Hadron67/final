module InstructionFetcher(
    input  wire [31:0] pc, epc, ra,
    input  wire branch,
    input  wire jmp,
    input  wire z,
    input  wire [25:0] target,
    input  wire [15:0] imm,
    input wire jr,
    input wire exception, eret,
    output wire [31:0] nextpc
);
    wire [29:0] pc1, addedpc1;
    reg [29:0] nextpc1;

    assign pc1 = pc[31:2];
    assign addedpc1 = pc1 + 30'd1;
    assign nextpc = {nextpc1, 2'd0};

    always @* begin
        if(eret)
            nextpc1 = epc[31:2];
        else if(exception)
            nextpc1 = 30'h20000020;
        else if(jr)
            nextpc1 = ra[31:2];
        else if(jmp)
            nextpc1 = { pc1[29:26], target };
        else if(branch && ~z)
            nextpc1 = $signed(addedpc1) + $signed(imm);
        else
            nextpc1 = addedpc1;
    end

endmodule // InstructionMem
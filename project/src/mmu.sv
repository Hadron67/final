interface IMMU;
    wire [31:0] index, random, entryLo0, entryLo1, ctx, pageMask, wired, entryHi;
    wire writeTlb, tlbMiss, tlbModified, tlbInvalid;
    modport cpu(
        input tlbMiss, tlbModified, tlbInvalid,
        output index, random, entryLo0, entryLo1, ctx, pageMask, wired, entryHi, writeTlb
    );
    modport mmu(
        output tlbMiss, tlbModified, tlbInvalid,
        input index, random, entryLo0, entryLo1, ctx, pageMask, wired, entryHi, writeTlb
    );
endinterface

module MMU(
    input wire clk, res,
    input wire [31:0] vAddr,
    output wire [31:0] pAddr,
    IMMU.mmu it
);
    localparam ENTRYHI_MASK = 32'hffffe0ff;// used to set 12-8 bits to zero
    logic [255:0] tlbEntries[63:0];
    always @(posedge clk) begin
        if(it.writeTlb)
            tlbEntries[it.index] <= {ENTRYHI_MASK & it.entryHi, it.entryLo0, it.entryLo1};
    end
endmodule
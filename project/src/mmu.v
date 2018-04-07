module MMU(
    input  wire clk, res,
    input  wire [31:0] vAddr,
    output wire [31:0] pAddr,
    
    input  wire [31:0] mmu_index, 
                       mmu_random, 
                       mmu_entryLo0, 
                       mmu_entryLo1, 
                       mmu_ctx, 
                       mmu_pageMask, 
                       mmu_wired, 
                       mmu_entryHi,
    input  wire        mmu_writeTlb,
    output wire        mmu_tlbMiss, 
                       mmu_tlbModified, 
                       mmu_tlbInvalid
);
    localparam ENTRYHI_MASK = 32'hffffe0ff;// used to set 12-8 bits to zero

    reg [255:0] tlbEntries[63:0];
    always @(posedge clk) begin
        if(mmu_writeTlb)
            tlbEntries[mmu_index] <= {ENTRYHI_MASK & mmu_entryHi, mmu_entryLo0, mmu_entryLo1};
    end
endmodule
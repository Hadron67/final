`include "mmu.vh"
module MMU #(
    parameter ENTRY_ADDR_WIDTH = 3
) (
    input  wire clk, res,
    input  wire addrValid,
    input  wire [31:0] vAddrIn,
    output wire [31:0] pAddrOut,
    output wire        ready,

    input  wire [31:0]   mmu_index,
                         mmu_random,
                         mmu_entryLo0,
                         mmu_entryLo1,
                         mmu_ctx,
                         mmu_pageMask,
                         mmu_wired,
                         mmu_entryHi,
    input  wire `TLBOP_T mmu_cmd,
    input wire           mmu_cmdValid,
    output wire [31:0]   matchedIndex,

    output wire          mmu_tlbMiss,
                         mmu_tlbModified,
                         mmu_tlbInvalid
);
    localparam ENTRY_COUNT = 1 << ENTRY_ADDR_WIDTH;
    localparam PAGEMASK_MASK = 32'hffffe0ff;// used to set 12-8 bits to zero
    localparam ENTRYHI_MASK  = 32'h1fffe000;

    wire vaSrc;
    wire [31:0] vAddr;
    reg [31:0] pAddr;
    // TLB entries
    reg [31:0] tlb_entryHi[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_entryLo0[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_entryLo1[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_pageMask[ENTRY_COUNT - 1:0];
    wire [31:0] selectedEntryLo;
    wire [31:0] tlbRead_entryHi;
    wire [31:0] tlbRead_entryLo0;
    wire [31:0] tlbRead_entryLo1;
    wire [31:0] tlbRead_pageMask;
    wire [7:0] asid;
    wire found;
    reg matchedEvenOddBit;
    reg [3:0] matchedPageMaskKind;
    reg [31:0] tlbWriteIndex;
    wire [31:0] tlbReadIndex;
    // TLB lookup temprory variables
    wire [ENTRY_COUNT - 1:0] matched;

    wire writeTlb;

    assign tlbRead_entryHi  = tlb_entryHi[tlbReadIndex];
    assign tlbRead_entryLo0 = tlb_entryLo0[tlbReadIndex];
    assign tlbRead_entryLo1 = tlb_entryLo1[tlbReadIndex];
    assign tlbRead_pageMask = tlb_pageMask[tlbReadIndex];
    assign selectedEntryLo = matchedEvenOddBit ? tlbRead_entryLo1 : tlbRead_entryLo0;
    assign vaSrc = mmu_cmd == `TLBOP_TLBP ? 1'b1 : 1'b0;
    assign vAddr = vaSrc ? vAddrIn : {mmu_entryHi[31:13], {14{1'b0}}};
    assign asid = mmu_entryHi[7:0];
    assign found = |matched;
    assign mmu_tlbMiss = ~found;

    assign writeTlb = mmu_cmdValid && (mmu_cmd == `TLBOP_TLBWR || mmu_cmd == `TLBOP_TLBWI);
    assign tlbReadIndex = addrValid ? matchedIndex : mmu_index;

    assign pAddrOut = pAddr;

    always @* begin
        case(mmu_cmd)
            `TLBOP_TLBWR: tlbWriteIndex = mmu_random;
            `TLBOP_TLBWI: tlbWriteIndex = mmu_index;
            default: tlbWriteIndex = 32'dx;
        endcase
    end

    always @* begin
        case(tlbRead_pageMask[28:13])
            16'b0000_0000_0000_0000: matchedPageMaskKind = 4'd0; // 4KB
            16'b0000_0000_0000_0011: matchedPageMaskKind = 4'd1; // 16KB
            16'b0000_0000_0000_11xx: matchedPageMaskKind = 4'd2; // 64KB
            16'b0000_0000_0011_xxxx: matchedPageMaskKind = 4'd3; // 256KB
            16'b0000_0000_11xx_xxxx: matchedPageMaskKind = 4'd4; // 1MB
            16'b0000_0011_xxxx_xxxx: matchedPageMaskKind = 4'd5; // 4MB
            16'b0000_11xx_xxxx_xxxx: matchedPageMaskKind = 4'd6; // 16MB
            16'b0011_xxxx_xxxx_xxxx: matchedPageMaskKind = 4'd7; // 64MB
            16'b11xx_xxxx_xxxx_xxxx: matchedPageMaskKind = 4'd8; // 256MB
            default:                 matchedPageMaskKind = 4'dx;
        endcase
    end

    always @* begin
        case(matchedPageMaskKind)
            4'd0: matchedEvenOddBit = vAddrIn[12]; 
            4'd1: matchedEvenOddBit = vAddrIn[14];
            4'd2: matchedEvenOddBit = vAddrIn[16];
            4'd3: matchedEvenOddBit = vAddrIn[18]; 
            4'd4: matchedEvenOddBit = vAddrIn[20]; 
            4'd5: matchedEvenOddBit = vAddrIn[22]; 
            4'd6: matchedEvenOddBit = vAddrIn[24];
            4'd7: matchedEvenOddBit = vAddrIn[26];
            4'd8: matchedEvenOddBit = vAddrIn[28];
            default: matchedEvenOddBit = 1'bx;
        endcase
    end

    always @* begin
        case(matchedPageMaskKind)
            4'd0: pAddr = {selectedEntryLo[31:12], vAddrIn[11:0]}; 
            4'd1: pAddr = {selectedEntryLo[31:14], vAddrIn[13:0]};
            4'd2: pAddr = {selectedEntryLo[31:16], vAddrIn[15:0]};
            4'd3: pAddr = {selectedEntryLo[31:18], vAddrIn[17:0]};
            4'd4: pAddr = {selectedEntryLo[31:20], vAddrIn[19:0]}; 
            4'd5: pAddr = {selectedEntryLo[31:22], vAddrIn[21:0]}; 
            4'd6: pAddr = {selectedEntryLo[31:24], vAddrIn[23:0]};
            4'd7: pAddr = {selectedEntryLo[31:26], vAddrIn[25:0]};
            4'd8: pAddr = {selectedEntryLo[31:28], vAddrIn[27:0]};
            default: pAddr = 32'dx;
        endcase
    end

    genvar i;
    generate
        for(i = 0; i < ENTRY_COUNT; i = i + 1) begin: tlbLookup
            wire [31:0] entryHi = tlb_entryHi[i];
            wire [31:0] entryLo0 = tlb_entryLo0[i];
            wire [31:0] entryLo1 = tlb_entryLo1[i];
            wire [15:0] mask = tlb_pageMask[i][28:13];
            wire [18:0] tlb_vpn2 = entryHi[31:13];
            wire [18:0] vpn2 = vAddr[31:13];
            wire g = entryLo0[0] & entryLo1[0];

            assign matched[i] = tlb_vpn2 & ~mask == vpn2 & ~mask && (g || mmu_entryHi[7:0] == entryHi[7:0]);
        end
    endgenerate

    Encoder #(.OUT_WIDTH(ENTRY_ADDR_WIDTH)) matchedEncoder (
        .in(matched),
        .out(matchedIndex)
    );

    always @(posedge clk) begin
        if(writeTlb) begin
            tlb_pageMask[tlbWriteIndex] <= mmu_pageMask;
            tlb_entryHi [tlbWriteIndex] <= mmu_entryHi;
            tlb_entryLo0[tlbWriteIndex] <= mmu_entryLo0;
            tlb_entryLo1[tlbWriteIndex] <= mmu_entryLo1;
            $display("written TLB entry $%d", tlbWriteIndex);
        end
    end
endmodule
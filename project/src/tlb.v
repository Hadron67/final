module TLB #(
    parameter ENTRY_ADDR_WIDTH = 3
) (
    input wire clk, res,
    input wire [31:0] vAddr,
    output reg [31:0] pAddr,
    input wire [31:0] entryHiIn, entryLo0In, entryLo1In, pageMaskIn,
    input wire [31:0] index,
    input wire re, we,
    output wire [31:0] entryHiOut, entryLo0Out, entryLo1Out, pageMaskOut, matchedIndex,
    output wire found, bitD, bitV, bitG, 
    output wire [2:0] bitC
);
    localparam ENTRY_COUNT = 1 << ENTRY_ADDR_WIDTH;
    reg [31:0] tlb_entryHi[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_entryLo0[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_entryLo1[ENTRY_COUNT - 1:0];
    reg [31:0] tlb_pageMask[ENTRY_COUNT - 1:0];
    wire [31:0] selectedEntryLo;
    wire [15:0] mask;
    wire [ENTRY_ADDR_WIDTH - 1:0] readIndex, matchedIndexOut;
    wire [ENTRY_COUNT - 1:0] matched;
    reg [3:0] matchedPageMaskKind;
    reg matchedEvenOddBit;

    assign matchedIndex = {{(32 - ENTRY_ADDR_WIDTH){1'b0}}, matchedIndexOut};
    assign readIndex = re ? index : matchedIndex;
    assign entryHiOut = tlb_entryHi[readIndex];
    assign entryLo0Out = tlb_entryLo0[readIndex];
    assign entryLo1Out = tlb_entryLo1[readIndex];
    assign pageMaskOut = tlb_pageMask[readIndex];
    assign selectedEntryLo = matchedEvenOddBit ? entryLo1Out : entryLo0Out;
    assign bitD = selectedEntryLo[2];
    assign bitV = selectedEntryLo[1];
    assign bitG = selectedEntryLo[0];
    assign bitC = selectedEntryLo[5:3];
    assign mask = pageMaskOut[28:13];
    assign found = |matched;

    always @* begin: maskConverter
        if(~|mask)
            matchedPageMaskKind = 4'd0;
        else if(~|mask[15:2] && &mask[1:0])
            matchedPageMaskKind = 4'd1;
        else if(~|mask[15:4] && &mask[3:2])
            matchedPageMaskKind = 4'd2;
        else if(~|mask[15:6] && &mask[5:4])
            matchedPageMaskKind = 4'd3;
        else if(~|mask[15:8] && &mask[7:6])
            matchedPageMaskKind = 4'd4;
        else if(~|mask[15:10] && &mask[9:8])
            matchedPageMaskKind = 4'd5;
        else if(~|mask[15:12] && &mask[11:10])
            matchedPageMaskKind = 4'd6;
        else if(~|mask[15:14] && &mask[13:12])
            matchedPageMaskKind = 4'd7;
        else if(&mask[15:14])
            matchedPageMaskKind = 4'd8;
        else
            matchedPageMaskKind = 4'dx;
    end

    always @* begin
        case(matchedPageMaskKind)
            4'd0: matchedEvenOddBit = vAddr[12];
            4'd1: matchedEvenOddBit = vAddr[14];
            4'd2: matchedEvenOddBit = vAddr[16];
            4'd3: matchedEvenOddBit = vAddr[18];
            4'd4: matchedEvenOddBit = vAddr[20];
            4'd5: matchedEvenOddBit = vAddr[22];
            4'd6: matchedEvenOddBit = vAddr[24];
            4'd7: matchedEvenOddBit = vAddr[26];
            4'd8: matchedEvenOddBit = vAddr[28];
            default: matchedEvenOddBit = 1'bx;
        endcase
    end

    always @* begin
        case(matchedPageMaskKind)
            4'd0: pAddr = {selectedEntryLo[25:6], vAddr[11:0]}; 
            4'd1: pAddr = {selectedEntryLo[25:8], vAddr[13:0]};
            4'd2: pAddr = {selectedEntryLo[25:10], vAddr[15:0]};
            4'd3: pAddr = {selectedEntryLo[25:12], vAddr[17:0]};
            4'd4: pAddr = {selectedEntryLo[25:14], vAddr[19:0]}; 
            4'd5: pAddr = {selectedEntryLo[25:16], vAddr[21:0]}; 
            4'd6: pAddr = {selectedEntryLo[25:18], vAddr[23:0]};
            4'd7: pAddr = {selectedEntryLo[25:20], vAddr[25:0]};
            4'd8: pAddr = {selectedEntryLo[25:22], vAddr[27:0]};
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

            assign matched[i] = ((tlb_vpn2 & ~mask) == (vpn2 & ~mask)) && (g || entryHiIn[7:0] == entryHi[7:0]);
        end
    endgenerate

    Encoder #(.OUT_WIDTH(ENTRY_ADDR_WIDTH)) matchedEncoder (
        .in(matched),
        .out(matchedIndexOut)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin

        end
        else begin
            if(we) begin
                tlb_pageMask[index] <= pageMaskIn;
                tlb_entryHi [index] <= entryHiIn;
                tlb_entryLo0[index] <= entryLo0In;
                tlb_entryLo1[index] <= entryLo1In;
                `ifdef DEBUG_DISPLAY
                $display("written TLB entry $%d", index);
                `endif
            end
        end
    end

endmodule // TLB
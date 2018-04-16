`include "DataBus.vh"
`include "mmu.vh"

module MMU #(
    parameter ENTRY_ADDR_WIDTH = 3
) (
    input wire clk, res,
    input wire addrValid,
    input wire [31:0] vAddrIn,
    output reg [31:0] pAddrOut,

    input wire `MMU_REG_T mmu_reg,
    input wire `MEM_ACCESS_T mmu_accessType,
    input wire [31:0] mmu_dataIn,
    output reg [31:0] mmu_dataOut,
    input wire `MMU_CMD_T mmu_cmd,
    output reg `MMU_EXCEPTION_T mmu_exception
);
    localparam ENTRY_COUNT = 1 << ENTRY_ADDR_WIDTH;
    localparam PAGEMASK_MASK = 32'hffffe0ff;// used to set 12-8 bits to zero
    localparam ENTRYHI_MASK  = 32'h1fffe000;

    reg [31:0] reg_index;
    reg [31:0] reg_random;
    reg [31:0] reg_entryLo0;
    reg [31:0] reg_entryLo1;
    reg [31:0] reg_ctx;
    reg [31:0] reg_pageMask;
    reg [31:0] reg_wired;
    reg [31:0] reg_entryHi;

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
    wire [15:0] mask;
    wire [7:0] asid;
    wire [31:0] matchedIndex;
    reg matchedEvenOddBit;
    reg [3:0] matchedPageMaskKind;
    reg [31:0] tlbWriteIndex;
    wire [31:0] tlbReadIndex;
    reg `MMU_EXCEPTION_T exceptionReg;
    // TLB lookup temprory variables
    wire [ENTRY_COUNT - 1:0] matched;

    wire writeTlb;

    assign tlbRead_entryHi  = tlb_entryHi[tlbReadIndex];
    assign tlbRead_entryLo0 = tlb_entryLo0[tlbReadIndex];
    assign tlbRead_entryLo1 = tlb_entryLo1[tlbReadIndex];
    assign tlbRead_pageMask = tlb_pageMask[tlbReadIndex];
    assign mask = tlbRead_pageMask[28:13];
    assign selectedEntryLo = matchedEvenOddBit ? tlbRead_entryLo1 : tlbRead_entryLo0;
    assign vaSrc = mmu_cmd == `MMU_CMD_PROB_TLB ? 1'b1 : 1'b0;
    assign vAddr = vaSrc ? vAddrIn : {reg_entryHi[31:13], {12{1'b0}}};
    assign asid = reg_entryHi[7:0];

    assign writeTlb = mmu_cmd == `MMU_CMD_WRITE_TLB || mmu_cmd == `MMU_CMD_WRITE_TLB_RANDOM;
    assign tlbReadIndex = addrValid ? matchedIndex : reg_index;

    always @* begin
        case(mmu_cmd)
            `MMU_CMD_WRITE_TLB_RANDOM: tlbWriteIndex = reg_random;
            `MMU_CMD_WRITE_TLB:        tlbWriteIndex = reg_index;
            default: tlbWriteIndex = 32'dx;
        endcase
    end

    always @* begin
        if(~selectedEntryLo[1])
            exceptionReg = `MMU_EXCEPTION_TLBINVALID;
        else if(selectedEntryLo[2] && mmu_accessType == `MEM_ACCESS_W)
            exceptionReg = `MMU_EXCEPTION_TLBMODIFIED;
        else if(~|matched)
            exceptionReg = `MMU_EXCEPTION_TLBMISS;
        else
            exceptionReg = `MMU_EXCEPTION_NONE;
    end

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
        // case(tlbRead_pageMask[28:13])
        //     16'b0000_0000_0000_0000: matchedPageMaskKind = 4'd0; // 4KB
        //     16'b0000_0000_0000_0011: matchedPageMaskKind = 4'd1; // 16KB
        //     16'b0000_0000_0000_11xx: matchedPageMaskKind = 4'd2; // 64KB
        //     16'b0000_0000_0011_xxxx: matchedPageMaskKind = 4'd3; // 256KB
        //     16'b0000_0000_11xx_xxxx: matchedPageMaskKind = 4'd4; // 1MB
        //     16'b0000_0011_xxxx_xxxx: matchedPageMaskKind = 4'd5; // 4MB
        //     16'b0000_11xx_xxxx_xxxx: matchedPageMaskKind = 4'd6; // 16MB
        //     16'b0011_xxxx_xxxx_xxxx: matchedPageMaskKind = 4'd7; // 64MB
        //     16'b11xx_xxxx_xxxx_xxxx: matchedPageMaskKind = 4'd8; // 256MB
        //     default:                 matchedPageMaskKind = 4'dx;
        // endcase
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

            assign matched[i] = tlb_vpn2 & ~mask == vpn2 & ~mask && (g || reg_entryHi[7:0] == entryHi[7:0]);
        end
    endgenerate

    Encoder #(.OUT_WIDTH(ENTRY_ADDR_WIDTH)) matchedEncoder (
        .in(matched),
        .out(matchedIndex)
    );

    always @(posedge clk) begin: tlbWrite
        if(writeTlb) begin
            tlb_pageMask[tlbWriteIndex] <= reg_pageMask;
            tlb_entryHi [tlbWriteIndex] <= reg_entryHi;
            tlb_entryLo0[tlbWriteIndex] <= reg_entryLo0;
            tlb_entryLo1[tlbWriteIndex] <= reg_entryLo1;
            $display("written TLB entry $%d", tlbWriteIndex);
        end
    end

    always @(posedge clk) begin
        if(addrValid) begin
            pAddrOut <= pAddr;
            mmu_exception <= exceptionReg;
        end
    end

    always @(posedge clk) begin: registerReadWrite
        if(mmu_cmd == `MMU_CMD_WRITE_REG)
            case(mmu_reg)
                `MMU_REG_INDEX: begin
                    reg_index <= mmu_dataIn;
                    $display("written mmu 'Index' register with data %x", mmu_dataIn);
                end
                `MMU_REG_RANDOM: begin
                    reg_random <= mmu_dataIn;
                    $display("written mmu 'Random' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_ENTRYLO0: begin
                    reg_entryLo0 <= mmu_dataIn;
                    $display("written mmu 'EntryLo0' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_ENTRYLO1: begin
                    reg_entryLo1 <= mmu_dataIn;
                    $display("written mmu 'EntryL01' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_CTX: begin
                    reg_ctx <= mmu_dataIn;
                    $display("written mmu 'Context' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_PAGEMASK: begin
                    reg_pageMask <= mmu_dataIn;
                    $display("written mmu 'PageMask' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_WIRED: begin
                    reg_wired <= mmu_dataIn;
                    $display("written mmu 'Wired' register with data %x", mmu_dataIn);
                end 
                `MMU_REG_ENTRYHI: begin
                    reg_entryHi <= mmu_dataIn;
                    $display("written mmu 'EntryHi' register with data %x", mmu_dataIn);
                end 
            endcase
        else if(mmu_cmd == `MMU_CMD_READ_REG)
            case(mmu_reg)
                `MMU_REG_INDEX: begin
                    mmu_dataOut <= reg_index;
                    $display("read mmu 'Index' register, data %x", reg_index);
                end 
                `MMU_REG_RANDOM: begin
                    mmu_dataOut <= reg_random;
                    $display("read mmu 'Random' register, data %x", reg_random);
                end 
                `MMU_REG_ENTRYLO0: begin
                    mmu_dataOut <= reg_entryLo0;
                    $display("read mmu 'EntryLo0' register, data %x", reg_entryLo0);
                end 
                `MMU_REG_ENTRYLO1: begin
                    mmu_dataOut <= reg_entryLo1;
                    $display("read mmu 'EntryLo1' register, data %x", reg_entryLo1);
                end 
                `MMU_REG_CTX: begin
                    mmu_dataOut <= reg_ctx;
                    $display("read mmu 'Context' register, data %x", reg_ctx);
                end 
                `MMU_REG_PAGEMASK: begin
                    mmu_dataOut <= reg_pageMask;
                    $display("read mmu 'PageMask' register, data %x", reg_pageMask);
                end 
                `MMU_REG_WIRED: begin
                    mmu_dataOut <= reg_wired;
                    $display("read mmu 'Wired' register, data %x", reg_wired);
                end 
                `MMU_REG_ENTRYHI: begin
                    mmu_dataOut <= reg_entryHi;
                    $display("read mmu 'EntryHi' register, data %x", reg_entryHi);
                end 
            endcase
    end
endmodule
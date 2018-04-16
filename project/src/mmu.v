`include "DataBus.vh"
`include "mmu.vh"

module MMU #(
    parameter ENTRY_ADDR_WIDTH = 4
) (
    input wire clk, res,
    input wire addrValid,
    input wire [31:0] vAddr,
    output reg [31:0] pAddr,

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
    wire [31:0] tlbOut_entryHi, tlbOut_entryLo0, tlbOut_entryLo1, tlbOut_pageMask, tlbOut_index;
    wire found, valid, dirty;

    wire writeTlb;
    wire [31:0] pAddrReg;
    reg [31:0] tlbWriteIndex;
    reg `MMU_EXCEPTION_T exceptionReg;

    assign writeTlb = mmu_cmd == `MMU_CMD_WRITE_TLB || mmu_cmd == `MMU_CMD_WRITE_TLB_RANDOM;

    always @* begin
        case(mmu_cmd)
            `MMU_CMD_WRITE_TLB_RANDOM: tlbWriteIndex = reg_random;
            `MMU_CMD_WRITE_TLB:        tlbWriteIndex = reg_index;
            default: tlbWriteIndex = 32'dx;
        endcase
    end

    always @* begin
        if(!valid)
            exceptionReg = `MMU_EXCEPTION_TLBINVALID;
        else if(dirty && mmu_accessType == `MEM_ACCESS_W)
            exceptionReg = `MMU_EXCEPTION_TLBMODIFIED;
        else if(~found)
            exceptionReg = `MMU_EXCEPTION_TLBMISS;
        else
            exceptionReg = `MMU_EXCEPTION_NONE;
    end

    TLB #(
        .ENTRY_ADDR_WIDTH(ENTRY_ADDR_WIDTH)
    ) tlb (
        .clk(clk),
        .res(res),
        .vAddr(mmu_cmd == `MMU_CMD_PROB_TLB ? {reg_entryHi[31:13], {12{1'b0}}} : vAddr),
        .pAddr(pAddrReg),
        .entryHiIn(reg_entryHi),
        .entryLo0In(reg_entryLo0),
        .entryLo1In(reg_entryLo1),
        .pageMaskIn(reg_pageMask),
        .index(tlbWriteIndex),
        
        .we(writeTlb),
        .re(mmu_cmd == `MMU_CMD_READ_TLB),
        .found(found),
        .bitV(valid),
        .bitD(dirty),

        .entryHiOut(tlbOut_entryHi),
        .entryLo0Out(tlbOut_entryLo0),
        .entryLo1Out(tlbOut_entryLo1),
        .pageMaskOut(tlbOut_pageMask),
        .matchedIndex(tlbOut_index)
    );

    always @(posedge clk) begin
        if(addrValid) begin
            pAddr <= pAddrReg;
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
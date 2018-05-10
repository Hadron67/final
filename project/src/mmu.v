`include "DataBus.vh"
`include "mmu.vh"
`include "CPU.vh"

module MMU #(
    parameter TAG = "MMU",
    parameter ENTRY_ADDR_WIDTH = 4
) (
    input wire clk, res,
    input wire addrValid,
    input wire `CPU_MODE cpuMode,
    input wire [31:0] vAddr,
    output wire [31:0] pAddr,
    output wire db_io,

    input wire `MMU_REG mmu_reg,
    input wire `MEM_ACCESS mmu_accessType,
    input wire [31:0] mmu_dataIn,
    output reg [31:0] mmu_dataOut,
    input wire `MMU_CMD mmu_cmd,
    output reg `MMU_EXCEPTION mmu_exception
);
    localparam ENTRY_COUNT = 1 << ENTRY_ADDR_WIDTH;
    localparam PAGEMASK_MASK = 32'hffffe0ff;// used to set 12-8 bits to zero
    localparam ENTRYHI_MASK  = 32'h1fffe000;

    reg [31:0] reg_index;
    wire [31:0] reg_random;
    reg [31:0] reg_entryLo0;
    reg [31:0] reg_entryLo1;
    reg [31:0] reg_ctx;
    reg [31:0] reg_pageMask;
    reg [31:0] reg_wired;
    reg [31:0] reg_entryHi;
    reg [31:0] vAddrLatch;
    reg prob, convert;
    reg `MEM_ACCESS accessTypeReg;
    wire [31:0] tlbOut_entryHi, tlbOut_entryLo0, tlbOut_entryLo1, tlbOut_pageMask, tlbOut_index;
    wire found, valid, dirty;

    wire writeTlb, mapped;
    wire [31:0] tlbAddrOut, randomOut;
    reg [31:0] tlbWriteIndex;

    assign writeTlb = mmu_cmd == `MMU_CMD_WRITE_TLB || mmu_cmd == `MMU_CMD_WRITE_TLB_RANDOM;
    assign pAddr = mapped ? tlbAddrOut : {3'b000, vAddrLatch[28:0]};
    assign mapped = vAddrLatch[31:30] != 2'b10;
    assign db_io = vAddrLatch[31:29] == 3'b101;

    always @* begin
        case(mmu_cmd)
            `MMU_CMD_WRITE_TLB_RANDOM: tlbWriteIndex = reg_random[ENTRY_ADDR_WIDTH - 1:0];
            `MMU_CMD_WRITE_TLB:        tlbWriteIndex = reg_index;
            `MMU_CMD_READ_TLB:         tlbWriteIndex = reg_index;
            default: tlbWriteIndex = 32'dx;
        endcase
    end

    always @* begin
        if(mapped)
            if(!found || !valid)
                if(accessTypeReg == `MEM_ACCESS_W)
                    mmu_exception = `MMU_EXCEPTION_TLBS;
                else
                    mmu_exception = `MMU_EXCEPTION_TLBL;
            else if(dirty && accessTypeReg == `MEM_ACCESS_W)
                mmu_exception = `MMU_EXCEPTION_TLBMODIFIED;
            else
                mmu_exception = `MMU_EXCEPTION_NONE;
        else
            mmu_exception = `MMU_EXCEPTION_NONE;
    end

    Random32 randomGen (
        .clk(clk),
        .res(res),
        .out(reg_random)
    );
    TLB #(
        .ENTRY_ADDR_WIDTH(ENTRY_ADDR_WIDTH)
    ) tlb (
        .clk(clk),
        .res(res),
        .vAddr(vAddrLatch),
        .pAddr(tlbAddrOut),
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

    always @(posedge clk or posedge res) begin
        if(res) begin
            prob <= 1'b0;
            convert <= 1'b0;
        end
        else begin
            if(addrValid) begin
                vAddrLatch <= vAddr;
                accessTypeReg <= mmu_accessType;
                convert <= 1'b1;
            end
            else if(mmu_cmd == `MMU_CMD_PROB_TLB && !prob) begin
                vAddrLatch <= {reg_entryHi[31:13], {12{1'b0}}};
                prob <= 1'b1;
            end
            if(prob) begin
                prob <= 1'b0;
            end
            if(convert)
                convert <= 1'b0;
        end
    end

    always @(posedge clk) begin: registerReadWrite
        if(mmu_cmd == `MMU_CMD_WRITE_REG)
            case(mmu_reg)
                `MMU_REG_INDEX: begin
                    reg_index <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'Index' register with data %x"}, mmu_dataIn);
                    `endif
                end
                `MMU_REG_RANDOM: begin
                    // reg_random <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]Warning: attempt to write read-only register 'Random'"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_ENTRYLO0: begin
                    reg_entryLo0 <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'EntryLo0' register with data %x"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_ENTRYLO1: begin
                    reg_entryLo1 <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'EntryL01' register with data %x"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_CTX: begin
                    reg_ctx <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'Context' register with data %x"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_PAGEMASK: begin
                    reg_pageMask <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'PageMask' register with data %x"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_WIRED: begin
                    reg_wired <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'Wired' register with data %x"}, mmu_dataIn);
                    `endif
                end 
                `MMU_REG_ENTRYHI: begin
                    reg_entryHi <= mmu_dataIn;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]written mmu 'EntryHi' register with data %x"}, mmu_dataIn);
                    `endif
                end 
            endcase
        else if(mmu_cmd == `MMU_CMD_READ_REG)
            case(mmu_reg)
                `MMU_REG_INDEX: begin
                    mmu_dataOut <= reg_index;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'Index' register, data %x"}, reg_index);
                    `endif
                end 
                `MMU_REG_RANDOM: begin
                    mmu_dataOut <= reg_random;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'Random' register, data %x"}, reg_random);
                    `endif
                end 
                `MMU_REG_ENTRYLO0: begin
                    mmu_dataOut <= reg_entryLo0;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'EntryLo0' register, data %x"}, reg_entryLo0);
                    `endif
                end 
                `MMU_REG_ENTRYLO1: begin
                    mmu_dataOut <= reg_entryLo1;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'EntryLo1' register, data %x"}, reg_entryLo1);
                    `endif
                end 
                `MMU_REG_CTX: begin
                    mmu_dataOut <= reg_ctx;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'Context' register, data %x"}, reg_ctx);
                    `endif
                end 
                `MMU_REG_PAGEMASK: begin
                    mmu_dataOut <= reg_pageMask;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'PageMask' register, data %x"}, reg_pageMask);
                    `endif
                end 
                `MMU_REG_WIRED: begin
                    mmu_dataOut <= reg_wired;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'Wired' register, data %x"}, reg_wired);
                    `endif
                end 
                `MMU_REG_ENTRYHI: begin
                    mmu_dataOut <= reg_entryHi;
                    `ifdef DEBUG_DISPLAY
                    $display({"[", TAG, "]read mmu 'EntryHi' register, data %x"}, reg_entryHi);
                    `endif
                end 
            endcase
        else if(prob) begin
            if(found) begin
                reg_index <= tlbOut_index;
                `ifdef DEBUG_DISPLAY
                $display({"[", TAG, "]written matched index %d to register 'Index'"}, tlbOut_index);
                `endif
            end
            else begin
                reg_index <= 1 << ENTRY_ADDR_WIDTH;
                `ifdef DEBUG_DISPLAY
                $display({"[", TAG, "]no matched entry, written %d to register 'Index'"}, 1 << ENTRY_ADDR_WIDTH);
                `endif
            end
        end
        else if(convert && mmu_exception != `MMU_EXCEPTION_NONE) begin
            reg_ctx <= {reg_ctx[31:23], vAddrLatch[31:13], 4'd0};
            `ifdef DEBUG_DISPLAY
            $display({"[", TAG, "]written bad VPN2 0x%x to register 'Context'"}, vAddrLatch[31:13]);
            `endif
        end
    end
endmodule
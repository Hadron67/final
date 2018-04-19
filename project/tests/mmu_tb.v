`include "mmu.vh"
`timescale 1ns/1ns

module mmu_tb();
    localparam TLB_ADDR_WIDTH = 3;
    localparam TLB_ENTRY_COUNT = 1 << TLB_ADDR_WIDTH;

    reg clk, res;
    reg addrValid;
    reg [31:0] vAddr;
    wire [31:0] pAddr;

    reg `MMU_REG_T mmu_reg;
    reg `MEM_ACCESS_T mmu_accessType;
    reg [31:0] mmu_dataIn;
    reg `MMU_CMD_T mmu_cmd;
    wire [31:0] mmu_dataOut;
    wire `MMU_EXCEPTION_T mmu_exception;

    task writeReg;
        input `MMU_REG_T mmuReg;
        input [31:0] data;
        begin
            mmu_reg = mmuReg;
            mmu_dataIn = data;
            mmu_cmd = `MMU_CMD_WRITE_REG;
            clk = 1;
            #100;
            clk = 0;
            #100;
            mmu_cmd = `MMU_CMD_NONE;
        end
    endtask

    task writeEntryHi;
        input [18:0] vpn2;
        input [7:0] asid;
        begin
            writeReg(`MMU_REG_ENTRYHI, {vpn2, 5'd0, asid});
        end
    endtask

    task writePageMask;
        input [15:0] mask;
        begin
            writeReg(`MMU_REG_PAGEMASK, {3'd0, mask, 13'd0});
        end
    endtask

    task writeEntryLo;
        input which;
        input [25:0] fpn;
        input [2:0] c;
        input d, v, g;
        begin
            writeReg(which ? `MMU_REG_ENTRYLO1 : `MMU_REG_ENTRYLO0, {fpn, c, d, v, g});
        end
    endtask

    task writeEntry;
        input which;
        input [31:0] index;
        input [18:0] vpn2;
        input [7:0] asid;
        input [15:0] mask;
        input [25:0] fpn;
        input [2:0] c;
        input g;
        begin
            writeReg(`MMU_REG_INDEX, index);
            writeEntryHi(vpn2, asid);
            writePageMask(mask);
            writeEntryLo(which, fpn, c, 1'b0, 1'b1, g);
            sendcmd(`MMU_CMD_WRITE_TLB);
        end
    endtask

    task initTlb;
        reg [31:0] i;
        begin
            writeReg(`MMU_REG_ENTRYHI, 32'd0);
            writeReg(`MMU_REG_PAGEMASK, 32'd0);
            writeReg(`MMU_REG_ENTRYLO0, 32'd0);
            writeReg(`MMU_REG_ENTRYLO1, 32'd0);
            for (i = 0; i < TLB_ENTRY_COUNT; i = i + 1) begin
                writeReg(`MMU_REG_INDEX, i);
                sendcmd(`MMU_CMD_WRITE_TLB);
            end
        end
    endtask

    task sendcmd;
        input `MMU_CMD_T cmd;
        begin
            mmu_cmd = cmd;
            clk = 1;
            #100;
            clk = 0;
            #100;
            mmu_cmd = `MMU_CMD_NONE;
        end
    endtask

    task reset;
        begin
            res = 0;
            #100;
            res = 1;
            #100;
            res = 0;
        end
    endtask

    task testAddr;
        input [31:0] va;
        input [31:0] expected;
        input `MMU_EXCEPTION_T expectedException;
        begin
            vAddr = va;
            addrValid = 1'b1;
            #100;
            clk = 1;
            #100;
            clk = 0;
            #100;
            addrValid = 1'b0;
            if(mmu_exception != `MMU_EXCEPTION_NONE) begin
                $display("%x -> exception %x -- %s", va, mmu_exception, (mmu_exception == expectedException ? "passed" : "failed!"));
            end
            else
                $display("%x -> %x -- %s", va, pAddr, pAddr == expected ? "passed" : "failed!");
        end
    endtask
    
    MMU #(.ENTRY_ADDR_WIDTH(TLB_ADDR_WIDTH)) uut (
        .clk(clk),
        .res(res),
        .addrValid(addrValid),
        .pAddr(pAddr),
        .vAddr(vAddr),
        .mmu_cmd(mmu_cmd),
        .mmu_reg(mmu_reg),
        .mmu_accessType(mmu_accessType),
        .mmu_dataIn(mmu_dataIn),
        .mmu_dataOut(mmu_dataOut),
        .mmu_exception(mmu_exception)
    );
    initial begin
        $dumpfile({`OUT_DIR, "/mmu_tb.vcd"});
        $dumpvars(0, uut);
        clk = 0;
        res = 0;
        reset();
        // invalidate all entries
        initTlb();
        writeEntry(1'b0, 32'd0, 19'd1, 8'd1, 16'd0, 26'd4, 3'd0, 1'd0);
        writeEntry(1'b0, 32'd1, 19'd2, 8'd1, 16'd0, 26'd20, 3'd0, 1'd0);
        writeEntry(1'b0, 32'd2, 19'd3, 8'd1, 16'd0, 26'd70, 3'd0, 1'd0);
        writeEntry(1'b1, 32'd2, 19'd3, 8'd1, 16'd0, 26'd80, 3'd0, 1'd0);
        writeEntry(1'b0, 32'd3, 19'd4, 8'd1, 16'd0, 26'd100, 3'd0, 1'd0);
        writeEntry(1'b0, 32'd4, {17'd28, 2'd0}, 8'd1, 16'd3, {24'd500, 2'd0}, 3'd0, 1'd0);
        testAddr({19'd2, 1'b0, 12'd12}, {1'b0, 19'd20, 12'd12}, `MMU_EXCEPTION_NONE);
        testAddr({19'd3, 1'b0, 12'd14}, {1'b0, 19'd70, 12'd14}, `MMU_EXCEPTION_NONE);
        testAddr({19'd4, 1'b0, 12'd19}, {1'b0, 19'd100, 12'd19}, `MMU_EXCEPTION_NONE);
        testAddr({19'd3, 1'b1, 12'd19}, {1'b0, 19'd80, 12'd19}, `MMU_EXCEPTION_NONE);
        testAddr(32'h81234567, 32'h01234567, `MMU_EXCEPTION_NONE);// umapped
        mmu_accessType = `MEM_ACCESS_W;
        testAddr({19'd1, 1'b1, 12'd12}, 32'dx, `MMU_EXCEPTION_TLBS);
        mmu_accessType = `MEM_ACCESS_R;
        testAddr({19'd1, 1'b1, 12'd12}, 32'dx, `MMU_EXCEPTION_TLBL);
        testAddr({17'd28, 1'b0, 14'd54}, {1'b0, 17'd500, 14'd54}, `MMU_CMD_NONE);
        writeReg(`MMU_REG_ENTRYHI, 32'd2);
        testAddr({19'd1, 1'b1, 12'd12}, 32'dx, `MMU_EXCEPTION_TLBMISS);
        #1000;
        $dumpflush;
        $stop;
    end
endmodule // mmu_tb
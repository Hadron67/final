`include "font.vh"
`include "DataBus.vh"

`timescale 1ns/1ns
module DummyMem #(
    parameter MEM_SIZE = 8 * 1024 * 1024 // 8M
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr, vAddr,
    input wire `MEM_ACCESS db_accessType,
    input wire db_io,
    output wire db_ready,
    output wire [31:0] db_dataIn,
    output reg hlt
);
    localparam CMD_ADDR_HLT        = 32'd0;
    localparam CMD_ADDR_WRITE_CHAR = 32'd1;
    localparam CMD_ADDR_WRITE_NUM  = 32'd2;

    reg [7:0] mem[MEM_SIZE - 1:0];
    reg [31:0] addrLatch;
    wire [31:0] dataIn;
    wire [31:0] addr2;

    assign dataIn = db_dataOut;
    assign db_ready = 1'b1; // always be ready
    assign db_dataIn = {mem[addrLatch], mem[addrLatch + 1], mem[addrLatch + 2], mem[addrLatch + 3]};
    assign addr2 = {db_addr[31:2], 2'd0};

    always @(posedge clk or posedge res) begin
        if(res) begin

        end else begin
            if(db_io) begin
                case(db_addr)
                    CMD_ADDR_HLT: hlt <= 1'b1;
                    CMD_ADDR_WRITE_CHAR: $write("%c", dataIn[7:0]);
                    CMD_ADDR_WRITE_NUM: $write("%x", dataIn);
                endcase
            end
            else begin
                case(db_accessType)
                    `MEM_ACCESS_X: addrLatch <= addr2;
                    `MEM_ACCESS_R: addrLatch <= addr2;
                    `MEM_ACCESS_W: {mem[addr2], mem[addr2 + 1], mem[addr2 + 2], mem[addr2 + 3]} <= dataIn;
                endcase
            end
        end
    end
    integer file;
    integer i;
    initial begin
        hlt = 1'b0;
        file = $fopen({`ELF_DIR, "/mmu_test/mmu_test.bin"}, "rb");
        i = $fread(mem, file);
        $fclose(file);
    end
endmodule

module mmu_cpu_tb();
    reg clk, res;
    wire [31:0] db_dataOut, db_addr, db_dataIn, vAddr;
    wire `MEM_ACCESS db_accessType;
    wire db_ready, db_io;
    wire hlt;
    reg enableclk;
    integer cnt;

    CPU_MMU uut (
        .clk(clk),
        .res(res),
        .ready(1'b1),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_io(db_io),
        .vAddr(vAddr),
        .db_ready(db_ready),
        .db_accessType(db_accessType)
    );

    DummyMem mem (
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_io(db_io),
        .vAddr(vAddr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        // .db_memLen(db_memLen),
        .hlt(hlt)
    );

    initial begin
        $dumpfile({`OUT_DIR, "/mmu_cpu.vcd"});
        $dumpvars(0, uut);
        $display("------------------------------------------------");
        clk = 0;
        res = 0;
        cnt = 0;
        #100;
        res = 1;
        #100;
        res = 0;
    end

    always begin: clkDriver
        #100;
        if(hlt) begin
            $display("------------------------------------------------");
            $display({`FONT_GREEN, "exit command received, exit.", `FONT_END});
            $dumpflush;
            $stop;
        end 
        else if(cnt >= 65535) begin
            $display("------------------------------------------------");
            $display({`FONT_GREEN, "time's up, exit.", `FONT_END});
            $dumpflush;
            $stop;
        end
        clk <= ~clk;
        cnt <= cnt + 1;
    end


endmodule
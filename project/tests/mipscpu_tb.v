`include "font.vh"
module DummyMem #(
    parameter SIZE = 8 * 1024 * 1024,
    parameter MEM_FILE = "mmu_cpu.bin"
) (
    input wire clk, res,

    output wire db_ready, 
    output reg hlt,
    output wire [31:0] db_dataIn,
    input wire [31:0] db_dataOut, db_addr,
    input wire db_re, db_we, db_io
);
    localparam CMD_ADDR_HLT        = 32'd0;
    localparam CMD_ADDR_WRITE_CHAR = 32'd1;

    reg [7:0] mem[0:SIZE - 1];
    reg [31:0] addrLatch;
    wire [31:0] addr;

    assign addr = {db_addr[31:2], 2'd0};
    assign db_dataIn = {mem[addrLatch], mem[addrLatch + 1], mem[addrLatch + 2], mem[addrLatch + 3]};
    assign db_ready = 1'b1;

    always @(posedge clk or posedge res) begin
        if(res) begin
            hlt <= 1'b0;
        end
        else begin
            if(db_we) begin
                if(db_io) begin
                    case(db_addr)
                        CMD_ADDR_HLT: hlt <= 1'b1;
                        CMD_ADDR_WRITE_CHAR: $write("%c", db_dataOut[7:0]);
                    endcase
                end
                else
                    {mem[addr], mem[addr + 1], mem[addr + 2], mem[addr + 3]} <= db_dataOut;
            end
            else if(db_re) begin
                addrLatch <= addr;
            end
        end
    end

    integer i, file;
    initial begin
        hlt = 1'b0;
        file = $fopen(MEM_FILE, "rb");
        i = $fread(mem, file);
        $fclose(file);
    end
endmodule // DummyMem

module mipscpu_tb;
    reg clk, res;
    wire [31:0] db_dataIn, db_dataOut, db_addr;
    wire db_ready, db_re, db_we, db_io, hlt;
    integer cnt;

    MipsCPU cpu (
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_re(db_re),
        .db_we(db_we),
        .db_io(db_io),
        .db_ready(db_ready)
    );

    DummyMem #(.MEM_FILE({`ELF_DIR, "/mmu_test/mmu_test.bin"})) mem (
        .clk(clk),
        .res(res),
        .hlt(hlt),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_re(db_re),
        .db_we(db_we),
        .db_io(db_io),
        .db_ready(db_ready)
    );

    always begin
        #100;
        // if(cnt >= 100000) begin
        //     $display({`FONT_RED, "time's up, exit", `FONT_END});
        //     $dumpflush;
        //     $stop;
        // end
        cnt <= cnt + 1;
        clk <= ~clk;
    end

    initial begin
        $dumpfile({`OUT_DIR, "/mipscpu.vcd"});
        $dumpvars(0, cpu);
        clk = 0;
        res = 0;
        cnt = 0;
        #100;
        res = 1;
        #100;
        res = 0;
        wait(hlt);
        $display({`FONT_GREEN, "exit command received, exit.", `FONT_END});
        $dumpflush;
        $stop;
    end

endmodule
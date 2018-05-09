`include "font.vh"
`include "DataBus.vh"
`timescale 1ns/1ns
module DummyMem #(
    parameter SIZE = 8 * 1024 * 1024
) (
    input wire clk, res,
    input wire db_re, db_we,
    input wire [31:0] db_addr, db_dataOut,
    output wire [31:0] db_dataIn,
    output wire db_ready
);
    reg [7:0] mem[0:SIZE - 1];
    reg [31:0] addrLatch;
    wire [31:0] addr2 = {db_addr[31:2], 2'd0};

    assign db_ready = 1'b1;
    assign db_dataIn = {mem[addrLatch], mem[addrLatch + 1], mem[addrLatch + 2], mem[addrLatch + 3]};

    always @(posedge clk) begin
        if(db_we) begin
            mem[addr2] <= {mem[addr2], mem[addr2 + 1], mem[addr2 + 2], mem[addr2 + 3]} <= db_dataOut;
            // `ifdef DEBUG_DISPLAY
            // $display("write memory to address 0x%x", addr2);
            // `endif
        end
        else if(db_re) begin
            addrLatch <= addr2;
            // `ifdef DEBUG_DISPLAY
            // $display("read memory at address 0x%x", addr2);
            // `endif
        end
    end

    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) begin
            mem[i] = i + 2;
        end
        for(i = 17; i < 32; i = i + 1) begin
            mem[i] = 3;
        end
    end
endmodule

module cache_tb();
    reg clk, res;
    integer count;

    wire [31:0] dbOut_dataIn, dbOut_dataOut, dbOut_addr;
    wire dbOut_re, dbOut_we, dbOut_ready;

    wire [31:0] db_dataIn;
    reg [31:0] pAddr, vAddr, db_dataOut;
    // output wire db_ready,
    reg `MEM_ACCESS db_accessType;

    Cache #(.INBLOCK_ADDR_WIDTH(4)) uut (
        .clk(clk),
        .res(res),

        .pAddr(pAddr),
        .vAddr(vAddr),
        .db_dataOut(db_dataOut),
        .db_dataIn(db_dataIn),
        .db_accessType(db_accessType),

        .dbOut_dataIn(dbOut_dataIn), 
        .dbOut_ready(dbOut_ready),
        .dbOut_addr(dbOut_addr), 
        .dbOut_dataOut(dbOut_dataOut),
        .dbOut_re(dbOut_re), 
        .dbOut_we(dbOut_we)
    );

    DummyMem mem (
        .clk(clk),
        .res(res),
        .db_re(dbOut_re),
        .db_we(dbOut_we),
        .db_addr(dbOut_addr),
        .db_dataIn(dbOut_dataIn),
        .db_dataOut(dbOut_dataOut),
        .db_ready(dbOut_ready)
    );

    always begin
        #100;
        if(count >= 1000) begin
            $stop;
        end
        count <= count + 1;
        clk <= ~clk;
    end

    initial begin
        $dumpfile({`OUT_DIR, "/cache.vcd"});
        $dumpvars(0, uut);
        count = 0;
        clk = 0;
        res = 0;
        #100;
        res = 1;
        #100;
        res = 0;
        #100;
        db_accessType = `MEM_ACCESS_R;
        pAddr = 32'd0;
        vAddr = 32'd0;
    end
endmodule // cache_tb
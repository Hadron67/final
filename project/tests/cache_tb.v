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
            {mem[addr2], mem[addr2 + 1], mem[addr2 + 2], mem[addr2 + 3]} <= db_dataOut;
            `ifdef DEBUG_DISPLAY
            $display("[Main memory]write data 0x%x to address 0x%x", db_dataOut, addr2);
            `endif
        end
        else if(db_re) begin
            addrLatch <= addr2;
            // `ifdef DEBUG_DISPLAY
            // $display("[Main memory]read memory at address 0x%x, data 0x%x", addr2, {mem[addr2], mem[addr2 + 1], mem[addr2 + 2], mem[addr2 + 3]});
            // `endif
        end
    end

    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) begin
            mem[i] = i + 2;
        end
        for(i = 0; i < 16; i = i + 1) begin
            mem[i + 32'h100] = 3;
        end
        {mem[32'h100], mem[32'h101], mem[32'h102], mem[32'h103]} = 32'h bad_cafe;
    end
endmodule

module cache_tb();
    reg clk, res;
    integer count;

    wire [31:0] dbOut_dataIn, dbOut_dataOut, dbOut_addr;
    wire dbOut_re, dbOut_we, dbOut_ready, ready, db_ready;

    wire [31:0] db_dataIn;
    reg [31:0] pAddr, vAddr, db_dataOut;
    // output wire db_ready,
    reg `MEM_ACCESS db_accessType;

    Cache #(.INBLOCK_ADDR_WIDTH(4)) uut (
        .clk(clk),
        .res(res),
        .ready(ready),
        .cachable(1'b1),

        .pAddr(pAddr),
        .vAddr(vAddr),
        .db_dataOut(db_dataOut),
        .db_dataIn(db_dataIn),
        .db_accessType(db_accessType),
        .db_ready(db_ready),

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

    task resetCache;
        begin
            res = 1;
            #100;
            res = 0;
            #100;
            wait(ready);
        end
    endtask

    task readMem;
        input [31:0] addr;
        begin
            wait(~clk);
            db_accessType = `MEM_ACCESS_R;
            pAddr = addr;
            vAddr = addr;
            #200;
            db_accessType = `MEM_ACCESS_NONE;
            wait(db_ready);
            $display("read memory at 0x%x, data 0x%x", addr, dbOut_dataOut);
        end
    endtask

    task writeMem;
        input [31:0] addr, data;
        begin
            wait(~clk);
            db_accessType = `MEM_ACCESS_W;
            pAddr = addr;
            vAddr = addr;
            db_dataOut = data;
            #200;
            db_accessType = `MEM_ACCESS_NONE;
            wait(db_ready);
            $display("write memory to 0x%x, data 0x%x", addr, data);
        end
    endtask

    always begin
        #100;
        if(count >= 1000) begin
            $dumpflush;
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
        db_accessType = `MEM_ACCESS_NONE;
        #100;
        resetCache();
        // readMem ({24'd0, 4'd0, 4'd0});
        // readMem ({24'd1, 4'd0, 4'd0});
        writeMem({24'd0, 4'd0, 4'd0}, 32'h bad_c0de);
        writeMem({24'd1, 4'd0, 4'd0}, 32'h dead_beef);
        readMem ({24'd2, 4'd0, 4'd0});

        // writeMem({24'd0, 4'd3, 4'd4}, 32'h bad_c0de);
        // readMem ({24'd0, 4'd0, 4'd0});
        // readMem ({24'd1, 4'd0, 4'd0});
        // writeMem({24'd2, 4'd3, 4'd4}, 32'h bad_cafe);
        #10000;
        $dumpflush;
        $stop;
    end
endmodule // cache_tb
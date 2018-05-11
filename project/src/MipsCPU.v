`include "DataBus.vh"
`timescale 1ns/1ns
module MipsCPU #(
    parameter TAG = "MipsCPU",
    parameter CACHE_BLOCK_ADDR_WIDTH = 4,
    parameter CACHE_INBLOCK_ADDR_WIDTH = 9
)(
    input wire clk, res,
    input wire db_ready,
    input wire [31:0] db_dataIn,
    output wire [31:0] db_dataOut, db_addr,
    output wire db_re, db_we, db_io
);
    wire ready;
    wire [31:0] vAddr, dbIn_dataIn, dbIn_dataOut, dbIn_addr;
    wire `MEM_ACCESS dbIn_accessType;
    wire dbIn_ready;
    wire cachable;

    CPU_MMU #(.TAG({TAG, "/CPU_MMU"})) cpu_mmu (
        .clk(clk),
        .res(res),
        .ready(ready),
        .cachable(cachable),
        .vAddr(vAddr),
        .db_addr(dbIn_addr),
        .db_dataOut(dbIn_dataOut),
        .db_dataIn(dbIn_dataIn),
        .db_accessType(dbIn_accessType),
        .db_io(db_io),
        .db_ready(dbIn_ready)
    );

    Cache #(
        .TAG({TAG, "/Cache"}), 
        .BLOCK_ADDR_WIDTH(CACHE_BLOCK_ADDR_WIDTH), 
        .INBLOCK_ADDR_WIDTH(CACHE_INBLOCK_ADDR_WIDTH)
    ) 
    cache (
        .clk(clk),
        .res(res),
        .ready(ready),
        .cachable(cachable),
        .pAddr(dbIn_addr),
        .vAddr(vAddr),
        .db_dataOut(dbIn_dataOut),
        .db_dataIn(dbIn_dataIn),
        .db_ready(dbIn_ready),
        .db_accessType(dbIn_accessType),
        .dbOut_dataIn(db_dataIn),
        .dbOut_dataOut(db_dataOut),
        .dbOut_addr(db_addr),
        .dbOut_re(db_re),
        .dbOut_we(db_we),
        .dbOut_ready(db_ready)
    );
endmodule // MipsCPU
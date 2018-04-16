`include "DataBus.vh"

module top(
    input wire clk,
    input wire res_n,
    input wire key1,
    
    input wire rx,
    output wire tx,
    
    // dummy ports
    input  wire [31:0] db_dataIn,
    input  wire        db_ready,
    output wire [31:0] db_dataOut,
    output wire  [31:0] db_addr,
    output wire `MEM_ACCESS_T db_accessType
);  
    CPU_MMU cpu_et_mmu (
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType)
    );
    // CPUCore cpu (
    //     .clk(clk),
    //     .res(res),

    //     .db_dataIn(db_dataIn),
    //     .db_dataOut(db_dataOut),
    //     .db_addr(db_addr),
    //     .db_ready(db_ready),
    //     .db_accessType(db_accessType)
    // );
endmodule
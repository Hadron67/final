`include "DataBus.vh"

module top(
    input wire clk,
    input wire res_n,
    input wire key1,
    
    input wire rx,
    output wire tx,
    
    // dummy ports
    input wire [31:0] db_dataIn,
    input wire db_ready,
    output wire [31:0] db_dataOut,
    output wire [31:0] db_addr,
    output wire db_re, db_we, db_io
);
    MipsCPU cpu (
        .clk(clk),
        .res(~res_n),
        .db_ready(db_ready),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_re(db_re),
        .db_we(db_we),
        .db_io(db_io)
    );
endmodule
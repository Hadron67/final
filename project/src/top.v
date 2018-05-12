`include "DataBus.vh"

module top #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600
) (
    input wire clk,
    input wire res_n,
    input wire key1,
    
    input wire rx,
    output wire tx
    
    // dummy ports
    // input wire [31:0] db_dataIn,
    // input wire db_ready,
    // output wire [31:0] db_dataOut,
    // output wire [31:0] db_addr,
    // output wire db_re, db_we, db_io
);
    wire [31:0] db_dataIn, db_dataOut, db_addr;
    wire db_re, db_we, db_io, db_ready;
    
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

    MemInterface #(.CLK(CLK), .BAUD_RATE(BAUD_RATE)) memIt (
        .clk(clk),
        .res(~res_n),
        .db_ready(db_ready),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_re(db_re),
        .db_we(db_we),
        .db_io(db_io),
        .rx(rx),
        .tx(tx)
    );

endmodule
`include "DataBus.vh"

module top #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600
) (
    input wire clk,
    input wire res_n,
    input wire rx,
    output wire tx,

    output wire [7:0] seg_data,
    output wire [5:0] seg_sel
);
    wire [31:0] db_dataIn, db_dataOut, db_addr;
    wire db_re, db_we, db_io, db_ready, res;

    assign res = ~res_n;
    
    MipsCPU cpu (
        .clk(clk),
        .res(res),
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
        .res(res),
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

    Peripheral #(.CLK(CLK)) peripheralCtl (
        .clk(clk),
        .res(res),
        .re(db_re && db_io),
        .we(db_we && db_io),
        .dataIn(db_dataOut),
        .addr(db_addr),
        .seg_data(seg_data),
        .seg_sel(seg_sel)
    );

endmodule
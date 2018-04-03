module top(
    input wire clk,
    input wire res_n,
    input wire key1,
    
    input wire rx,
    output wire tx
    
);
    localparam DATA_LEN = 11;
    wire res;
    assign res = ~res_n;
    logic [0:DATA_LEN * 8 - 1] data = "hkm, soor\r\n";
    
    DataBus db();
    CPUCore U1(
        .clk(clk),
        .res(res),
        .db(db.master)
    );

    UART_tx #(.DATA_MAX_LEN(DATA_LEN)) usartTx (
        .clk(~clk),
        .res(res),
        .tx(tx),
        .data(data),
        .send(1'b1),
        .len(DATA_LEN)
    );
    
endmodule
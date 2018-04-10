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
    output wire  [1:0]  db_accessType
);
    localparam DATA_LEN = 11;
    wire res;
    assign res = ~res_n;
    wire [0:DATA_LEN * 8 - 1] data = "hkm, soor\r\n";
    
    CPUCore U1(
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_accessType(db_accessType),
        .db_ready(db_ready)
    );

    MMU m (
        
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
module strrev #(
    parameter LEN = 1
) (
    input wire [LEN * 8 - 1:0] in,
    output wire [LEN * 8 - 1:0] out
);
    genvar i;
    generate
        for(i = 0; i < LEN; i = i + 1) begin: AAA
            assign out[(i + 1) * 8 - 1:i * 8] = in[(LEN - i) * 8:(LEN - i - 1) * 8];
        end
    endgenerate
endmodule // strrev

module uart_tb;
    localparam SLEN = 32;
    localparam CLK = 1;
    localparam BAUD_RATE = 10000;

    reg clk, res, send;
    wire link, txReady, recved;
    wire [SLEN * 8 - 1:0] sdata, data, dataOut;

    assign data = "hkm, soor, tstssoor";

    strrev #(.LEN(SLEN)) rev (.in(data), .out(sdata));

    UART_tx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), .DATA_MAX_LEN(SLEN)) tx (
        .clk(clk),
        .res(res),
        .data(data),
        .len_1(SLEN - 1),
        .ready(txReady),
        .send(send),
        .tx(link)
    );

    UART_rx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), .DATA_MAX_LEN(SLEN)) rx (
        .clk(clk),
        .res(res),
        .len_1(SLEN - 1),
        .data(dataOut),
        .recved(recved),
        .rx(link)
    );

    always begin
        #100;
        clk = ~clk;
    end

    initial begin
        $dumpfile({`OUT_DIR, "/uart_tb.vcd"});
        $dumpvars(0, tx);
        $dumpvars(0, rx);
        clk = 0;
        res = 0;
        send = 0;
        #100;
        res = 1;
        #100;
        res = 0;
        #1000;
        wait(~clk);
        send = 1;
        #200;
        send = 0;
        wait(txReady);
        $display("received: %s", dataOut);
        #1000;
        $dumpflush;
        $stop;
    end
endmodule // uart_tb
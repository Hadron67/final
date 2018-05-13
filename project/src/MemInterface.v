`include "DataBus.vh"
`include "font.vh"

module MemInterface #(
    parameter BAUD_RATE = 9600,
    parameter CLK = 25,
    parameter TIMEOUT = 100
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr,
    input wire db_re, db_we, db_io,
    output wire [31:0] db_dataIn,
    output wire db_ready,

    output wire tx,
    input wire rx
);
    localparam TX_MAX_LEN = 9;
    localparam RX_TIMEOUT = CLK * 1000 * TIMEOUT;

    localparam CMD_NONE     = 8'd0; // a placeholder
    localparam CMD_READ     = 8'd1;
    localparam CMD_WRITE    = 8'd2;
    localparam CMD_PRINT    = 8'd3;
    localparam CMD_HLT      = 8'd4;

    localparam S_IDLE        = 3'd0;
    localparam S_SEND        = 3'd1;
    localparam S_SEND_WAIT   = 3'd2;
    localparam S_WAIT_DATA   = 3'd3;
    localparam S_RESEND      = 3'd4;
    localparam S_RESEND_WAIT = 3'd5;

    localparam IO_ADDR_HLT   = 32'h0000_0000;
    localparam IO_ADDR_PRINT = 32'h0000_0001;

    reg [2:0] state, nextState;
    reg [TX_MAX_LEN * 8 - 1:0] dataOut, dataOutLatch;
    wire [31:0] dataIn;
    reg [7:0] outLen_1;
    reg [7:0] cmd;
    wire send, txReady, recved, resend;
    reg needWait;
    reg [31:0] dataInLatch, timeOutCnt;
    wire timedOut;

    // assign dataOut = {db_dataOut, db_addr, cmd};
    assign db_ready = state == S_IDLE;
    assign db_dataIn = dataInLatch;
    assign send = state == S_IDLE && nextState == S_SEND;
    assign resend = nextState == S_RESEND;
    assign timedOut = timeOutCnt == RX_TIMEOUT - 1;

    always @* begin
        if(db_io && db_we) begin
            case(db_addr)
                IO_ADDR_HLT:   cmd = CMD_HLT;
                IO_ADDR_PRINT: cmd = CMD_PRINT;
                default: cmd = CMD_NONE;
            endcase
        end
        else begin
            if(db_we) begin
                cmd = CMD_WRITE;
            end
            else if(db_re) begin
                cmd = CMD_READ;
            end
            else
                cmd = CMD_NONE;
        end
    end
    always @* begin
        case(cmd)
            CMD_READ,
            CMD_WRITE: dataOut = {db_dataOut, db_addr, cmd};
            CMD_PRINT: dataOut = {32'd0, db_dataOut, cmd};
            CMD_HLT:   dataOut = {64'd0, cmd};
            default: dataOut = 40'dx;
        endcase
    end
    always @* begin
        case(cmd)
            CMD_READ: outLen_1 = 8'd4;
            CMD_WRITE: outLen_1 = 8'd8;
            CMD_PRINT: outLen_1 = 8'd1;
            CMD_HLT: outLen_1 = 8'd0;
            default: outLen_1 = 8'dx;
        endcase
    end
    always @* begin
        case(state)
            S_IDLE: nextState = cmd != CMD_NONE ? S_SEND : S_IDLE;
            S_SEND,
            S_SEND_WAIT: nextState = txReady ? (needWait ? S_WAIT_DATA : S_IDLE) : S_SEND_WAIT;
            S_WAIT_DATA: nextState = recved ? S_IDLE : (timedOut ? S_RESEND : S_WAIT_DATA);
            S_RESEND,
            S_RESEND_WAIT: nextState = txReady ? (needWait ? S_WAIT_DATA : S_IDLE) : S_RESEND_WAIT;
            default: nextState = 3'dx;
        endcase
    end

    UART_tx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), .DATA_MAX_LEN(TX_MAX_LEN)) uart_tx (
        .clk(clk),
        .res(res),
        .data(dataOut),
        .len_1(outLen_1),
        .send(send),
        .resend(resend),
        .ready(txReady),
        .tx(tx)
    );

    UART_rx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), .DATA_MAX_LEN(4)) uart_rx (
        .clk(clk),
        .res(res || nextState == S_SEND || nextState == S_RESEND),
        .data(dataIn),
        .recved(recved),
        .len_1(3),
        .en(nextState == S_WAIT_DATA),
        .rx(rx)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_IDLE;
        end 
        else begin
            if(nextState == S_SEND) begin
                needWait <= db_re;
                timeOutCnt <= 32'd0;
            end
            if(nextState == S_RESEND) begin
                timeOutCnt <= 32'd0;
            end
            if(nextState == S_WAIT_DATA) begin
                timeOutCnt <= timeOutCnt + 32'd1;
            end
            if(state == S_WAIT_DATA && recved)
                dataInLatch <= dataIn;
            state <= nextState;
        end
    end

    // `ifdef DEBUG
    // always @(posedge clk) begin
    //     if(state == S_IDLE && db_we && db_addr == IO_ADDR_HLT) begin

    //         $dumpflush;
    //         $stop;
    //     end
    // end
    // `endif

endmodule // MemInterface
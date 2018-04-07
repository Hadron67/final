module MainMem #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600
) (
    DataBus.slave db,
    input wire res,
    input wire rx,
    output wire tx
);
    localparam MAX_LEN = 9;
    typedef enum logic [7:0] {
        MEMCMD_ACK    = 8'd1,
        MEMCMD_RESEND = 8'd2,
        MEMCMD_READ   = 8'd3,
        MEMCMD_WRITE  = 8'd4
    } MemCmd;
    typedef enum logic [2:0] {
        MEMSTATE_IDLE,
        MEMSTATE_WAITACK,
        MEMSTATE_SENDCMD
    } MemState;

    wire clk = db.clk;
    int sendLen, recvLen;
    logic [MAX_LEN - 1:0] sendData, recvData;
    logic send, sendReady;
    logic recved, ack;
    MemState state;

    UART_tx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), DATA_MAX_LEN(MAX_LEN)) uartTx (
        .clk(~clk),
        .res(res),
        .len(sendLen),
        .tx(tx),
        .send(send),
        .ready(sendReady),
        .data(sendData)
    );
    UART_rx #(.CLK(CLK), .BAUD_RATE(BAUD_RATE), .DATA_MAX_LEN(MAX_LEN)) uartRx (
        .clk(~clk),
        .res(res),
        .rx(rx),
        .ack(ack),
        .len(recvLen),
        .data(recvData),
        .recved(recved)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= MEMSTATE_IDLE;
        end else 
            case(state)
                MEMSTATE_IDLE: begin
                    if(db.write) begin
                        
                    end
                end
            endcase
    end

endmodule
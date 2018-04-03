module UART_tx #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600,
    parameter DATA_MAX_LEN = 1
) (
    input wire clk,
    input wire res,
    input wire [DATA_MAX_LEN * 8 - 1:0] data,
    input int len,
    input wire send,
    output wire ready,
    output logic tx
);
    typedef enum logic [3:0] {
        UARTSTATE_IDLE,
        UARTSTATE_START,
        UARTSTATE_SEND,
        UARTSTATE_STOP
    } UARTTxState;
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    UARTTxState state;
    logic [2:0] sendPtr;
    int cycleCount, sendBase;

    assign ready = state == UARTSTATE_IDLE;
    always @* begin
        case (state)
            UARTSTATE_IDLE:  tx = 1'b1;
            UARTSTATE_START: tx = 1'b0;
            UARTSTATE_SEND:  tx = data[sendBase + sendPtr];
            UARTSTATE_STOP:  tx = 1'b1;
        endcase
    end

    always @(posedge clk or posedge res) begin
        if(res)
            state <= UARTSTATE_IDLE;
        else
            case(state)
                UARTSTATE_IDLE: begin
                    if(send) begin
                        state <= UARTSTATE_START;
                        cycleCount <= 0;
                        sendBase <= 0;
                        $display("start sending");
                    end
                end
                UARTSTATE_START: begin
                    if(cycleCount == CYCLE - 1) begin
                        state <= UARTSTATE_SEND;
                        cycleCount <= 0;
                        sendPtr <= 3'b0;
                    end else 
                        cycleCount <= cycleCount + 1;
                end
                UARTSTATE_SEND: begin
                    if(cycleCount == CYCLE - 1) begin
                        cycleCount <= 0;
                        if(sendPtr == 7) 
                            state <= UARTSTATE_STOP;
                        else
                            sendPtr <= sendPtr + 3'b1;
                    end else
                        cycleCount <= cycleCount + 1; 
                end
                UARTSTATE_STOP: begin
                    if(cycleCount == CYCLE - 1) begin
                        if(sendBase == (len - 1) * 8)
                            state <= UARTSTATE_IDLE;
                        else begin
                            state <= UARTSTATE_START;
                            sendBase <= sendBase + 8;
                        end
                        cycleCount <= 0;
                    end else
                        cycleCount <= cycleCount + 1; 
                end
            endcase
    end
endmodule

module UART_rx #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600,
    parameter DATA_MAX_LEN = 1
) (
    input wire clk,
    input wire res,
    input wire rx,
    input wire ack,
    input int len,
    output logic [DATA_MAX_LEN * 8 - 1:0] data,
    output wire recved
);
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    typedef enum logic [2:0] {
        UARTRXSTATE_IDLE,
        UARTRXSTATE_START,
        UARTRXSTATE_RECV,
        UARTRXSTATE_STOP,
        UARTRXSTATE_WAITNEXT,
        UARTRXSTATE_WAITACK
    } UARTRxState;
    UARTRxState state;
    int cycleCount, recvBase;
    logic [2:0] recvPtr;
    assign recved = state == UARTRXSTATE_WAITACK;

    always @(posedge clk, posedge res) begin
        if(res) begin
            state <= UARTRXSTATE_IDLE;
        end else
            case(state)
                UARTRXSTATE_IDLE: 
                    if(rx == 1'b0) begin
                        state <= UARTRXSTATE_START;
                        cycleCount <= 0;
                        recvBase <= 0;
                    end
                UARTRXSTATE_WAITNEXT:
                    if(rx == 1'b0) begin
                        state <= UARTRXSTATE_START;
                        cycleCount <= 0;
                    end
                UARTRXSTATE_START:
                    if(rx == 1'b1)
                        state <= UARTRXSTATE_IDLE; // frame error
                    else if(cycleCount == CYCLE - 1) begin
                        state <= UARTRXSTATE_RECV;
                        recvPtr <= 0;
                    end else
                        cycleCount <= cycleCount + 1;
                UARTRXSTATE_RECV:
                    if(cycleCount == CYCLE / 2)
                        data[recvBase + recvPtr] <= rx;
                    else if(cycleCount == CYCLE - 1) begin
                        if(recvPtr == 7) begin
                            state <= UARTRXSTATE_STOP;
                            cycleCount <= 0;
                        end else
                            recvPtr <= recvPtr + 3'b1;
                    end else
                        cycleCount <= cycleCount + 1;
                UARTRXSTATE_STOP:
                    if(cycleCount == CYCLE / 2) begin
                        if(recvBase == (len - 1) * 8) begin
                            state <= UARTRXSTATE_WAITACK;   
                        end else begin
                            state <= UARTRXSTATE_WAITNEXT;
                            recvBase <= recvBase + 8;
                        end
                    end else
                        cycleCount <= cycleCount + 1;
                UARTRXSTATE_WAITACK:
                    if(ack)
                        state <= UARTRXSTATE_IDLE;
            endcase
    end

endmodule
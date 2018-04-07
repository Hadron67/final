module UART_tx #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600,
    parameter DATA_MAX_LEN = 1
) (
    input wire clk,
    input wire res,
    input wire [DATA_MAX_LEN * 8 - 1:0] data,
    input wire [31:0] len,
    input wire send,
    output wire ready,
    output reg tx
);
    localparam S_IDLE  = 3'd0;
    localparam S_START = 3'd1;
    localparam S_SEND  = 3'd2;
    localparam S_STOP  = 3'd3;
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    reg [2:0] state;
    reg [2:0] sendPtr;
    integer cycleCount, sendBase;

    assign ready = state == S_IDLE;
    always @* begin
        case (state)
            S_IDLE:  tx = 1'b1;
            S_START: tx = 1'b0;
            S_SEND:  tx = data[sendBase + sendPtr];
            S_STOP:  tx = 1'b1;
        endcase
    end

    always @(posedge clk or posedge res) begin
        if(res)
            state <= S_IDLE;
        else
            case(state)
                S_IDLE: begin
                    if(send) begin
                        state <= S_START;
                        cycleCount <= 0;
                        sendBase <= 0;
                        $display("start sending");
                    end
                end
                S_START: begin
                    if(cycleCount == CYCLE - 1) begin
                        state <= S_SEND;
                        cycleCount <= 0;
                        sendPtr <= 3'b0;
                    end else 
                        cycleCount <= cycleCount + 1;
                end
                S_SEND: begin
                    if(cycleCount == CYCLE - 1) begin
                        cycleCount <= 0;
                        if(sendPtr == 7) 
                            state <= S_STOP;
                        else
                            sendPtr <= sendPtr + 3'b1;
                    end else
                        cycleCount <= cycleCount + 1; 
                end
                S_STOP: begin
                    if(cycleCount == CYCLE - 1) begin
                        if(sendBase == (len - 1) * 8)
                            state <= S_IDLE;
                        else begin
                            state <= S_START;
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
    input wire [31:0] len,
    output reg [DATA_MAX_LEN * 8 - 1:0] data,
    output wire recved
);
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    localparam S_IDLE     = 3'd0;
    localparam S_START    = 3'd1;
    localparam S_RECV     = 3'd2;
    localparam S_STOP     = 3'd3;
    localparam S_WAITNEXT = 3'd4;
    localparam S_WAITACK  = 3'd5;
    reg [2:0] state;
    integer cycleCount, recvBase;
    reg [2:0] recvPtr;
    assign recved = state == S_WAITACK;

    always @(posedge clk, posedge res) begin
        if(res) begin
            state <= S_IDLE;
        end else
            case(state)
                S_IDLE: 
                    if(rx == 1'b0) begin
                        state <= S_START;
                        cycleCount <= 0;
                        recvBase <= 0;
                    end
                S_WAITNEXT:
                    if(rx == 1'b0) begin
                        state <= S_START;
                        cycleCount <= 0;
                    end
                S_START:
                    if(rx == 1'b1)
                        state <= S_IDLE; // frame error
                    else if(cycleCount == CYCLE - 1) begin
                        state <= S_RECV;
                        recvPtr <= 0;
                    end else
                        cycleCount <= cycleCount + 1;
                S_RECV:
                    if(cycleCount == CYCLE / 2)
                        data[recvBase + recvPtr] <= rx;
                    else if(cycleCount == CYCLE - 1) begin
                        if(recvPtr == 7) begin
                            state <= S_STOP;
                            cycleCount <= 0;
                        end else
                            recvPtr <= recvPtr + 3'b1;
                    end else
                        cycleCount <= cycleCount + 1;
                S_STOP:
                    if(cycleCount == CYCLE / 2) begin
                        if(recvBase == (len - 1) * 8) begin
                            state <= S_WAITACK;   
                        end else begin
                            state <= S_WAITNEXT;
                            recvBase <= recvBase + 8;
                        end
                    end else
                        cycleCount <= cycleCount + 1;
                S_WAITACK:
                    if(ack)
                        state <= S_IDLE;
            endcase
    end

endmodule
module UART_tx #(
    parameter CLK = 50,
    parameter BAUD_RATE = 9600,
    parameter DATA_MAX_LEN = 1
) (
    input wire clk,
    input wire res,
    input wire [DATA_MAX_LEN * 8 - 1:0] data,
    input wire [31:0] len_1,
    input wire send, resend,
    output wire ready,
    output reg tx
);
    localparam S_IDLE  = 3'd0;
    localparam S_START = 3'd1;
    localparam S_SEND  = 3'd2;
    localparam S_STOP  = 3'd3;
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    reg [31:0] lenLatch_1;
    reg [DATA_MAX_LEN * 8 - 1:0] dataLatch;
    reg [2:0] state, nextState;
    reg [2:0] sendPtr;
    integer cycleCount, sendBase;
    wire cycleEnd;

    assign ready = state == S_IDLE || state == S_STOP && cycleEnd && (sendBase == lenLatch_1);
    assign cycleEnd = cycleCount == CYCLE - 1;
    
    always @* begin
        case (state)
            S_IDLE:  tx = 1'b1;
            S_START: tx = 1'b0;
            S_SEND:  tx = dataLatch[{sendBase, sendPtr}];
            S_STOP:  tx = 1'b1;
        endcase
    end

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_IDLE;
            cycleCount <= 0;
            sendBase <= 0;            
        end
        else
            case(state)
                S_IDLE: begin
                    if(send) begin
                        dataLatch <= data;
                        lenLatch_1 <= len_1;
                        state <= S_START;
                    end
                    else if(resend) begin
                        state <= S_START;
                    end
                end
                S_START: begin
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        state <= S_SEND;
                        sendPtr <= 3'b0;
                    end else 
                        cycleCount <= cycleCount + 1;
                end
                S_SEND: begin
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        if(sendPtr == 3'd7) 
                            state <= S_STOP;
                        else
                            sendPtr <= sendPtr + 3'b1;
                    end else
                        cycleCount <= cycleCount + 1; 
                end
                S_STOP: begin
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        if(sendBase == lenLatch_1) begin
                            sendBase <= 0;
                            state <= S_IDLE;
                        end
                        else begin
                            state <= S_START;
                            sendBase <= sendBase + 1;
                        end
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
    input wire en,
    input wire rx,
    input wire [31:0] len_1,
    output reg [DATA_MAX_LEN * 8 - 1:0] data,
    output wire recved
);
    localparam CYCLE = CLK * 1000000 / BAUD_RATE;
    localparam S_IDLE     = 3'd0;
    localparam S_START    = 3'd1;
    localparam S_RECV     = 3'd2;
    localparam S_STOP     = 3'd3;
    localparam S_WAITNEXT = 3'd4;

    reg [2:0] state;
    integer cycleCount, recvBase;
    reg [2:0] recvPtr;
    reg [31:0] lenLatch_1;
    wire cycleEnd = cycleCount == CYCLE - 1;

    assign recved = state == S_STOP && cycleEnd && recvBase == lenLatch_1;

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_IDLE;
            cycleCount <= 0;
            recvBase <= 0;     
            recvPtr <= 0;                            
        end 
        else
            case(state)
                S_IDLE:
                    if(~rx && en) begin
                        state <= S_START;
                        lenLatch_1 <= len_1;
                    end
                S_WAITNEXT:
                    if(~rx) begin
                        state <= S_START;
                    end
                S_START:
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        state <= S_RECV;
                    end
                    else
                        cycleCount <= cycleCount + 1;
                S_RECV:
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        if(recvPtr == 3'd7) begin
                            recvPtr <= 3'd0;
                            state <= S_STOP;
                        end
                        else
                            recvPtr <= recvPtr + 3'b1;
                    end
                    else begin
                        if(cycleCount == CYCLE / 2)
                            data[{recvBase, recvPtr}] <= rx;
                        cycleCount <= cycleCount + 1;
                    end
                S_STOP:
                    if(cycleEnd) begin
                        cycleCount <= 0;
                        if(recvBase == lenLatch_1) begin
                            recvBase <= 0;
                            if(~rx && en) begin
                                state <= S_START;
                                lenLatch_1 <= len_1;
                            end
                            else
                                state <= S_IDLE;
                        end
                        else begin
                            recvBase <= recvBase + 1;
                            state <= ~rx ? S_START : S_WAITNEXT;
                        end
                    end else
                        cycleCount <= cycleCount + 1;
            endcase
    end

endmodule
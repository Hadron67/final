interface SPIBus;
    logic sclk;
    logic mosi;
    logic miso;
    logic cs;
    modport master(
        input miso,
        output sclk, output mosi, output cs
    );
    modport slave(
        output miso,
        input sclk, input mosi, input cs
    );
endinterface

module SPIMaster(
    input wire    clk,
	input wire    res,
	SPIBus.master bus,
	input wire    CPOL,
	input wire    CPHA,
	input wire    cs,
	input [15:0]  clkDiv, // f_{spi} = \frac {f_0} {(clkDiv + 2) * 2}
	input wire    write,
	output logic  ready,
	input [7:0]   dataIn,
	output [7:0]  dataOut
);
    typedef enum logic [2:0] {
        SPISTATE_IDEL,
        SPISTATE_START,
        SPISTATE_SEND,
        SPISTATE_STOP
    } SPIState;
    SPIState state;
    logic dividedClk;
    logic [15:0] clkCounter;
    logic [2:0] sendPtr;
    always @(posedge clk or posedge res) begin
        if(res)
            clkCounter <= 15'b0;
        else if(state != SPISTATE_IDEL) begin
            if(clkCounter == clkDiv) begin
                clkCounter <= 15'b0;
                dividedClk <= ~dividedClk;
            end else
                clkCounter <= clkCounter + 15'b1;
        end
    end
    wire clk0, clk1;
    assign clk1 = CPOL == 'b0 ? dividedClk : ~dividedClk;
    assign clk0 = state == SPISTATE_IDEL ? clk : dividedClk;
    assign bus.cs = state == SPISTATE_IDEL;
    assign bus.mosi = dataIn[sendPtr];

    always @(posedge clk0 or negedge clk0 or posedge res) begin
        if(res)
            state <= SPISTATE_IDEL;
        else
            case(state)
                SPISTATE_IDEL: begin
                    if(write) begin
                        if(CPHA == 1'b0) begin
                            sendPtr <= 0;
                            state <= SPISTATE_SEND;
                        end else begin
                            state <= SPISTATE_START;    
                        end 
                    end
                end
                SPISTATE_START:
                    if(clk0 == 1'b1)
                        if(CPHA == 1'b0)
                SPISTATE_STOP: state <= SPISTATE_IDEL;
            endcase
    end
    always @(posedge clk0) begin
        if(CPHA == 'b0 && state == SPISTATE_SEND) begin
            dataOut[sendPtr] <= bus.miso;
        end else begin
            if(state == SPISTATE_START) begin
                sendPtr <= 0;
                state <= SPISTATE_SEND;
            end else if(state == SPISTATE_SEND) begin
                if(sendPtr == 7)
                    state <= SPISTATE_IDEL;
                else
                    sendPtr <= sendPtr + 'b1;
            end
        end
    end
    always @(negedge clk0) begin
        if(CPHA == 'b0 && state == SPISTATE_SEND) begin
            if(sendPtr == 7)
                state <= SPISTATE_STOP;
            else
                sendPtr <= sendPtr + 'b1;
        end else begin
            dataOut[sendPtr] <= bus.miso;
        end
    end
endmodule
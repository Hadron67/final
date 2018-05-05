module Ram #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TAG = "RAM"
) (
    input wire clk, res, re, we,
    input wire [ADDR_WIDTH - 1:0] addr,
    input wire [WIDTH - 1:0] dataIn,
    output wire [WIDTH - 1:] dataOut
);
    localparam SIZE = 1 << ADDR_WIDTH;

    reg [WIDTH - 1:0] data[SIZE - 1:0];
    reg [ADDR_WIDTH - 1:0] addrLatch;

    assign dataOut = data[addrLatch];
    
    always @(posedge clk) begin
        if(we) begin
            data[addr] <= dataIn;
            `ifdef DEBUG_DISPLAY
            $display({"[", TAG, "] written data (0x%x) to address (0x%x)"}, dataIn, addr);
            `endif
        end
        else if(re) begin
            addrLatch <= addr;
        end
    end

endmodule // Ram
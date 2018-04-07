module SerialTx_tb();
    logic clk, res;
    logic send, ready, tx;
    logic [7:0] data;
    
    UART_tx #(
        .CLK(1),
        .BAUD_RATE(1000000)
    ) s (
        .clk(clk),
        .res(res),
        .send(1'b1),
        .ready(ready),
        .tx(tx),
        .data(data)
    );
    initial begin
        $dumpfile("Serial_tb.vcd"); 
        $dumpvars(0, s);
        clk = 0;
        res = 0;
        #5;
        res = 1;
        #5;
        res = 0;
        data = 8'b01100111;
        send = 1;
        #20;
        send = 0;
        #4000;
        $dumpflush;
        $stop();
    end
    
    always begin
        clk <= ~clk;
        #10;
    end

endmodule
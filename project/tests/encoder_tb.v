module encoder_tb();
    localparam OUT_LEN = 3;
    reg [(1 << OUT_LEN) - 1:0] in;
    wire [OUT_LEN - 1:0] out;

    Encoder #(.OUT_WIDTH(OUT_LEN)) uut (
        .in(in),
        .out(out)
    );

    initial begin
        $dumpfile({`OUT_DIR, "/encoder.vcd"}); 
        $dumpvars(0, uut);
        for(in = 8'd0; in < 8'hff; in = in + 1) begin
            #10;
            $display("%d", out);
        end

        $dumpflush();
        $stop();
    end
endmodule
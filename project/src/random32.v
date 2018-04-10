module Random32 (
    input wire clk, res,
    output reg [31:0] out
);
    wire feedBackBit;
    wire [31:0] next;

    assign feedBackBit = out[10] ^ out[12] ^ out[13] ^ out[15];
    assign next = {out[30:0], feedBackBit};

    always @(posedge clk or posedge res) begin
        if(res) 
            out <= 32'd123456;
        else
            out <= next;
    end
endmodule
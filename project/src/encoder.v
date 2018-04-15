// Priority encoder
// Thanks to: https://github.com/yugr/primogen/blob/master/src/prio_enc.v

module Encoder #(
    parameter OUT_WIDTH = 3
) (
    input wire [IN_WIDTH - 1:0] in,
    output wire [OUT_WIDTH - 1:0] out
);
    localparam IN_WIDTH = 1 << OUT_WIDTH;

    wire [IN_WIDTH - 1:0] ors[OUT_WIDTH - 1:0];

    assign ors[OUT_WIDTH - 1] = in;

    genvar i;
    generate
        for(i = OUT_WIDTH - 1; i >= 0; i = i - 1) begin: genLogic
            wire [IN_WIDTH - 1:0] line = ors[i];
            wire [(1 << i) - 1:0] origLine = line[2 * (1 << i) - 1:1 << i];
            assign out[i] = |origLine;
            if(i > 0) begin
                assign ors[i - 1][(1 << i) - 1:0] = out[i] ? origLine : line[(1 << i) - 1:0];
            end
        end
    endgenerate
  
endmodule
module Peripheral #(
    parameter CLK = 50,
    parameter SCAN_F = 400
) (
    input wire clk, res,
    input wire re, we,
    input wire [31:0] dataIn, addr,

    output wire [7:0] seg_data,
    output wire [5:0] seg_sel
);
    localparam SCAN_CNT = CLK * 1000000 / SCAN_F;

    localparam ADDR_SEG0 = 32'h0000_0010;
    localparam ADDR_SEG1 = 32'h0000_0014;
    localparam ADDR_SEG2 = 32'h0000_0018;
    localparam ADDR_SEG3 = 32'h0000_001c;
    localparam ADDR_SEG4 = 32'h0000_0020;
    localparam ADDR_SEG5 = 32'h0000_0024;

    reg [7:0] seg_data2;
    reg [5:0] seg_sel2;
    reg [7:0] seg0, seg1, seg2, seg3, seg4, seg5;
    reg [31:0] counter;

    assign seg_data = ~seg_data2;
    assign seg_sel = ~seg_sel2;

    always @* begin
        case(seg_sel2)
            6'b000001: seg_data2 = seg0;
            6'b000010: seg_data2 = seg1;
            6'b000100: seg_data2 = seg2;
            6'b001000: seg_data2 = seg3;
            6'b010000: seg_data2 = seg4;
            6'b100000: seg_data2 = seg5;
            default: seg_data2 = 8'd0;
        endcase
    end

    always @(posedge clk or posedge res) begin
        if(res) begin
            seg0 <= 8'd0;
            seg1 <= 8'd0;
            seg2 <= 8'd0;
            seg3 <= 8'd0;
            seg4 <= 8'd0;
            seg5 <= 8'd0;
            seg_sel2 <= 6'd1;
            counter <= 32'd0;
        end
        else begin
            if(we) begin
                case(addr)
                    ADDR_SEG0: seg0 <= dataIn[7:0];
                    ADDR_SEG1: seg1 <= dataIn[7:0];
                    ADDR_SEG2: seg2 <= dataIn[7:0];
                    ADDR_SEG3: seg3 <= dataIn[7:0];
                    ADDR_SEG4: seg4 <= dataIn[7:0];
                    ADDR_SEG5: seg5 <= dataIn[7:0];
                endcase
            end

            if(counter == SCAN_CNT - 1) begin
                counter <= 32'd0;
                seg_sel2 <= {seg_sel2[4:0], seg_sel2[5]};
            end
            else
                counter <= counter + 32'd1;
        end
    end
endmodule // Peripheral
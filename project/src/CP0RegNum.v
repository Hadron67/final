module CP0RegNum(
    input wire [4:0] rd,
    input wire [2:0] sel,
    output wire [5:0] regNum
);
    reg [5:0] cp0RegNum;
    assign regNum = cp0RegNum;

    always @* begin
        case(rd)
            5'd7 : cp0RegNum = sel == 3'd0 ? 6'd0 : 6'dx;
            5'd8 : cp0RegNum = 6'd1;
            5'd9 : cp0RegNum = 6'd2;
            5'd11: cp0RegNum = 6'd3;
            5'd12: 
                case(sel)
                    3'd1: cp0RegNum = 6'd4;
                    3'd2: cp0RegNum = 6'd5;
                    3'd3: cp0RegNum = 6'd6;
                    default: cp0RegNum = 6'd7;
                endcase
            5'd13: cp0RegNum = 6'd8;
            5'd14: cp0RegNum = 6'd9;
            5'd15: cp0RegNum = sel == 3'd1 ? 6'd10 : 6'd11;
            5'd16: 
                case(sel)
                    3'd1: cp0RegNum = 6'd12;
                    3'd2: cp0RegNum = 6'd13;
                    3'd3: cp0RegNum = 6'd14;
                    default: cp0RegNum = 6'd15;
                endcase
            5'd17: cp0RegNum = sel == 3'd0 ? 6'd16 : 6'dx;
            5'd18: cp0RegNum = sel == 3'd0 ? 6'd17 : 6'dx;
            5'd19: cp0RegNum = sel == 3'd0 ? 6'd18 : 6'dx;

            5'd23: cp0RegNum = sel == 3'd0 ? 6'd19 : 6'dx;
            5'd24: cp0RegNum = sel == 3'd0 ? 6'd20 : 6'dx;
            5'd25: 
                case(sel)
                    3'd0: cp0RegNum = 6'd21;
                    3'd1: cp0RegNum = 6'd22;
                    default: cp0RegNum = 6'dx;
                endcase
            5'd26: cp0RegNum = 6'd23;
            5'd27: cp0RegNum = 6'd24;
            5'd28: cp0RegNum = sel == 3'd1 ? 6'd25 : 6'd26;
            5'd29: 
                case(sel)
                    3'd0: cp0RegNum = 6'd27;
                    3'd1: cp0RegNum = 6'd28;
                    default: cp0RegNum = 6'dx;
                endcase
            5'd30: cp0RegNum = 6'd29;
            5'd31: cp0RegNum = sel == 3'd0 ? 6'd30 : 6'dx;
            default cp0RegNum = 6'dx;
        endcase
    end
endmodule
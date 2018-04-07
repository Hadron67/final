module CP0RegNum(
    input wire [4:0] rd,
    input wire [3:0] sel,
    output wire [5:0] regNum
);
    reg [5:0] cp0RegNum;
    assign regNum = cp0RegNum;

    always @* begin
        case(rd)
            0 : cp0RegNum = 6'd0;
            1 : cp0RegNum = 6'd1;
            2 : cp0RegNum = 6'd2;
            3 : cp0RegNum = 6'd3;
            4 : cp0RegNum = 6'd4;
            5 : cp0RegNum = 6'd5;
            6 : cp0RegNum = 6'd6;
            7 : cp0RegNum = sel == 4'd0 ? 6'd7 : 6'dx;
            8 : cp0RegNum = 6'd8;
            9 : cp0RegNum = 6'd9;
            10: cp0RegNum = 6'd10;
            11: cp0RegNum = 6'd11;
            12: 
                case(sel)
                    4'd1: cp0RegNum = 6'd12;
                    4'd2: cp0RegNum = 6'd13;
                    4'd3: cp0RegNum = 6'd14;
                    default: cp0RegNum = 6'd15;
                endcase
            13: cp0RegNum = 6'd16;
            14: cp0RegNum = 6'd17;
            15: cp0RegNum = sel == 4'd1 ? 6'd18 : 6'd19;
            16: 
                case(sel)
                    4'd1: cp0RegNum = 6'd20;
                    4'd2: cp0RegNum = 6'd21;
                    4'd3: cp0RegNum = 6'd22;
                    default: cp0RegNum = 6'd23;
                endcase
            17: cp0RegNum = sel == 4'd0 ? 6'd24 : 6'dx;
            18: cp0RegNum = sel == 4'd0 ? 6'd25 : 6'dx;
            19: cp0RegNum = sel == 4'd0 ? 6'd26 : 6'dx;
            20: cp0RegNum = 6'dx;
            21: cp0RegNum = 6'dx;
            22: cp0RegNum = 6'dx;
            23: cp0RegNum = sel == 4'd0 ? 6'd27 : 6'dx;
            24: cp0RegNum = sel == 4'd0 ? 6'd28 : 6'dx;
            25: 
                case(sel)
                    4'd0: cp0RegNum = 6'd29;
                    4'd1: cp0RegNum = 6'd30;
                    default: cp0RegNum = 6'dx;
                endcase
            26: cp0RegNum = 6'd31;
            27: cp0RegNum = 6'd32;
            28: cp0RegNum = sel == 4'd1 ? 6'd33 : 6'd34;
            29: 
                case(sel)
                    4'd0: cp0RegNum = 6'd35;
                    4'd1: cp0RegNum = 6'd35;
                    default: cp0RegNum = 6'dx;
                endcase
            30: cp0RegNum = 6'd37;
            31: cp0RegNum = sel == 4'd0 ? 6'd38 : 6'dx;
        endcase
    end
endmodule
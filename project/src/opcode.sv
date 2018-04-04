package OpCode;
    typedef enum logic [5:0] {
        PSOP_R    = 6'd0,
        PSOP_B    = 6'd1,
        J         = 6'd2,
        JAL       = 6'd3,
        BEQ       = 6'd4,
        BNE       = 6'd5,
        BLEZ      = 6'd6,
        BGTZ      = 6'd7,
        ADDI      = 6'd8,
        ADDIU     = 6'd9,
        SLTI      = 6'd10,
        SLTIU     = 6'd11,
        ANDI      = 6'd12,
        ORI       = 6'd13,
        XORI      = 6'd14,
        LUI       = 6'd15,
        COP0      = 6'd16,
        LB        = 6'd32,
        LH        = 6'd33,
        LWL       = 6'd34,
        LW        = 6'd35,
        LBU       = 6'd36,
        LHU       = 6'd37,
        LWR       = 6'd38,
        SB        = 6'd40,
        SH        = 6'd41,
        SWL       = 6'd42,
        SW        = 6'd43,
        SWR       = 6'd46
    } OpCode_t;
endpackage

package Func;
    typedef enum logic [5:0] {
        SLL   = 6'd0,
        SRL   = 6'd2,
        SRA   = 6'd3,
        SLLV  = 6'd4,
        SRLV  = 6'd6,
        SRAV  = 6'd7,
        JR    = 6'd8,
        JALR  = 6'd9,
        MFHI  = 6'd16,
        MTHI  = 6'd17,
        MFLO  = 6'd18,
        MTLO  = 6'd19,
        MULT  = 6'd24,
        MULTU = 6'd25,
        DIV   = 6'd26,
        DIVU  = 6'd27,
        ADD   = 6'd32,
        ADDU  = 6'd33,
        SUB   = 6'd34,
        SUBU  = 6'd35,
        AND   = 6'd36,
        OR    = 6'd37,
        XOR   = 6'd38,
        NOR   = 6'd39,
        SLT   = 6'd42,
        SLTU  = 6'd43
    } Func_t;
endpackage
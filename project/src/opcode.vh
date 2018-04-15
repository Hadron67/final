`ifndef _OPCODE_VH_
`define _OPCODE_VH_

`define OPCODE_PSOP_R 6'd0
`define OPCODE_PSOP_B 6'd1
`define OPCODE_J      6'd2
`define OPCODE_JAL    6'd3
`define OPCODE_BEQ    6'd4
`define OPCODE_BNE    6'd5
`define OPCODE_BLEZ   6'd6
`define OPCODE_BGTZ   6'd7
`define OPCODE_ADDI   6'd8
`define OPCODE_ADDIU  6'd9
`define OPCODE_SLTI   6'd10
`define OPCODE_SLTIU  6'd11
`define OPCODE_ANDI   6'd12
`define OPCODE_ORI    6'd13
`define OPCODE_XORI   6'd14
`define OPCODE_LUI    6'd15
`define OPCODE_COP0   6'd16
`define OPCODE_LB     6'd32
`define OPCODE_LH     6'd33
`define OPCODE_LWL    6'd34
`define OPCODE_LW     6'd35
`define OPCODE_LBU    6'd36
`define OPCODE_LHU    6'd37
`define OPCODE_LWR    6'd38
`define OPCODE_SB     6'd40
`define OPCODE_SH     6'd41
`define OPCODE_SWL    6'd42
`define OPCODE_SW     6'd43
`define OPCODE_SWR    6'd46

`define FUNC_SLL   6'd0
`define FUNC_SRL   6'd2
`define FUNC_SRA   6'd3
`define FUNC_SLLV  6'd4
`define FUNC_SRLV  6'd6
`define FUNC_SRAV  6'd7
`define FUNC_JR    6'd8
`define FUNC_JALR  6'd9
`define FUNC_MFHI  6'd16
`define FUNC_MTHI  6'd17
`define FUNC_MFLO  6'd18
`define FUNC_MTLO  6'd19
`define FUNC_MULT  6'd24
`define FUNC_MULTU 6'd25
`define FUNC_DIV   6'd26
`define FUNC_DIVU  6'd27
`define FUNC_ADD   6'd32
`define FUNC_ADDU  6'd33
`define FUNC_SUB   6'd34
`define FUNC_SUBU  6'd35
`define FUNC_AND   6'd36
`define FUNC_OR    6'd37
`define FUNC_XOR   6'd38
`define FUNC_NOR   6'd39
`define FUNC_SLT   6'd42
`define FUNC_SLTU  6'd43

`define TLBOP_NONE     6'd0
`define TLBOP_TLBINV   6'd3
`define TLBOP_TLBINVF  6'd4
`define TLBOP_TLBP     6'd8
`define TLBOP_TLBR     6'd1
`define TLBOP_TLBWR    6'd6
`define TLBOP_TLBWI    6'd2

`endif
package BranchCondKind;
    typedef enum logic [2:0] {
        NONE,
        LTZ,
        GEZ,
        GTZ,
        EQ,
        NE,
        LEZ
    } BranchCondKind_t;
endpackage

import ALUOptr::ALUOptr_t;
import OpCode::OpCode_t;
import Func::Func_t;
import BranchCondKind::BranchCondKind_t;

module Controller(
    input wire [31:0] ins,
    
    output wire aluSrcA,
    output wire aluSrcB,
    output BranchCondKind_t branchCond,
    output ALUOptr_t aluOptr,
    output wire aluOverflow,
    output wire regDest,
    output wire extOp,
    output wire writeReg,
    output wire [1:0] writeRegSrc,
    output wire writeMem,
    output wire readMem,
    output wire jmp,
    output wire branch,
    output wire writeCP0
);
    OpCode_t op;
    Func_t func;
    wire [4:0] rs, rt;
    
    wire load, store, aluToReg, readCP0;
    
    assign func = Func_t'(ins[5:0]);
    assign op = OpCode_t'(ins[31:26]);
    assign rs = ins[25:21];
    assign rt = ins[20:16];

    assign aluSrcA = ~|op && (func == Func::SLL || func == Func::SRL || func == Func::SRA ) ? 1'b1 : 1'b0;
    assign aluSrcB = ~|op || op == OpCode::BEQ || op == OpCode::BNE ? 1'b0 : 1'b1; // format R
    assign aluOptr = 
        op == OpCode::PSOP_R && func == Func::ADD || op == OpCode::ADDI || load || store   ? ALUOptr::PLUS :
        op == OpCode::PSOP_R && func == Func::ADDU || op == OpCode::ADDIU                  ? ALUOptr::PLUSU :
        op == OpCode::PSOP_R && func == Func::SUB                                          ? ALUOptr::MINUS :
        op == OpCode::PSOP_R && func == Func::SUBU                                         ? ALUOptr::MINUSU :
        op == OpCode::PSOP_R && func == Func::AND || op == OpCode::ANDI                    ? ALUOptr::AND :
        op == OpCode::PSOP_R && func == Func::MULT                                         ? ALUOptr::TIMES :
        op == OpCode::PSOP_R && func == Func::MULTU                                        ? ALUOptr::TIMESU :
        op == OpCode::PSOP_R && func == Func::DIV                                          ? ALUOptr::DIV :
        op == OpCode::PSOP_R && func == Func::DIVU                                         ? ALUOptr::DIVU :
        op == OpCode::PSOP_R && func == Func::OR || op == OpCode::ORI                      ? ALUOptr::OR :
        op == OpCode::PSOP_R && func == Func::XOR || op == OpCode::XORI                    ? ALUOptr::XOR :
        op == OpCode::PSOP_R && func == Func::NOR                                          ? ALUOptr::NOR :
        op == OpCode::PSOP_R && func == Func::SLT || op == OpCode::SLTI                    ? ALUOptr::LT :
        op == OpCode::PSOP_R && func == Func::SLTU || op == OpCode::SLTIU                  ? ALUOptr::LTU :
        op == OpCode::BEQ                                                                  ? ALUOptr::EQ :
        op == OpCode::BNE                                                                  ? ALUOptr::NE :
        ALUOptr::NONE;
    assign aluOverflow = 
        op == OpCode::PSOP_R && (func == Func::ADD || func == Func::SUB) ||
        op == OpCode::ADDI ? 1'b1 : 1'b0;
    assign regDest = 
        ~|op ? 1'b0 :
        1'b1;
    assign extOp = 
        op == OpCode::ADDI ||
        op == OpCode::SLTI ||
        load || store ? 1'b1 : 1'b0;
    assign load = 
        op == OpCode::LB ||
        op == OpCode::LH ||
        op == OpCode::LWL ||
        op == OpCode::LW ||
        op == OpCode::LBU ||
        op == OpCode::LHU ||
        op == OpCode::LWR ? 1'b1 : 1'b0;
    assign store = 
        op == OpCode::SB ||
        op == OpCode::SH ||
        op == OpCode::SWL ||
        op == OpCode::SW ||
        op == OpCode::SWR ? 1'b1 : 1'b0;
    assign aluToReg = 
        ~|op || 
        op == OpCode::ADDI ||
        op == OpCode::ADDIU ||
        op == OpCode::SLTI ||
        op == OpCode::SLTIU ||
        op == OpCode::ANDI ||
        op == OpCode::ORI ||
        op == OpCode::XORI ||
        op == OpCode::LUI ? 1'b1 : 1'b0;
    assign writeReg = load | store | aluToReg | readCP0;
    assign writeRegSrc = 
        load ? 2'd1 : 
        aluToReg ? 2'd0 : 
        readCP0 ? 2'd2 :
        2'dx;
    assign writeMem = store ? 1'b1 : 1'b0;
    assign readMem = load ? 1'b1 : 1'b0;
    assign jmp = 
        op == OpCode::PSOP_R && (func == Func::JR || func == Func::JALR) ||
        op == OpCode::J ||
        op == OpCode::JAL ? 1'b1 : 1'b0;
    assign branch = 
        op == OpCode::PSOP_B || 
        op == OpCode::BEQ ||
        op == OpCode::BNE ||
        op == OpCode::BLEZ ||
        op == OpCode::BGTZ ? 1'b1 : 1'b0;
    assign branchCond = 
        op == OpCode::PSOP_B && rt == 0 /* bltz */ ? BranchCondKind::LTZ :
        op == OpCode::PSOP_B && rt == 1 /* bgez */ ? BranchCondKind::GEZ :
        op == OpCode::PSOP_B && rt == 16 /* bltzal */ ? BranchCondKind::LTZ :
        op == OpCode::PSOP_B && rt == 17 /* bgezal */ ? BranchCondKind::GEZ :
        op == OpCode::BEQ ? BranchCondKind::EQ :
        op == OpCode::BNE ? BranchCondKind::NE :
        op == OpCode::BLEZ ? BranchCondKind::LEZ :
        op == OpCode::BGTZ ? BranchCondKind::GTZ : BranchCondKind::NONE;
    assign readCP0 = op == OpCode::COP0 && rs == 0 && ~|ins[10:3];
    assign writeCP0 = op == OpCode::COP0 && rs == 4 && ~|ins[10:3];
endmodule
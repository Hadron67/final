`include "opcode.vh"
`include "ALUOp.vh"

module Controller(
    input wire [31:0] ins,
    
    output wire isLastIns,
    output wire aluSrcA,
    output wire aluSrcB,
    output wire `ALUOP_T aluOptr,
    output wire aluOverflow,
    output wire regDest,
    output wire extOp,
    output wire writeReg,
    output wire [1:0] writeRegSrc,
    output wire writeMem,
    output wire readMem,
    output wire jmp,
    output wire branch,
    output wire writeCP0,
    output wire readCP0,
    output wire isTlbOp,
    output wire eret
);
    wire [5:0] op;
    wire [5:0] func;
    wire [4:0] rs, rt;
    
    wire load, store, aluToReg;
    
    assign func = ins[5:0];
    assign op = ins[31:26];
    assign rs = ins[25:21];
    assign rt = ins[20:16];

    assign isLastIns = &ins;
    // XXX: What a mess! Need a better way to write signals
    assign aluSrcA = ~|op && (func == `FUNC_SLL || func == `FUNC_SRL || func == `FUNC_SRA ) ? 1'b1 : 1'b0;
    assign aluSrcB = ~|op || op == `OPCODE_BEQ || op == `OPCODE_BNE ? 1'b0 : 1'b1; // format R
    assign aluOptr = 
        op == `OPCODE_PSOP_R && func == `FUNC_ADD || op == `OPCODE_ADDI || load || store  ? `ALUOP_PLUS :
        op == `OPCODE_PSOP_R && func == `FUNC_ADDU || op == `OPCODE_ADDIU                 ? `ALUOP_PLUSU :
        op == `OPCODE_PSOP_R && func == `FUNC_SUB                                         ? `ALUOP_MINUS :
        op == `OPCODE_PSOP_R && func == `FUNC_SUBU                                        ? `ALUOP_MINUSU :
        op == `OPCODE_PSOP_R && func == `FUNC_AND || op == `OPCODE_ANDI                   ? `ALUOP_AND :
        op == `OPCODE_PSOP_R && func == `FUNC_MULT                                        ? `ALUOP_TIMES :
        op == `OPCODE_PSOP_R && func == `FUNC_MULTU                                       ? `ALUOP_TIMESU :
        op == `OPCODE_PSOP_R && func == `FUNC_DIV                                         ? `ALUOP_DIV :
        op == `OPCODE_PSOP_R && func == `FUNC_DIVU                                        ? `ALUOP_DIVU :
        op == `OPCODE_PSOP_R && func == `FUNC_OR || op == `OPCODE_ORI                     ? `ALUOP_OR :
        op == `OPCODE_PSOP_R && func == `FUNC_XOR || op == `OPCODE_XORI                   ? `ALUOP_XOR :
        op == `OPCODE_PSOP_R && func == `FUNC_NOR                                         ? `ALUOP_NOR :
        op == `OPCODE_PSOP_R && func == `FUNC_SLT || op == `OPCODE_SLTI                   ? `ALUOP_LT :
        op == `OPCODE_PSOP_R && func == `FUNC_SLTU || op == `OPCODE_SLTIU                 ? `ALUOP_LTU :
        op == `OPCODE_BEQ                                                                 ? `ALUOP_EQ :
        op == `OPCODE_BNE                                                                 ? `ALUOP_NE :
        `ALUOP_NONE;
    assign aluOverflow = 
        op == `OPCODE_PSOP_R && (func == `FUNC_ADD || func == `FUNC_SUB) ||
        op == `OPCODE_ADDI ? 1'b1 : 1'b0;
    assign regDest = 
        ~|op ? 1'b0 :
        1'b1;
    assign extOp = 
        op == `OPCODE_ADDI ||
        op == `OPCODE_SLTI ||
        load || store ? 1'b1 : 1'b0;
    assign load = 
        op == `OPCODE_LB ||
        op == `OPCODE_LH ||
        op == `OPCODE_LWL ||
        op == `OPCODE_LW ||
        op == `OPCODE_LBU ||
        op == `OPCODE_LHU ||
        op == `OPCODE_LWR ? 1'b1 : 1'b0;
    assign store = 
        op == `OPCODE_SB ||
        op == `OPCODE_SH ||
        op == `OPCODE_SWL ||
        op == `OPCODE_SW ||
        op == `OPCODE_SWR ? 1'b1 : 1'b0;
    assign aluToReg = 
        ~|op || 
        op == `OPCODE_ADDI ||
        op == `OPCODE_ADDIU ||
        op == `OPCODE_SLTI ||
        op == `OPCODE_SLTIU ||
        op == `OPCODE_ANDI ||
        op == `OPCODE_ORI ||
        op == `OPCODE_XORI ||
        op == `OPCODE_LUI ? 1'b1 : 1'b0;
    assign writeReg = load | aluToReg | readCP0;
    assign writeRegSrc = 
        load ? 2'd1 : 
        aluToReg ? 2'd0 : 
        readCP0 ? 2'd2 :
        2'dx;
    assign writeMem = store ? 1'b1 : 1'b0;
    assign readMem = load ? 1'b1 : 1'b0;
    assign jmp = 
        op == `OPCODE_PSOP_R && (func == `FUNC_JR || func == `FUNC_JALR) ||
        op == `OPCODE_J ||
        op == `OPCODE_JAL ? 1'b1 : 1'b0;
    assign branch = 
        op == `OPCODE_PSOP_B || 
        op == `OPCODE_BEQ ||
        op == `OPCODE_BNE ||
        op == `OPCODE_BLEZ ||
        op == `OPCODE_BGTZ ? 1'b1 : 1'b0;
    assign readCP0 = op == `OPCODE_COP0 && rs == 0 && ~|ins[10:3];
    assign writeCP0 = op == `OPCODE_COP0 && rs == 4 && ~|ins[10:3];
    assign isTlbOp = op == `OPCODE_COP0 && ins[25] && ~|ins[24:6];
    assign eret = isTlbOp && ins[5:0] == 6'b011000;

endmodule
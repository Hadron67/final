`include "opcode.vh"
`include "ALUOp.vh"
`include "CPU.vh"
`include "DataBus.vh"

module Controller(
    input wire [31:0] ins,
    
    output wire nop,
    output wire isLastIns,
    output wire db_signed,
    output wire `CPU_ALU_SRC_A aluSrcA,
    output wire `CPU_ALU_SRC_B aluSrcB,
    output reg `MEM_LEN accessMemLen,
    output reg `ALUOP_T aluOptr,
    output wire aluOverflow,
    output wire `CPU_WRITE_REG_DEST_SRC regDestSrc,
    output wire extOp,
    output wire writeReg,
    output wire `CPU_WRITE_REG_SRC writeRegSrc,
    output wire writeMem,
    output wire readMem,
    output wire jmp, jr, link,
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
    assign nop = ~|ins;
    // XXX: What a mess! Need a better way to write signals
    assign aluSrcA = ~|op && (func == `FUNC_SLL || func == `FUNC_SRL || func == `FUNC_SRA ) ? `CPU_ALU_SRC_A_SHAMT : `CPU_ALU_SRC_A_REGA;
    assign aluSrcB = ~|op || op == `OPCODE_BEQ || op == `OPCODE_BNE ? `CPU_ALU_SRC_B_REGB : `CPU_ALU_SRC_B_IMM; // format R
    assign aluOverflow = 
        op == `OPCODE_PSOP_R && (func == `FUNC_ADD || func == `FUNC_SUB) ||
        op == `OPCODE_ADDI ? 1'b1 : 1'b0;
    assign regDestSrc = 
        ~|op ? `CPU_WRITE_REG_DEST_SRC_RD :
        `CPU_WRITE_REG_DEST_SRC_RT;
    assign extOp = 
        op == `OPCODE_ADDI ||
        op == `OPCODE_SLTI ||
        load || store;
    assign load = 
        op == `OPCODE_LB ||
        op == `OPCODE_LH ||
        op == `OPCODE_LWL ||
        op == `OPCODE_LW ||
        op == `OPCODE_LBU ||
        op == `OPCODE_LHU ||
        op == `OPCODE_LWR;
    assign store = 
        op == `OPCODE_SB ||
        op == `OPCODE_SH ||
        op == `OPCODE_SWL ||
        op == `OPCODE_SW ||
        op == `OPCODE_SWR;
    assign db_signed = !(op == `OPCODE_LBU || op == `OPCODE_LHU);
    assign aluToReg = 
        ~|op || 
        op == `OPCODE_ADDI ||
        op == `OPCODE_ADDIU ||
        op == `OPCODE_SLTI ||
        op == `OPCODE_SLTIU ||
        op == `OPCODE_ANDI ||
        op == `OPCODE_ORI ||
        op == `OPCODE_XORI;
    assign writeReg = load | aluToReg | readCP0 | op == `OPCODE_LUI;
    assign writeRegSrc = 
        load ? `CPU_WRITE_REG_SRC_MEM : 
        aluToReg ? `CPU_WRITE_REG_SRC_ALU : 
        readCP0 ? `CPU_WRITE_REG_SRC_CP0REG :
        op == `OPCODE_LUI ? `CPU_WRITE_REG_SRC_IMM :
        2'dx;
    assign writeMem = store;
    assign readMem = load;
    assign jmp = 
        op == `OPCODE_PSOP_R && (func == `FUNC_JR || func == `FUNC_JALR) ||
        op == `OPCODE_J ||
        op == `OPCODE_JAL;
    assign branch = 
        op == `OPCODE_PSOP_B || 
        op == `OPCODE_BEQ ||
        op == `OPCODE_BNE ||
        op == `OPCODE_BLEZ ||
        op == `OPCODE_BGTZ;
    assign readCP0 = op == `OPCODE_COP0 && rs == 0 && ~|ins[10:3];
    assign writeCP0 = op == `OPCODE_COP0 && rs == 4 && ~|ins[10:3];
    assign isTlbOp = op == `OPCODE_COP0 && ins[25] && ~|ins[24:6];
    assign eret = isTlbOp && ins[5:0] == 6'b011000;

    always @* begin
        case(op)
            `OPCODE_LB:  accessMemLen = `MEM_LEN_B;
            `OPCODE_LH:  accessMemLen = `MEM_LEN_H;
            `OPCODE_LWL: accessMemLen = `MEM_LEN_WL;
            `OPCODE_LW:  accessMemLen = `MEM_LEN_W;
            `OPCODE_LBU: accessMemLen = `MEM_LEN_B;
            `OPCODE_LHU: accessMemLen = `MEM_LEN_H;
            `OPCODE_LWR: accessMemLen = `MEM_LEN_WR;
            `OPCODE_SB:  accessMemLen = `MEM_LEN_B;
            `OPCODE_SH:  accessMemLen = `MEM_LEN_H;
            `OPCODE_SWL: accessMemLen = `MEM_LEN_WL;
            `OPCODE_SW:  accessMemLen = `MEM_LEN_W;
            `OPCODE_SWR: accessMemLen = `MEM_LEN_WR;
            default: accessMemLen = 3'dx;
        endcase
    end
    always @* begin
        if(op == `OPCODE_PSOP_R)
            case(func)
                `FUNC_ADD:  aluOptr = `ALUOP_PLUS;
                `FUNC_ADDU: aluOptr = `ALUOP_PLUS;
                `FUNC_SUB:  aluOptr = `ALUOP_MINUS;
                `FUNC_SUBU: aluOptr = `ALUOP_MINUSU;
                `FUNC_AND:  aluOptr = `ALUOP_AND;
                `FUNC_MULT: aluOptr = `ALUOP_TIMES;
                `FUNC_MULTU:aluOptr = `ALUOP_TIMESU;
                `FUNC_DIV:  aluOptr = `ALUOP_DIV;
                `FUNC_DIVU: aluOptr = `ALUOP_DIVU;
                `FUNC_OR:   aluOptr = `ALUOP_OR;
                `FUNC_XOR:  aluOptr = `ALUOP_XOR;
                `FUNC_NOR:  aluOptr = `ALUOP_NOR;
                `FUNC_SLT:  aluOptr = `ALUOP_LT;
                `FUNC_SLTU: aluOptr = `ALUOP_LTU;
                default: aluOptr = `ALUOP_NONE;
            endcase
        else
            case(op)
                `OPCODE_ADDI:  aluOptr = `ALUOP_PLUS;
                `OPCODE_ADDIU: aluOptr = `ALUOP_PLUS;
                `OPCODE_ANDI:  aluOptr = `ALUOP_AND;
                `OPCODE_ORI:   aluOptr = `ALUOP_OR;
                `OPCODE_XORI:  aluOptr = `ALUOP_XOR;
                `OPCODE_SLTI:  aluOptr = `ALUOP_LT;
                `OPCODE_SLTIU: aluOptr = `ALUOP_LTU;
                `OPCODE_BEQ:   aluOptr = `ALUOP_EQ;
                `OPCODE_BNE:   aluOptr = `ALUOP_NE;
                default: aluOptr = load || store ? `ALUOP_PLUS : `ALUOP_NONE;
            endcase
    end

endmodule
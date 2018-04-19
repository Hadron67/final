// import ALUOptr::ALUOptr_t;
// import BranchCondKind::BranchCondKind_t;
// import OpCode::OpCode_t;
`include "DataBus.vh"
`include "ALUOp.vh"
`include "opcode.vh"
`include "mmu.vh"
`include "CPU.vh"

module CPUCore(
    input wire clk,
    input wire res,
    output reg `CPU_MODE_T cpuMode,
    
    input wire [31:0] db_dataIn,
    input wire db_ready,
    output wire [31:0] db_dataOut,
    output reg [31:0] db_addr,
    output reg `MEM_ACCESS_T db_accessType,
    output reg `MEM_LEN db_memLen,

    output wire `MMU_REG_T mmu_reg,
    output wire [31:0] mmu_dataIn,
    input wire [31:0] mmu_dataOut,
    output reg `MMU_CMD_T mmu_cmd,
    input wire `MMU_EXCEPTION_T mmu_exception
);
    localparam S_INITIAL           = 4'd0;
    localparam S_FETCH_INSTRUCTION = 4'd1;
    localparam S_EXEC              = 4'd2;
    localparam S_READ_MEM          = 4'd4;
    localparam S_WRITE_MEM         = 4'd5;
    localparam S_EXCEPTION         = 4'd6;
    localparam S_SAVE_INSTRUCTION  = 4'd8;
    localparam S_SAVE_PC           = 4'd9;

    integer i;
    reg [31:0] insReg;
    wire [31:0] ins;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm;
    wire [31:0] aluInA, aluInB, aluOut;
    wire [31:0] regOutA, regOutB;
    reg [31:0] dataIn;
    wire overflow, zero;
    reg [31:0] regIn;
    reg [31:0] aluA, aluB;
    reg [4:0] regDest;

    wire nop;
    wire `MEM_LEN accessMemLen;
    wire memSigned;
    wire `CPU_ALU_SRC_A aluSrcA;
    wire `CPU_ALU_SRC_B aluSrcB;
    // prepare all the signals according to next state
    reg [3:0] state, nextState;
    wire `ALUOP_T aluOptr;
    wire aluOverflow, extOp, writeReg;
    wire `CPU_WRITE_REG_DEST_SRC regDestSrc;
    wire `CPU_WRITE_REG_SRC writeRegSrc;
    wire writeMem, readMem;
    wire jmp, branch, jmpReg;
    wire writeCP0, readCP0;
    wire isTlbOp, eret;
    
    reg [31:0] pc;
    wire [31:0] nextpc, linkpc;
    reg [63:0] acc;
    wire [7:0] cp0RegDesc;
    wire [31:0] cp0RegOut;
    wire [5:0] tlbOp;
    wire readMMUReg, writeMMUReg;
    wire [31:0] cp0_epc, cp0_status, cp0_cause, cp0_badVAddr;

    assign ins = state == S_FETCH_INSTRUCTION && db_ready ? db_dataIn : insReg;
    assign rs = ins[25:21];
    assign rt = ins[20:16];
    assign rd = ins[15:11];
    assign shamt = ins[10:6];
    assign imm = ins[15:0];
    assign tlbOp = ins[5:0];
    assign cp0RegDesc = {rd, ins[2:0]};
    assign linkpc = pc + 32'd8;

    assign db_dataOut = regOutB;
    // assign dataIn = db_dataIn;

    always @* begin
        case(db_memLen)
            `MEM_LEN_B: dataIn = {{24{memSigned ? db_dataIn[7] : 1'b0}}, db_dataIn[7:0]};
            `MEM_LEN_H: dataIn = {{16{memSigned ? db_dataIn[15] : 1'b0}}, db_dataIn[15:0]};
            `MEM_LEN_W: dataIn = db_dataIn;
            default: dataIn = 32'dx;
        endcase
    end
    // multiplexer for registers input
    always @* begin: mux_registerInput
        case(writeRegSrc)
            `CPU_WRITE_REG_SRC_ALU: regIn = aluOut;
            `CPU_WRITE_REG_SRC_MEM: regIn = dataIn;
            `CPU_WRITE_REG_SRC_CP0REG: regIn = cp0RegOut;
            `CPU_WRITE_REG_SRC_IMM: regIn = {imm, {16{1'b0}}};
            `CPU_WRITE_REG_SRC_PC: regIn = linkpc;
            default: regIn = 32'dx;
        endcase
    end
    always @* begin
        case(aluSrcA)
            `CPU_ALU_SRC_A_REGA:  aluA = regOutA;
            `CPU_ALU_SRC_A_SHAMT: aluA = shamt;
            default: aluA = 32'dx;
        endcase
    end
    always @* begin
        case(aluSrcB)
            `CPU_ALU_SRC_B_REGB: aluB = regOutB;
            `CPU_ALU_SRC_B_IMM:  aluB = { {16{extOp ? imm[15] : 1'b0}}, imm };
            default: aluB = 32'dx;
        endcase
    end
    always @* begin
        case(regDestSrc)
            `CPU_WRITE_REG_DEST_SRC_RT: regDest = rt;
            `CPU_WRITE_REG_DEST_SRC_RD: regDest = rd;
            `CPU_WRITE_REG_DEST_SRC_RA: regDest = 5'd31;
            default: regDest = 5'dx;
        endcase
    end
    // data address
    always @* begin: mux_dataAddress
        if(nextState == S_FETCH_INSTRUCTION) begin
            if(state == S_INITIAL)
                db_addr = pc;
            else
                db_addr = nextpc;
        end else
            db_addr = aluOut;
    end
    // data access type
    always @* begin: mux_accessType
        case(nextState)
            S_FETCH_INSTRUCTION: db_accessType = `MEM_ACCESS_X;
            S_READ_MEM:          db_accessType = `MEM_ACCESS_R;
            S_WRITE_MEM:         db_accessType = `MEM_ACCESS_W;
            default:             db_accessType = `MEM_ACCESS_NONE;
        endcase
    end
    always @* begin
        if(nextState == S_FETCH_INSTRUCTION)
            db_memLen = `MEM_LEN_W;
        else
            db_memLen = accessMemLen;
    end
    always @* begin
        case(cp0_status[4:3])
            2'b0: cpuMode = cp0_status[2:1] == 2'b11 ? `CPU_MODE_KERNEL : 2'dx;
            2'b01: cpuMode = cp0_status[2:1] == 2'b00 ? `CPU_MODE_SUPERVISOR : 2'dx;
            2'b10: cpuMode = cp0_status[2:1] == 2'b00 ? `CPU_MODE_USER : 2'dx;
            default: cpuMode = 2'dx;
        endcase
    end
    always @* begin: mux_tlbOp
        if(isTlbOp && state == S_FETCH_INSTRUCTION) begin
            case(tlbOp)
                // `TLBOP_TLBINV: 
                // `TLBOP_TLBINVF:
                `TLBOP_TLBP:  mmu_cmd = `MMU_CMD_PROB_TLB;
                `TLBOP_TLBR:  mmu_cmd = `MMU_CMD_READ_TLB;
                `TLBOP_TLBWR: mmu_cmd = `MMU_CMD_WRITE_TLB_RANDOM;
                `TLBOP_TLBWI: mmu_cmd = `MMU_CMD_WRITE_TLB;
                default:      mmu_cmd = `MMU_CMD_NONE;
            endcase
        end 
        else if(writeMMUReg)
            mmu_cmd = `MMU_CMD_WRITE_REG;
        else if(readMMUReg)
            mmu_cmd = `MMU_CMD_READ_REG;
        else
            mmu_cmd = `MMU_CMD_NONE;
    end
    // combinational logic to get next state to go.
    always @* begin: getNextState
        case(state)
            S_INITIAL: nextState = S_FETCH_INSTRUCTION;
            S_FETCH_INSTRUCTION: 
                if(mmu_exception != `MMU_EXCEPTION_NONE) begin
                    nextState = S_EXCEPTION;
                end 
                else if(db_ready)
                    if(isTlbOp || nop)
                        nextState = S_FETCH_INSTRUCTION;
                    else
                        nextState = S_EXEC;
                else 
                    nextState = S_FETCH_INSTRUCTION;
            S_EXEC:
                if(readMem)
                    nextState = S_READ_MEM;
                else if(writeMem)
                    nextState = S_WRITE_MEM;
                else
                    nextState = S_FETCH_INSTRUCTION;
            S_READ_MEM:  nextState = db_ready ? S_FETCH_INSTRUCTION : S_READ_MEM;
            S_WRITE_MEM: nextState = db_ready ? S_FETCH_INSTRUCTION : S_WRITE_MEM;
            // TODO: process exceptions
            S_EXCEPTION: nextState = S_FETCH_INSTRUCTION;
        endcase
    end

    InstructionFetcher insFetcher (
        .branch(branch),
        .jmp(jmp),
        .jr(jmpReg),
        .target(ins[25:0]),
        .imm(ins[15:0]),
        .ra(regOutA),
        .pc(pc),
        .epc(cp0_epc),
        .nextpc(nextpc),
        .z(zero),
        .eret(eret)
    );
    Controller ctl(
        .ins(ins),
        .nop(nop),
        .aluSrcA(aluSrcA),
        .aluSrcB(aluSrcB),
        .aluOptr(aluOptr),
        .memSigned(memSigned),
        .accessMemLen(accessMemLen),
        .aluOverflow(aluOverflow),
        .regDestSrc(regDestSrc),
        .extOp(extOp),
        .writeReg(writeReg),
        .writeRegSrc(writeRegSrc),
        .writeMem(writeMem),
        .readMem(readMem),
        .jmp(jmp),
        .branch(branch),
        .jr(jmpReg),
        .writeCP0(writeCP0),
        .readCP0(readCP0),
        .isTlbOp(isTlbOp),
        .eret(eret)
    );
    RegFile regs (
        .clk(clk),
        .regA(rs),
        .regB(rt),
        .regW(regDest),
        .dataIn(regIn),
        .outA(regOutA),
        .outB(regOutB),
        .we(writeReg && nextState == S_FETCH_INSTRUCTION),
        .re(!readCP0 && state == S_FETCH_INSTRUCTION && nextState == S_EXEC)
    );
    CP0Regs cp0Regs (
        .clk(clk),
        .we(writeCP0 && nextState == S_FETCH_INSTRUCTION),
        .re(readCP0 && nextState == S_EXEC),
        .rd(cp0RegDesc[7:3]),
        .sel(cp0RegDesc[2:0]),
        .dataIn(regOutB),
        .dataOut(cp0RegOut),

        .mmu_dataOut(mmu_dataOut),
        .mmu_dataIn(mmu_dataIn),
        .mmu_reg(mmu_reg),
        .readMMUReg(readMMUReg),
        .writeMMUReg(writeMMUReg),

        .in_epc(pc),
        .we_epc(nextState == S_EXCEPTION),

        .cp0_epc(cp0_epc),
        .cp0_cause(cp0_cause),
        .cp0_badVAddr(cp0_badVAddr),
        .cp0_status(cp0_status)
    );
    ALU alu (
        .optr(aluOptr),
        .overflowTrap(aluOverflow),
        .A(aluA),
        .B(aluB),
        .z(zero),
        .overflow(overflow),
        .result(aluOut)
    );
    
    // pc and instruction ff
    always @(posedge clk or posedge res) begin: ff_pc
        if(res) begin
            state <= S_INITIAL;
            pc <= 32'h80000000;
            // pc <= 0;
        end 
        else begin
            if(state == S_FETCH_INSTRUCTION && db_ready)
                insReg <= db_dataIn;
            if(state != S_INITIAL && nextState == S_FETCH_INSTRUCTION)
                pc <= nextpc;
            state <= nextState;
        end
    end
endmodule // CPU
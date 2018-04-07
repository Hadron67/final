// import ALUOptr::ALUOptr_t;
// import BranchCondKind::BranchCondKind_t;
// import OpCode::OpCode_t;
`include "DataBus.vh"
`include "ALUOp.vh"

module CPUCore(
    input  wire        clk,
    input  wire        res,
    input  wire        pageFaultIReq,
    
    input  wire [31:0] db_dataIn,
    input  wire        db_ready,
    output wire [31:0] db_dataOut,
    output reg  [31:0] db_addr,
    output reg  [1:0]  db_accessType,

    output wire [31:0] mmu_index, 
                       mmu_random, 
                       mmu_entryLo0, 
                       mmu_entryLo1, 
                       mmu_ctx, 
                       mmu_pageMask, 
                       mmu_wired, 
                       mmu_entryHi,
    output wire        mmu_writeTlb,
    input  wire        mmu_tlbMiss, 
                       mmu_tlbModified, 
                       mmu_tlbInvalid
);
    localparam S_INITIAL           = 3'd0;
    localparam S_FETCH_INSTRUCTION = 3'd1;
    localparam S_EXEC              = 3'd2;
    localparam S_WRITE_REG         = 3'd3;
    localparam S_READ_MEM          = 3'd4;
    localparam S_WRITE_MEM         = 3'd5;
    localparam S_EXCEPTION         = 3'd6;

    integer i;
    reg [31:0] insReg;
    wire [31:0] ins;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm;
    wire [31:0] aluInA, aluInB, aluOut;
    wire [31:0] regOutA, regOutB;
    wire [31:0] dataIn;
    wire overflow, zero;
    reg [31:0] regIn;
    reg [31:0] mmuRegs[7:0];

    wire aluSrcA, aluSrcB;
    // prepare all the signals according to next state
    reg [2:0] state, nextState;
    wire `ALUOP_T aluOptr;
    wire aluOverflow, regDest, extOp, writeReg;
    wire [1:0] writeRegSrc;
    wire writeMem, readMem;
    wire jmp, branch;
    wire writeCP0, readCP0;
    
    reg [31:0] pc; 
    wire [31:0] nextpc;
    reg [63:0] acc;
    wire [2:0] sel;
    wire [31:0] cp0RegOut;

    assign ins = state == S_FETCH_INSTRUCTION && db_ready ? db_dataIn : insReg;
    assign rs = ins[25:21];
    assign rt = ins[20:16];
    assign rd = ins[15:11];
    assign shamt = ins[10:6];
    assign imm = ins[15:0];
    assign sel = ins[2:0];

    assign db_dataOut = regOutB;
    assign dataIn = db_dataIn;

    // assign mmu_index     = cp0Regs[0];
    // assign mmu_random    = cp0Regs[1];
    // assign mmu_entryLo0  = cp0Regs[2];
    // assign mmu_entryLo1  = cp0Regs[3];
    // assign mmu_ctx       = cp0Regs[4];
    // assign mmu_pageMask  = cp0Regs[5];
    // assign mmu_wired     = cp0Regs[6];
    // assign mmu_entryHi   = cp0Regs[10];
    
    always @* begin
        case(writeRegSrc)
            0: regIn = aluOut;
            1: regIn = dataIn;
            2: regIn = cp0RegOut;
            default: regIn = 32'dx;
        endcase
    end
    always @* begin
        if(nextState == S_FETCH_INSTRUCTION) begin
            if(state == S_INITIAL)
                db_addr = pc;
            else
                db_addr = nextpc;
        end else
            db_addr = aluOut;
    end
    always @* begin
        case(nextState)
            S_FETCH_INSTRUCTION: db_accessType = `MEM_ACCESS_X;
            S_READ_MEM:          db_accessType = `MEM_ACCESS_R;
            S_WRITE_MEM:         db_accessType = `MEM_ACCESS_W;
            default:             db_accessType = `MEM_ACCESS_NONE;
        endcase
    end
    
    InstructionFetcher insFetcher (
        .branch(branch),
        .jmp(jmp),
        .target(ins[25:0]),
        .imm(ins[15:0]),
        .pc(pc),
        .nextpc(nextpc),
        .z(zero)
    );
    Controller ctl(
        .ins(ins),
        .aluSrcA(aluSrcA),
        .aluSrcB(aluSrcB),
        .aluOptr(aluOptr),
        .aluOverflow(aluOverflow),
        .regDest(regDest),
        .extOp(extOp),
        .writeReg(writeReg),
        .writeRegSrc(writeRegSrc),
        .writeMem(writeMem),
        .readMem(readMem),
        .jmp(jmp),
        .branch(branch),
        // .branchCond(branchCond),
        .writeCP0(writeCP0),
        .readCP0(readCP0)
    );
    RegFile regs (
        .clk(clk),
        .regA(rs),
        .regB(rt),
        .regW(regDest == 0 ? rd : rt),
        .dataIn(regIn),
        .outA(regOutA),
        .outB(regOutB),
        .we(writeReg && (nextState == S_WRITE_REG || state == S_EXEC && !writeMem && !readMem )),
        .re(nextState == S_EXEC)
    );
    CP0Regs cp0Regs (
        .clk(clk),
        .we(writeCP0 && nextState == S_WRITE_REG),
        .re(readCP0 && nextState == S_EXEC),
        .rd(rd),
        .sel(sel),
        .dataIn(regOutB),
        .dataOut(cp0RegOut)
    );
    ALU alu (
        .optr(aluOptr),
        .overflowTrap(aluOverflow),
        .A(aluSrcA == 0 ? regOutA : shamt),
        .B(aluSrcB == 0 ? regOutB : { {16{extOp ? imm[15] : 1'b0}}, imm }),
        .z(zero),
        .overflow(overflow),
        .result(aluOut)
    );

    // combinational logic to get next state to go.
    always @* begin
        case(state)
            S_INITIAL: nextState = S_FETCH_INSTRUCTION;
            S_FETCH_INSTRUCTION: 
                if(pageFaultIReq) begin
                    nextState = S_EXCEPTION;
                end else if(db_ready)
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
            S_READ_MEM:  nextState = db_ready ? S_WRITE_REG : S_READ_MEM;
            S_WRITE_MEM: nextState = db_ready ? S_FETCH_INSTRUCTION : S_WRITE_MEM;
            S_WRITE_REG: nextState = S_FETCH_INSTRUCTION;
            // TODO: process exceptions
            S_EXCEPTION: nextState = S_EXCEPTION;
        endcase
    end
    
    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_INITIAL;
            pc <= 0;
        end else begin
            if(state == S_FETCH_INSTRUCTION && nextState == S_EXEC)
                insReg <= dataIn;
            if(state != S_INITIAL && nextState == S_FETCH_INSTRUCTION)
                pc <= nextpc;

            state <= nextState;
        end
    end

endmodule // CPU
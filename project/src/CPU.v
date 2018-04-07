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
    localparam S_READ_MEM          = 3'd3;
    localparam S_WRITE_MEM         = 3'd4;
    localparam S_WRITE_BACK        = 3'd5;
    localparam S_PAGEFAULT         = 3'd6;

    integer i;
    reg [31:0] ins;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm;
    wire [31:0] aluInA, aluInB, aluOut;
    wire [31:0] regOutA, regOutB;
    wire [31:0] dataIn;
    wire overflow, zero;
    reg [31:0] regIn;
    reg [31:0] cpuRegs[31:0];

    wire aluSrcA;
    wire aluSrcB;
    // prepare all the signals according to next state
    reg [2:0] state, nextState;
    wire `ALUOP_T aluOptr;
    wire aluOverflow;
    wire regDest;
    wire extOp;
    wire writeReg;
    wire [1:0] writeRegSrc;
    wire writeMem, readMem;
    wire jmp;
    wire branch;
    wire writeCP0;
    // BranchCondKind_t branchCond;
    // wire [5:0] op;
    
    reg [31:0] pc; 
    wire [31:0] nextpc;
    reg [63:0] acc;
    reg [31:0] cp0Regs[38:0];
    wire [5:0] cp0RegNum;
    wire [3:0] sel;

    assign rs = ins[25:21];
    assign rt = ins[20:16];
    assign rd = ins[15:11];
    assign shamt = ins[10:6];
    assign imm = ins[15:0];
    assign sel = ins[2:0];

    assign regOutA = rs == 0 ? 32'd0 : cpuRegs[rs];
    assign regOutB = rt == 0 ? 32'd0 : cpuRegs[rt];

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
            2: regIn = cp0Regs[cp0RegNum];
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
    
    CP0RegNum U20 (
        .rd(rd),
        .sel(sel),
        .regNum(cp0RegNum)
    );
    InstructionFetcher U1 (
        .branch(branch),
        .jmp(jmp),
        .target(ins[25:0]),
        .imm(ins[15:0]),
        .pc(pc),
        .nextpc(nextpc),
        .z(zero)
    );
    Controller U2(
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
        .writeCP0(writeCP0)
    );
    ALU U4 (
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
                if(pageFaultIReq)
                    nextState = S_PAGEFAULT;
                else if(db_ready)
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
            S_READ_MEM:   nextState = db_ready ? S_WRITE_BACK : S_READ_MEM;
            S_WRITE_MEM:  nextState = db_ready ? S_FETCH_INSTRUCTION : S_WRITE_MEM;
            S_WRITE_BACK: nextState = S_FETCH_INSTRUCTION;
            // TODO: process page fault
            S_PAGEFAULT: nextState = S_PAGEFAULT;
        endcase
    end
    
    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_INITIAL;
            pc <= 0;
        end else begin
            if(state == S_FETCH_INSTRUCTION && nextState == S_EXEC)
                ins <= dataIn;
            if(state != S_INITIAL && nextState == S_FETCH_INSTRUCTION)
                pc <= nextpc;
            if(state == S_EXEC)
                $display("executing: %d", ins[31:26]);
            
            // register file
            if(writeReg && (nextState == S_WRITE_BACK || nextState == S_EXEC && !writeMem && !readMem )) begin
                cpuRegs[regDest == 0 ? rd : rt] <= regIn;
                $display("written data (%d) to register $%d", regIn, regDest == 0 ? rd : rt);
            end

            //coprocessor1 registers
            if(writeCP0) begin
                cp0Regs[cp0RegNum] <= regOutB;
                $display("written data (%d) to cp0 register $%d", regOutB, cp0RegNum);
            end

            state <= nextState;
        end
    end

endmodule // CPU
import ALUOptr::ALUOptr_t;
import BranchCondKind::BranchCondKind_t;
import OpCode::OpCode_t;

module CPUCore(
    input wire clk,
    input wire res,
    input wire pageFaultIReq,
    DataBus.master db,
    IMMU.cpu mmu
);
    typedef enum logic [2:0] {
        CPUSTATE_INITIAL,
        CPUSTATE_FETCHINSTRUCTION,
        CPUSTATE_EXEC,
        CPUSTATE_READMEM,
        CPUSTATE_WRITEMEM,
        CPUSTATE_WRITEBACK,
    
        CPUSTATE_PAGEFAULT
    } CPUState;
    int i;
    logic [31:0] ins;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm;
    wire [31:0] aluInA, aluInB, aluOut;
    wire [31:0] regOutA, regOutB;
    wire [31:0] dataIn;
    wire overflow, zero;
    logic [31:0] regIn;
    logic [31:0] cpuRegs[31:0];

    wire aluSrcA;
    wire aluSrcB;
    // prepare all the signals according to next state
    CPUState state, nextState;
    ALUOptr_t aluOptr;
    wire aluOverflow;
    wire regDest;
    wire extOp;
    wire writeReg;
    wire [1:0] writeRegSrc;
    wire writeMem, readMem;
    wire jmp;
    wire branch;
    wire writeCP0;
    BranchCondKind_t branchCond;
    OpCode_t op;
    
    logic [31:0] pc, nextpc;
    logic [63:0] acc;
    logic [31:0] cp0Regs[38:0];
    logic [5:0] cp0RegNum;
    logic [3:0] sel;

    assign rs = ins[25:21];
    assign rt = ins[20:16];
    assign rd = ins[15:11];
    assign shamt = ins[10:6];
    assign imm = ins[15:0];

    assign regOutA = rs == 0 ? 32'd0 : cpuRegs[rs];
    assign regOutB = rt == 0 ? 32'd0 : cpuRegs[rt];

    assign db.read = nextState == CPUSTATE_READMEM || nextState == CPUSTATE_FETCHINSTRUCTION;
    assign db.write = nextState == CPUSTATE_WRITEMEM;
    assign db.dataOut = regOutB;
    assign dataIn = db.dataIn;
    assign db.memType = nextState == CPUSTATE_FETCHINSTRUCTION ? MemType::WORD : MemType::BYTE;
    
    // assign cp0.writeReg = writeCP0;
    // assign cp0.sel = ins[2:0];
    // assign cp0.regNum = rd;
    // assign cp0.dataCPU = regOutB;
    assign mmu.index     = cp0Regs[0];
    assign mmu.random    = cp0Regs[1];
    assign mmu.entryLo0  = cp0Regs[2];
    assign mmu.entryLo1  = cp0Regs[3];
    assign mmu.ctx       = cp0Regs[4];
    assign mmu.pageMask  = cp0Regs[5];
    assign mmu.wired     = cp0Regs[6];
    assign mmu.entryHi   = cp0Regs[10];
    
    always_comb begin
        case(writeRegSrc)
            0: regIn = aluOut;
            1: regIn = dataIn;
            2: regIn = cp0Regs[cp0RegNum];
            default: regIn = 32'dx;
        endcase
    end
    always_comb begin
        if(nextState == CPUSTATE_FETCHINSTRUCTION) begin
            if(state == CPUSTATE_INITIAL)
                db.addr = pc;
            else
                db.addr = nextpc;
        end else
            db.addr = aluOut;
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
        .branchCond(branchCond),
        .writeCP0(writeCP0)
    );
    ALU U4 (
        .optr(aluOptr),
        .overflowTrap(aluOverflow),
        .A(aluSrcA == 0 ? regOutA : shamt),
        .B(aluSrcB == 0 ? regOutB : extOp ? 32'(signed'(imm)) : 32'(imm)),
        .z(zero),
        .overflow(overflow),
        .result(aluOut)
    );

    // combinational logic to get next state to go.
    always_comb begin
        case(state)
            CPUSTATE_INITIAL: nextState = CPUSTATE_FETCHINSTRUCTION;
            CPUSTATE_FETCHINSTRUCTION: 
                if(pageFaultIReq)
                    nextState = CPUSTATE_PAGEFAULT;
                else if(db.ready)
                    nextState = CPUSTATE_EXEC;
                else 
                    nextState = CPUSTATE_FETCHINSTRUCTION;
            CPUSTATE_EXEC:
                if(readMem)
                    nextState = CPUSTATE_READMEM;
                else if(writeMem)
                    nextState = CPUSTATE_WRITEMEM;
                else
                    nextState = CPUSTATE_FETCHINSTRUCTION;
            CPUSTATE_READMEM:
                if(db.ready)
                    nextState = CPUSTATE_WRITEBACK;
                else 
                    nextState = CPUSTATE_READMEM;
            CPUSTATE_WRITEMEM:
                if(db.ready)
                    nextState = CPUSTATE_FETCHINSTRUCTION;
                else
                    nextState = CPUSTATE_WRITEMEM;
            CPUSTATE_WRITEBACK:
                nextState = CPUSTATE_FETCHINSTRUCTION;
            // TODO: process page fault
            CPUSTATE_PAGEFAULT: nextState = CPUSTATE_PAGEFAULT;
        endcase
    end
    
    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= CPUSTATE_INITIAL;
            pc <= 0;
            for(i = 0; i < 32; i++)
                cpuRegs[i] <= 32'd0;
            for(i = 0; i < 39; i++)
                cp0Regs[i] <= 32'd0;
        end else begin
            if(state == CPUSTATE_FETCHINSTRUCTION && nextState == CPUSTATE_EXEC)
                ins <= dataIn;
            if(state != CPUSTATE_INITIAL && nextState == CPUSTATE_FETCHINSTRUCTION)
                pc <= nextpc;
            if(state == CPUSTATE_EXEC)
                $display("executing: %d", ins[31:26]);
            
            // register file
            if(writeReg && (nextState == CPUSTATE_WRITEBACK || nextState == CPUSTATE_EXEC && !writeMem && !readMem )) begin
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
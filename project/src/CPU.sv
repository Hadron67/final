import ALUOptr::ALUOptr_t;
import BranchCondKind::BranchCondKind_t;
import OpCode::OpCode_t;

module CPUCore(
    input wire clk,
    input wire res,
    input wire pageFaultIReq,
    DataBus.master db
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

    reg [31:0] ins;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm;
    
    wire [31:0] aluInA, aluInB, aluOut;
    wire [31:0] regOutA, regOutB;
    wire [31:0] dataIn;
    wire overflow, zero;

    wire aluSrcA;
    wire aluSrcB;
    CPUState state;
    ALUOptr_t aluOptr;
    wire aluOverflow;
    wire regDest;
    wire extOp;
    wire writeReg;
    wire writeRegSrc;
    wire writeMem, readMem;
    wire jmp;
    wire branch;
    BranchCondKind_t branchCond;
    OpCode_t op;
    
    logic [31:0] pc, nextpc;
    logic [63:0] acc;
    
    assign rs = ins[25:21];
    assign rt = ins[20:16];
    assign rd = ins[15:11];
    assign shamt = ins[10:6];
    assign imm = ins[15:0];
    
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
        .branchCond(branchCond)
    );
    RegFile U3 (
        .clk(~clk),
        .writeReg(writeReg && (state == CPUSTATE_WRITEBACK || state == CPUSTATE_EXEC && !writeMem && !readMem )),
        .addrA(rs),
        .addrB(rt),
        .addrWrite(regDest == 0 ? rd : rt),
        .writeData(writeRegSrc == 0 ? aluOut : dataIn),
        .outA(regOutA),
        .outB(regOutB)
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

    assign db.clk = ~clk;
    assign db.read = state == CPUSTATE_READMEM || state == CPUSTATE_FETCHINSTRUCTION;
    assign db.write = state == CPUSTATE_WRITEMEM;
    assign db.addr = 
        state == CPUSTATE_FETCHINSTRUCTION ? pc : aluOut;
    assign db.dataOut = regOutB;
    assign dataIn = db.dataIn;
    assign db.memType = 
        state == CPUSTATE_FETCHINSTRUCTION ? MemType::WORD : MemType::BYTE;
    
    always @(posedge clk or posedge res) begin 
        if(res) begin
            state <= CPUSTATE_INITIAL;
            pc <= 0;
        end else
            case (state)
                CPUSTATE_INITIAL: begin
                    state <= CPUSTATE_FETCHINSTRUCTION;
                end 
                CPUSTATE_FETCHINSTRUCTION: begin 
                    if(pageFaultIReq)
                        state <= CPUSTATE_PAGEFAULT;
                    else if(db.ready) begin
                        state <= CPUSTATE_EXEC;
                        ins <= dataIn;
                    end
                end
                CPUSTATE_EXEC: begin 
                    // $display("opcode %s", op.name());
                    $display("executing: %d", ins[31:26]);
                    if(readMem) 
                        state <= CPUSTATE_READMEM;
                    else if(writeMem)
                        state <= CPUSTATE_WRITEMEM;
                    else begin
                        state <= CPUSTATE_FETCHINSTRUCTION;
                        pc <= nextpc;
                    end
                end
                CPUSTATE_READMEM: begin
                    if(db.ready)
                        state <= CPUSTATE_WRITEBACK;
                end
                CPUSTATE_WRITEMEM: begin
                    if(db.ready) begin
                        state <= CPUSTATE_FETCHINSTRUCTION;
                        pc <= nextpc;
                    end
                end
                CPUSTATE_WRITEBACK: begin
                    state <= CPUSTATE_FETCHINSTRUCTION;
                    pc <= nextpc;
                end
                // TODO
                CPUSTATE_PAGEFAULT: begin
                    
                end
                default: ;
            endcase
    end

endmodule // CPU
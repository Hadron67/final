`include "DataBus.vh"
`include "mmu.vh"

module CPU_MMU(
    input wire clk, res,

    input wire [31:0] db_dataIn,
    output wire [31:0] db_dataOut, db_addr,
    output reg [31:0] vAddr,
    input wire db_ready, 
    output wire db_io,
    output wire `MEM_ACCESS db_accessType,
    output wire `MEM_LEN db_memLen
);
    localparam S_IDLE              = 4'd0;
    localparam S_SAVE_ADDR         = 4'd1;
    localparam S_ACCESS_MEM        = 4'd2;

    reg [3:0] state, nextState;
    wire `MMU_REG mmu_reg;
    wire [31:0] mmu_dataIn;
    wire [31:0] mmu_dataOut;
    wire `MMU_CMD mmu_cmd;
    wire `MMU_EXCEPTION mmu_exception;

    wire [31:0] db2_addr;
    wire db2_ready;
    wire `MEM_ACCESS db2_accessType;
    wire `MEM_ACCESS accessType;

    wire accessMem;

    assign accessMem =
        db2_accessType == `MEM_ACCESS_W ||
        db2_accessType == `MEM_ACCESS_R ||
        db2_accessType == `MEM_ACCESS_X;
    assign db_accessType = nextState == S_ACCESS_MEM ? db2_accessType : `MEM_ACCESS_NONE;
    assign db2_ready = state == S_ACCESS_MEM && db_ready;
    
    always @* begin: getNextState
        case(state)
            S_IDLE: begin
                if(accessMem)
                    nextState = S_SAVE_ADDR;
                else
                    nextState = S_IDLE;
            end
            S_SAVE_ADDR: nextState = S_ACCESS_MEM;
            S_ACCESS_MEM: 
                if(mmu_exception != `MMU_EXCEPTION_NONE || db_ready)
                    nextState = accessMem ? S_SAVE_ADDR : S_IDLE;
                else
                    nextState = S_ACCESS_MEM;
        endcase
    end

    CPUCore cpu (
        .clk(clk),
        .res(res),

        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_ready(db2_ready),
        .db_addr(db2_addr),
        .db_accessType(db2_accessType),
        .db_memLen(db_memLen),

        .mmu_reg(mmu_reg),
        .mmu_dataIn(mmu_dataIn),
        .mmu_dataOut(mmu_dataOut),
        .mmu_cmd(mmu_cmd),
        .mmu_exception(mmu_exception)
    );

    MMU mmu (
        .clk(clk),
        .res(res),
        .addrValid(nextState == S_SAVE_ADDR),
        .vAddr(db2_addr),
        .pAddr(db_addr),
        .db_io(db_io),

        .mmu_reg(mmu_reg),
        .mmu_dataIn(mmu_dataIn),
        .mmu_dataOut(mmu_dataOut),
        .mmu_cmd(mmu_cmd),
        .mmu_exception(mmu_exception)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_IDLE;
        end
        else begin
            if(nextState == S_SAVE_ADDR)
                vAddr <= db2_addr;
            state <= nextState;
        end
    end
endmodule // MipsCPU
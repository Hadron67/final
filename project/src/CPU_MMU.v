`include "DataBus.vh"
`include "mmu.vh"
`include "font.vh"

module CPU_MMU(
    input wire clk, res,

    input wire [31:0] db_dataIn,
    output wire [31:0] db_addr,
    output reg [31:0] db_dataOut,
    output reg [31:0] vAddr,
    input wire db_ready, 
    output wire db_io, cachable,
    output reg `MEM_ACCESS db_accessType
);
    localparam S_IDLE       = 4'd0;
    localparam S_SAVE_ADDR  = 4'd1;
    localparam S_ACCESS_MEM = 4'd2;
    localparam S_WRITE_BACK = 4'd3;

    reg [3:0] state, nextState;

    wire `MMU_REG mmu_reg;
    wire [31:0] mmu_dataIn;
    wire [31:0] mmu_dataOut;
    wire `MMU_CMD mmu_cmd;
    wire `MMU_EXCEPTION mmu_exception;

    wire `MEM_LEN db_memLen;   
    reg `MEM_LEN memLenLatch;
    wire [31:0] db2_addr, db2_dataOut;
    reg [31:0] db2_dataIn, writeDataLatch;
    wire db2_ready, needWriteback;
    wire `MEM_ACCESS db2_accessType;
    reg `MEM_ACCESS accessTypeLatch;
    wire accessMem;

    assign accessMem =
        db2_accessType == `MEM_ACCESS_W ||
        db2_accessType == `MEM_ACCESS_R ||
        db2_accessType == `MEM_ACCESS_X;
    // assign db_accessType = nextState == S_ACCESS_MEM ? db2_accessType : `MEM_ACCESS_NONE;
    assign db2_ready = (state == S_ACCESS_MEM && db_ready && !needWriteback) || (state == S_WRITE_BACK && db_ready);
    assign needWriteback = accessTypeLatch == `MEM_ACCESS_W && (memLenLatch == `MEM_LEN_B || memLenLatch == `MEM_LEN_H);
    
    always @* begin
        case(nextState)
            S_ACCESS_MEM: db_accessType = needWriteback ? `MEM_ACCESS_R : db2_accessType;
            S_WRITE_BACK: db_accessType = `MEM_ACCESS_W;
            default: db_accessType = `MEM_ACCESS_NONE;
        endcase
    end
    always @* begin
        case(memLenLatch)
            `MEM_LEN_B:
                case(vAddr[1:0])
                    2'd0: db2_dataIn = {24'd0, db_dataIn[31:24]};
                    2'd1: db2_dataIn = {24'd0, db_dataIn[23:16]};
                    2'd2: db2_dataIn = {24'd0, db_dataIn[15:8]};
                    2'd3: db2_dataIn = {24'd0, db_dataIn[7:0]};
                endcase
            `MEM_LEN_H: 
                case(vAddr[1])
                    1'd0: db2_dataIn = {16'd0, db_dataIn[31:16]};
                    1'd1: db2_dataIn = {16'd0, db_dataIn[15:0]};
                endcase
            `MEM_LEN_W: db2_dataIn = db_dataIn;
            default: db2_dataIn = 32'dx;
        endcase
    end
    always @* begin
        case(nextState)
            S_ACCESS_MEM: db_dataOut = db2_dataOut;
            S_WRITE_BACK: 
                case(memLenLatch)
                    `MEM_LEN_B:
                        case(vAddr[1:0])
                            2'd0: db_dataOut = {db2_dataOut[7:0], db_dataIn[23:0]};
                            2'd1: db_dataOut = {db_dataIn[31:24], db2_dataOut[7:0], db_dataIn[15:0]};
                            2'd2: db_dataOut = {db_dataIn[31:16], db2_dataOut[7:0], db_dataIn[7:0]};
                            2'd3: db_dataOut = {db_dataIn[31:8], db2_dataOut[7:0]};
                        endcase
                    `MEM_LEN_H:
                        case(vAddr[1])
                            1'd0: db_dataOut = {db2_dataOut[15:0], db_dataIn[15:0]};
                            1'd1: db_dataOut = {db_dataIn[31:16], db2_dataOut[15:0]};
                        endcase
                    default: db_dataOut = 32'dx;
                endcase
            default: db_dataOut = 32'dx;
        endcase
    end
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
                if(mmu_exception != `MMU_EXCEPTION_NONE || db_ready) begin
                    if(needWriteback && mmu_exception == `MMU_EXCEPTION_NONE)
                        nextState = S_WRITE_BACK;
                    else
                        nextState = accessMem ? S_SAVE_ADDR : S_IDLE;
                end
                else
                    nextState = S_ACCESS_MEM;
            S_WRITE_BACK:
                if(db_ready)
                    nextState = accessMem ? S_SAVE_ADDR : S_IDLE;
                else
                    nextState = S_ACCESS_MEM;
        endcase
    end

    CPUCore cpu (
        .clk(clk),
        .res(res),

        .db_dataIn(db2_dataIn),
        .db_dataOut(db2_dataOut),
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
        .mmu_exception(mmu_exception),
        .mmu_accessType(db2_accessType)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_IDLE;
        end
        else begin
            if(nextState == S_SAVE_ADDR) begin
                vAddr <= db2_addr;
                memLenLatch <= db_memLen;
                accessTypeLatch <= db2_accessType;
            end
            if(db_accessType == `MEM_ACCESS_W) begin
                writeDataLatch <= db_dataOut;
            end
            state <= nextState;
        end
    end

    `ifdef DEBUG_DISPLAY
    
    always @(posedge clk) begin
        case(state)
            S_ACCESS_MEM:
                if(mmu_exception != `MMU_EXCEPTION_NONE) begin
                    $display(`FONT_RED("mmu exception %d occurs for address 0x%x (0x%x)"), mmu_exception, db_addr, vAddr);
                end
                else if(db_ready) begin
                    if(needWriteback) begin
                        $display("read memory at address 0x%x (0x%x) for writting back, data 0x%x", db_addr, vAddr, db_dataIn);
                    end
                    else
                        case(accessTypeLatch)
                            `MEM_ACCESS_R: $display("read memory at address 0x%x (0x%x), data 0x%x", db_addr, vAddr, db_dataIn);
                            `MEM_ACCESS_W: $display("write memory at address 0x%x (0x%x), data 0x%x", db_addr, vAddr, writeDataLatch);
                            `MEM_ACCESS_X: $display(`FONT_YELLOW("execute memory at address 0x%x (0x%x), data 0x%x"), db_addr, vAddr, db_dataIn);
                        endcase
                end
            S_WRITE_BACK:
                if(db_ready)
                    $display("writting back memory at address 0x%x (0x%x), data 0x%x", db_addr, vAddr, writeDataLatch);
        endcase
    end

    `endif
endmodule // MipsCPU
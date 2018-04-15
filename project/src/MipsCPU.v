`include "DataBus.vh"
`include "mmu.vh"

module MipsCPU(
    input wire clk, res,
    output wire hlt,

    input wire [31:0] db_dataIn,
    output wire [31:0] db_dataOut, db_addr,
    input wire db_ready,
    output wire `MEM_ACCESS_T db_accessType
);
    localparam S_IDLE         = 4'd0;
    localparam S_CONVERT_ADDR = 4'd1;

    reg [3:0] state, nextState;
    wire `MMU_REG_T mmu_reg;
    wire [31:0] mmu_dataIn;
    wire [31:0] mmu_dataOut;
    wire `MMU_CMD_T mmu_cmd;
    wire mmu_tlbMiss, mmu_tlbModified, mmu_tlbInvalid;

    wire [31:0] db2_dataIn, db2_dataOut, db2_addr;
    wire db2_ready;
    wire `MEM_ACCESS_T db2_accessType;

    wire mmuReady;
    wire [31:0] pAddr;
    reg addrValid;

    CPUCore cpu (
        .clk(clk),
        .res(res),
        .hlt(hlt),

        .db_dataIn(db2_dataIn),
        .db_dataOut(db2_dataOut),
        .db_ready(db2_ready),
        .db_addr(db2_addr),
        .db_accessType(db2_accessType),

        .mmu_reg(mmu_reg),
        .mmu_dataIn(mmu_dataIn),
        .mmu_dataOut(mmu_dataOut),
        .mmu_cmd(mmu_cmd),
        .mmu_tlbMiss(mmu_tlbMiss),
        .mmu_tlbModified(mmu_tlbModified),
        .mmu_tlbInvalid(mmu_tlbInvalid)
    );

    MMU mmu (
        .clk(clk),
        .res(res),
        .addrValid(addrValid),
        .vAddrIn(db2_addr),
        .pAddrOut(pAddr),
        .ready(mmuReady),

        .mmu_reg(mmu_reg),
        .mmu_dataIn(mmu_dataIn),
        .mmu_dataOut(mmu_dataOut),
        .mmu_cmd(mmu_cmd),
        .mmu_tlbMiss(mmu_tlbMiss),
        .mmu_tlbModified(mmu_tlbModified),
        .mmu_tlbInvalid(mmu_tlbInvalid)
    );
endmodule // MipsCPU
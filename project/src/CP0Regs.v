`include "mmu.vh"

module CP0Regs(
    input wire clk,
    input wire we, re,
    input wire [4:0] rd,
    input wire [2:0] sel,
    input wire [31:0] dataIn,
    output wire [31:0] dataOut,

    input wire [31:0] mmu_dataOut,
    output wire [31:0] mmu_dataIn,
    output reg `MMU_REG_T mmu_reg,
    output wire readMMUReg, writeMMUReg
);
    reg [31:0] regs[30:0];
    wire [5:0] regNum;
    reg [5:0] A;
    wire isMMU;

    assign dataOut = isMMU ? mmu_dataOut : regs[A];
    assign mmu_dataIn = dataIn;
    assign isMMU = 
        rd == 5'd0 ||
        rd == 5'd1 ||
        rd == 5'd2 ||
        rd == 5'd3 ||
        rd == 5'd4 ||
        rd == 5'd5 ||
        rd == 5'd6 ||
        rd == 5'd10;
    assign readMMUReg = re && isMMU;
    assign writeMMUReg = we && isMMU;

    always @* begin
        case(rd)
            5'd0: mmu_reg = `MMU_REG_INDEX;
            5'd1: mmu_reg = `MMU_REG_RANDOM;
            5'd2: mmu_reg = `MMU_REG_ENTRYLO0;
            5'd3: mmu_reg = `MMU_REG_ENTRYLO1;
            5'd4: mmu_reg = `MMU_REG_CTX;
            5'd5: mmu_reg = `MMU_REG_PAGEMASK;
            5'd6: mmu_reg = `MMU_REG_WIRED;
            5'd10: mmu_reg = `MMU_REG_ENTRYHI;
            default: mmu_reg = `MMU_REG_NONE;
        endcase
    end

    CP0RegNum cp0RegNum (
        .rd(rd),
        .sel(sel),
        .regNum(regNum)
    );

    always @(posedge clk) begin
        if(!isMMU) begin
            if(we) begin
                regs[regNum] <= dataIn;
                $display("written cp0 register $%d, data %x", regNum, dataIn);
            end
            else if(re) begin
                A <= regNum;
                $display("read cp0 register $%d, data %x", regNum, dataOut);
            end
        end
    end
endmodule
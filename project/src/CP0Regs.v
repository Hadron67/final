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
    output wire readMMUReg, writeMMUReg,

    input wire [31:0] in_epc, in_status, in_cause, in_badVAddr,
    input wire we_epc, we_status, we_cause, we_badVAddr,
    output reg [31:0] cp0_epc, cp0_status, cp0_cause, cp0_badVAddr
);
    reg [31:0] regOut;
    wire isMMU;

    assign dataOut = isMMU ? mmu_dataOut : regOut;
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

    always @(posedge clk) begin
        if(!isMMU) begin
            if(we && rd == 5'd8 || we_badVAddr) begin
                cp0_badVAddr <= dataIn;
                $display("written cp0 register 'BadVAddr', data %x", dataIn);
            end
            if(we && rd == 5'd12 || we_status) begin
                cp0_status <= dataIn;
                $display("written cp0 register 'Status', data %x", dataIn);
            end
            if(we && rd == 5'd13 || we_cause) begin
                cp0_cause <= dataIn;
                $display("written cp0 register 'Cause', data %x", dataIn);
            end
            if(we && rd == 5'd14 || we_epc) begin
                cp0_epc <= dataIn;
                $display("written cp0 register 'EPC', data %x", dataIn);
            end
            if(re) begin
                case(rd)
                    5'd8 : begin
                        regOut <= cp0_badVAddr;
                        $display("read cp0 register 'BadVAddr', data %x", cp0_badVAddr);
                    end 
                    5'd12: begin
                        regOut <= cp0_status;
                        $display("read cp0 register 'BadVAddr', data %x", cp0_status);
                    end 
                    5'd13: begin
                        regOut <= cp0_cause;
                        $display("read cp0 register 'BadVAddr', data %x", cp0_cause);
                    end 
                    5'd14: begin
                        regOut <= cp0_epc;
                        $display("read cp0 register 'BadVAddr', data %x", cp0_epc);
                    end 
                endcase
            end
        end
    end
endmodule
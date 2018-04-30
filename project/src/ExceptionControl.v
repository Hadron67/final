`include "mmu.vh"
`include "CPU.vh"

module ExceptionControl(
    input wire `MMU_EXCEPTION mmu_exception,
    input wire res, syscall, extInt,
    input wire [7:0] irq,
    input wire [31:0] cp0_status, cp0_cause,
    output reg exception, incEpc,
    output wire we_status, we_cause, we_epc, we_badVAddr,
    output wire [31:0] out_status, out_cause, etarget
);
    // interrupt, tlb exception, segv, syscall
    reg [4:0] excCode;
    wire exl, erl, ie;
    wire [7:0] maksedIrq;

    assign ie = cp0_status[0];
    assign exl = cp0_status[1];
    assign erl = cp0_status[2];
    assign maksedIrq = cp0_status[15:8] & irq;
    assign etarget = 32'h80000080;

    assign we_status = exception;
    assign we_cause = exception;
    assign we_epc = !exl && exception;
    assign we_badVAddr = exception && mmu_exception != `MMU_EXCEPTION_NONE;

    assign out_status = {cp0_status[31:2], exception, cp0_status[0]};
    assign out_cause = {cp0_cause[31:16], maksedIrq, 1'b0, excCode, 2'b00};

    // Exception priority encoder
    always @* begin
        if(extInt && ie && |maksedIrq) begin
            excCode = `CPU_EXCEPTION_INT;
            exception = 1'b1;
            incEpc = 1'b0;
        end
        else if(mmu_exception != `MMU_EXCEPTION_NONE) begin
            excCode = mmu_exception;
            exception = 1'b1;
            incEpc = 1'b0;
        end
        else if(syscall) begin
            excCode = `CPU_EXCEPTION_SYS;
            exception = 1'b1;
            incEpc = 1'b1;
        end
        else begin
            excCode = 5'dx;
            exception = 1'b0;
            incEpc = 1'b0;
        end
    end
endmodule // ExceptionControl
`include "mmu.vh"
`include "CPU.vh"

module ExceptionControl(
    input wire `MMU_EXCEPTION_T mmu_exception,
    input wire syscall, extInt,
    input wire [7:0] irq,
    input wire [31:0] cp0_status, cp0_cause,
    output wire exception, we_cause, we_epc, inc_epc,
    output wire [31:0] out_status, out_cause
);
    // interrupt, tlb exception, segv, syscall
    reg [4:0] excCode;
    
endmodule // ExceptionControl
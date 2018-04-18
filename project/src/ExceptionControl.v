`include "mmu.vh"
`include "CPU.vh"

module ExceptionControl(
    input wire `MMU_EXCEPTION_T mmu_exception,
    input wire syscall,
    input wire [31:0] cp0_status, cp0_cause,
    output wire exception, we_cause, we_epc,
    output wire [31:0] out_status, out_cause
);
    
endmodule // ExceptionControl
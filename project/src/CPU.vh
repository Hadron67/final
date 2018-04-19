`ifndef __CPU_H__
`define __CPU_H__

`define CPU_WRITE_REG_SRC_ALU    3'd0
`define CPU_WRITE_REG_SRC_MEM    3'd1
`define CPU_WRITE_REG_SRC_CP0REG 3'd2
`define CPU_WRITE_REG_SRC_IMM    3'd3
`define CPU_WRITE_REG_SRC_PC     3'd4
`define CPU_WRITE_REG_SRC [2:0]

`define CPU_WRITE_REG_DEST_SRC_RT  2'd0
`define CPU_WRITE_REG_DEST_SRC_RD  2'd1
`define CPU_WRITE_REG_DEST_SRC_RA  2'd2
`define CPU_WRITE_REG_DEST_SRC [1:0]

`define CPU_ALU_SRC_A_REGA  1'd0
`define CPU_ALU_SRC_A_SHAMT 1'd1
`define CPU_ALU_SRC_A [0:0]

`define CPU_ALU_SRC_B_REGB  1'd0
`define CPU_ALU_SRC_B_IMM   1'd1
`define CPU_ALU_SRC_B [0:0]

`define CPU_MODE_KERNEL     2'd0
`define CPU_MODE_SUPERVISOR 2'd1
`define CPU_MODE_USER       2'd2
`define CPU_MODE_T [1:0]

`define CPU_EXCEPTION_INT   5'd0
`define CPU_EXCEPTION_MOD   5'd1
`define CPU_EXCEPTION_TLBS  5'd3
`define CPU_EXCEPTION_TLBL  5'd2
`define CPU_EXCEPTION_SYS   5'd8
`define CPU_EXCEPTION_OV    5'd12
`define CPU_EXCEPTION [4:0]

`endif
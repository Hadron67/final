`ifndef __MMU_VH__
`define __MMU_VH__

`define MMU_REG_NONE     4'd0
`define MMU_REG_INDEX    4'd1
`define MMU_REG_RANDOM   4'd2
`define MMU_REG_ENTRYLO0 4'd3
`define MMU_REG_ENTRYLO1 4'd4
`define MMU_REG_CTX      4'd5
`define MMU_REG_PAGEMASK 4'd6
`define MMU_REG_WIRED    4'd7
`define MMU_REG_ENTRYHI  4'd8
`define MMU_REG [3:0]

`define MMU_CMD_NONE              4'd0
`define MMU_CMD_READ_REG          4'd1
`define MMU_CMD_WRITE_REG         4'd2
`define MMU_CMD_WRITE_TLB         4'd3
`define MMU_CMD_WRITE_TLB_RANDOM  4'd4
`define MMU_CMD_PROB_TLB          4'd5
// `define MMU_CMD_CONVERT_ADDR      4'd6
`define MMU_CMD_READ_TLB          4'd7
`define MMU_CMD [3:0]

`define MMU_EXCEPTION_NONE        5'd0
`define MMU_EXCEPTION_TLBL        5'd2
`define MMU_EXCEPTION_TLBS        5'd3
`define MMU_EXCEPTION_TLBMODIFIED 5'd1
`define MMU_EXCEPTION [4:0]

`endif
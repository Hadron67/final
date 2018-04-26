`ifndef __DATABUS_VH__
`define __DATABUS_VH__

`define MEM_ACCESS_NONE 2'd0
`define MEM_ACCESS_W    2'd1
`define MEM_ACCESS_R    2'd2
`define MEM_ACCESS_X    2'd3
`define MEM_ACCESS [1:0]

`define MEM_LEN_B  2'd0 // 8 bit
`define MEM_LEN_H  2'd1 // 16 bit
`define MEM_LEN_W  2'd2 // 32 bit
`define MEM_LEN [1:0]

`endif
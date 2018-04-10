`ifndef __MMU_VH__
`define __MMU_VH__

`define TLBOP_TLBINV   6'd3
`define TLBOP_TLBINVF  6'd4
`define TLBOP_TLBP     6'd8
`define TLBOP_TLBR     6'd1
`define TLBOP_TLBWR    6'd6
`define TLBOP_TLBWI    6'd2

`define TLBOP_T [5:0]

`endif
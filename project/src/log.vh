`ifndef __LOG_VH__
`define __LOG_VH__

`ifdef __DEBUG
`define DISPLAY(a) $display("%s", $sformatf a)
`else
`define DISPLAY(a)
`endif

`endif
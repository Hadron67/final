// For printing colored text in simulation (need POSIX terminals)

`ifndef __FONT_VH__
`define __FONT_VH__

`ifdef __IV
`define FONT_YELLOW(a) {"\033[1;33m", a, "\033[0m"}
`define FONT_GREEN(a) {"\033[1;32m", a, "\033[0m"}
`else
`define FONT_YELLOW(a) a
`define FONT_GREEN(a) a
`endif

`endif
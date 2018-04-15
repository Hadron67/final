// For printing colored text in simulation (need POSIX terminals)

`ifndef __FONT_VH__
`define __FONT_VH__

`define FONT_YELLOW(a) {"\033[1;33m", a, "\033[0m"}
`define FONT_GREEN(a) {"\033[1;32m", a, "\033[0m"}

`endif
// For printing colored text in simulation (need POSIX terminals)

`ifndef __FONT_VH__
`define __FONT_VH__

`ifdef __IV
    `define FONT_END "\033[0m"

    `define FONT_YELLOW "\033[1;33m"
    `define FONT_GREEN  "\033[1;32m"
    `define FONT_RED    "\033[1;31m"

    // `define FONT_YELLOW(a) {"\033[1;33m", a, "\033[0m"}
    // `define FONT_GREEN(a) {"\033[1;32m", a, "\033[0m"}
    // `define FONT_RED(a) {"\033[1;31m", a, "\033[0m"}
`else
    `define FONT_END ""

    `define FONT_YELLOW ""
    `define FONT_GREEN  ""
    `define FONT_RED    ""

    // `define FONT_YELLOW(a) a
    // `define FONT_GREEN(a) a
    // `define FONT_RED(a) a
`endif

`endif
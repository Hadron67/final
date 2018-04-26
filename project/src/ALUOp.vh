`ifndef __ALUOP_VH__
`define __ALUOP_VH__

`define ALUOP [4:0]

`define ALUOP_NONE      5'd0
`define ALUOP_PLUS      5'd1
`define ALUOP_MINUS     5'd3
`define ALUOP_MINUSU    5'd4
`define ALUOP_TIMES     5'd5
`define ALUOP_TIMESU    5'd6
`define ALUOP_DIV       5'd7
`define ALUOP_DIVU      5'd8
`define ALUOP_AND       5'd9
`define ALUOP_OR        5'd10
`define ALUOP_XOR       5'd11
`define ALUOP_NOR       5'd12
`define ALUOP_EQ        5'd13
`define ALUOP_NE        5'd14
`define ALUOP_LT        5'd15
`define ALUOP_LTU       5'd16
`define ALUOP_LS        5'd18
`define ALUOP_RS        5'd19
`define ALUOP_RSA       5'd20
`define ALUOP_GEZ       5'd21

`endif
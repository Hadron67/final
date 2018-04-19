    .section .text.start
_start:
    li $sp, 4095
    eret
    .global _start
    .type _start, @function
    
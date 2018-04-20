.section .text.start
_start:
    # initialize stack
    li $sp, 4095
    move $fp, $sp
    # jal main
    nop
    lui $t1, 0xa000
    sw $zero, 0($t1)
    .global _start
    .global main
    .type _start, @function

.data
v1: .word 4
v2: .word 5
v3: .word 9
v4: .word 0
term: .word 0xa0000000
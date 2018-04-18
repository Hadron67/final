.text
main:
    la $t1, v1
    la $t2, v2
    la $t3, v3
    lw $t1, 0($t1)
    lw $t2, 0($t2)
    lw $t3, 0($t3)
    add $t2, $t2, $t3
    la $t1, v4
    beq $t2, $t3, target
    sw $t3, 0($t1)
    li $t1, 100
target:
    addi $t1, $t1, -1
    addi $t2, $t2, -1
    bnez $t1, target
    nop
    j exit
    .global main
    .global exit
    .type main, @function

.data
v1: .word 4
v2: .word 5
v3: .word 9
v4: .word 0
term: .word 0xbfffffff
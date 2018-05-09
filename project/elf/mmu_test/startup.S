    .equ c0_index, $0
    .equ c0_random, $1
    .equ c0_entrylo0, $2
    .equ c0_entrylo1, $3
    .equ c0_context, $4
    .equ c0_pagemask, $5
    .equ c0_wired, $6
    .equ c0_entryhi, $10
    .equ cp0_status, $12
    .equ cp0_cause, $13

    .section .text.start
    .align 4
_start:
    la $gp, globalTable
    # $gp should be read-only from now on
    la $sp, kernelStack
    move $fp, $sp
    jal initKernel
    lui $t1, 0xa000
    sw $zero, 0($t1)

    .section .text.ihandler
    .align 4
    .set noat
handleException:
    sw $1, 4($gp)
    sw $2, 8($gp)
    sw $3, 12($gp)
    sw $4, 16($gp)
    sw $5, 20($gp)
    sw $6, 24($gp)
    sw $7, 28($gp)
    sw $8, 32($gp)
    sw $9, 36($gp)
    sw $10, 40($gp)
    sw $11, 44($gp)
    sw $12, 48($gp)
    sw $13, 52($gp)
    sw $14, 56($gp)
    sw $15, 60($gp)
    sw $16, 64($gp)
    sw $17, 68($gp)
    sw $18, 72($gp)
    sw $19, 76($gp)
    sw $20, 80($gp)
    sw $21, 84($gp)
    sw $22, 88($gp)
    sw $23, 92($gp)
    sw $24, 96($gp)
    sw $25, 100($gp)
    sw $26, 104($gp)
    sw $27, 108($gp)
    # needn't backup $gp    
    sw $29, 116($gp)
    sw $30, 120($gp)
    sw $31, 124($gp)
    la $sp, exceptionStack
    move $fp, $sp
    mfc0 $t1, cp0_cause
    andi $t1, $t1, 0b1111100
    la $t2, exceptionTable
    addu $t1, $t1, $t2
    lw $t1, 0($t1)
    jalr $t1
handler_int:
handler_tlbMod:
handler_tlbLoad:
handler_tlbStore:
handler_none:
handler_sys:
    lw $1, 4($gp)
    lw $2, 8($gp)
    lw $3, 12($gp)
    lw $4, 16($gp)
    lw $5, 20($gp)
    lw $6, 24($gp)
    lw $7, 28($gp)
    lw $8, 32($gp)
    lw $9, 36($gp)
    lw $10, 40($gp)
    lw $11, 44($gp)
    lw $12, 48($gp)
    lw $13, 52($gp)
    lw $14, 56($gp)
    lw $15, 60($gp)
    lw $16, 64($gp)
    lw $17, 68($gp)
    lw $18, 72($gp)
    lw $19, 76($gp)
    lw $20, 80($gp)
    lw $21, 84($gp)
    lw $22, 88($gp)
    lw $23, 92($gp)
    lw $24, 96($gp)
    lw $25, 100($gp)
    lw $26, 104($gp)
    lw $27, 108($gp)
    lw $29, 116($gp)
    lw $30, 120($gp)
    lw $31, 124($gp)
    eret

    .data
    .align 4
exceptionTable:
    .word handler_int
    .word handler_tlbMod
    .word handler_tlbLoad
    .word handler_tlbStore
    .word handler_none
    .word handler_none
    .word handler_none
    .word handler_none
    .word handler_sys

    .section .bss
    .align 4
    .fill 256, 4, 0
kernelStack:
    .fill 256, 4, 0
exceptionStack:
    
    .global _start
    .type _start, @function

    .weak handler_int
    .weak handler_tlbMod
    .weak handler_tlbLoad
    .weak handler_tlbStore
    .weak handler_none
    .weak handler_sys

    .section .text.start
    .equ c0_index, $0
    .equ c0_random, $1
    .equ c0_entrylo0, $2
    .equ c0_entrylo1, $3
    .equ c0_context, $4
    .equ c0_pagemask, $5
    .equ c0_wired, $6
    .equ c0_entryhi, $10
_start:
    lui $sp, 0x8000 # kernel umapped
    ori $sp, $sp, 4095
    move $fp, $sp
initTlb:
    li $t1, 0
    mtc0 $t1, c0_entrylo0
    mtc0 $t1, c0_entrylo1
    mtc0 $t1, c0_entryhi
    mtc0 $t1, c0_pagemask
    li $t1, 16 # 16 entries
l0:
    beqz $t1, tlbInitdone
    nop
    addi $t1, $t1, -1
    mtc0 $t1, c0_index
    tlbwi
    b l0
    nop
tlbInitdone:
writeTlb:
    # TODO: write initial tlb entries

    jal main
    nop
quit:
    lui $t1, 0xa000
    sw $zero, 0($t1)

    .global _start
    .global main
    .type _start, @function
    
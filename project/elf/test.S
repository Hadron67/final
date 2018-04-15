.text
__runTest:
    # addi    $t0, $zero, 64
    la    $t0, v1  
    lw    $t1, 0($t0)
    la    $t0, v2
    lw    $t2, 0($t0)
    add   $t2, $t2, $t1
    la    $t0, v3
    lw    $t2, 8($t0)
    beq   $t1, $t2, target    # if $t1 == $t2 then target
    sw    $t0, 12($t0)        # 
target:
    sw    $t1, 12($t0)        # 
    mfc0  $t2, $9
    move  $t3, $t2
    .data
v1: 
    .word 4
v2: 
    .word 5
v3: 
    .word 9
hkm: 
    .word 23
soor: 
    .asciiz "统统锁尔"
    sw    $t1, 12($t0) 
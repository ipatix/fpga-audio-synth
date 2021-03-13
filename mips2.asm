.text
nop
nop
nop
nop
nop
nop
nop
xor $zero, $zero, $zero
xor $t0, $t0, $t0
xor $t1, $t1, $t1
xor $t2, $t2, $t2
xor $t3, $t3, $t3
xor $t4, $t4, $t4
xor $t5, $t5, $t5
xor $t6, $t6, $t6
xor $t7, $t7, $t7
nop
nop
nop
nop
addi $t1, $t0, 0
addi $t2, $t0, 0x2000

loop:

addi $t1, $t1, 4
addi $t1, $t1, -5
addi $t1, $t1, 2
nop
nop
sw $t1, ($t2)
sw $t1, ($t0)
lw $s0, ($t0)
nop
nop
nop
beq $zero, $zero, loop
addi $t3, $t3, 1
addi $t4, $t4, 1
addi $t5, $t5, 1
addi $t6, $t6, 1
addi $t7, $t7, 1
.text

xor $t0, $t0, $t0  # ZERO
xor $zero, $zero, $zero
addi $t1, $t0, 1   # t1 = 0
addi $t5, $t0, 20  # count = 20
addi $t7, $t0, 0x2000
addi $t3, $t0, 0xFF
nop
nop
nop
sw $t3, ($t7)

xor $t3, $t3, $t3  # ZERO
addi $t6, $t0, 1   # fac_c, fac_prod

sw $t6, 0x10($t0)  # fac_c
sw $t6, 0x14($t0)  # fac_prod

addi $t4, $t3, 4
sw $t1, ($t3)
sw $t1, ($t4)


loop:

# fibonacci and faculty

lw $t1, ($t3)       # n
lw $t2, 4($t3)      # n+1
nop
add $t1, $t1, $t2   # n+2
nop
nop
nop
sw $t2, -4($t4)     # store new n
sw $t1, ($t4)       # store new n+1

lw $t1, 0x10($t0)   # fac_c
lw $t2, 0x14($t0)   # fac_prod
addi $t1, $t1, 1    # fac_c += 1
mul $t2, $t2, $t1   # fac_prod *= fac_c
nop
nop
sw $t1, 0x10($t3)   # store
sw $t2, 0x14($t3)   # ...

addi $t5, $t5, -1
beq $t0, $t5, led_loop
nop
nop
nop
beq $zero, $zero, loop
nop
nop
nop

# blinking led on port

led_loop:
addi $t1, $t0, 1  # leftmost led state
addi $t6, $t0, 0x2000 # io register
addi $t7, $t0, 128 # rightmost led state
addi $t3, $t0, 1  # t3 = LED value
lui $t2, 0x40

left_loop:
addi $t2, $t2, -1
beq $t2, $t0, left_step
nop
nop
nop
beq  $zero, $zero, left_loop
nop
nop
nop

left_step:
sllv $t3, $t3, $t1
nop
nop
nop
sw $t3, ($t6)
lui $t2, 0x40
beq $t3, $t7, right_loop
nop
nop
nop
beq $zero, $zero, left_loop
nop
nop
nop

right_loop:
addi, $t2, $t2, -1
beq $t2, $t0, right_step
nop
nop
nop
beq $zero, $zero, right_loop
nop
nop
nop

right_step:
srlv $t3, $t3, $t1
nop
nop
nop
sw $t3, ($t6)
lui $t2, 0x40
beq $t3, $t1, left_loop
nop
nop
nop
beq $zero, $zero, right_loop
nop
nop
nop
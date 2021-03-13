# ERROR CODES

.eqv MIDI_DATA_WAIT 0x2
.eqv MIDI_DATA_NOTE_OFF 0x3
.eqv MIDI_DATA_NOTE_ON 0x4
.eqv MIDI_DATA_NAFTT 0x5
.eqv MIDI_DATA_CONTROLLER 0x6
.eqv MIDI_DATA_PROG 0x7
.eqv MIDI_DATA_CAFTT 0x8
.eqv MIDI_DATA_PB 0x9
.eqv MIDI_DATA_SYSEX 0xA
.eqv INVALID_MIDI_DATA 0xF1
.eqv INVALID_PATCH_DATA 0xF2

# INSTRUCTION MACROS

.macro i_lw(%value_reg, %offset_reg, %imm_offset)
lw %value_reg, %imm_offset(%offset_reg)
nop
nop
nop
.end_macro

.macro i_lb(%value_reg, %offset_reg, %imm_offset)
lb %value_reg, %imm_offset(%offset_reg)
nop
nop
nop
.end_macro

.macro i_sw(%value_reg, %offset_reg, %imm_offset)
nop
nop
nop
nop
sw %value_reg, %imm_offset(%offset_reg)
.end_macro

.macro i_sb(%value_reg, %offset_reg, %imm_offset)
nop
nop
nop
nop
sb %value_reg, %imm_offset(%offset_reg)
.end_macro

.macro i_b(%label)
beq $zero, $zero, %label
nop
nop
nop
.end_macro

.macro i_beq(%ra, %rb, %label)
beq %ra, %rb, %label
nop
nop
nop
.end_macro

.macro i_beqim(%ra, %imm, %label)
addi $at, $zero, %imm
beq %ra, $at, %label
nop
nop
nop
.end_macro

.macro i_bz(%ra, %label)
beq %ra, $zero, %label
nop
nop
nop
.end_macro

.macro i_blt(%ra, %rb, %label)
slt $at, %ra, %rb
addi $at, $at, -1
beq $at, $zero, %label
nop
nop
nop
.end_macro

.macro i_bge(%ra, %rb, %label)
slt $at, %ra, %rb
beq $at, $zero, %label
nop
nop
nop
.end_macro

.macro i_bgt(%ra, %rb, %label)
addi $at, %ra, -1
slt $at, $at, %rb
beq $at, $zero, %label
nop
nop
nop
.end_macro

.macro i_bne(%ra, %rb, %label)
slt $k0, %ra, %rb
slt $k1, %rb, %ra
nor $k0, $k0, $k1
andi $k0, $k0, 1
beq $k0, $zero, %label
nop
nop
nop
.end_macro

.macro i_bneim(%ra, %imm, %label)
addi $at, $zero, %imm
slt $k0, %ra, $at
slt $k1, $at, %ra
nor $k0, $k0, $k1
andi $k0, $k0, 1
beq $k0, $zero, %label
nop
nop
nop
.end_macro

.macro i_debug(%code)
addi $at, $zero, %code
nop
nop
nop
nop
sw $at, (R_GPIO)
.end_macro

.macro f_error(%code)
addi $a0, $zero, %code
beq $zero, $zero, fatal_error
nop
nop
nop
.end_macro

# FUNCTION MACROS
.macro f_calc_vol(%vel, %vol, %expr, %pan)
mul $at, %vel, %vol
mul $at, $at, %expr
addi $v0, $zero, 127
sub $v0, $v0, %pan      # left vol
add $v1, $zero, %pan    # right vol

mul $v0, $v0, $at
srl $v0, $v0, 20
add $k0, R_VOL_TBL, $v0
lb $v0, ($k0)
mul $v1, $v1, $at
srl $v1, $v1, 20
add $k1, R_VOL_TBL, $v1
lb $v1, ($k1)
nop
nop
nop
.end_macro

.macro f_calc_pitch(%key, %bend, %bend_range)
# first convert to key + 0..255 range
mul $at, %bend, %bend_range
sra $at, $at, 5
andi $k0, $at, 0xFF # $k0 = 0..255 bend range
sra $at, $at, 8
add $k1, %key, $at  # $k1 = key
add $v0, $k1, R_KEY_TBL # lookup table consists of 128 2x4 bit nibbles: octave & key
lb $v1, 1($v0)      # $v1
lb $v0, ($v0)       # $v0
nop
andi $a0, $v0, 0xF  # $a0 = key in octave   LOW
sll $a0, $a0, 2     # $a0 = key * 4         LOW 
srl $v0, $v0, 4     # $v0 = octave          LOW

andi $a1, $v1, 0xF  # $a1 = key in octave   HIGH
sll $a1, $a1, 2     # $a1 = key * 4         HIGH
srl $v1, $v1, 4     # $v1 = octave          HIGH
add $at, R_PITCH_TBL, $a0                 # LOW
lw $a0, ($at)       # $a0 = pitch value     LOW
add $at, R_PITCH_TBL, $a1                 # HIGH
lw $a1, ($at)       # $a1 = pitch value     HIGH
nop
nop

srlv $a0, $a0, $v0  # $a0 = final pitch value LOW
srlv $a1, $a1, $v1  # $a1 = final pitch value HIGH

sub $v0, $a1, $a0   # $at = pitch diff
srl $v0, $v0, 3
mul $v0, $v0, $k0
srl $v0, $v0, 5
add $v0, $v0, $a0
# $v0 = pitch value
.end_macro

# MAIN CODE

# flush pipeline
nop
nop
nop
nop
nop
nop

# zero registers
xor $0, $0, $0
xor $1, $0, $0
xor $2, $0, $0
xor $3, $0, $0
xor $4, $0, $0
xor $5, $0, $0
xor $6, $0, $0
xor $7, $0, $0
xor $8, $0, $0
xor $9, $0, $0
xor $10, $0, $0
xor $11, $0, $0
xor $12, $0, $0
xor $13, $0, $0
xor $14, $0, $0
xor $15, $0, $0
xor $16, $0, $0
xor $17, $0, $0
xor $18, $0, $0
xor $19, $0, $0
xor $20, $0, $0
xor $21, $0, $0
xor $22, $0, $0
xor $23, $0, $0
xor $24, $0, $0
xor $25, $0, $0
xor $26, $0, $0
xor $27, $0, $0
xor $28, $0, $0
xor $29, $0, $0
xor $30, $0, $0
xor $31, $0, $0

.eqv SOUND_REG_COUNT 64

# write only bits
.eqv CHN_STATUS_INIT 0x20
.eqv CHN_STATUS_FORCERELEASE 0x10
.eqv CHN_STATUS_FORCESTOP 0x8

# read only bits
.eqv CHN_STATUS_ATTACK 0x4
.eqv CHN_STATUS_DECAY 0x3
.eqv CHN_STATUS_SUSTAIN 0x2
.eqv CHN_STATUS_RELEASE 0x1
.eqv CHN_STATUS_STOPPED 0x0

# permanent registers:
.eqv R_MIDI_STATE $s0
.eqv R_UART_INTERFACE $s1
.eqv R_SOUND_REGS $s2
.eqv R_GPIO $s3
.eqv R_PATCH_MEM $s4
.eqv R_VOL_TBL $s5
.eqv R_PITCH_TBL $s6
.eqv R_KEY_TBL $s7

.eqv MIDI_STATE_PROGRAM     0x0
#.eqv MIDI_STATE_MOD         0x1
.eqv MIDI_STATE_VOLUME      0x2
.eqv MIDI_STATE_PAN         0x3
.eqv MIDI_STATE_EXPRESSION  0x4
.eqv MIDI_STATE_RPN_LSB     0x5
.eqv MIDI_STATE_RPN_MSB     0x6
.eqv MIDI_STATE_BEND_RANGE  0x7
.eqv MIDI_STATE_BEND        0x8
.eqv MIDI_STATE_SIZE        0xC

.eqv UART_INTERFACE_DATA    0x0
.eqv UART_INTERFACE_DATA_READY 0x4

.eqv SOUND_REG_STATUS       0x0 # upper bits, write only, lower bits read only
.eqv SOUND_REG_KEY          0x1 # write/read
.eqv SOUND_REG_LEFT_VOL     0x2 # write/read
.eqv SOUND_REG_RIGHT_VOL    0x3
.eqv SOUND_REG_WAVE_TYPE    0x4
.eqv SOUND_REG_OWNER        0x5
.eqv SOUND_REG_VELOCITY     0x6
.eqv SOUND_REG_FREQ         0x8
.eqv SOUND_REG_ADSR         0xC
.eqv SOUND_REG_WAVEFORM     0x10
.eqv SOUND_REG_WAVEFORM_P_4 0x14
.eqv SOUND_REG_WAVEFORM_P_8 0x18
.eqv SOUND_REG_WAVEFORM_P_C 0x1C
.eqv SOUND_REG_SIZE         0x20

.eqv PATCH_TYPE             0x0
.eqv PATCH_KEY              0x1
.eqv PATCH_ADSR             0x4
.eqv PATCH_WAVE             0x8
.eqv PATCH_WAVE_P_4         0xC
.eqv PATCH_WAVE_P_8         0x10
.eqv PATCH_WAVE_P_C         0x14
.eqv PATCH_SIZE             0x18

.eqv PATCH_SIZE_M_256       0x1800
.eqv PATCH_SIZE_M_128       0xC00

addi R_VOL_TBL, $zero, 0x0
addi R_KEY_TBL, $zero, 0x100
addi R_PITCH_TBL, $zero, 0x180
addi R_MIDI_STATE, $zero, 0x800
addi R_PATCH_MEM, $zero, 0x1000
addi $sp, $zero, 0x4000
addi R_GPIO, $zero, 0x4000
addi R_UART_INTERFACE, $zero, 0x4010
addi R_SOUND_REGS, $zero, 0x5000


main:
    addi $t0, $zero, 0xFF
    i_sb($t0, R_SOUND_REGS, SOUND_REG_LEFT_VOL)
    addi $t0, $zero, 0xFF
    i_sb($t0, R_SOUND_REGS, SOUND_REG_RIGHT_VOL)


    li $t0, 0x00FF00FF
    i_sw($t0, R_SOUND_REGS, SOUND_REG_ADSR)
    li $t0, 0x67452301
    i_sw($t0, R_SOUND_REGS, SOUND_REG_WAVEFORM)
    li $t0, 0xEFCDAB89
    i_sw($t0, R_SOUND_REGS, SOUND_REG_WAVEFORM_P_4)
    li $t0, 0x98BADCFE
    i_sw($t0, R_SOUND_REGS, SOUND_REG_WAVEFORM_P_8)
    li $t0, 0x10325476
    i_sw($t0, R_SOUND_REGS, SOUND_REG_WAVEFORM_P_C)
    addi $t0, $zero, 0x3C
    addi $t1, $zero, -2000
    addi $t2, $zero, 12
    nop
    nop
    nop
    f_calc_pitch($t0, $t1, $t2)
    i_sw($v0, R_SOUND_REGS, SOUND_REG_FREQ)

loop:
    addi $t0, $zero, CHN_STATUS_FORCESTOP
    i_sb($t0, R_SOUND_REGS, SOUND_REG_STATUS)
    addi $t2, $zero, 0x7f
    addi $t3, $zero, 0x40
    nop
    nop
    nop
    f_calc_vol($t2, $t2, $t2, $t3)
    i_sb($v0, R_SOUND_REGS, SOUND_REG_LEFT_VOL)
    i_sb($v1, R_SOUND_REGS, SOUND_REG_RIGHT_VOL)
    addi $t0, $zero, CHN_STATUS_INIT
    i_sb($t0, R_SOUND_REGS, SOUND_REG_STATUS)
    i_debug(0xF0)
    li $t1, 0x80
loop_delay:
    addi $t1, $t1, -1
    i_bgt($t1, $zero, loop_delay)

    addi $t0, $zero, CHN_STATUS_FORCERELEASE
    i_sb($t0, R_SOUND_REGS, SOUND_REG_STATUS)
    i_debug(0x03)
    li $t1, 0x80
loop_delay_b:
    addi $t1, $t1, -1
    i_bgt($t1, $zero, loop_delay_b)
    i_b(loop)

# FATAL ERROR
fatal_error:
i_sw($a0, R_GPIO, 0)
fatal_error_loop:
i_b(fatal_error_loop)

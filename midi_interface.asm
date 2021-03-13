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
.eqv MIDI_DATA_RESET 0xB
.eqv CHANNEL_RESET 0xC
.eqv CHANNEL_OVERFLOW 0xAA
.eqv INVALID_MIDI_DATA 0xF1
.eqv INVALID_PATCH_DATA 0xF2

# misc

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
.eqv MIDI_STATE_MOD         0x1 # not used yet
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

.macro i_debugr(%reg)
nop
nop
nop
nop
sw %reg, (R_GPIO)
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

.macro f_uart_read_byte(%dest)
uart_read:
i_lw(%dest, R_UART_INTERFACE, UART_INTERFACE_DATA_READY)
i_bz(%dest, uart_read)
i_lw(%dest, R_UART_INTERFACE, UART_INTERFACE_DATA)
.end_macro

.macro f_reset_midi_chn(%chn_ptr)
addi $k0, $zero, 0x7F
addi $k1, $zero, 0x40
addi $at, $zero, 12
sb $zero, MIDI_STATE_PROGRAM(%chn_ptr)
sb $zero, MIDI_STATE_MOD(%chn_ptr)
sb $k0, MIDI_STATE_VOLUME(%chn_ptr)
sb $k1, MIDI_STATE_PAN(%chn_ptr)
sb $k0, MIDI_STATE_EXPRESSION(%chn_ptr)
sb $zero, MIDI_STATE_RPN_LSB(%chn_ptr)
sb $zero, MIDI_STATE_RPN_MSB(%chn_ptr)
sb $at, MIDI_STATE_BEND_RANGE(%chn_ptr)
sw $zero, MIDI_STATE_BEND(%chn_ptr)
.end_macro

.macro f_reset_snd_chn(%chn_ptr)
addi $at, $zero, -1
sw $zero, SOUND_REG_STATUS(%chn_ptr)
sw $zero, SOUND_REG_WAVE_TYPE(%chn_ptr)
sw $zero, SOUND_REG_FREQ(%chn_ptr)
sw $zero, SOUND_REG_ADSR(%chn_ptr)
sw $at, SOUND_REG_WAVEFORM(%chn_ptr)
sw $at, SOUND_REG_WAVEFORM_P_4(%chn_ptr)
sw $zero, SOUND_REG_WAVEFORM_P_8(%chn_ptr)
sw $zero, SOUND_REG_WAVEFORM_P_C(%chn_ptr)
.end_macro


#########################
# MAIN CODE STARTS HERE #
#########################

# flush pipeline
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


addi R_VOL_TBL, $zero, 0x0
addi R_KEY_TBL, $zero, 0x100
addi R_PITCH_TBL, $zero, 0x180
addi R_MIDI_STATE, $zero, 0x800
addi R_PATCH_MEM, $zero, 0x1000
addi $sp, $zero, 0x4000
addi R_GPIO, $zero, 0x4000
addi R_UART_INTERFACE, $zero, 0x4010
addi R_SOUND_REGS, $zero, 0x5000
nop
nop
nop
nop

# rough program layout:
# 
# - wait for midi data and select:
#   > reset channels
#       > pretty much reset everything
#   > note on
#       > allocate channel, load wave, calculate parameters
#   > note off
#       > deallocate channel, zero the status byte
#   > program change
#       > just set value
#   > controller/pitch change
#       > set value to table, recalculate pitch for pitch change, set volume for volume/expression/pan change
#   > load patch
#       > load byte data from input to patch register
midi_state_reset:
    # now reset all midi channel states
    i_debug(MIDI_DATA_RESET)
    addi $t0, $zero, 16
    addi $t1, R_MIDI_STATE, 0
_mc_sysex_reset_loop:
       f_reset_midi_chn($t1)
       addi $t1, $t1, MIDI_STATE_SIZE
       addi $t0, $t0, -1
       i_bgt($t0, $zero, _mc_sysex_reset_loop)
    # now force stop all channels
    i_debug(CHANNEL_RESET)
    addi $t0, $zero, SOUND_REG_COUNT
    addi $t1, R_SOUND_REGS, 0
_mc_sysex_reset_loop_2:
        f_reset_snd_chn($t1)
        addi $t1, $t1, SOUND_REG_SIZE
        addi $t0, $t0, -1
        i_bgt($t0, $zero, _mc_sysex_reset_loop_2)
    # okay, reset all sound channels

# wait for midi data
midi_data_wait:

i_debug(MIDI_DATA_WAIT)

f_uart_read_byte($t0)                           # $t0 = UART_DATA;
srl $t1, $t0, 4                                 # $t1 = UART_DATA >> 4; // MIDI EVENT TYPE
andi $t0, $t0, 0xF                              # $t0 = UART_DATA & 0xF; // MIDI CHANNEL
nop
nop
i_beqim($t1, 0x8, midi_command_note_off)        # if ($t1 == 8) goto midi_command_note_off;
i_beqim($t1, 0x9, midi_command_note_on)         # if ($t1 == 9) goto midi_command_note_on;
i_beqim($t1, 0xA, midi_command_note_aftertouch)
i_beqim($t1, 0xB, midi_command_controller)
i_beqim($t1, 0xC, midi_command_program_change)
i_beqim($t1, 0xD, midi_command_channel_aftertouch)
i_beqim($t1, 0xE, midi_command_pitch_bend)
i_beqim($t1, 0xF, midi_command_sysex)
f_error(INVALID_MIDI_DATA)

# MIDI COMMAND - NOTE OFF (0x8)
midi_command_note_off:
    i_debug(MIDI_DATA_NOTE_OFF)
    f_uart_read_byte($t2)               # $t2 = midi key
    f_uart_read_byte($at)               # void = velocity
_mc_noff_vel_zero:

    # find channel with key being played
    addi $t1, $zero, SOUND_REG_COUNT    # $t1 = 64 channels
    move $t3, R_SOUND_REGS              # $t3 = current channel address
    # now scan channel if it contains this note
_mc_noff_channel_loop:
        i_lb($t4, $t3, SOUND_REG_KEY)
        i_bne($t4, $t2, _mc_noff_channel_loop_next)
        i_lb($t4, $t3, SOUND_REG_OWNER)
        i_bne($t4, $t0, _mc_noff_channel_loop_next)

        # okay, this is a channel to be stopped
        addi $t4, $zero, CHN_STATUS_FORCERELEASE
        i_sb($t4, $t3, SOUND_REG_STATUS)

_mc_noff_channel_loop_next:
        addi $t3, $t3, SOUND_REG_SIZE
        addi $t1, $t1, -1
        i_bgt($t1, $zero, _mc_noff_channel_loop)
    i_b(midi_data_wait)




# MIDI COMMAND - NOTE ON (0x9)
midi_command_note_on:
    i_debug(MIDI_DATA_NOTE_ON)
    f_uart_read_byte($t2)               # $t2 = midi key
    f_uart_read_byte($t5)               # $t5 = velocity
    i_beq($t5, $zero, _mc_noff_vel_zero)

    # find channel which is currently stopped
    addi $t1, $zero, SOUND_REG_COUNT    # $t1 = 64 channels
    move $t3, R_SOUND_REGS              # $t3 = current channel address
    # now scan channels which are currently stopped
_mc_non_channel_fstop_loop:
        i_lb($t4, $t3, SOUND_REG_STATUS)
        i_beqim($t4, CHN_STATUS_STOPPED, _mc_non_load)
_mc_non_channel_fstop_loop_next:
        addi $t3, $t3, SOUND_REG_SIZE
        addi $t1, $t1, -1
        i_bgt($t1, $zero, _mc_non_channel_fstop_loop)
    # okay, didn't find a free channel up to this point
    addi $t1, $zero, SOUND_REG_COUNT    # $t1 = 64 channels
    move $t3, R_SOUND_REGS              # $t3 = current channel address
    # now scan for channels which are currently being released
_mc_non_channel_frelease_loop:
        i_lb($t4, $t3, SOUND_REG_STATUS)
        i_beqim($t4, CHN_STATUS_RELEASE, _mc_non_load)
_mc_non_channel_frelease_loop_next:
        addi $t3, $t3, SOUND_REG_SIZE
        addi $t1, $t1, -1
        i_bgt($t1, $zero, _mc_non_channel_frelease_loop)
    # okay, still didn't find a free channel
    move $t3, R_SOUND_REGS
    i_debug(CHANNEL_OVERFLOW)
    # just use the first channel
_mc_non_load:
    # before doing anything, stop channel
    addi $t4, $zero, CHN_STATUS_FORCESTOP
    i_sb($t4, $t3, SOUND_REG_STATUS)

    # $t0 = MIDI channel (owner)
    # $t2 = midi key
    # $t3 = channel offset
    # $t5 = note velocity
    addi $t4, $zero, MIDI_STATE_SIZE
    mul $t4, $t4, $t0
    add $t4, $t4, R_MIDI_STATE
    nop
    nop
    nop
    # $t4 = midi channel offset
    lb $t6, MIDI_STATE_VOLUME($t4)
    # $t6 = volume
    lb $t7, MIDI_STATE_EXPRESSION($t4)
    # $t7 = expression
    lb $t8, MIDI_STATE_PAN($t4)
    # $t8 = pan
    nop
    nop
    nop
    f_calc_vol($t5, $t6, $t7, $t8)

    # store first things
    sb $v0, SOUND_REG_LEFT_VOL($t3)
    sb $v1, SOUND_REG_RIGHT_VOL($t3)
    sb $t2, SOUND_REG_KEY($t3)
    sb $t0, SOUND_REG_OWNER($t3)
    sb $t5, SOUND_REG_VELOCITY($t3)

    # calculate patch offset
    i_lb($t6, $t4, MIDI_STATE_PROGRAM)
    addi $t5, $zero, PATCH_SIZE
    mul $t5, $t5, $t6
    add $t5, $t5, R_PATCH_MEM           # $t5 = Patch Location
    i_bneim($t0, 9, _mc_non_no_drum)
    i_beqim($t6, 127, _mc_non_no_drum)

    addi $t5, $zero, PATCH_SIZE
    mul $t5, $t5, $t2
    add $t5, $t5, R_PATCH_MEM
    addi $t5, $t5, PATCH_SIZE_M_128
    nop
    nop
    nop
    lb $t2, PATCH_KEY($t5)
_mc_non_no_drum:
    lw $t6, PATCH_WAVE($t5)
    lw $t7, PATCH_WAVE_P_4($t5)
    lw $t8, PATCH_WAVE_P_8($t5)
    lw $t9, PATCH_WAVE_P_C($t5)
    nop
    sw $t6, SOUND_REG_WAVEFORM($t3)
    sw $t7, SOUND_REG_WAVEFORM_P_4($t3)
    sw $t8, SOUND_REG_WAVEFORM_P_8($t3)
    sw $t9, SOUND_REG_WAVEFORM_P_C($t3)

    lw $t6, PATCH_ADSR($t5)
    lb $t7, PATCH_TYPE($t5)
    nop
    nop
    nop
    sw $t6, SOUND_REG_ADSR($t3)
    sb $t7, SOUND_REG_WAVE_TYPE($t3)
    nop
    nop
    nop

    # now only thing left is Pitch and loading the waveform
    lb $t5, MIDI_STATE_BEND_RANGE($t4)
    lw $t6, MIDI_STATE_BEND($t4)
    nop
    nop
    nop
    f_calc_pitch($t2, $t5, $t6)
    i_sw($v0, $t3, SOUND_REG_FREQ)

    # okay, setup everything, now enable sound channel
    addi $t0, $zero, CHN_STATUS_INIT
    i_sb($t0, $t3, SOUND_REG_STATUS)
    i_b(midi_data_wait)




# MIDI COMMAND - NOTE AFTERTOUCH (0xA)
midi_command_note_aftertouch:
    i_debug(MIDI_DATA_NAFTT)
    # read aftertouch key -> void
    f_uart_read_byte($t0)

    # read intensity -> void 
    f_uart_read_byte($t0)
    i_b(midi_data_wait)




# MIDI COMMAND - CONTROLLER (0xB)
midi_command_controller:
    i_debug(MIDI_DATA_CONTROLLER)

    f_uart_read_byte($t1)                             # $t1 = midi controller
    f_uart_read_byte($t2)                             # $t2 = controller value

    # load channel address
    addi $t3, $zero, MIDI_STATE_SIZE
    mul $t3, $t3, $t0
    add $t3, $t3, R_MIDI_STATE

    # check whether a 'used' controller has been set
    i_beqim($t1, 6, _mc_ctrl_set_data_entry)
    i_beqim($t1, 7, _mc_ctrl_set_vol)
    i_beqim($t1, 10, _mc_ctrl_set_pan)
    i_beqim($t1, 11, _mc_ctrl_set_expr)

    i_b(midi_data_wait)

_mc_ctrl_set_data_entry:
    i_lb($t4, $t3, MIDI_STATE_RPN_LSB)
    i_bne($t4, $zero, midi_data_wait)
    i_lb($t4, $t3, MIDI_STATE_RPN_MSB)
    i_bne($t4, $zero, midi_data_wait)
    i_sb($t2, $t3, MIDI_STATE_BEND_RANGE)
    i_b(midi_data_wait)

_mc_ctrl_set_vol:
    i_sb($t2, $t3, MIDI_STATE_VOLUME)
    i_b(_mc_ctrl_recalc_volume)

_mc_ctrl_set_pan:
    i_sb($t2, $t3, MIDI_STATE_PAN)
    i_b(_mc_ctrl_recalc_volume)

_mc_ctrl_set_expr:
    i_sb($t2, $t3, MIDI_STATE_EXPRESSION)
    i_b(_mc_ctrl_recalc_volume)

_mc_ctrl_recalc_volume:
    lb $t1, MIDI_STATE_VOLUME($t3)
    lb $t2, MIDI_STATE_PAN($t3)
    lb $t4, MIDI_STATE_EXPRESSION($t3)

    # now search for matching channels
    addi $t6, $zero, SOUND_REG_COUNT
    addi $t3, R_SOUND_REGS, 0
_mc_ctrl_recalc_vol_loop:
        i_lb($t5, $t3, SOUND_REG_OWNER)
        i_bne($t5, $t0, _mc_ctrl_recalc_vol_loop_next)
        i_lb($t5, $t3, SOUND_REG_STATUS)
        i_beqim($t5, CHN_STATUS_RELEASE, _mc_ctrl_recalc_vol_loop_next)

        i_lb($t5, $t3, SOUND_REG_VELOCITY)
        f_calc_vol($t5, $t1, $t4, $t2)
        nop
        sb $v0, SOUND_REG_LEFT_VOL($t3)
        sb $v1, SOUND_REG_RIGHT_VOL($t3)
_mc_ctrl_recalc_vol_loop_next:
        addi $t3, $t3, SOUND_REG_SIZE
        addi $t6, $t6, -1
        i_bgt($t6, $zero, _mc_ctrl_recalc_vol_loop)
    # okay, updated volume, now return
    i_b(midi_data_wait)




# MIDI COMMAND - PROGRAM CHANGE (0xC)
midi_command_program_change:
    i_debug(MIDI_DATA_PROG)
    # read program to change to
    f_uart_read_byte($t1)
    
    addi $t2, $zero, MIDI_STATE_SIZE
    mul $t2, $t2, $t0
    add $t2, $t2, R_MIDI_STATE
    i_sb($t1, $t2, MIDI_STATE_PROGRAM)
    i_b(midi_data_wait)




# MIDI COMMAND - CHANNEL AFTERTOUCH (0xD)
midi_command_channel_aftertouch:
    i_debug(MIDI_DATA_CAFTT)
    # read aftertouch intensity
    f_uart_read_byte($t0)
    i_b(midi_data_wait)




# MIDI COMMAND - PITCH BEND (0xE)
midi_command_pitch_bend:
    i_debug(MIDI_DATA_PB)
    # read bend value 1
    f_uart_read_byte($t1)
    f_uart_read_byte($t2)

    sll $t2, $t2, 7
    or $t1, $t1, $t2
    addi $t1, $t1, -0x2000

    addi $t3, $zero, MIDI_STATE_SIZE
    mul $t3, $t3, $t0
    add $t3, $t3, R_MIDI_STATE
    i_sw($t1, $t3, MIDI_STATE_BEND)

    # now update pitch on this channel
    lb $t6, MIDI_STATE_BEND_RANGE($t3)
    addi $t2, $zero, SOUND_REG_COUNT
    addi $t4, R_SOUND_REGS, 0
    # iterate through channels
_mc_pb_channel_loop:
        i_lb($t5, $t4, SOUND_REG_OWNER)
        i_bne($t5, $t0, _mc_pb_channel_loop_next)
        i_lb($t5, $t4, SOUND_REG_STATUS)
        i_beqim($t5, CHN_STATUS_RELEASE, _mc_pb_channel_loop_next)

        i_lb($t5, $t4, SOUND_REG_KEY)
        f_calc_pitch($t5, $t1, $t6)
        i_sw($v0, $t4, SOUND_REG_FREQ)
        
_mc_pb_channel_loop_next:
        addi $t4, $t4, SOUND_REG_SIZE
        addi $t2, $t2, -1
        i_bgt($t2, $zero, _mc_pb_channel_loop)
    # updated all channels, now return
    i_b(midi_data_wait)




# MIDI COMMAND - SYSEX LOAD PATCH (0xF)
midi_command_sysex:
    i_debug(MIDI_DATA_SYSEX)
    add $t0, $zero, R_PATCH_MEM
    addi $t1, $zero, PATCH_SIZE_M_256

_mc_sysex_loop:
        f_uart_read_byte($t2)
        i_sb($t2, $t0, 0x0)
        srl $at, $t1, 6
        ori $at, $at, 0x80
        i_sb($at, R_GPIO, 0)
        addi $t0, $t0, 1
        addi $t1, $t1, -1
        i_bgt($t1, $zero, _mc_sysex_loop)
    # loaded new patch data
    f_uart_read_byte($t0)
    addi $a0, $zero, INVALID_PATCH_DATA
    i_bneim($t0, 0xF7, fatal_error)
    i_b(midi_state_reset)


    

# FATAL ERROR
fatal_error:
i_sw($a0, R_GPIO, 0)
fatal_error_loop:
i_b(fatal_error_loop)

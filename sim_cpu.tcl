vlib work

# compile files

vcom -93 -explicit gpio.vhd
vcom -93 -explicit uart_interface.vhd
vcom -93 -explicit i2c.vhd
vcom -93 -explicit i2s_data_interface.vhd
vcom -93 -explicit i3c2.vhd
vcom -93 -explicit adau1761_configuraiton_data.vhd
vcom -93 -explicit adau1761_izedboard.vhd
vcom -93 -explicit adau1761_interface.vhd
vcom -93 -explicit audio_synth.vhd
vcom -93 -explicit system_bus.vhd
vcom -93 -explicit pc.vhd 
vcom -93 -explicit regfile.vhd 
vcom -93 -explicit alu.vhd 
vcom -93 -explicit instr_mem.vhd 
vcom -93 -explicit data_mem.vhd
vcom -93 -explicit cpu.vhd
vcom -93 -explicit clocking.vhd
vcom -93 -explicit tb_cpu.vhd

# start simulation

vsim -novopt tb_cpu
view wave

add wave tb_cpu/uut/*
add wave tb_cpu/uut/rf_instance/registers
add wave tb_cpu/uut/dmem_instance/mem

# run simulation
run 10000 ns 

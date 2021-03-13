// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.3 (lin64) Build 1368829 Mon Sep 28 20:06:39 MDT 2015
// Date        : Wed Aug 30 14:22:21 2017
// Host        : i3xcd.informatik.uni-erlangen.de running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub
//               /home/inf3/ar42enus/Documents/Ex6/project_1/project_1.srcs/sources_1/ip/blk_ram_data/blk_ram_data_stub.v
// Design      : blk_ram_data
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_0,Vivado 2015.3" *)
module blk_ram_data(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[3:0],addra[11:0],dina[31:0],clkb,addrb[11:0],doutb[31:0]" */;
  input clka;
  input [3:0]wea;
  input [11:0]addra;
  input [31:0]dina;
  input clkb;
  input [11:0]addrb;
  output [31:0]doutb;
endmodule

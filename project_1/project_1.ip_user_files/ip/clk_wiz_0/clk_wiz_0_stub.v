// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.3 (lin64) Build 1368829 Mon Sep 28 20:06:39 MDT 2015
// Date        : Wed Jul 26 18:33:16 2017
// Host        : i3xcd.informatik.uni-erlangen.de running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub
//               /home/inf3/ar42enus/Documents/Ex6/project_1/project_1.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_in_100, clk_out_100, clk_out_48, reset, locked)
/* synthesis syn_black_box black_box_pad_pin="clk_in_100,clk_out_100,clk_out_48,reset,locked" */;
  input clk_in_100;
  output clk_out_100;
  output clk_out_48;
  input reset;
  output locked;
endmodule

// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4.op (lin64) Build 2193837 Tue Apr 10 18:06:59 MDT 2018
// Date        : Mon Aug 20 01:01:28 2018
// Host        : ip-172-31-26-36.ap-southeast-2.compute.internal running 64-bit CentOS Linux release 7.5.1804 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /home/centos/test_proj/test_proj.srcs/sources_1/ip/fifo_sync_512/fifo_sync_512_stub.v
// Design      : fifo_sync_512
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flgb2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_1,Vivado 2017.4.op" *)
module fifo_sync_512(clk, srst, din, wr_en, rd_en, dout, full, empty, valid, 
  prog_empty, wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[511:0],wr_en,rd_en,dout[511:0],full,empty,valid,prog_empty,wr_rst_busy,rd_rst_busy" */;
  input clk;
  input srst;
  input [511:0]din;
  input wr_en;
  input rd_en;
  output [511:0]dout;
  output full;
  output empty;
  output valid;
  output prog_empty;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule

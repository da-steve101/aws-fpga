-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4.op (lin64) Build 2193837 Tue Apr 10 18:06:59 MDT 2018
-- Date        : Tue Oct  9 22:18:26 2018
-- Host        : ip-172-31-31-8.ap-southeast-2.compute.internal running 64-bit CentOS Linux release 7.5.1804 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/centos/ip_proj/ip_proj.srcs/sources_1/ip/axis_dwidth_converter_512_to_64/axis_dwidth_converter_512_to_64_stub.vhdl
-- Design      : axis_dwidth_converter_512_to_64
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axis_dwidth_converter_512_to_64 is
  Port ( 
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axis_tvalid : in STD_LOGIC;
    s_axis_tready : out STD_LOGIC;
    s_axis_tdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axis_tvalid : out STD_LOGIC;
    m_axis_tready : in STD_LOGIC;
    m_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

end axis_dwidth_converter_512_to_64;

architecture stub of axis_dwidth_converter_512_to_64 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aclk,aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[511:0],m_axis_tvalid,m_axis_tready,m_axis_tdata[63:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "axis_dwidth_converter_v1_1_14_axis_dwidth_converter,Vivado 2017.4.op";
begin
end;

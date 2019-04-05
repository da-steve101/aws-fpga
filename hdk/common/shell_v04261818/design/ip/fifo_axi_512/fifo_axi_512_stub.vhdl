-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2_AR71275_op (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
-- Date        : Sat Mar 30 08:57:49 2019
-- Host        : ip-172-31-28-37.ap-southeast-2.compute.internal running 64-bit CentOS Linux release 7.5.1804 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/centos/project_1/project_1.srcs/sources_1/ip/fifo_axi_512/fifo_axi_512_stub.vhdl
-- Design      : fifo_axi_512
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_axi_512 is
  Port ( 
    s_aclk : in STD_LOGIC;
    s_aresetn : in STD_LOGIC;
    s_axis_tvalid : in STD_LOGIC;
    s_axis_tready : out STD_LOGIC;
    s_axis_tdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    s_axis_tkeep : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_axis_tlast : in STD_LOGIC;
    s_axis_tuser : in STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_tvalid : out STD_LOGIC;
    m_axis_tready : in STD_LOGIC;
    m_axis_tdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axis_tkeep : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_tlast : out STD_LOGIC;
    m_axis_tuser : out STD_LOGIC_VECTOR ( 63 downto 0 );
    axis_prog_empty : out STD_LOGIC
  );

end fifo_axi_512;

architecture stub of fifo_axi_512 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[511:0],s_axis_tkeep[63:0],s_axis_tlast,s_axis_tuser[63:0],m_axis_tvalid,m_axis_tready,m_axis_tdata[511:0],m_axis_tkeep[63:0],m_axis_tlast,m_axis_tuser[63:0],axis_prog_empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_2_2,Vivado 2018.2_AR71275_op";
begin
end;

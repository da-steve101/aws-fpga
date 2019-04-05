// Amazon FPGA Hardware Development Kit
//
// Copyright 2016-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

//Registers
//
// 0x00-0xFC - CL_PKT_TST (TX)
// 0x180: RX Control
//    0 - loopback mode
//    1 - Timer go
//    2 - Timer start on first data
//    3 - Timer stop on number of data phases
//    4 - INP Backpressure enable
//    5 - RX mismatch check enable
//
// 0x184: RX Rst
//    0 - Reset the RX FIFO pointers
//
// 0x18c:  INP FIFO pointers
//    15:0 - INP FIFO Read Pointer
//    31:16 - INP FIFO Write Pointer
//
// 0x190-0x1E0: INP Data {last, user[63:0], keep[63:0], data[511:0]}
//
//
// 0x1E8: Timer[31:0]
// 0x1EC: Timer[63:32]
//
// 0x1F0: RX data phases[31:0]
// 0x1F4: RX data phases[63:32]
//
// 0x1F8: Num pkts[31:0]
// 0x1Fc: Num pkts[63:32]
//
// 0x200: Stop RX data phases[31:0]
// 0x204: Stop RX data phases[63:32]


module cl_sde_srm (

   input clk,
   input rst_n,

   input[11:0] cfg_srm_addr,
   input cfg_srm_wr,
   input cfg_srm_rd,
   input[31:0] cfg_srm_wdata,

   output logic srm_cfg_ack,
   output logic[31:0] srm_cfg_rdata,

   input ins_valid,
   input[511:0] ins_data,
   input[63:0] ins_keep,
   input[63:0] ins_user,
   input ins_last,
   output logic ins_ready,

   output logic ots_valid,
   output logic[511:0] ots_data,
   output logic[63:0] ots_keep,
   output logic[63:0] ots_user,
   output logic ots_last,
   input ots_ready
   );

//Read ack/rdata
logic inp_cfg_ack;
always @(posedge clk)
begin
   inp_cfg_ack <= (cfg_srm_wr || cfg_srm_rd);
end

assign srm_cfg_ack = inp_cfg_ack;
assign srm_cfg_rdata = 32'hDEADBEEF;

logic img_rdy_n;
   
   wire vgg_valid;
   wire [511:0] vgg_data;
   wire [63:0] 	vgg_keep;
   wire [63:0] 	vgg_user;
   wire 	vgg_last;
   wire 	vgg_ready;

   AWSVggWrapper tnn
     (
      .clock( clk ),
      .reset( !rst_n ),
      .io_dataIn_valid( ins_valid ),
      .io_dataIn_ready( ins_ready ),
      .io_dataIn_bits_0( ins_data[15:0] ),
      .io_dataIn_bits_1( ins_data[31:16] ),
      .io_dataIn_bits_2( ins_data[47:32] ),
      .io_dataOut_valid( vgg_valid ),
      .io_dataOut_ready( vgg_ready ),
      .io_dataOut_bits_0( vgg_data[15:0] )
      );
   
   assign vgg_last = 1;
   assign vgg_user = 0;
   assign vgg_keep = 64'hffffffffffffffffffff;
   assign vgg_data[511:16] = 0;
   
fifo_axi_512 fifo_inst (
 .s_aclk(clk),
 .s_aresetn(rst_n),
 .s_axis_tvalid(vgg_valid),
 .s_axis_tready(vgg_ready),
 .s_axis_tdata(vgg_data),
 .s_axis_tkeep(vgg_keep),
 .s_axis_tlast(vgg_last),
 .s_axis_tuser(vgg_user),
 .m_axis_tvalid(ots_valid),
 .m_axis_tready(ots_ready),
 .m_axis_tdata(ots_data),
 .m_axis_tkeep(ots_keep),
 .m_axis_tlast(ots_last),
 .m_axis_tuser(ots_user),
 .axis_prog_empty( img_rdy_n )
);

endmodule


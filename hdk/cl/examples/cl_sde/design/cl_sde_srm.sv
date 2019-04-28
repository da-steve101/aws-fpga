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

   output  srm_cfg_ack,
   output [31:0] srm_cfg_rdata,

   input ins_valid,
   input[511:0] ins_data,
   input[63:0] ins_keep,
   input[63:0] ins_user,
   input ins_last,
   output  ins_ready,

   output  ots_valid,
   output [511:0] ots_data,
   output [63:0] ots_keep,
   output [63:0] ots_user,
   output  ots_last,
   input ots_ready
   );

//Read ack/rdata
reg inp_cfg_ack;
always @(posedge clk)
begin
   inp_cfg_ack <= (cfg_srm_wr || cfg_srm_rd);
end

assign srm_cfg_ack = inp_cfg_ack;
assign srm_cfg_rdata = 32'hDEADBEEF;

   wire img_rdy_n;
   wire vgg_valid;
   wire [511:0] vgg_data;
   wire [63:0] 	vgg_keep;
   wire [63:0] 	vgg_user;
   wire 	vgg_last;
   wire 	vgg_ready;

   wire pixel_valid;
   wire [511:0] pixel_data;
   wire [63:0] 	pixel_keep;
   wire [63:0] 	pixel_user;
   wire 	pixel_last;
   wire 	pixel_ready;
   wire 	nxt_data;

fifo_axi_512 fifo_in (
 .s_aclk(clk),
 .s_aresetn(rst_n),
 .s_axis_tvalid(ins_valid),
 .s_axis_tready(ins_ready),
 .s_axis_tdata(ins_data),
 .s_axis_tkeep(ins_keep),
 .s_axis_tlast(ins_last),
 .s_axis_tuser(ins_user),
 .m_axis_tvalid(pixel_valid),
 .m_axis_tready(pixel_ready & nxt_data),
 .m_axis_tdata(pixel_data),
 .m_axis_tkeep(pixel_keep),
 .m_axis_tlast(pixel_last),
 .m_axis_tuser(pixel_user),
 .axis_prog_empty( img_rdy_n )
);
   reg [9:0] 	img_cntr;
   reg 		data_vld;
   wire 	running;
   reg [511:0] 	pixel_data_reg;
   assign pixel_ready = ( !img_rdy_n | running );
   assign nxt_data = img_cntr[2:0] == 0;
   assign running = img_cntr != 0;
   always @( posedge clk ) begin
      if ( !rst_n ) begin
	 img_cntr <= 0;
      end else begin
	 if ( ( pixel_ready & pixel_valid ) | running ) begin
	    img_cntr <= img_cntr + 1;
	 end
	 data_vld <= ( pixel_ready & pixel_valid ) | running;
	 if ( img_cntr[2:0] == 0 ) begin
	    pixel_data_reg <= pixel_data;
	 end else begin
	    pixel_data_reg <= { 64'h0, pixel_data_reg[511:64] };
	 end
      end
   end

`define TNN 1
`ifdef TNN
   AWSVggWrapper tnn
     (
      .clock( clk ),
      .reset( !rst_n ),
      .io_dataIn_valid( data_vld ),
      .io_dataIn_bits_0( pixel_data_reg[15:0] ),
      .io_dataIn_bits_1( pixel_data_reg[31:16] ),
      .io_dataIn_bits_2( pixel_data_reg[47:32] ),
      .io_dataOut_valid( vgg_valid ),
      .io_dataOut_ready( vgg_ready ),
      .io_dataOut_bits_0( vgg_data[15:0] ),
      .io_dataOut_bits_1( vgg_data[31:16] ),
      .io_dataOut_bits_2( vgg_data[47:32] ),
      .io_dataOut_bits_3( vgg_data[63:48] ),
      .io_dataOut_bits_4( vgg_data[79:64] ),
      .io_dataOut_bits_5( vgg_data[95:80] ),
      .io_dataOut_bits_6( vgg_data[111:96] ),
      .io_dataOut_bits_7( vgg_data[127:112] ),
      .io_dataOut_bits_8( vgg_data[143:128] ),
      .io_dataOut_bits_9( vgg_data[159:144] )
      );
   assign vgg_last = 1;
   assign vgg_user = 64'h0;
   assign vgg_keep = 64'hffffffffffffffff;
   assign vgg_data[511:160] = 0;
`else

   reg 		tmp_valid;
   reg [511:0] 	tmp_data;
   reg [63:0] 	tmp_keep;
   reg [63:0] 	tmp_user;
   reg 		tmp_last;
   reg [9:0] 	tmp_cntr;

   always @( posedge clk ) begin
      if ( !rst_n ) begin
	 tmp_valid <= 0;
	 tmp_cntr <= 0;
      end else begin
	 if ( data_vld ) begin
	    tmp_cntr <= tmp_cntr + 1;
	 end
	 tmp_valid <= ( tmp_cntr[2:0] == 7 );
      end
      tmp_data <= { pixel_data_reg[63:0], tmp_data[511:64] };
      tmp_keep <= 64'hffffffffffffffff;;
      tmp_last <= ( tmp_cntr == 1023 );
      tmp_user <= 64'h0;
   end

   assign vgg_data = tmp_data;
   assign vgg_valid = tmp_valid;
   assign vgg_user = tmp_user;
   assign vgg_keep = tmp_keep;
   assign vgg_last = tmp_last;

`endif

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
 .m_axis_tuser(ots_user)
);

endmodule

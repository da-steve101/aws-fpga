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
   input[63:0] ins_keep, // assume this always 1's
   input[63:0] ins_user, // ignore this
   input ins_last,
   output logic ins_ready,

   output logic ots_valid,
   output logic[511:0] ots_data,
   output logic[63:0] ots_keep,
   output logic[63:0] ots_user, // ignore this
   output logic ots_last,
   input ots_ready
   );

   assign srm_cfg_ack = 1;
   assign srm_cfg_rdata = 32'habcd1234;

   wire        ins_full;
   wire        img_rdy_n;
   assign ins_tready = !ins_full;
   wire        pixel_in_tvalid;
   wire        pixel_in_tready;
   wire [63:0] pixel_in_tdata;

   wire        class_out_tvalid;
   wire [159:0] class_out_tdata;
   

   // have an fifo to buffer images at the input
   input_fifo input_fifo_inst
     (
      .clk(clk),
      .srst(!rst_n),
      .din(ins_tdata),
      .wr_en(rst_n & ins_tvalid),
      .rd_en(pixel_in_tready),
      .dout(pixel_in_tdata),
      .valid(pixel_in_tvalid),
      .prog_full(ins_full),
      .prog_empty(img_rdy_n)
      );

   reg 		vld_cnn;
   reg [159:0] 	class_cnn;
   assign class_out_tdata = class_cnn;
   assign class_out_tvalid = vld_cnn;
   reg [9:0] 	img_cntr;
   reg 		running;
   assign pixel_in_tready = running;
   // ensure image is buffered before starting
   always @( posedge clk ) begin
      if (!rst_n ) begin
	 img_cntr <= 0;
	 running <= 0;
      end else begin
	 if ( img_cntr == 0 ) begin
	    if ( !img_rdy_n ) begin
	       img_cntr <= img_cntr - 1;
	       running <= 1;
	    end else begin
	       running <= 0;
	    end
	 end
	 if ( img_cntr != 0 ) begin
	    img_cntr <= img_cntr - 1;
	 end
      end
   end
   // *************************************************
   // Replace with the TNN
   reg 		vld_toggle;
   always @( posedge clk ) begin
      if (!rst_n ) begin
	 vld_cnn <= 0;
	 vld_toggle <= 0;
      end else begin
	 vld_cnn <= pixel_in_tvalid & vld_toggle;
	 vld_toggle <= !vld_toggle;
	 class_cnn[63:0] <= pixel_in_tdata;
	 class_cnn[127:64] <= pixel_in_tdata ^ 64'hAAAAAAAAAAAAAAAA;
	 class_cnn[159:128] <= pixel_in_tdata[31:0] ^ 32'h55555555;
      end
   end
   // ***************************************************
   
   // have a fifo to store outputs of 160 bits and send to output
   output_fifo output_fifo_inst
     (
      .clk(clk),
      .srst(!rst_n),
      .din(class_out_tdata),
      .wr_en(rst_n & class_out_tvalid),
      .rd_en( rst_n & ots_ready ),
      .dout( ots_data ),
      .valid( ost_valid )
      );
   assign ots_data[511:160] = 0;
   assign ots_last = 1;
   assign ots_keep = 64'hFFFFF; // just keep bottom 160 bits
   assign ots_user = 0;
endmodule


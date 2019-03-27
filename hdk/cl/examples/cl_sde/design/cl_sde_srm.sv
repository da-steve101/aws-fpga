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
   assign ins_ready = !ins_full;
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
      .din(ins_data),
      .wr_en(rst_n & ins_valid),
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
   localparam USE_TNN = 1;
   // *************************************************
`ifdef USE_TNN
   wire [1023:0] data_out;
   reg [1023:0] data_out_reg;
   reg [3:0] 	out_cntr;
   wire 	 vld_out;
   always @( posedge clk ) begin
      if ( !rst_n ) begin
	 vld_cnn <= 0;
      end else begin
	 if ( vld_out ) begin
	    cntr <= 0;
	    vld_cnn <= 1;
	 end else begin
	    if ( cntr <= 6 ) begin
	       cntr <= cntr + 1;
	    end else begin
	       vld_cnn <= 0;
	    end
	 end
      end
      if ( vld_out ) begin
	 data_out_reg <= data_out;
      end else begin
	 data_out_reg <= { data_out_reg[1023:160], 160'h0 };
      end
      class_cnn <= data_out_reg[1023:864];
   end
   Vgg7 tnn
     (
.clock(clk),
.reset(!rst_n),
.io_dataIn_ready(),
.io_dataIn_valid(running),
.io_dataIn_bits_0(pixel_in_tdata[15:0]),
.io_dataIn_bits_1(pixel_in_tdata[31:16]),
.io_dataIn_bits_2(pixel_in_tdata[47:32]),
.io_dataOut_ready(1),
.io_dataOut_valid(vld_out),
.io_dataOut_bits_0( data_out[15:0] ),
.io_dataOut_bits_1( data_out[31:16] ),
.io_dataOut_bits_2( data_out[47:32] ),
.io_dataOut_bits_3( data_out[63:48] ),
.io_dataOut_bits_4( data_out[79:64] ),
.io_dataOut_bits_5( data_out[95:80] ),
.io_dataOut_bits_6( data_out[111:96] ),
.io_dataOut_bits_7( data_out[127:112] ),
.io_dataOut_bits_8( data_out[143:128] ),
.io_dataOut_bits_9( data_out[159:144] ),
.io_dataOut_bits_10( data_out[175:160] ),
.io_dataOut_bits_11( data_out[191:176] ),
.io_dataOut_bits_12( data_out[207:192] ),
.io_dataOut_bits_13( data_out[223:208] ),
.io_dataOut_bits_14( data_out[239:224] ),
.io_dataOut_bits_15( data_out[255:240] ),
.io_dataOut_bits_16( data_out[271:256] ),
.io_dataOut_bits_17( data_out[287:272] ),
.io_dataOut_bits_18( data_out[303:288] ),
.io_dataOut_bits_19( data_out[319:304] ),
.io_dataOut_bits_20( data_out[335:320] ),
.io_dataOut_bits_21( data_out[351:336] ),
.io_dataOut_bits_22( data_out[367:352] ),
.io_dataOut_bits_23( data_out[383:368] ),
.io_dataOut_bits_24( data_out[399:384] ),
.io_dataOut_bits_25( data_out[415:400] ),
.io_dataOut_bits_26( data_out[431:416] ),
.io_dataOut_bits_27( data_out[447:432] ),
.io_dataOut_bits_28( data_out[463:448] ),
.io_dataOut_bits_29( data_out[479:464] ),
.io_dataOut_bits_30( data_out[495:480] ),
.io_dataOut_bits_31( data_out[511:496] ),
.io_dataOut_bits_32( data_out[527:512] ),
.io_dataOut_bits_33( data_out[543:528] ),
.io_dataOut_bits_34( data_out[559:544] ),
.io_dataOut_bits_35( data_out[575:560] ),
.io_dataOut_bits_36( data_out[591:576] ),
.io_dataOut_bits_37( data_out[607:592] ),
.io_dataOut_bits_38( data_out[623:608] ),
.io_dataOut_bits_39( data_out[639:624] ),
.io_dataOut_bits_40( data_out[655:640] ),
.io_dataOut_bits_41( data_out[671:656] ),
.io_dataOut_bits_42( data_out[687:672] ),
.io_dataOut_bits_43( data_out[703:688] ),
.io_dataOut_bits_44( data_out[719:704] ),
.io_dataOut_bits_45( data_out[735:720] ),
.io_dataOut_bits_46( data_out[751:736] ),
.io_dataOut_bits_47( data_out[767:752] ),
.io_dataOut_bits_48( data_out[783:768] ),
.io_dataOut_bits_49( data_out[799:784] ),
.io_dataOut_bits_50( data_out[815:800] ),
.io_dataOut_bits_51( data_out[831:816] ),
.io_dataOut_bits_52( data_out[847:832] ),
.io_dataOut_bits_53( data_out[863:848] ),
.io_dataOut_bits_54( data_out[879:864] ),
.io_dataOut_bits_55( data_out[895:880] ),
.io_dataOut_bits_56( data_out[911:896] ),
.io_dataOut_bits_57( data_out[927:912] ),
.io_dataOut_bits_58( data_out[943:928] ),
.io_dataOut_bits_59( data_out[959:944] ),
.io_dataOut_bits_60( data_out[975:960] ),
.io_dataOut_bits_61( data_out[991:976] ),
.io_dataOut_bits_62( data_out[1007:992] ),
.io_dataOut_bits_63( data_out[1023:1008] )
);
`else	   
   reg 		vld_toggle;
   always @( posedge clk ) begin
      if (!rst_n ) begin
	 vld_cnn <= 0;
	 vld_toggle <= 0;
      end else begin
	 vld_cnn <= pixel_in_tvalid & vld_toggle;
	 vld_toggle <= !vld_toggle;
      end
      class_cnn[63:0] <= pixel_in_tdata;
      class_cnn[127:64] <= pixel_in_tdata ^ 64'hAAAAAAAAAAAAAAAA;
      class_cnn[159:128] <= pixel_in_tdata[31:0] ^ 32'h55555555;
   end
`endif
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


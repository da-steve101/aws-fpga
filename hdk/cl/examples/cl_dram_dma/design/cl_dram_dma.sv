// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

module cl_dram_dma #(parameter NUM_DDR=4)

(
   `include "cl_ports.vh"

);

`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_dram_dma_defines.vh"

// TIE OFF ALL UNUSED INTERFACES
// Including all the unused interface to tie off
// This list is put in the top of the fie to remind
// developers to remve the specific interfaces
// that the CL will use

`include "unused_sh_bar1_template.inc"
`include "unused_flr_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_pcim_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
`include "unused_sh_ocl_template.inc"

//----------------------------
// Internal signals
//----------------------------
axi_bus_t sh_cl_dma_pcis_bus();
axi_bus_t sh_cl_dma_pcis_q();

logic clk;
(* dont_touch = "true" *) logic pipe_rst_n;
logic pre_sync_rst_n;
(* dont_touch = "true" *) logic sync_rst_n;

assign cl_sh_id0[31:0] = `CL_SH_ID0;
assign cl_sh_id1[31:0] = `CL_SH_ID1;

//----------------------------
// End Internal signals
//----------------------------

assign clk = clk_main_a0;

//reset synchronizer
lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_main_n), .out_bus(pipe_rst_n));

always_ff @(negedge pipe_rst_n or posedge clk)
   if (!pipe_rst_n)
   begin
      pre_sync_rst_n <= 0;
      sync_rst_n <= 0;
   end
   else
   begin
      pre_sync_rst_n <= 1;
      sync_rst_n <= pre_sync_rst_n;
   end

(* dont_touch = "true" *) logic dma_pcis_slv_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(8)) DMA_PCIS_SLV_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(dma_pcis_slv_sync_rst_n));

`define NO_QUEUE 4
`define NO_QUEUE_LOG 2

wire [511:0] mem_str;
wire        mem_vld;
wire 	    wrting;
reg [3:0]   no_transfers_wrt_buf[`NO_QUEUE-1:0];
reg [3:0]   no_transfers_rd_buf[`NO_QUEUE-1:0];
reg [3:0]   no_transfers_wrt;
reg [3:0]   no_transfers_rd;
// consumer and producers
reg [`NO_QUEUE_LOG-1:0] tran_wrt_cntr_prod, tran_wrt_cntr_con;
reg [`NO_QUEUE_LOG-1:0] tran_rd_cntr_prod, tran_rd_cntr_con;
reg [5:0] wid_buf[`NO_QUEUE-1:0];
reg [5:0] rid_buf[`NO_QUEUE-1:0];
reg [5:0] wid;
reg [5:0] rid;
reg 	  bid_vld;
reg 	  rd_vld;
reg 	  awrdy;
reg 	  arrdy;
reg 	  rlast;
reg 	  wlast;
reg 	  wready;
reg [511:0] rdata;
wire      full;

logic   image_buffered_n;
logic 	output_buffered_n;
logic [7:0] img_cntr;
logic [7:0] img_cntr_out;
logic 	run;
logic 	run_out;
logic 	image_vld;

assign sh_cl_dma_pcis_q.awready = awrdy;

// recv burst
assign wrting = ( tran_wrt_cntr_prod + 1 ) != ( tran_wrt_cntr_con - 1 );

assign sh_cl_dma_pcis_q.wready = wready & !full;
assign sh_cl_dma_pcis_q.bresp = 0;
assign sh_cl_dma_pcis_q.bvalid = bid_vld;
assign sh_cl_dma_pcis_q.bid[5:0] = wid;

assign sh_cl_dma_pcis_q.arready = arrdy;
assign sh_cl_dma_pcis_q.rvalid = rd_vld;
assign sh_cl_dma_pcis_q.rid[5:0] = rid;
assign sh_cl_dma_pcis_q.rresp = 0;
assign sh_cl_dma_pcis_q.rdata = rdata;
assign sh_cl_dma_pcis_q.rlast = rlast;

// set up burst
always_ff @( negedge dma_pcis_slv_sync_rst_n or posedge clk )
begin
   if (!dma_pcis_slv_sync_rst_n)
   begin
      wready <= 0;
      bid_vld <= 0;
      rd_vld <= 0;
      awrdy <= 0;
      arrdy <= 0;
      rlast <= 0;
      wlast <= 1;
      no_transfers_rd <= 0;
      no_transfers_wrt <= 0;
      tran_wrt_cntr_prod <= 0;
      tran_wrt_cntr_con <= 0;
      tran_rd_cntr_prod <= 0;
      tran_rd_cntr_con <= 0;
   end
   else
   begin
      // producer
      if ( sh_cl_dma_pcis_q.awvalid )
      begin
	 no_transfers_wrt_buf[tran_wrt_cntr_prod] <= sh_cl_dma_pcis_q.awlen;
	 wid_buf[tran_wrt_cntr_prod] <= sh_cl_dma_pcis_q.awid[5:0];
	 if ( awrdy )
	 begin
	    tran_wrt_cntr_prod <= tran_wrt_cntr_prod + 1;
	    if ( !wrting )
	    begin
	       awrdy <= 0;
	    end
	 end
	 else
	 begin
	    if ( wrting )
	    begin
	       awrdy <= 1;
	    end
	 end
      end
      else
      begin
	 awrdy <= 1;
      end // else: !if( sh_cl_dma_pcis_q.awvalid )
      // wrt consumer
      if ( wlast )
      begin
	 bid_vld <= 0;
	 wready <= 1;
	 if ( tran_wrt_cntr_con != tran_wrt_cntr_prod )
	 begin
	    no_transfers_wrt <= no_transfers_wrt_buf[tran_wrt_cntr_con];
	    wid <= wid_buf[tran_wrt_cntr_con];
	    tran_wrt_cntr_con <= tran_wrt_cntr_con + 1;
	    wlast <= 0;
	 end
      end
      else
      begin
	 if ( sh_cl_dma_pcis_q.wvalid & wready & !full )
	 begin
	    if ( sh_cl_dma_pcis_q.wlast & !wlast )
	    begin
	       wlast <= 1;
	       wready <= 0;
	       bid_vld <= 1;
	    end
	    no_transfers_wrt <= no_transfers_wrt - 1;
	 end
      end
      // build the producer
      if ( sh_cl_dma_pcis_q.arvalid )
      begin
	 no_transfers_rd_buf[tran_rd_cntr_prod] <= sh_cl_dma_pcis_q.arlen;
	 rid_buf[tran_rd_cntr_prod] <= sh_cl_dma_pcis_q.arid[5:0]; // make a queue for rids ... for now cbf cause all 1?
	 if ( arrdy )
	 begin
	    tran_rd_cntr_prod <= tran_rd_cntr_prod + 1;
	    if ( tran_rd_cntr_prod + 1 == tran_rd_cntr_con - 1 )
	    begin
	       arrdy <= 0;
	    end
	 end
	 else
	 begin
	    if ( tran_rd_cntr_prod + 1 != tran_rd_cntr_con - 1 )
	    begin
	       arrdy <= 1;
	    end
	 end
      end // if ( sh_cl_dma_pcis_q.arvalid )
      // build the consumer
      if ( sh_cl_dma_pcis_q.rready & run_out )
      begin
	 rdata <= mem_str;
	 rd_vld <= mem_vld;
	 if ( mem_vld )
	 begin
	    no_transfers_rd <= no_transfers_rd - 1;
	    if ( no_transfers_rd == 0 )
	    begin
	       rlast <= 1;
	       if ( tran_rd_cntr_con != tran_rd_cntr_prod )
	       begin
		  tran_rd_cntr_con <= tran_rd_cntr_con + 1;
		  no_transfers_rd <= no_transfers_rd_buf[tran_rd_cntr_con];
		  rid <= rid_buf[tran_rd_cntr_con];
	       end
	    end
	    else
	    begin
	       rlast <= 0;
	    end
	 end // if ( mem_vld )
      end
      else
      begin
	 rlast <= 0;
	 if ( tran_rd_cntr_con != tran_rd_cntr_prod )
	 begin
	    no_transfers_rd <= no_transfers_rd_buf[tran_rd_cntr_con];
	    rid <= rid_buf[tran_rd_cntr_con];
	    tran_rd_cntr_con <= tran_rd_cntr_con + 1;
	 end
      end
   end
end // always_ff @ ( negedge dma_pcis_slv_sync_rst_n or posedge clk )

assign sh_cl_dma_pcis_bus.awvalid = sh_cl_dma_pcis_awvalid;
assign sh_cl_dma_pcis_bus.awaddr = sh_cl_dma_pcis_awaddr; // dont care
assign sh_cl_dma_pcis_bus.awid[5:0] = sh_cl_dma_pcis_awid;// should be b000000
assign sh_cl_dma_pcis_bus.awlen = sh_cl_dma_pcis_awlen;   // should be b0001
assign sh_cl_dma_pcis_bus.awsize = sh_cl_dma_pcis_awsize; // should be b110
assign cl_sh_dma_pcis_awready = sh_cl_dma_pcis_bus.awready;

assign sh_cl_dma_pcis_bus.wvalid = sh_cl_dma_pcis_wvalid;
assign sh_cl_dma_pcis_bus.wdata = sh_cl_dma_pcis_wdata; // data sent
assign sh_cl_dma_pcis_bus.wstrb = sh_cl_dma_pcis_wstrb; // channel select: should be b1111
assign sh_cl_dma_pcis_bus.wlast = sh_cl_dma_pcis_wlast;
assign cl_sh_dma_pcis_wready = sh_cl_dma_pcis_bus.wready;

assign cl_sh_dma_pcis_bvalid = sh_cl_dma_pcis_bus.bvalid;
assign cl_sh_dma_pcis_bresp = sh_cl_dma_pcis_bus.bresp; // send error code back
assign sh_cl_dma_pcis_bus.bready = sh_cl_dma_pcis_bready;
assign cl_sh_dma_pcis_bid = sh_cl_dma_pcis_bus.bid[5:0]; // send wid completed back

assign sh_cl_dma_pcis_bus.arvalid = sh_cl_dma_pcis_arvalid;
assign sh_cl_dma_pcis_bus.araddr = sh_cl_dma_pcis_araddr;
assign sh_cl_dma_pcis_bus.arid[5:0] = sh_cl_dma_pcis_arid;
assign sh_cl_dma_pcis_bus.arlen = sh_cl_dma_pcis_arlen;
assign sh_cl_dma_pcis_bus.arsize = sh_cl_dma_pcis_arsize;
assign cl_sh_dma_pcis_arready = sh_cl_dma_pcis_bus.arready;

assign cl_sh_dma_pcis_rvalid = sh_cl_dma_pcis_bus.rvalid;
assign cl_sh_dma_pcis_rid = sh_cl_dma_pcis_bus.rid[5:0];
assign cl_sh_dma_pcis_rlast = sh_cl_dma_pcis_bus.rlast;
assign cl_sh_dma_pcis_rresp = sh_cl_dma_pcis_bus.rresp;
assign cl_sh_dma_pcis_rdata = sh_cl_dma_pcis_bus.rdata;
assign sh_cl_dma_pcis_bus.rready = sh_cl_dma_pcis_rready;

   axi_register_slice PCI_AXL_REG_SLC (
       .aclk          (clk),
       .aresetn       (dma_pcis_slv_sync_rst_n),
       .s_axi_awid    (sh_cl_dma_pcis_bus.awid),
       .s_axi_awaddr  (sh_cl_dma_pcis_bus.awaddr),
       .s_axi_awlen   (sh_cl_dma_pcis_bus.awlen),
       .s_axi_awvalid (sh_cl_dma_pcis_bus.awvalid),
       .s_axi_awsize  (sh_cl_dma_pcis_bus.awsize),
       .s_axi_awready (sh_cl_dma_pcis_bus.awready),
       .s_axi_wdata   (sh_cl_dma_pcis_bus.wdata),
       .s_axi_wstrb   (sh_cl_dma_pcis_bus.wstrb),
       .s_axi_wlast   (sh_cl_dma_pcis_bus.wlast),
       .s_axi_wvalid  (sh_cl_dma_pcis_bus.wvalid),
       .s_axi_wready  (sh_cl_dma_pcis_bus.wready),
       .s_axi_bid     (sh_cl_dma_pcis_bus.bid),
       .s_axi_bresp   (sh_cl_dma_pcis_bus.bresp),
       .s_axi_bvalid  (sh_cl_dma_pcis_bus.bvalid),
       .s_axi_bready  (sh_cl_dma_pcis_bus.bready),
       .s_axi_arid    (sh_cl_dma_pcis_bus.arid),
       .s_axi_araddr  (sh_cl_dma_pcis_bus.araddr),
       .s_axi_arlen   (sh_cl_dma_pcis_bus.arlen),
       .s_axi_arvalid (sh_cl_dma_pcis_bus.arvalid),
       .s_axi_arsize  (sh_cl_dma_pcis_bus.arsize),
       .s_axi_arready (sh_cl_dma_pcis_bus.arready),
       .s_axi_rid     (sh_cl_dma_pcis_bus.rid),
       .s_axi_rdata   (sh_cl_dma_pcis_bus.rdata),
       .s_axi_rresp   (sh_cl_dma_pcis_bus.rresp),
       .s_axi_rlast   (sh_cl_dma_pcis_bus.rlast),
       .s_axi_rvalid  (sh_cl_dma_pcis_bus.rvalid),
       .s_axi_rready  (sh_cl_dma_pcis_bus.rready),

       .m_axi_awid    (sh_cl_dma_pcis_q.awid),
       .m_axi_awaddr  (sh_cl_dma_pcis_q.awaddr),
       .m_axi_awlen   (sh_cl_dma_pcis_q.awlen),
       .m_axi_awvalid (sh_cl_dma_pcis_q.awvalid),
       .m_axi_awsize  (sh_cl_dma_pcis_q.awsize),
       .m_axi_awready (sh_cl_dma_pcis_q.awready),
       .m_axi_wdata   (sh_cl_dma_pcis_q.wdata),
       .m_axi_wstrb   (sh_cl_dma_pcis_q.wstrb),
       .m_axi_wvalid  (sh_cl_dma_pcis_q.wvalid),
       .m_axi_wlast   (sh_cl_dma_pcis_q.wlast),
       .m_axi_wready  (sh_cl_dma_pcis_q.wready),
       .m_axi_bresp   (sh_cl_dma_pcis_q.bresp),
       .m_axi_bvalid  (sh_cl_dma_pcis_q.bvalid),
       .m_axi_bid     (sh_cl_dma_pcis_q.bid),
       .m_axi_bready  (sh_cl_dma_pcis_q.bready),
       .m_axi_arid    (sh_cl_dma_pcis_q.arid),
       .m_axi_araddr  (sh_cl_dma_pcis_q.araddr),
       .m_axi_arlen   (sh_cl_dma_pcis_q.arlen),
       .m_axi_arsize  (sh_cl_dma_pcis_q.arsize),
       .m_axi_arvalid (sh_cl_dma_pcis_q.arvalid),
       .m_axi_arready (sh_cl_dma_pcis_q.arready),
       .m_axi_rid     (sh_cl_dma_pcis_q.rid),
       .m_axi_rdata   (sh_cl_dma_pcis_q.rdata),
       .m_axi_rresp   (sh_cl_dma_pcis_q.rresp),
       .m_axi_rlast   (sh_cl_dma_pcis_q.rlast),
       .m_axi_rvalid  (sh_cl_dma_pcis_q.rvalid),
       .m_axi_rready  (sh_cl_dma_pcis_q.rready)
   );

   logic [511:0] fifo_in_bits;
   logic 	fifo_in_valid;
   logic 	fifo_in_ready;

   logic [63:0] data_in_bits;
   logic 	data_in_valid;
   logic 	data_in_ready;

   logic [63:0] data_out_bits;
   logic [15:0] data_out_bits_0;
   logic [15:0] data_out_bits_1;
   logic [15:0] data_out_bits_2;
   logic [15:0] data_out_bits_3;
   logic 	data_out_valid;
   logic 	data_out_ready;

   logic [511:0] fifo_out_bits;
   logic 	fifo_out_valid;
   logic 	fifo_out_ready;

(* dont_touch = "true" *) logic fifo_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) FIFO_SYNC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(fifo_sync_rst_n));

// Put the 64 bits into a AXI Data FIFO (xilinx ip)
fifo_sync_512 AXI_DATA_FIFO_IN
(
 .clk( clk ),
 .srst( !fifo_sync_rst_n ),

 .wr_en( sh_cl_dma_pcis_q.wvalid & wready & !full ),
 .full( full ),
 .din( sh_cl_dma_pcis_q.wdata ),

 .valid( image_vld ),
 .prog_empty( image_buffered_n ),
 .rd_en( run & fifo_in_ready ),
 .dout( fifo_in_bits )
);

always_ff @( negedge fifo_sync_rst_n or posedge clk )
  begin
     if ( !fifo_sync_rst_n )
       begin
	  img_cntr <= 0;
	  img_cntr_out <= 0;
	  run <= 0;
	  run_out <= 0;
       end
     else
       begin
	  if ( img_cntr == 0 )
	    begin
	       if ( !image_buffered_n )
		 begin
		    run <= 1;
		    img_cntr <= 8'h80;
		 end
	       else
		 begin
		    run <= 0;
		 end
	    end
	  else if ( img_cntr > 0 & fifo_in_ready & image_vld )
	    begin
	       img_cntr <= img_cntr - 1;
	    end
	  if ( img_cntr_out == 0 )
	    begin
	       if ( !output_buffered_n )
		 begin
		    run_out <= 1;
		    img_cntr_out <= 8'h10;
		 end
	       else
		 begin
		    run_out <= 0;
		 end
	    end
	  else if ( img_cntr_out > 0 )
	    begin
	       if ( mem_vld & sh_cl_dma_pcis_q.rready )
		 begin
		    img_cntr_out <= img_cntr_out - 1;
		 end
	    end
	  else
	    begin
	       run_out <= 0;
	    end
       end
  end

axi_dwidth_converter_512_to_64 AXI_DWIDTH_TO_64
(
 .aclk( clk ),
 .aresetn( fifo_sync_rst_n ),

 .s_axis_tvalid( image_vld & run ),
 .s_axis_tready( fifo_in_ready ),
 .s_axis_tdata( fifo_in_bits ),

 .m_axis_tvalid( data_in_valid ),
 .m_axis_tready( data_in_ready ),
 .m_axis_tdata( data_in_bits )
);

(* dont_touch = "true" *) logic cnn_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) CNN_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(cnn_rst_n));

`ifndef IMPLEMENT_CNN
parameter N = 10;
// make a shift reg ...
logic [(N*64)-1:0] bits_reg;
logic [N-1:0] valid_reg = 0;

assign data_out_bits = bits_reg[63:0];
assign data_out_valid = valid_reg[0];
assign data_in_ready = data_out_ready;

always_ff @(posedge clk)
begin
  if ( data_out_ready )
  begin
    bits_reg <= { data_in_bits, bits_reg[(N*64)-1:64] };
    valid_reg <= { data_in_valid, valid_reg[N-1:1]};
  end
end

`else
// Insert CNN here
assign data_out_bits = { data_out_bits_3, data_out_bits_2, data_out_bits_1, data_out_bits_0 };
AWSVggWrapper cifar10
(
 .clock( clk ),
 .reset( !cnn_rst_n ),
 .io_dataIn_ready( data_in_ready ),
 .io_dataIn_valid( data_in_valid ),
 .io_dataIn_bits_0( data_in_bits[15:0] ),
 .io_dataIn_bits_1( data_in_bits[31:16] ),
 .io_dataIn_bits_2( data_in_bits[47:32] ),
 .io_dataOut_ready( data_out_ready ),
 .io_dataOut_valid( data_out_valid ),
 .io_dataOut_bits_0( data_out_bits_0 ),
 .io_dataOut_bits_1( data_out_bits_1 ),
 .io_dataOut_bits_2( data_out_bits_2 ),
 .io_dataOut_bits_3( data_out_bits_3 )
);
logic [9:0] pixel_cntr;
logic [9:0] pixel_out_cntr;
always_ff @( negedge cnn_rst_n or posedge clk )
  begin
     if ( !cnn_rst_n )
       begin
	  pixel_cntr <= 10'h0;
	  pixel_out_cntr <= 10'h0;
       end
     else
       begin
	  if ( data_in_valid )
	    begin
	       pixel_cntr <= pixel_cntr + 1'h1;
	       $display( "pixel_in[%d] = [%h,%h,%h]\n", pixel_cntr, data_in_bits[15:0], data_in_bits[31:16], data_in_bits[47:32] );
	    end
	  if ( data_out_valid )
	    begin
	       pixel_out_cntr <= pixel_out_cntr + 1'h1;
	       $display( "pixel_out[%d] = [%h,%h,%h,%h]\n", pixel_out_cntr, data_out_bits_0, data_out_bits_1, data_out_bits_2, data_out_bits_3 );
	    end
       end
  end
`endif // IMPLEMENT_CNN

(* dont_touch = "true" *) logic fifo_out_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) FIFO_OUT_SYNC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(fifo_out_sync_rst_n));

// Read the data from the AXI Data FIFO into a AXI Data Width Converter( Xilinx IP )
// Convert from 64 bits to 512 bits
// Send to the output using cl_sh_pcim_bus
axi_dwidth_converter_64_to_512 AXI_DWIDTH_TO_512
(
 .aclk( clk ),
 .aresetn( fifo_out_sync_rst_n ),

 .s_axis_tvalid( data_out_valid ),
 .s_axis_tready( data_out_ready ),
 .s_axis_tdata( data_out_bits ),

 .m_axis_tvalid( fifo_out_valid ),
 .m_axis_tready( 1'b1 ),
 .m_axis_tdata( fifo_out_bits )
);

logic [7:0] tmp_cntr;
logic [7:0] tmp_in_cntr;
logic [7:0] tmp_in_rdy_cntr;

always_ff @( posedge clk )
begin
   if ( !sync_rst_n )
     begin
	tmp_cntr <= 0;
	tmp_in_cntr <= 0;
	tmp_in_rdy_cntr <= 0;
     end
   else
     begin
	if ( fifo_out_valid )
	  begin
	     tmp_cntr <= tmp_cntr + 1;
	  end
	if ( sh_cl_dma_pcis_q.wvalid )
	  begin
	     tmp_in_cntr <= tmp_in_cntr + 1;
	     if ( sh_cl_dma_pcis_q.wready )
	       begin
		  tmp_in_rdy_cntr <= tmp_in_rdy_cntr + 1;
	       end
	  end
     end
end

fifo_sync_512 AXI_DATA_FIFO_OUT
(
 .clk( clk ),
 .srst( !fifo_out_sync_rst_n ),

 .wr_en( fifo_out_valid ),
 .din( fifo_out_bits ),

 .valid( mem_vld ),
 .empty( output_buffered_n ),
 .rd_en( sh_cl_dma_pcis_q.rready & run_out ),
 .dout( mem_str )
);

endmodule

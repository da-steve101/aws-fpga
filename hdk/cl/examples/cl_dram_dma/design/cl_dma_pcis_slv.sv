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

module cl_dma_pcis_slv
(
    input aclk,
    input aresetn,

    axi_bus_t.master sh_cl_dma_pcis_bus,

    axi_bus_t.slave lcl_cl_sh_ddra,

    axi_bus_t sh_cl_dma_pcis_q,

    axi_bus_t.slave cl_sh_ddr_bus,
    output [511:0] fifo_in_bits,
    output         fifo_in_vld,
    input          fifo_in_rdy,
    input  [511:0] fifo_out_bits,
    input          fifo_out_vld,
    output         fifo_out_rdy
);

//----------------------------
// Internal signals
//----------------------------
axi_bus_t lcl_cl_sh_ddra_q();
axi_bus_t lcl_cl_sh_ddra_q2();
axi_bus_t cl_sh_ddr_q();
axi_bus_t cl_sh_ddr_q2();
axi_bus_t sh_cl_pcis();

reg output_available;
// count 4k blocks
reg [12:0] input_cnt;
reg [12:0] output_cnt;
logic ddra_add_cnt, ddra_sub_cnt, ddrc_add_cnt, ddrc_sub_cnt;

// send read request
logic r_addr_vld;
logic [63:0] r_addr;

// send write request
logic w_addr_vld;
logic [63:0] w_addr;
logic w_last;
reg [5:0] w_cntr;
reg [12:0] trans_cntr;

//----------------------------
// End Internal signals
//----------------------------

//reset synchronizers
(* dont_touch = "true" *) logic slr0_sync_aresetn;
(* dont_touch = "true" *) logic slr1_sync_aresetn;
(* dont_touch = "true" *) logic slr2_sync_aresetn;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr0_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR1_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr1_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR2_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr2_sync_aresetn));

fifo_addr r_addr_fifo (
  .clk( aclk ),
  .srst( !aresetn ),
  .din( lcl_cl_sh_ddra_q.awaddr ),
  .wr_en( lcl_cl_sh_ddra_q.awvalid & lcl_cl_sh_ddra_q.awready ),
  .rd_en( ddra_sub_cnt ),
  .dout( r_addr ),
  .valid( r_addr_vld )
);

// process input logic
assign ddra_add_cnt = lcl_cl_sh_ddra_q.bvalid & lcl_cl_sh_ddra_q.bready;
assign ddra_sub_cnt = r_addr_vld & lcl_cl_sh_ddra_q.arready & input_cnt > 0;
always_ff @( posedge aclk or negedge aresetn ) begin
   if ( !aresetn ) begin
      input_cnt <= 0;
   end
   else begin
      if ( ddra_add_cnt & !ddra_sub_cnt ) begin
	 input_cnt <= input_cnt + 1;
      end
      if ( ddra_sub_cnt & !ddra_add_cnt ) begin
	 input_cnt <= input_cnt - 1;
      end
   end
end

fifo_addr w_addr_fifo (
  .clk( aclk ),
  .srst( !aresetn ),
  .din( r_addr ),
  .wr_en( ddra_sub_cnt ),
  .rd_en( cl_sh_ddr_q.awready & cl_sh_ddr_q.awvalid ),
  .dout( w_addr ),
  .valid( w_addr_vld )
);

// process output logic
assign w_last = ( w_cntr == 6'h0 );
assign ddrc_add_cnt = cl_sh_ddr_q.bvalid;
assign ddrc_sub_cnt = sh_cl_dma_pcis_q.arvalid & cl_sh_ddr_q.arready & output_available;
always_ff @( posedge aclk or negedge aresetn ) begin
   if ( !aresetn ) begin
      output_cnt <= 0;
      output_available <= 0;
      w_cntr <= 6'h3f;
      trans_cntr <= 0;
   end
   else begin
      if ( ddrc_add_cnt & !ddrc_sub_cnt ) begin
	 output_cnt <= output_cnt + 1;
      end
      if ( ddrc_sub_cnt & !ddrc_add_cnt ) begin
	 output_cnt <= output_cnt - 1;
      end
      if ( output_available & output_cnt < 1 ) begin
         output_available <= 0;
      end
      else if ( output_cnt >= 1 ) begin
         output_available <= 1;
      end
      if ( ddra_sub_cnt ) begin
	 trans_cntr <= trans_cntr + 1;
      end
      else if ( trans_cntr > 0 & cl_sh_ddr_q.awready & cl_sh_ddr_q.awvalid ) begin
	 trans_cntr <= trans_cntr - 1;
      end
      if ( fifo_out_vld & fifo_out_rdy ) begin
	 if ( w_last ) begin
            w_cntr <= 6'h3f;
	 end
	 else begin
	    w_cntr <= w_cntr - 1;
	 end
      end
   end
end

// INTERNAL CONNECTIONS
assign lcl_cl_sh_ddra_q.araddr = r_addr; //{40'b0, r_addr};
assign lcl_cl_sh_ddra_q.arid = 0;
assign lcl_cl_sh_ddra_q.arlen = 63;
assign lcl_cl_sh_ddra_q.arsize = 6;
assign lcl_cl_sh_ddra_q.arvalid = r_addr_vld;

assign fifo_in_bits = lcl_cl_sh_ddra_q.rdata;
assign lcl_cl_sh_ddra_q.rready = fifo_in_rdy;
assign fifo_in_vld = lcl_cl_sh_ddra_q.rvalid;

assign cl_sh_ddr_q.awaddr = w_addr; // {40'b0, w_addr};
assign cl_sh_ddr_q.awid = 0;
assign cl_sh_ddr_q.awlen = 63;
assign cl_sh_ddr_q.awsize = 6;
assign cl_sh_ddr_q.awvalid = w_addr_vld;

assign cl_sh_ddr_q.bready = 1'b1;

assign cl_sh_ddr_q.wdata = fifo_out_bits;
assign cl_sh_ddr_q.wid = 0;
assign cl_sh_ddr_q.wlast = w_last;
assign cl_sh_ddr_q.wstrb = 64'hffffffffffffffff;
assign cl_sh_ddr_q.wvalid = fifo_out_vld;
assign fifo_out_rdy = cl_sh_ddr_q.wready;

//----------------------------
// flop the dma_pcis interface input of CL
//----------------------------

   // AXI4 Register Slice for dma_pcis interface
   axi_register_slice PCI_AXL_REG_SLC (
       .aclk          (aclk),
       .aresetn       (slr0_sync_aresetn),
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

// EXTERNAL CONNECTIONS
assign sh_cl_dma_pcis_q.rid[15:6] = 10'b0 ;
assign sh_cl_dma_pcis_q.bid[15:6] = 10'b0 ;

assign cl_sh_ddr_q.araddr = {sh_cl_dma_pcis_q.araddr[63:37], 1'b0, sh_cl_dma_pcis_q.araddr[35:0]};
assign cl_sh_ddr_q.arid = sh_cl_dma_pcis_q.arid;
assign cl_sh_ddr_q.arlen = sh_cl_dma_pcis_q.arlen;
assign sh_cl_dma_pcis_q.arready = cl_sh_ddr_q.arready & output_available;
assign cl_sh_ddr_q.arsize = sh_cl_dma_pcis_q.arsize;
assign cl_sh_ddr_q.arvalid = sh_cl_dma_pcis_q.arvalid & output_available;
assign sh_cl_dma_pcis_q.rdata = cl_sh_ddr_q.rdata;
assign sh_cl_dma_pcis_q.rid[5:0] = cl_sh_ddr_q.rid;
assign sh_cl_dma_pcis_q.rlast = cl_sh_ddr_q.rlast;
assign cl_sh_ddr_q.rready = sh_cl_dma_pcis_q.rready;
assign sh_cl_dma_pcis_q.rresp = cl_sh_ddr_q.rresp;
assign sh_cl_dma_pcis_q.rvalid = cl_sh_ddr_q.rvalid;

assign lcl_cl_sh_ddra_q.awaddr = {sh_cl_dma_pcis_q.awaddr[63:37], 1'b0, sh_cl_dma_pcis_q.awaddr[35:0]};
assign lcl_cl_sh_ddra_q.awid = sh_cl_dma_pcis_q.awid;
assign lcl_cl_sh_ddra_q.awlen = sh_cl_dma_pcis_q.awlen;
assign sh_cl_dma_pcis_q.awready = lcl_cl_sh_ddra_q.awready;
assign lcl_cl_sh_ddra_q.awsize = sh_cl_dma_pcis_q.awsize;
assign lcl_cl_sh_ddra_q.awvalid = sh_cl_dma_pcis_q.awvalid;
assign sh_cl_dma_pcis_q.bid[5:0] = lcl_cl_sh_ddra_q.bid;
assign lcl_cl_sh_ddra_q.bready = sh_cl_dma_pcis_q.bready;
assign sh_cl_dma_pcis_q.bresp = lcl_cl_sh_ddra_q.bresp;
assign sh_cl_dma_pcis_q.bvalid = lcl_cl_sh_ddra_q.bvalid;
assign lcl_cl_sh_ddra_q.wdata = sh_cl_dma_pcis_q.wdata;
assign lcl_cl_sh_ddra_q.wid = sh_cl_dma_pcis_q.wid;
assign lcl_cl_sh_ddra_q.wlast = sh_cl_dma_pcis_q.wlast;
assign sh_cl_dma_pcis_q.wready = lcl_cl_sh_ddra_q.wready;
assign lcl_cl_sh_ddra_q.wstrb = sh_cl_dma_pcis_q.wstrb;
assign lcl_cl_sh_ddra_q.wvalid = sh_cl_dma_pcis_q.wvalid;

//----------------------------
// flop the output of interconnect for DDRC
//----------------------------
   axi_register_slice DDR_C_TST_AXI4_REG_SLC (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),

       .s_axi_awid     (cl_sh_ddr_q.awid),
       .s_axi_awaddr   ({cl_sh_ddr_q.awaddr[63:36], 2'b0, cl_sh_ddr_q.awaddr[33:0]}),
       .s_axi_awlen    (cl_sh_ddr_q.awlen),
       .s_axi_awsize   (cl_sh_ddr_q.awsize),
       .s_axi_awvalid  (cl_sh_ddr_q.awvalid),
       .s_axi_awready  (cl_sh_ddr_q.awready),
       .s_axi_wdata    (cl_sh_ddr_q.wdata),
       .s_axi_wstrb    (cl_sh_ddr_q.wstrb),
       .s_axi_wlast    (cl_sh_ddr_q.wlast),
       .s_axi_wvalid   (cl_sh_ddr_q.wvalid),
       .s_axi_wready   (cl_sh_ddr_q.wready),
       .s_axi_bid      (cl_sh_ddr_q.bid),
       .s_axi_bresp    (cl_sh_ddr_q.bresp),
       .s_axi_bvalid   (cl_sh_ddr_q.bvalid),
       .s_axi_bready   (cl_sh_ddr_q.bready),
       .s_axi_arid     (cl_sh_ddr_q.arid),
       .s_axi_araddr   ({cl_sh_ddr_q.araddr[63:36], 2'b0, cl_sh_ddr_q.araddr[33:0]}),
       .s_axi_arlen    (cl_sh_ddr_q.arlen),
       .s_axi_arsize   (cl_sh_ddr_q.arsize),
       .s_axi_arvalid  (cl_sh_ddr_q.arvalid),
       .s_axi_arready  (cl_sh_ddr_q.arready),
       .s_axi_rid      (cl_sh_ddr_q.rid),
       .s_axi_rdata    (cl_sh_ddr_q.rdata),
       .s_axi_rresp    (cl_sh_ddr_q.rresp),
       .s_axi_rlast    (cl_sh_ddr_q.rlast),
       .s_axi_rvalid   (cl_sh_ddr_q.rvalid),
       .s_axi_rready   (cl_sh_ddr_q.rready),
       .m_axi_awid     (cl_sh_ddr_q2.awid),
       .m_axi_awaddr   (cl_sh_ddr_q2.awaddr),
       .m_axi_awlen    (cl_sh_ddr_q2.awlen),
       .m_axi_awsize   (cl_sh_ddr_q2.awsize),
       .m_axi_awvalid  (cl_sh_ddr_q2.awvalid),
       .m_axi_awready  (cl_sh_ddr_q2.awready),
       .m_axi_wdata    (cl_sh_ddr_q2.wdata),
       .m_axi_wstrb    (cl_sh_ddr_q2.wstrb),
       .m_axi_wlast    (cl_sh_ddr_q2.wlast),
       .m_axi_wvalid   (cl_sh_ddr_q2.wvalid),
       .m_axi_wready   (cl_sh_ddr_q2.wready),
       .m_axi_bid      (cl_sh_ddr_q2.bid),
       .m_axi_bresp    (cl_sh_ddr_q2.bresp),
       .m_axi_bvalid   (cl_sh_ddr_q2.bvalid),
       .m_axi_bready   (cl_sh_ddr_q2.bready),
       .m_axi_arid     (cl_sh_ddr_q2.arid),
       .m_axi_araddr   (cl_sh_ddr_q2.araddr),
       .m_axi_arlen    (cl_sh_ddr_q2.arlen),
       .m_axi_arsize   (cl_sh_ddr_q2.arsize),
       .m_axi_arvalid  (cl_sh_ddr_q2.arvalid),
       .m_axi_arready  (cl_sh_ddr_q2.arready),
       .m_axi_rid      (cl_sh_ddr_q2.rid),
       .m_axi_rdata    (cl_sh_ddr_q2.rdata),
       .m_axi_rresp    (cl_sh_ddr_q2.rresp),
       .m_axi_rlast    (cl_sh_ddr_q2.rlast),
       .m_axi_rvalid   (cl_sh_ddr_q2.rvalid),
       .m_axi_rready   (cl_sh_ddr_q2.rready)
   );


//----------------------------
// flop the output of ATG/Scrubber for DDRC
//----------------------------

   axi_register_slice DDR_C_TST_AXI4_REG_SLC_1 (
     .aclk           (aclk),
     .aresetn        (slr1_sync_aresetn),

     .s_axi_awid     (cl_sh_ddr_q2.awid),
     .s_axi_awaddr   (cl_sh_ddr_q2.awaddr),
     .s_axi_awlen    (cl_sh_ddr_q2.awlen),
     .s_axi_awsize   (cl_sh_ddr_q2.awsize),
     .s_axi_awvalid  (cl_sh_ddr_q2.awvalid),
     .s_axi_awready  (cl_sh_ddr_q2.awready),
     .s_axi_wdata    (cl_sh_ddr_q2.wdata),
     .s_axi_wstrb    (cl_sh_ddr_q2.wstrb),
     .s_axi_wlast    (cl_sh_ddr_q2.wlast),
     .s_axi_wvalid   (cl_sh_ddr_q2.wvalid),
     .s_axi_wready   (cl_sh_ddr_q2.wready),
     .s_axi_bid      (cl_sh_ddr_q2.bid),
     .s_axi_bresp    (cl_sh_ddr_q2.bresp),
     .s_axi_bvalid   (cl_sh_ddr_q2.bvalid),
     .s_axi_bready   (cl_sh_ddr_q2.bready),
     .s_axi_arid     (cl_sh_ddr_q2.arid),
     .s_axi_araddr   (cl_sh_ddr_q2.araddr),
     .s_axi_arlen    (cl_sh_ddr_q2.arlen),
     .s_axi_arsize   (cl_sh_ddr_q2.arsize),
     .s_axi_arvalid  (cl_sh_ddr_q2.arvalid),
     .s_axi_arready  (cl_sh_ddr_q2.arready),
     .s_axi_rid      (cl_sh_ddr_q2.rid),
     .s_axi_rdata    (cl_sh_ddr_q2.rdata),
     .s_axi_rresp    (cl_sh_ddr_q2.rresp),
     .s_axi_rlast    (cl_sh_ddr_q2.rlast),
     .s_axi_rvalid   (cl_sh_ddr_q2.rvalid),
     .s_axi_rready   (cl_sh_ddr_q2.rready),

     .m_axi_awid     (cl_sh_ddr_bus.awid),
     .m_axi_awaddr   (cl_sh_ddr_bus.awaddr),
     .m_axi_awlen    (cl_sh_ddr_bus.awlen),
     .m_axi_awsize   (cl_sh_ddr_bus.awsize),
     .m_axi_awvalid  (cl_sh_ddr_bus.awvalid),
     .m_axi_awready  (cl_sh_ddr_bus.awready),
     .m_axi_wdata    (cl_sh_ddr_bus.wdata),
     .m_axi_wstrb    (cl_sh_ddr_bus.wstrb),
     .m_axi_wlast    (cl_sh_ddr_bus.wlast),
     .m_axi_wvalid   (cl_sh_ddr_bus.wvalid),
     .m_axi_wready   (cl_sh_ddr_bus.wready),
     .m_axi_bid      (cl_sh_ddr_bus.bid),
     .m_axi_bresp    (cl_sh_ddr_bus.bresp),
     .m_axi_bvalid   (cl_sh_ddr_bus.bvalid),
     .m_axi_bready   (cl_sh_ddr_bus.bready),
     .m_axi_arid     (cl_sh_ddr_bus.arid),
     .m_axi_araddr   (cl_sh_ddr_bus.araddr),
     .m_axi_arlen    (cl_sh_ddr_bus.arlen),
     .m_axi_arsize   (cl_sh_ddr_bus.arsize),
     .m_axi_arvalid  (cl_sh_ddr_bus.arvalid),
     .m_axi_arready  (cl_sh_ddr_bus.arready),
     .m_axi_rid      (cl_sh_ddr_bus.rid),
     .m_axi_rdata    (cl_sh_ddr_bus.rdata),
     .m_axi_rresp    (cl_sh_ddr_bus.rresp),
     .m_axi_rlast    (cl_sh_ddr_bus.rlast),
     .m_axi_rvalid   (cl_sh_ddr_bus.rvalid),
     .m_axi_rready   (cl_sh_ddr_bus.rready)
   );


//----------------------------
// flop the output of interconnect for DDRA
// back to back for SLR crossing
//----------------------------
   //back to back register slices for SLR crossing
   src_register_slice DDR_A_TST_AXI4_REG_SLC_1 (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddra_q.awid),
       .s_axi_awaddr   ({lcl_cl_sh_ddra_q.awaddr[63:36], 2'b0, lcl_cl_sh_ddra_q.awaddr[33:0]}),
       .s_axi_awlen    (lcl_cl_sh_ddra_q.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddra_q.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddra_q.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddra_q.awready),
       .s_axi_wdata    (lcl_cl_sh_ddra_q.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddra_q.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddra_q.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddra_q.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddra_q.wready),
       .s_axi_bid      (lcl_cl_sh_ddra_q.bid),
       .s_axi_bresp    (lcl_cl_sh_ddra_q.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddra_q.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddra_q.bready),
       .s_axi_arid     (lcl_cl_sh_ddra_q.arid),
       .s_axi_araddr   ({lcl_cl_sh_ddra_q.araddr[63:36], 2'b0, lcl_cl_sh_ddra_q.araddr[33:0]}),
       .s_axi_arlen    (lcl_cl_sh_ddra_q.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddra_q.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddra_q.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddra_q.arready),
       .s_axi_rid      (lcl_cl_sh_ddra_q.rid),
       .s_axi_rdata    (lcl_cl_sh_ddra_q.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddra_q.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddra_q.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddra_q.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddra_q.rready),
       .m_axi_awid     (lcl_cl_sh_ddra_q2.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddra_q2.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddra_q2.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddra_q2.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddra_q2.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddra_q2.awready),
       .m_axi_wdata    (lcl_cl_sh_ddra_q2.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddra_q2.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddra_q2.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddra_q2.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddra_q2.wready),
       .m_axi_bid      (lcl_cl_sh_ddra_q2.bid),
       .m_axi_bresp    (lcl_cl_sh_ddra_q2.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddra_q2.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddra_q2.bready),
       .m_axi_arid     (lcl_cl_sh_ddra_q2.arid),
       .m_axi_araddr   (lcl_cl_sh_ddra_q2.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddra_q2.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddra_q2.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddra_q2.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddra_q2.arready),
       .m_axi_rid      (lcl_cl_sh_ddra_q2.rid),
       .m_axi_rdata    (lcl_cl_sh_ddra_q2.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddra_q2.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddra_q2.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddra_q2.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddra_q2.rready)
       );
   dest_register_slice DDR_A_TST_AXI4_REG_SLC_2 (
       .aclk           (aclk),
       .aresetn        (slr2_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddra_q2.awid),
       .s_axi_awaddr   (lcl_cl_sh_ddra_q2.awaddr),
       .s_axi_awlen    (lcl_cl_sh_ddra_q2.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddra_q2.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddra_q2.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddra_q2.awready),
       .s_axi_wdata    (lcl_cl_sh_ddra_q2.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddra_q2.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddra_q2.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddra_q2.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddra_q2.wready),
       .s_axi_bid      (lcl_cl_sh_ddra_q2.bid),
       .s_axi_bresp    (lcl_cl_sh_ddra_q2.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddra_q2.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddra_q2.bready),
       .s_axi_arid     (lcl_cl_sh_ddra_q2.arid),
       .s_axi_araddr   (lcl_cl_sh_ddra_q2.araddr),
       .s_axi_arlen    (lcl_cl_sh_ddra_q2.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddra_q2.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddra_q2.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddra_q2.arready),
       .s_axi_rid      (lcl_cl_sh_ddra_q2.rid),
       .s_axi_rdata    (lcl_cl_sh_ddra_q2.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddra_q2.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddra_q2.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddra_q2.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddra_q2.rready),
       .m_axi_awid     (lcl_cl_sh_ddra.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddra.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddra.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddra.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddra.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddra.awready),
       .m_axi_wdata    (lcl_cl_sh_ddra.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddra.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddra.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddra.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddra.wready),
       .m_axi_bid      (lcl_cl_sh_ddra.bid),
       .m_axi_bresp    (lcl_cl_sh_ddra.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddra.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddra.bready),
       .m_axi_arid     (lcl_cl_sh_ddra.arid),
       .m_axi_araddr   (lcl_cl_sh_ddra.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddra.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddra.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddra.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddra.arready),
       .m_axi_rid      (lcl_cl_sh_ddra.rid),
       .m_axi_rdata    (lcl_cl_sh_ddra.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddra.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddra.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddra.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddra.rready)
       );

endmodule

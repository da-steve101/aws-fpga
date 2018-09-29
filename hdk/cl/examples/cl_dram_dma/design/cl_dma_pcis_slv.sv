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
    output         fifo_out_rdy,
    input          img_buffered
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

// send read request
reg arvalid;
reg [33:0] r_addr;
reg [33:0] written_until;

// send write request
reg [33:0] w_addr;
logic w_last;
reg w_done;
reg [1:0] w_addr_rdy;
reg [7:0] w_cntr;
reg [33:0] read_until;
reg running;
logic awvalid;
logic [71:0] written_addr;
logic [33:0] rd_request_addr;

reg [511:0] debug_data_reg;
//----------------------------
// End Internal signals
//----------------------------

//reset synchronizers
(* dont_touch = "true" *) logic slr0_sync_aresetn;
(* dont_touch = "true" *) logic slr1_sync_aresetn;
(* dont_touch = "true" *) logic slr2_sync_aresetn;
(* dont_touch = "true" *) logic rd_fifo_areset;
(* dont_touch = "true" *) logic wr_fifo_areset;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr0_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR1_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr1_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR2_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr2_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) RD_FIFO_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(!aresetn), .out_bus(rd_fifo_areset));
lib_pipe #(.WIDTH(1), .STAGES(4)) WR_FIFO_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(!aresetn), .out_bus(wr_fifo_areset));

// write transactions are alot of small writes
fifo_addr r_addr_fifo (
  .clk( aclk ),
  .srst( rd_fifo_areset ),
  .din( { 38'h0, lcl_cl_sh_ddra_q.awaddr[33:0] + ( ( lcl_cl_sh_ddra_q.awlen + 1 ) << 6 ) } ),
  .wr_en( lcl_cl_sh_ddra_q.awvalid & lcl_cl_sh_ddra_q.awready & lcl_cl_sh_ddra_q.awid[5:0] == 0),
  .rd_en( lcl_cl_sh_ddra_q.bvalid & lcl_cl_sh_ddra_q.bready & lcl_cl_sh_ddra_q.bid[5:0] == 0  ),
  .dout( written_addr ),
  .valid( wr_vld )
);

// process input logic
always_ff @( posedge aclk ) begin
   if ( !aresetn ) begin
      r_addr <= 0;
      arvalid <= 0;
      written_until <= 0;
   end
   else begin
      if ( lcl_cl_sh_ddra_q.bvalid & lcl_cl_sh_ddra_q.bready & lcl_cl_sh_ddra_q.bid[5:0] == 0 ) begin
	 written_until <= written_addr[33:0];
      end
      if ( lcl_cl_sh_ddra_q.arvalid & lcl_cl_sh_ddra_q.arready ) begin
	 r_addr <= r_addr + 4096;
	 arvalid <= 0;
      end
      if ( !arvalid & ( (written_until - r_addr >= 4096) | ( r_addr > 34'h3c0000000 & written_until < 34'h3fffffff ) ) ) begin
	 arvalid <= 1;
      end
   end
end

// process output logic
assign w_last = ( w_cntr[5:0] == 0 );
assign awvalid = w_addr_rdy > 0;
assign rd_request_addr = sh_cl_dma_pcis_q.araddr[33:0] + ( ( sh_cl_dma_pcis_q.arlen + 1 ) << 6 );
always_ff @( posedge aclk ) begin
   if ( !aresetn ) begin
      w_cntr <= 0;
      w_done <= 1;
      w_addr <= 0;
      read_until <= 0;
      w_addr_rdy <= 0;
      running <= 0;
      output_available <= 0;
   end
   else begin
      // read transactions are two reads for each 4096 written ... no idea why :/
      if ( cl_sh_ddr_q.bvalid ) begin
	 read_until <= read_until + 4096;
      end
      if ( cl_sh_ddr_q.arready & sh_cl_dma_pcis_q.arvalid & !output_available ) begin
	 // check the read addr
	 if ( sh_cl_dma_pcis_q.arid[5:0] == 0 ) begin
	    output_available <= ( read_until + 63 >= rd_request_addr ) | ( rd_request_addr > 34'h3c0000000 & read_until < 34'h3fffffff );
	 end
	 else begin
	    output_available <= 1;
	 end
      end
      if ( output_available ) begin
	 output_available <= 0;
      end
      // send two write transactions at once for whole image
      if ( cl_sh_ddr_q.awready & cl_sh_ddr_q.awvalid ) begin
	 w_addr_rdy <= w_addr_rdy - 1;
	 w_addr <= w_addr + 4096;
      end
      if ( w_done & img_buffered & w_addr_rdy == 0 ) begin
	 w_done <= 0;
	 running <= 1;
	 w_cntr <= 8'h7f;
	 w_addr_rdy <= 2;
      end // extra write address causing screw up? writing stats?
      if ( fifo_out_vld & fifo_out_rdy & !w_done ) begin
	 w_cntr <= w_cntr - 1;
	 if ( w_cntr == 0 ) begin
	    w_done <= 1;
	    running <= 0;
	 end
      end
   end
end

// INTERNAL CONNECTIONS
assign lcl_cl_sh_ddra_q.araddr = { 30'h0, r_addr };
assign lcl_cl_sh_ddra_q.arid = 1;
assign lcl_cl_sh_ddra_q.arlen = 8'h3f;
assign lcl_cl_sh_ddra_q.arsize = 6;
assign lcl_cl_sh_ddra_q.arvalid = arvalid;

assign fifo_in_bits = lcl_cl_sh_ddra_q.rdata;
assign lcl_cl_sh_ddra_q.rready = fifo_in_rdy;
assign fifo_in_vld = lcl_cl_sh_ddra_q.rvalid;

assign cl_sh_ddr_q.awaddr = { 30'h0, w_addr };
assign cl_sh_ddr_q.awid = 1;
assign cl_sh_ddr_q.awlen = 8'h3f;
assign cl_sh_ddr_q.awsize = 6;
assign cl_sh_ddr_q.awvalid = awvalid;

assign cl_sh_ddr_q.bready = 1'b1;

assign cl_sh_ddr_q.wdata = fifo_out_bits;
assign cl_sh_ddr_q.wid = 0;
assign cl_sh_ddr_q.wlast = w_last;
assign cl_sh_ddr_q.wstrb = 64'hffffffffffffffff;
assign cl_sh_ddr_q.wvalid = fifo_out_vld & running;
assign fifo_out_rdy = cl_sh_ddr_q.wready & running;

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
assign sh_cl_dma_pcis_q.rid[15:6] = 10'b0;
assign sh_cl_dma_pcis_q.bid[15:6] = 10'b0;
assign lcl_cl_sh_ddra_q.wid[15:6] = 10'b0;

assign cl_sh_ddr_q.araddr = {sh_cl_dma_pcis_q.araddr[63:37], 1'b0, sh_cl_dma_pcis_q.araddr[35:0]};
assign cl_sh_ddr_q.arid = sh_cl_dma_pcis_q.arid;
assign cl_sh_ddr_q.arlen = sh_cl_dma_pcis_q.arlen;
assign sh_cl_dma_pcis_q.arready = cl_sh_ddr_q.arready & ( output_available | sh_cl_dma_pcis_q.arid[5:0] != 0 );
assign cl_sh_ddr_q.arsize = sh_cl_dma_pcis_q.arsize;
assign cl_sh_ddr_q.arvalid = sh_cl_dma_pcis_q.arvalid & ( output_available | sh_cl_dma_pcis_q.arid[5:0] != 0 );
assign sh_cl_dma_pcis_q.rdata = cl_sh_ddr_q.rdata;
assign sh_cl_dma_pcis_q.rid[5:0] = cl_sh_ddr_q.rid;
assign sh_cl_dma_pcis_q.rlast = cl_sh_ddr_q.rlast;
assign cl_sh_ddr_q.rready = sh_cl_dma_pcis_q.rready;
assign sh_cl_dma_pcis_q.rresp = cl_sh_ddr_q.rresp;
assign sh_cl_dma_pcis_q.rvalid = cl_sh_ddr_q.rvalid;

assign lcl_cl_sh_ddra_q.awaddr = {sh_cl_dma_pcis_q.awaddr[63:37], 1'b0, sh_cl_dma_pcis_q.awaddr[35:0]};
assign lcl_cl_sh_ddra_q.awid[5:0] = sh_cl_dma_pcis_q.awid;
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

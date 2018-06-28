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
lib_pipe #(.WIDTH(1), .STAGES(4)) DMA_PCIS_SLV_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(dma_pcis_slv_sync_rst_n));

reg [511:0] mem_str[15:0];
reg 	    wrting;
reg 	    rding;
reg [3:0]   no_transfers_wrt;
reg [3:0]   no_transfers_rd;
reg [5:0] wid;
reg [5:0] rid;
reg 	  bid_vld;
reg 	  rd_vld;
reg 	  awrdy;
reg 	  arrdy;
reg 	  rlast;
reg 	  wlast;
reg [511:0] rdata;

assign sh_cl_dma_pcis_q.awready = awrdy;

// recv burst
assign sh_cl_dma_pcis_q.wready = wrting;
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
      wrting <= 0;
      rding <= 0;
      bid_vld <= 0;
      rd_vld <= 0;
      awrdy <= 0;
      arrdy <= 0;
      rlast <= 0;
      no_transfers_rd <= 0;
      no_transfers_wrt <= 0;
   end
   else
   begin
      if ( !wrting )
      begin
	 bid_vld <= 0;
	 if ( !sh_cl_dma_pcis_q.awvalid || !awrdy )
	 begin
	    awrdy <= 1;
	 end
	 else
	 begin
	    wrting <= 1;
	    no_transfers_wrt <= sh_cl_dma_pcis_q.awlen;
	    awrdy <= 0;
	 end
      end
      else
      begin
	 if ( sh_cl_dma_pcis_q.wvalid )
	 begin
	    wid <= sh_cl_dma_pcis_q.awid[5:0];
	    mem_str[no_transfers_wrt] <= sh_cl_dma_pcis_q.wdata;
	    no_transfers_wrt <= no_transfers_wrt - 1;
	    if ( sh_cl_dma_pcis_q.wlast & !wlast )
	    begin
	       wlast <= 1;
	    end
	 end
	 if ( wlast )
	 begin
	    wrting <= 0;
	    bid_vld <= 1;
	    wlast <= 0;
	 end
      end
      if ( !rding )
      begin
	 rlast <= 0;
	 rd_vld <= 0;
	 if ( !sh_cl_dma_pcis_q.arvalid || !arrdy )
	 begin
	    arrdy <= 1;
	 end
	 else
	 begin
	    rding <= 1;
	    no_transfers_rd <= sh_cl_dma_pcis_q.arlen;
	    rid <= sh_cl_dma_pcis_q.arid[5:0];
	    arrdy <= 0;
	 end
      end
      else if ( sh_cl_dma_pcis_q.rready )
      begin
	 rd_vld <= 1;
	 rdata <= mem_str[no_transfers_rd];
	 no_transfers_rd <= no_transfers_rd - 1;
	 if ( no_transfers_rd == 0 )
	 begin
	    rlast <= 1;
	    rding <= 0;
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

endmodule

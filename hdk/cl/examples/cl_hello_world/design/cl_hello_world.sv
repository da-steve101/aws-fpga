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

module cl_hello_world

(
   `include "cl_ports.vh" // Fixed port definition

);

`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_hello_world_defines.vh" // CL Defines for cl_hello_world

logic rst_main_n_sync;

//--------------------------------------------0
// Start with Tie-Off of Unused Interfaces
//---------------------------------------------
// the developer should use the next set of `include
// to properly tie-off any unused interface
// The list is put in the top of the module
// to avoid cases where developer may forget to
// remove it from the end of the file

`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
// use pcim and dma pcis
// `include "unused_pcim_template.inc"
// `include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"

//-------------------------------------------------
// Wires
//-------------------------------------------------
  logic        arvalid_q;
  logic [31:0] araddr_q;
  logic [31:0] hello_world_q_byte_swapped;

//-------------------------------------------------
// ID Values (cl_hello_world_defines.vh)
//-------------------------------------------------
  assign cl_sh_id0[31:0] = `CL_SH_ID0;
  assign cl_sh_id1[31:0] = `CL_SH_ID1;

// 512b input bus
   axi_bus_t sh_cl_dma_pcis_bus();

// 512b output bus
   axi_bus_t cl_sh_pcim_bus();

   logic       clk;
   assign clk = clk_main_a0;
//-------------------------------------------------
// Reset Synchronization
//-------------------------------------------------
logic pre_sync_rst_n;

always_ff @(negedge rst_main_n or posedge clk_main_a0)
   if (!rst_main_n)
   begin
      pre_sync_rst_n  <= 0;
      rst_main_n_sync <= 0;
   end
   else
   begin
      pre_sync_rst_n  <= 1;
      rst_main_n_sync <= pre_sync_rst_n;
   end

//-------------------------------------------------
// PCIe OCL AXI-L (SH to CL) Timing Flops
//-------------------------------------------------

  // Write address
  logic        sh_ocl_awvalid_q;
  logic [31:0] sh_ocl_awaddr_q;
  logic        ocl_sh_awready_q;

  // Write data
  logic        sh_ocl_wvalid_q;
  logic [31:0] sh_ocl_wdata_q;
  logic [ 3:0] sh_ocl_wstrb_q;
  logic        ocl_sh_wready_q;

  // Write response
  logic        ocl_sh_bvalid_q;
  logic [ 1:0] ocl_sh_bresp_q;
  logic        sh_ocl_bready_q;

  // Read address
  logic        sh_ocl_arvalid_q;
  logic [31:0] sh_ocl_araddr_q;
  logic        ocl_sh_arready_q;

  // Read data/response
  logic        ocl_sh_rvalid_q;
  logic [31:0] ocl_sh_rdata_q;
  logic [ 1:0] ocl_sh_rresp_q;
  logic        sh_ocl_rready_q;

  axi_register_slice_light AXIL_OCL_REG_SLC (
   .aclk          (clk_main_a0),
   .aresetn       (rst_main_n_sync),
   .s_axi_awaddr  (sh_ocl_awaddr),
   .s_axi_awprot   (2'h0),
   .s_axi_awvalid (sh_ocl_awvalid),
   .s_axi_awready (ocl_sh_awready),
   .s_axi_wdata   (sh_ocl_wdata),
   .s_axi_wstrb   (sh_ocl_wstrb),
   .s_axi_wvalid  (sh_ocl_wvalid),
   .s_axi_wready  (ocl_sh_wready),
   .s_axi_bresp   (ocl_sh_bresp),
   .s_axi_bvalid  (ocl_sh_bvalid),
   .s_axi_bready  (sh_ocl_bready),
   .s_axi_araddr  (sh_ocl_araddr),
   .s_axi_arvalid (sh_ocl_arvalid),
   .s_axi_arready (ocl_sh_arready),
   .s_axi_rdata   (ocl_sh_rdata),
   .s_axi_rresp   (ocl_sh_rresp),
   .s_axi_rvalid  (ocl_sh_rvalid),
   .s_axi_rready  (sh_ocl_rready),
   .m_axi_awaddr  (sh_ocl_awaddr_q),
   .m_axi_awprot  (),
   .m_axi_awvalid (sh_ocl_awvalid_q),
   .m_axi_awready (ocl_sh_awready_q),
   .m_axi_wdata   (sh_ocl_wdata_q),
   .m_axi_wstrb   (sh_ocl_wstrb_q),
   .m_axi_wvalid  (sh_ocl_wvalid_q),
   .m_axi_wready  (ocl_sh_wready_q),
   .m_axi_bresp   (ocl_sh_bresp_q),
   .m_axi_bvalid  (ocl_sh_bvalid_q),
   .m_axi_bready  (sh_ocl_bready_q),
   .m_axi_araddr  (sh_ocl_araddr_q),
   .m_axi_arvalid (sh_ocl_arvalid_q),
   .m_axi_arready (ocl_sh_arready_q),
   .m_axi_rdata   (ocl_sh_rdata_q),
   .m_axi_rresp   (ocl_sh_rresp_q),
   .m_axi_rvalid  (ocl_sh_rvalid_q),
   .m_axi_rready  (sh_ocl_rready_q)
  );

//--------------------------------------------------------------
// PCIe OCL AXI-L Slave Accesses (accesses from PCIe AppPF BAR0)
//--------------------------------------------------------------
// Only supports single-beat accesses.

   logic        awvalid;
   logic [31:0] awaddr;
   logic        wvalid;
   logic [31:0] wdata;
   logic [3:0]  wstrb;
   logic        bready;
   logic        arvalid;
   logic [31:0] araddr;
   logic        rready;

   logic        awready;
   logic        wready;
   logic        bvalid;
   logic [1:0]  bresp;
   logic        arready;
   logic        rvalid;
   logic [31:0] rdata;
   logic [1:0]  rresp;

   // Inputs
   assign awvalid         = sh_ocl_awvalid_q;
   assign awaddr[31:0]    = sh_ocl_awaddr_q;
   assign wvalid          = sh_ocl_wvalid_q;
   assign wdata[31:0]     = sh_ocl_wdata_q;
   assign wstrb[3:0]      = sh_ocl_wstrb_q;
   assign bready          = sh_ocl_bready_q;
   assign arvalid         = sh_ocl_arvalid_q;
   assign araddr[31:0]    = sh_ocl_araddr_q;
   assign rready          = sh_ocl_rready_q;

   // Outputs
   assign ocl_sh_awready_q = awready;
   assign ocl_sh_wready_q  = wready;
   assign ocl_sh_bvalid_q  = bvalid;
   assign ocl_sh_bresp_q   = bresp[1:0];
   assign ocl_sh_arready_q = arready;
   assign ocl_sh_rvalid_q  = rvalid;
   assign ocl_sh_rdata_q   = rdata;
   assign ocl_sh_rresp_q   = rresp[1:0];

// Write Request
logic        wr_active;
logic [31:0] wr_addr;

always_ff @(posedge clk_main_a0)
  if (!rst_main_n_sync) begin
     wr_active <= 0;
     wr_addr   <= 0;
  end
  else begin
     wr_active <=  wr_active && bvalid  && bready ? 1'b0     :
                  ~wr_active && awvalid           ? 1'b1     :
                                                    wr_active;
     wr_addr <= awvalid && ~wr_active ? awaddr : wr_addr     ;
  end

assign awready = ~wr_active;
assign wready  =  wr_active && wvalid;

// Write Response
always_ff @(posedge clk_main_a0)
  if (!rst_main_n_sync)
    bvalid <= 0;
  else
    bvalid <=  bvalid &&  bready           ? 1'b0  :
                         ~bvalid && wready ? 1'b1  :
                                             bvalid;
assign bresp = 0;

// Read Request
always_ff @(posedge clk_main_a0)
   if (!rst_main_n_sync) begin
      arvalid_q <= 0;
      araddr_q  <= 0;
   end
   else begin
      arvalid_q <= arvalid;
      araddr_q  <= arvalid ? araddr : araddr_q;
   end

assign arready = !arvalid_q && !rvalid;

// Read Response
always_ff @(posedge clk_main_a0)
   if (!rst_main_n_sync)
   begin
      rvalid <= 0;
      rdata  <= 0;
      rresp  <= 0;
   end
   else if (rvalid && rready)
   begin
      rvalid <= 0;
      rdata  <= 0;
      rresp  <= 0;
   end
   else if (arvalid_q)
   begin
      rvalid <= 1;
      rdata  <= (araddr_q == `HELLO_WORLD_REG_ADDR) ? hello_world_q:
                (araddr_q == `VLED_REG_ADDR       ) ? 32'b0 : `UNIMPLEMENTED_REG_VALUE;
      rresp  <= 0;
   end

//-------------------------------------------------
// Hello World Register
//-------------------------------------------------
// When read it, returns the byte-flipped value.

always_ff @(posedge clk_main_a0)
   if (!rst_main_n_sync) begin                    // Reset
      hello_world_q[31:0] <= 32'h0000_0000;
   end
   else if (wready & (wr_addr == `HELLO_WORLD_REG_ADDR)) begin
      hello_world_q[31:0] <= wdata[31:0];
   end
   else begin                                // Hold Value
      hello_world_q[31:0] <= hello_world_q[31:0];
   end

//-------------------------------------------
// Tie-Off Unused Global Signals
//-------------------------------------------
// The functionality for these signals is TBD so they can can be tied-off.
  assign cl_sh_status0[31:0] = 32'h0;
  assign cl_sh_status1[31:0] = 32'h0;

// buffer the output AXI
axi_register_slice PCI_AXI4_REG_SLC
(
 .aclk           (aclk),
 .aresetn        (aresetn),

 .s_axi_awid     ({7'b0, cl_sh_pcim_bus.awid[8:0]}),
 .s_axi_awaddr   (cl_sh_pcim_bus.awaddr),
 .s_axi_awlen    (cl_sh_pcim_bus.awlen),
 .s_axi_awsize   (3'h6),
 .s_axi_awvalid  (cl_sh_pcim_bus.awvalid),
 .s_axi_awready  (cl_sh_pcim_bus.awready),
 .s_axi_wdata    (cl_sh_pcim_bus.wdata),
 .s_axi_wstrb    (cl_sh_pcim_bus.wstrb),
 .s_axi_wlast    (cl_sh_pcim_bus.wlast),
 .s_axi_wvalid   (cl_sh_pcim_bus.wvalid),
 .s_axi_wready   (cl_sh_pcim_bus.wready),
 .s_axi_bid      (cl_sh_pcim_bus.bid),
 .s_axi_bresp    (cl_sh_pcim_bus.bresp),
 .s_axi_bvalid   (cl_sh_pcim_bus.bvalid),
 .s_axi_bready   (cl_sh_pcim_bus.bready),
 .s_axi_arid     ({7'b0, cl_sh_pcim_bus.arid[8:0]}),
 .s_axi_araddr   (cl_sh_pcim_bus.araddr),
 .s_axi_arlen    (cl_sh_pcim_bus.arlen),
 .s_axi_arsize   (3'h6),
 .s_axi_arvalid  (cl_sh_pcim_bus.arvalid),
 .s_axi_arready  (cl_sh_pcim_bus.arready),
 .s_axi_rid      (cl_sh_pcim_bus.rid),
 .s_axi_rdata    (cl_sh_pcim_bus.rdata),
 .s_axi_rresp    (cl_sh_pcim_bus.rresp),
 .s_axi_rlast    (cl_sh_pcim_bus.rlast),
 .s_axi_rvalid   (cl_sh_pcim_bus.rvalid),
 .s_axi_rready   (cl_sh_pcim_bus.rready),

 .m_axi_awid     (cl_sh_pcim_awid),
 .m_axi_awaddr   (cl_sh_pcim_awaddr),
 .m_axi_awlen    (cl_sh_pcim_awlen),
 .m_axi_awsize   (cl_sh_pcim_awsize),
 .m_axi_awvalid  (cl_sh_pcim_awvalid),
 .m_axi_awready  (cl_sh_pcim_awready),
 .m_axi_wdata    (cl_sh_pcim_wdata),
 .m_axi_wstrb    (cl_sh_pcim_wstrb),
 .m_axi_wlast    (cl_sh_pcim_wlast),
 .m_axi_wvalid   (cl_sh_pcim_wvalid),
 .m_axi_wready   (cl_sh_pcim_wready),
 .m_axi_bid      (cl_sh_pcim_bid),
 .m_axi_bresp    (cl_sh_pcim_bresp),
 .m_axi_bvalid   (cl_sh_pcim_bvalid),
 .m_axi_bready   (cl_sh_pcim_bready),
 .m_axi_arid     (cl_sh_pcim_arid),
 .m_axi_araddr   (cl_sh_pcim_araddr),
 .m_axi_arlen    (cl_sh_pcim_arlen),
 .m_axi_arsize   (cl_sh_pcim_arsize),
 .m_axi_arvalid  (cl_sh_pcim_arvalid),
 .m_axi_arready  (cl_sh_pcim_arready),
 .m_axi_rid      (cl_sh_pcim_rid),
 .m_axi_rdata    (cl_sh_pcim_rdata),
 .m_axi_rresp    (cl_sh_pcim_rresp),
 .m_axi_rlast    (cl_sh_pcim_rlast),
 .m_axi_rvalid   (cl_sh_pcim_rvalid),
 .m_axi_rready   (cl_sh_pcim_rready)
);

// buffer the input AXI
axi_register_slice PCI_AXL_REG_SLC
(
 .aclk          (aclk),
 .aresetn       (slr0_sync_aresetn),

 .s_axi_awid    (sh_cl_dma_pcis_awid),
 .s_axi_awaddr  (sh_cl_dma_pcis_awaddr),
 .s_axi_awlen   (sh_cl_dma_pcis_awlen),
 .s_axi_awvalid (sh_cl_dma_pcis_awvalid),
 .s_axi_awsize  (sh_cl_dma_pcis_awsize),
 .s_axi_awready (sh_cl_dma_pcis_awready),
 .s_axi_wdata   (sh_cl_dma_pcis_wdata),
 .s_axi_wstrb   (sh_cl_dma_pcis_wstrb),
 .s_axi_wlast   (sh_cl_dma_pcis_wlast),
 .s_axi_wvalid  (sh_cl_dma_pcis_wvalid),
 .s_axi_wready  (sh_cl_dma_pcis_wready),
 .s_axi_bid     (sh_cl_dma_pcis_bid),
 .s_axi_bresp   (sh_cl_dma_pcis_bresp),
 .s_axi_bvalid  (sh_cl_dma_pcis_bvalid),
 .s_axi_bready  (sh_cl_dma_pcis_bready),
 .s_axi_arid    (sh_cl_dma_pcis_arid),
 .s_axi_araddr  (sh_cl_dma_pcis_araddr),
 .s_axi_arlen   (sh_cl_dma_pcis_arlen),
 .s_axi_arvalid (sh_cl_dma_pcis_arvalid),
 .s_axi_arsize  (sh_cl_dma_pcis_arsize),
 .s_axi_arready (sh_cl_dma_pcis_arready),
 .s_axi_rid     (sh_cl_dma_pcis_rid),
 .s_axi_rdata   (sh_cl_dma_pcis_rdata),
 .s_axi_rresp   (sh_cl_dma_pcis_rresp),
 .s_axi_rlast   (sh_cl_dma_pcis_rlast),
 .s_axi_rvalid  (sh_cl_dma_pcis_rvalid),
 .s_axi_rready  (sh_cl_dma_pcis_rready),

 .m_axi_awid    (sh_cl_dma_pcis_bus.awid),
 .m_axi_awaddr  (sh_cl_dma_pcis_bus.awaddr),
 .m_axi_awlen   (sh_cl_dma_pcis_bus.awlen),
 .m_axi_awvalid (sh_cl_dma_pcis_bus.awvalid),
 .m_axi_awsize  (sh_cl_dma_pcis_bus.awsize),
 .m_axi_awready (sh_cl_dma_pcis_bus.awready),
 .m_axi_wdata   (sh_cl_dma_pcis_bus.wdata),
 .m_axi_wstrb   (sh_cl_dma_pcis_bus.wstrb),
 .m_axi_wvalid  (sh_cl_dma_pcis_bus.wvalid),
 .m_axi_wlast   (sh_cl_dma_pcis_bus.wlast),
 .m_axi_wready  (sh_cl_dma_pcis_bus.wready),
 .m_axi_bresp   (sh_cl_dma_pcis_bus.bresp),
 .m_axi_bvalid  (sh_cl_dma_pcis_bus.bvalid),
 .m_axi_bid     (sh_cl_dma_pcis_bus.bid),
 .m_axi_bready  (sh_cl_dma_pcis_bus.bready),
 .m_axi_arid    (sh_cl_dma_pcis_bus.arid),
 .m_axi_araddr  (sh_cl_dma_pcis_bus.araddr),
 .m_axi_arlen   (sh_cl_dma_pcis_bus.arlen),
 .m_axi_arsize  (sh_cl_dma_pcis_bus.arsize),
 .m_axi_arvalid (sh_cl_dma_pcis_bus.arvalid),
 .m_axi_arready (sh_cl_dma_pcis_bus.arready),
 .m_axi_rid     (sh_cl_dma_pcis_bus.rid),
 .m_axi_rdata   (sh_cl_dma_pcis_bus.rdata),
 .m_axi_rresp   (sh_cl_dma_pcis_bus.rresp),
 .m_axi_rlast   (sh_cl_dma_pcis_bus.rlast),
 .m_axi_rvalid  (sh_cl_dma_pcis_bus.rvalid),
 .m_axi_rready  (sh_cl_dma_pcis_bus.rready)
);

// cnn wiring
   logic [63:0] fifo_in_bits;
   logic 	fifo_in_valid;
   logic 	fifo_in_ready;

   logic [63:0] data_in_bits;
   logic 	data_in_valid;
   logic 	data_in_ready;

   logic [63:0] data_out_bits;
   logic 	data_out_valid;
   logic 	data_out_ready;
   
   logic [63:0] fifo_out_bits;
   logic 	fifo_out_valid;
   logic 	fifo_out_ready;

// Read the data from input into a AXI Data Width Converter ( xilinx IP ) using sh_cl_dma_pcis_bus
// Convert from 512 to 64 bits
axi_dwidth_converter_512_to_64 AXI_DWIDTH_TO_64
(
 .aclk( clk ),
 .aresetn( slr0_sync_aresetn ),

 .s_axis_tvalid( sh_cl_dma_pcis_bus.wvalid ),
 .s_axis_tready( sh_cl_dma_pcis_bus.wready ),
 .s_axis_tdata( sh_cl_dma_pcis_bus.wdata ),

 .m_axis_tvalid( fifo_in_valid ),
 .m_axis_tready( fifo_in_ready ),
 .m_axis_tdata( fifo_in_bits )
);
   
// Put the 64 bits into a AXI Data FIFO (xilinx ip)
axi_data_fifo_sync_64 AXI_DATA_FIFO_IN
(
 .s_axis_aclk( clk ),
 .s_axis_aresetn( slr0_sync_aresetn ),

 .s_axis_tvalid( fifo_in_valid ),
 .s_axis_tready( fifo_in_ready ),
 .s_axis_tdata( fifo_in_bits ),

 .m_axis_tvalid( data_in_valid ),
 .m_axis_tready( data_in_ready ),
 .m_axis_tdata( data_in_bits )
);
   
// Insert CNN here ...
assign data_out_valid = data_in_valid;
assign data_out_bits = data_in_bits;
assign data_in_ready = data_out_ready;

axi_data_fifo_sync_64 AXI_DATA_FIFO_IN
(
 .s_axis_aclk( clk ),
 .s_axis_aresetn( slr0_sync_aresetn ),

 .s_axis_tvalid( data_out_valid ),
 .s_axis_tready( data_out_ready ),
 .s_axis_tdata( data_out_bits ),

 .m_axis_tvalid( fifo_out_valid ),
 .m_axis_tready( fifo_out_ready ),
 .m_axis_tdata( fifo_out_bits )
);
   
// Read the data from the AXI Data FIFO into a AXI Data Width Converter( Xilinx IP )
// Convert from 64 bits to 512 bits
// Send to the output using cl_sh_pcim_bus
axi_dwidth_converter_64_to_512 AXI_DWIDTH_TO_512
(
 .aclk( clk ),
 .aresetn( slr0_sync_aresetn ),

 .s_axis_tvalid( fifo_out_valid ),
 .s_axis_tready( fifo_out_ready ),
 .s_axis_tdata( fifo_out_bits ),

 .m_axis_tvalid( cl_sh_pcim_bus.wvalid ),
 .m_axis_tready( cl_sh_pcim_bus.wready ),
 .m_axis_tdata( cl_sh_pcim_bus.wdata )
);

// connect the rest of cl_sh_pcim_bus wires

endmodule

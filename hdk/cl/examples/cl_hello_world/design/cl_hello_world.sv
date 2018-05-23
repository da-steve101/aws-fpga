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

`include "unused_sh_bar1_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_sh_ocl_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_pcim_template.inc"
// `include "unused_dma_pcis_template.inc"
`include "unused_flr_template.inc"
`include "unused_ddr_c_template.inc"

logic       clk;
logic       rst_n;
assign cl_sh_id0[31:0] = `CL_SH_ID0;
assign cl_sh_id1[31:0] = `CL_SH_ID1;
assign cl_sh_status0[31:0] = 32'h0;
assign cl_sh_status1[31:0] = 32'h0;

// 512b input bus
axi_bus_t sh_cl_dma_pcis_bus();

assign clk = clk_main_a0;
assign rst_n = rst_main_n;

// buffer the input AXI
axi_register_slice PCI_AXL_REG_SLC
(
 .aclk          (clk),
 .aresetn       (rst_n),

 .s_axi_awid    (sh_cl_dma_pcis_awid),
 .s_axi_awaddr  (sh_cl_dma_pcis_awaddr),
 .s_axi_awlen   (sh_cl_dma_pcis_awlen),
 .s_axi_awvalid (sh_cl_dma_pcis_awvalid),
 .s_axi_awsize  (sh_cl_dma_pcis_awsize),
 .s_axi_awready (cl_sh_dma_pcis_awready),
 .s_axi_wdata   (sh_cl_dma_pcis_wdata),
 .s_axi_wstrb   (sh_cl_dma_pcis_wstrb),
 .s_axi_wlast   (sh_cl_dma_pcis_wlast),
 .s_axi_wvalid  (sh_cl_dma_pcis_wvalid),
 .s_axi_wready  (cl_sh_dma_pcis_wready),
 .s_axi_bid     (cl_sh_dma_pcis_bid),
 .s_axi_bresp   (cl_sh_dma_pcis_bresp),
 .s_axi_bvalid  (cl_sh_dma_pcis_bvalid),
 .s_axi_bready  (sh_cl_dma_pcis_bready),
 .s_axi_arid    (sh_cl_dma_pcis_arid),
 .s_axi_araddr  (sh_cl_dma_pcis_araddr),
 .s_axi_arlen   (sh_cl_dma_pcis_arlen),
 .s_axi_arvalid (sh_cl_dma_pcis_arvalid),
 .s_axi_arsize  (sh_cl_dma_pcis_arsize),
 .s_axi_arready (cl_sh_dma_pcis_arready),
 .s_axi_rid     (cl_sh_dma_pcis_rid),
 .s_axi_rdata   (cl_sh_dma_pcis_rdata),
 .s_axi_rresp   (cl_sh_dma_pcis_rresp),
 .s_axi_rlast   (cl_sh_dma_pcis_rlast),
 .s_axi_rvalid  (cl_sh_dma_pcis_rvalid),
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
   logic [15:0] data_out_bits_0;
   logic [15:0] data_out_bits_1;
   logic [15:0] data_out_bits_2;
   logic [15:0] data_out_bits_3;
   logic 	data_out_valid;
   logic 	data_out_ready;
   
   logic [63:0] fifo_out_bits;
   logic 	fifo_out_valid;
   logic 	fifo_out_ready;

   logic [511:0] axi_out_bits;
   logic 	 axi_out_valid;
   logic 	 axi_out_ready;


// Read the data from input into a AXI Data Width Converter ( xilinx IP ) using sh_cl_dma_pcis_bus
// Convert from 512 to 64 bits
axi_dwidth_converter_512_to_64 AXI_DWIDTH_TO_64
(
 .aclk( clk ),
 .aresetn( rst_n ),

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
 .s_axis_aresetn( rst_n ),

 .s_axis_tvalid( fifo_in_valid ),
 .s_axis_tready( fifo_in_ready ),
 .s_axis_tdata( fifo_in_bits ),

 .m_axis_tvalid( data_in_valid ),
 .m_axis_tready( data_in_ready ),
 .m_axis_tdata( data_in_bits )
);
   
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
 .reset( !rst_n ),
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
`endif // IMPLEMENT_CNN

axi_data_fifo_sync_64 AXI_DATA_FIFO_OUT
(
 .s_axis_aclk( clk ),
 .s_axis_aresetn( rst_n ),

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
 .aresetn( rst_n ),

 .s_axis_tvalid( fifo_out_valid ),
 .s_axis_tready( fifo_out_ready ),
 .s_axis_tdata( fifo_out_bits ),

 .m_axis_tvalid( axi_out_valid ),
 .m_axis_tready( axi_out_ready ),
 .m_axis_tdata( axi_out_bits )
);

logic [5:0] 	 img_cntr;

always_ff @(posedge clk)
  if ( !rst_n )
    begin
       img_cntr <= 0;
    end
  else
    begin
       if ( axi_out_valid & axi_out_ready )
	 begin
	    img_cntr <= img_cntr + 1;
	 end
  end

assign sh_cl_dma_pcis_bus.awready = 1;
assign sh_cl_dma_pcis_bus.bid = 0;
assign sh_cl_dma_pcis_bus.bresp = 0;
assign sh_cl_dma_pcis_bus.bvalid = 0;
assign sh_cl_dma_pcis_bus.arready = 1;
assign sh_cl_dma_pcis_bus.rid = 1;
assign sh_cl_dma_pcis_bus.rdata = axi_out_bits;
assign sh_cl_dma_pcis_bus.rresp = 0;
assign sh_cl_dma_pcis_bus.rlast = ( img_cntr == 6'h3f ); // indicate last bit
assign sh_cl_dma_pcis_bus.rvalid = axi_out_valid;
assign axi_out_ready = sh_cl_dma_pcis_bus.rready;

endmodule

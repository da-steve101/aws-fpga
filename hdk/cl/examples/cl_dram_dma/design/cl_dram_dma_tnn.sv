
module cl_dram_dma_tnn
(
    input 	   aclk,
    input 	   aresetn,
    input [511:0] fifo_in_bits,
    input 	   fifo_in_vld,
    output 	   fifo_in_rdy,
    output [511:0]  fifo_out_bits,
    output	   fifo_out_vld,
    input 	   fifo_out_rdy
);

assign fifo_out_bits = fifo_in_bits;
assign fifo_out_vld = fifo_in_vld;
assign fifo_in_rdy = fifo_out_rdy;
   
endmodule

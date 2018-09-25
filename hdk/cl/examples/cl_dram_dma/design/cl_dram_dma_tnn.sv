
module cl_dram_dma_tnn
(
    input 	   aclk,
    input 	   aresetn,
    input [511:0] fifo_in_bits,
    input 	   fifo_in_vld,
    output 	   fifo_in_rdy,
    output [511:0]  fifo_out_bits,
    output	   fifo_out_vld,
    input 	   fifo_out_rdy,
    output         img_buffered
);

logic output_fifo_full, input_fifo_full, img_done_n, img_buffered_n;

logic [511:0] data_in_bits;
logic data_in_vld;
logic data_in_rdy;

logic [511:0] data_out_bits;
logic data_out_vld;
logic data_out_rdy;

assign fifo_in_rdy = !input_fifo_full;
assign data_out_rdy = !output_fifo_full;
assign data_out_bits = data_in_bits;
assign data_out_vld = data_in_vld;
assign data_in_rdy = data_out_rdy;
assign img_buffered = !img_done_n;

fifo_sync_512 input_fifo
(
 .clk( aclk ),
 .srst( !aresetn ),
 .din( fifo_in_bits ),
 .wr_en( fifo_in_vld & fifo_in_rdy ),
 .full( input_fifo_full ),
 .rd_en( data_in_rdy & data_in_vld ),
 .valid( data_in_vld ),
 .dout( data_in_bits ),
 .prog_empty( img_buffered_n )
);

fifo_sync_512 output_fifo
(
 .clk( aclk ),
 .srst( !aresetn ),
 .din( data_out_bits ),
 .wr_en( data_out_vld & data_out_rdy ),
 .full( output_fifo_full ),
 .rd_en( fifo_out_rdy & fifo_out_vld ),
 .valid( fifo_out_vld ),
 .dout( fifo_out_bits ),
 .prog_empty( img_done_n )
);

endmodule

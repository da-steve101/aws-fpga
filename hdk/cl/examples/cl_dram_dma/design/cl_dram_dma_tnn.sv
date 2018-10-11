
module cl_dram_dma_tnn
(
    input 	   aclk,
    input          clk_a1,
    input 	   aresetn,
    input [511:0]  fifo_in_bits,
    input 	   fifo_in_vld,
    output 	   fifo_in_rdy,
    output [511:0] fifo_out_bits,
    output 	   fifo_out_vld,
    input 	   fifo_out_rdy,
    output 	   img_buffered
);

logic output_fifo_full, input_fifo_full, img_done_n, img_buffered_n;

logic [511:0] data_in_bits;
logic data_in_vld;
logic data_in_rdy;

logic [63:0] res_bits;
logic res_vld;

logic [63:0] image_pixel;
reg [63:0] image_pixel_reg;
logic image_vld;
reg image_vld_reg;

logic [511:0] data_out_bits;
logic data_out_vld;
logic data_out_rdy;

(* dont_touch = "true" *) logic rst_n_a1;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(clk_a1), .rst_n(1'b1), .in_bus(aresetn), .out_bus(rst_n_a1));

assign fifo_in_rdy = !input_fifo_full;
assign data_out_rdy = !output_fifo_full;
assign img_buffered = !img_done_n;

fifo_async_512_input input_fifo
(
 .wr_clk( aclk ),
 .rd_clk( clk_a1 ),
 .srst( !aresetn ),
 .din( fifo_in_bits ),
 .wr_en( fifo_in_vld & fifo_in_rdy ),
 .full( input_fifo_full ),
 .rd_en( data_in_rdy & data_in_vld ),
 .valid( data_in_vld ),
 .dout( data_in_bits ),
 .prog_empty( img_buffered_n )
);


axis_dwidth_converter_512_to_64 downsizer
(
 .aclk( clk_a1 ),
 .aresetn( rst_n_a1 ),
 .s_axis_tvalid( data_in_vld ),
 .s_axis_tready( data_in_rdy ),
 .s_axis_tdata( data_in_bits ),
 .m_axis_tvalid( image_vld ),
 .m_axis_tready( 1'b1 ),
 .m_axis_tdata( image_pixel )
);

always_ff @( posedge clk_a1 ) begin
   image_pixel_reg <= image_pixel;
   image_vld_reg <= image_vld;
end
assign res_bits = image_pixel_reg;
assign res_vld = image_vld_reg;

axis_dwidth_converter_64_to_512 upsizer
(
 .aclk( clk_a1 ),
 .aresetn( rst_n_a1 ),
 .s_axis_tvalid( res_vld ),
 .s_axis_tdata( res_bits ),
 .m_axis_tvalid( data_out_vld ),
 .m_axis_tready( 1'b1 ),
 .m_axis_tdata( data_out_bits )
);

fifo_async_512_output output_fifo
(
 .wr_clk( clk_a1 ),
 .rd_clk( aclk ),
 .srst( !rst_n_a1 ),
 .din( data_out_bits ),
 .wr_en( data_out_vld & data_out_rdy ),
 .full( output_fifo_full ),
 .rd_en( fifo_out_rdy & fifo_out_vld ),
 .valid( fifo_out_vld ),
 .dout( fifo_out_bits ),
 .prog_empty( img_done_n )
);

endmodule

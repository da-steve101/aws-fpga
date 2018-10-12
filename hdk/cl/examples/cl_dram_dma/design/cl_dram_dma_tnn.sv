
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

logic [63:0] res_bits;
logic res_vld;

logic [63:0] image_pixel;
reg [63:0] image_pixel_reg;
reg [9:0] img_cntr;
logic image_vld;
reg runnning;

logic [511:0] data_out_bits;
logic data_out_vld;
logic data_out_rdy;

(* dont_touch = "true" *) logic rst_n_a1;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(clk_a1), .rst_n(1'b1), .in_bus(aresetn), .out_bus(rst_n_a1));

assign fifo_in_rdy = !input_fifo_full;
assign data_out_rdy = !output_fifo_full;
assign img_buffered = !img_done_n;

fifo_async_512_to_64 input_fifo
(
 .wr_clk( aclk ),
 .rd_clk( clk_a1 ),
 .srst( !aresetn ),
 .din( fifo_in_bits ),
 .wr_en( fifo_in_vld & fifo_in_rdy ),
 .full( input_fifo_full ),
 .rd_en( running ),
 .valid( image_vld ),
 .dout( image_pixel ),
 .prog_empty( img_buffered_n )
);

always_ff @( posedge clk_a1 ) begin
   if ( rst_n_a1 ) begin
      running <= 0;
      img_cntr <= 0;
   end else begin
      if ( !img_buffered_n & img_cntr == 0 ) begin
	 running <= 1;
	 img_cntr <= 10'h3ff;
      end else begin
	 if ( img_cntr == 0 ) begin
	    running <= 0;
	 end else begin
	    img_cntr <= img_cntr - 1;
	 end
      end
   end
end

// need to wait for image to be buffered
AWSVggWrapper tnn
(
 .clock( clk_a1 ),
 .reset( rst_n_a1 ),
 // .io_dataIn_ready(),
 .io_dataIn_valid( running ),
 .io_dataIn_bits_0( image_pixel[15:0] ),
 .io_dataIn_bits_1( image_pixel[31:16] ),
 .io_dataIn_bits_2( image_pixel[47:32] ),
 .io_dataOut_ready( 1'b1 ),
 .io_dataOut_valid( res_vld ),
 .io_dataOut_bits_0( res_bits[15:0] ),
 .io_dataOut_bits_1( res_bits[31:16] ),
 .io_dataOut_bits_2( res_bits[47:32] ),
 .io_dataOut_bits_3( res_bits[63:48] )
);

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

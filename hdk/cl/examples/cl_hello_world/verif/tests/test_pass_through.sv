
module test_pass_through();

   import tb_type_defines_pkg::*;
   
   initial begin

      logic [63:0] host_memory_buffer_address;
      int 	   len0 = 8192;
      int 	   timeout_count;
      logic [3:0]  status = 0;
      logic [7:0]  cmp_data;
      int 	   error_count;

      tb.power_up(.clk_recipe_a(ClockRecipe::A1),
                  .clk_recipe_b(ClockRecipe::B0),
                  .clk_recipe_c(ClockRecipe::C0));

      tb.nsec_delay(1000);

      $display("[%t] : Initializing buffers", $realtime);

      host_memory_buffer_address = 64'h0;

      //Queue data to be transfered to CL DDR
      tb.que_buffer_to_cl(.chan(0), .src_addr(host_memory_buffer_address), .cl_addr(64'h0000_0000_0000), .len(len0) ); // move buffer to DDR 0
      tb.que_buffer_to_cl(.chan(0), .src_addr(host_memory_buffer_address + 16'h2000), .cl_addr(64'h0000_0000_2000), .len(len0) ); // move buffer to DDR 0
      tb.que_buffer_to_cl(.chan(0), .src_addr(host_memory_buffer_address + 16'h4000), .cl_addr(64'h0000_0000_4000), .len(len0) ); // move buffer to DDR 0
      tb.que_buffer_to_cl(.chan(0), .src_addr(host_memory_buffer_address + 16'h6000), .cl_addr(64'h0000_0000_6000), .len(len0) ); // move buffer to DDR 0

      // Put test pattern in host memory
      for (int i = 0 ; i < 4*len0; i++) begin
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d( i % 256 ));
         host_memory_buffer_address++;
      end
      $display("[%t] : Start transfers", $realtime);

      // read the data from cl and put it in the host memory
      host_memory_buffer_address = 64'h8000;
      tb.que_cl_to_buffer(.chan(1), .dst_addr(host_memory_buffer_address), .cl_addr(64'h0000_0000_8000), .len(len0) ); // move DDR0 to buffer
      tb.que_cl_to_buffer(.chan(1), .dst_addr(host_memory_buffer_address + 16'h2000), .cl_addr(64'h0000_0000_a000), .len(len0) ); // move DDR0 to buffer
      tb.que_cl_to_buffer(.chan(1), .dst_addr(host_memory_buffer_address + 16'h4000), .cl_addr(64'h0000_0000_c000), .len(len0) ); // move DDR0 to buffer
      tb.que_cl_to_buffer(.chan(1), .dst_addr(host_memory_buffer_address + 16'h6000), .cl_addr(64'h0000_0000_e000), .len(len0) ); // move DDR0 to buffer

      //Start transfers of data to CL
      tb.start_que_to_cl(.chan(0));

      //Start transfers of data from CL DDR
      tb.start_que_to_buffer(.chan(1));

      // Timeout on input
      timeout_count = 0;
      do begin
         status[0] = tb.is_dma_to_cl_done(.chan(0));
         #10ns;
         timeout_count++;
      end while ((status == 4'h0) && (timeout_count < 4000));

      if (timeout_count >= 4000) begin
         $display("[%t] : *** ERROR *** Timeout waiting for dma transfers to cl", $realtime);
         error_count++;
      end

      $display("[%t] : Waiting for output", $realtime);

      // wait for dma transfers to complete
      timeout_count = 0;
      do begin
         status[0] = tb.is_dma_to_buffer_done(.chan(1));
         #10ns;
         timeout_count++;
      end while ((status == 4'h0) && (timeout_count < 1000));

      if (timeout_count >= 1000) begin
         $display("[%t] : *** ERROR *** Timeout waiting for dma transfers from cl", $realtime);
         error_count++;
      end

      #1us;

      $display("[%t] : DMA buffer from DDR 0", $realtime);

      for (int i = 0 ; i<4*len0; i++) begin
	 cmp_data = tb.hm_get_byte(.addr(i));
         if (tb.hm_get_byte(.addr(host_memory_buffer_address + i)) !== cmp_data ) begin
            $display("[%t] : *** ERROR *** DDR0 Data mismatch, addr:%0x read data is: %0x != %0x",
                     $realtime, (host_memory_buffer_address + i), tb.hm_get_byte(.addr(host_memory_buffer_address + i)), cmp_data);
            error_count++;
         end
      end
      
      $display("[%t] : Done", $realtime);
      
      // Power down
      #500ns;
      tb.power_down();

      $finish;
   end // initial begin

endmodule // test_dram_dma

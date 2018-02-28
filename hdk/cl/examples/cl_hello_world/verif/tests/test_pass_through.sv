
module test_pass_through();

   import tb_type_defines_pkg::*;
   
   initial begin

      logic [63:0] host_memory_buffer_address;
      logic [511:0] data_in;
      logic [511:0] data_out;
      int 	    len0 = 64;
      int 	    timeout_count;
      logic [3:0]   status = 0;
      int 	    error_count;

      tb.power_up(.clk_recipe_a(ClockRecipe::A1),
                  .clk_recipe_b(ClockRecipe::B0),
                  .clk_recipe_c(ClockRecipe::C0));

      tb.nsec_delay(1000);

      $display("[%t] : Initializing buffers", $realtime);

      host_memory_buffer_address = 64'h0;

      //Queue data to be transfered to CL DDR
      tb.que_buffer_to_cl(.chan(0), .src_addr(host_memory_buffer_address), .cl_addr(64'h0000_0000_0002), .len(len0) ); // move buffer to DDR 0

      // Put test pattern in host memory
      for (int i = 0 ; i < len0 ; i++) begin
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d(8'hAA));
         host_memory_buffer_address++;
      end
      /*
      host_memory_buffer_address = 64'h0_0000_3000;

      tb.que_buffer_to_cl(.chan(1), .src_addr(host_memory_buffer_address), .cl_addr(64'h0004_0000_0000), .len(len1) ); // move buffer to DDR 1

      for (int i = 0 ; i < len1 ; i++) begin
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d(8'hBB));
         host_memory_buffer_address++;
      end

      host_memory_buffer_address = 64'h0_0000_6000;
      tb.que_buffer_to_cl(.chan(2), .src_addr(host_memory_buffer_address), .cl_addr(64'h0008_0000_0005), .len(len2) ); // move buffer to DDR 2

      for (int i = 0 ; i < len2 ; i++) begin
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d(8'hCC));
         host_memory_buffer_address++;
      end

      host_memory_buffer_address = 64'h0_0000_9000;
      tb.que_buffer_to_cl(.chan(3), .src_addr(host_memory_buffer_address), .cl_addr(64'h000C_0000_0000), .len(len3) ); // move buffer to DDR 3

      for (int i = 0 ; i < len3 ; i++) begin
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d(8'hDD));
         host_memory_buffer_address++;
      end
       */
      $display("[%t] : Start transfers", $realtime);

      //Start transfers of data to CL DDR
      tb.start_que_to_cl(.chan(0));
      // tb.start_que_to_cl(.chan(1));
      // tb.start_que_to_cl(.chan(2));
      // tb.start_que_to_cl(.chan(3));

      timeout_count = 0;
      do begin
         status[0] = tb.is_dma_to_cl_done(.chan(0));
         // status[1] = tb.is_dma_to_cl_done(.chan(1));
         // status[2] = tb.is_dma_to_cl_done(.chan(2));
         // status[3] = tb.is_dma_to_cl_done(.chan(3));
         #10ns;
         timeout_count++;
      end while ((status == 4'h0) && (timeout_count < 4000));

      if (timeout_count >= 4000) begin
         $display("[%t] : *** ERROR *** Timeout waiting for dma transfers from cl", $realtime);
         error_count++;
      end

      $display("[%t] : starting C2H DMA channels ", $realtime);

      // read the data from cl and put it in the host memory
      host_memory_buffer_address = 64'h0_0001_0800;
      tb.que_cl_to_buffer(.chan(0), .dst_addr(host_memory_buffer_address), .cl_addr(64'h0000_0000_0002), .len(len0) ); // move DDR0 to buffer
      /*
      host_memory_buffer_address = 64'h0_0002_1800;
      tb.que_cl_to_buffer(.chan(1), .dst_addr(host_memory_buffer_address), .cl_addr(64'h0004_0000_0000), .len(len1) ); // move DDR1 to buffer

      host_memory_buffer_address = 64'h0_0003_2800;
      tb.que_cl_to_buffer(.chan(2), .dst_addr(host_memory_buffer_address), .cl_addr(64'h0008_0000_0005), .len(len2) ); // move DDR2 to buffer

      host_memory_buffer_address = 64'h0_0004_3800;
      tb.que_cl_to_buffer(.chan(3), .dst_addr(host_memory_buffer_address), .cl_addr(64'h000C_0000_0000), .len(len3) ); // move DDR3 to buffer
       */
      //Start transfers of data from CL DDR
      tb.start_que_to_buffer(.chan(0));
      // tb.start_que_to_buffer(.chan(1));
      // tb.start_que_to_buffer(.chan(2));
      // tb.start_que_to_buffer(.chan(3));

      // wait for dma transfers to complete
      timeout_count = 0;
      do begin
         status[0] = tb.is_dma_to_buffer_done(.chan(0));
         // status[1] = tb.is_dma_to_buffer_done(.chan(1));
         // status[2] = tb.is_dma_to_buffer_done(.chan(2));
         // status[3] = tb.is_dma_to_buffer_done(.chan(3));
         #10ns;
         timeout_count++;
      end while ((status == 4'h0) && (timeout_count < 1000));

      if (timeout_count >= 1000) begin
         $display("[%t] : *** ERROR *** Timeout waiting for dma transfers from cl", $realtime);
         error_count++;
      end

      #1us;

      // DDR 0
      // Compare the data in host memory with the expected data
      $display("[%t] : DMA buffer from DDR 0", $realtime);

      host_memory_buffer_address = 64'h0_0001_0800;
      for (int i = 0 ; i<len0 ; i++) begin
         if (tb.hm_get_byte(.addr(host_memory_buffer_address + i)) !== 8'hAA) begin
            $display("[%t] : *** ERROR *** DDR0 Data mismatch, addr:%0x read data is: %0x",
                     $realtime, (host_memory_buffer_address + i), tb.hm_get_byte(.addr(host_memory_buffer_address + i)));
            error_count++;
         end
      end
      /*
      // DDR 1
      // Compare the data in host memory with the expected data
      $display("[%t] : DMA buffer from DDR 1", $realtime);

      host_memory_buffer_address = 64'h0_0002_1800;
      for (int i = 0 ; i< len1 ; i++) begin
         if (tb.hm_get_byte(.addr(host_memory_buffer_address)) !== 8'hBB) begin
            $display("[%t] : *** ERROR *** DDR1 Data mismatch, addr:%0x read data is: %0x",
                     $realtime, (host_memory_buffer_address + i), tb.hm_get_byte(.addr(host_memory_buffer_address + i)));
            error_count++;
         end
      end

      // DDR 2
      // Compare the data in host memory with the expected data
      $display("[%t] : DMA buffer from DDR 2", $realtime);

      host_memory_buffer_address = 64'h0_0003_2800;
      for (int i = 0 ; i< len2 ; i++) begin
         if (tb.hm_get_byte(.addr(host_memory_buffer_address)) !== 8'hCC) begin
            $display("[%t] : *** ERROR *** DDR2 Data mismatch, addr:%0x read data is: %0x",
                     $realtime, (host_memory_buffer_address + i), tb.hm_get_byte(.addr(host_memory_buffer_address + i)));
            error_count++;
         end
      end

      // DDR 3
      // Compare the data in host memory with the expected data
      $display("[%t] : DMA buffer from DDR 3", $realtime);

      host_memory_buffer_address = 64'h0_0004_3800;
      for (int i = 0 ; i< len3 ; i++) begin
         if (tb.hm_get_byte(.addr(host_memory_buffer_address)) !== 8'hDD) begin
            $display("[%t] : *** ERROR *** DDR3 Data mismatch, addr:%0x read data is: %0x",
                     $realtime, (host_memory_buffer_address + i), tb.hm_get_byte(.addr(host_memory_buffer_address + i)));
            error_count++;
         end
      end
       */      
      
      $display("[%t] : Done", $realtime);
      
      // Power down
      #500ns;
      tb.power_down();

      if (data_in != data_out) begin
         $display("[%t] : *** TEST FAILED ***", $realtime);
      end else begin
         $display("[%t] : *** TEST PASSED ***", $realtime);
      end

      $finish;
   end // initial begin

endmodule // test_dram_dma


module test_image();

   import tb_type_defines_pkg::*;
   
   initial begin

      logic [63:0] host_memory_buffer_address;
      int 	   len0 = 8192;
      logic [2:0]  byte_addr = 0;
      int 	   timeout_count;
      logic [3:0]  status = 0;
      logic [7:0]  cmp_data;
      int 	   error_count;

      logic [63:0] airplane4_image [1023:0] = { 64'h1100120014, 64'h1100130014, 64'h1200130015, 64'h1200130015, 64'h1300140015, 64'h1200130015, 64'h1200130015, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1400150016, 64'h1400150016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1200130015, 64'h1200130015, 64'h1100120014, 64'h1100120014, 64'h1100120014, 64'h1100110014, 64'h1000110014, 64'h1000100013, 64'hf000f0012, 64'he000f0011, 64'he000e0011, 64'hd000e0011, 64'he000f0011, 64'h1100120014, 64'h1100130014, 64'h1200130015, 64'h1300130015, 64'h1300140015, 64'hf00100011, 64'hd000e000f, 64'h1200130015, 64'h1400150016, 64'h1300140015, 64'h1300140016, 64'h1300140015, 64'h1300140015, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140016, 64'h1300140015, 64'h1200130015, 64'h1200130015, 64'h1100120014, 64'h1100120014, 64'h1100110014, 64'h1000110014, 64'h1000100013, 64'hf00100013, 64'hf00100013, 64'he000f0012, 64'he000f0011, 64'hd000e0011, 64'he000f0011, 64'h1100120014, 64'h1100130014, 64'h1100130014, 64'h1300140016, 64'h9000b000f, 64'h600090009, 64'h500050008, 64'h600060009, 64'h1000120013, 64'h1400150016, 64'h1300140015, 64'h1300140015, 64'h1200140015, 64'h1300150015, 64'h1300140015, 64'h1300140015, 64'h1300140015, 64'h1300140015, 64'h1200130015, 64'h1200130015, 64'h1100130015, 64'h1100120014, 64'h1100120014, 64'h1100110014, 64'h1000110014, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'he000e0012, 64'hd000e0011, 64'hd000e0010, 64'he000f0012, 64'h1100120014, 64'h1100130014, 64'h1100120014, 64'h1200140015, 64'hfffe00020008, 64'hfff7fff90001, 64'h400040008, 64'h100020004, 64'h200040004, 64'hf000f0010, 64'h1400140015, 64'h1200140015, 64'h1100140014, 64'h1200150015, 64'h1000120013, 64'hf00100011, 64'h1200130015, 64'h1200130015, 64'h1100130014, 64'h1100120015, 64'h1100120015, 64'h1100120015, 64'h1100110014, 64'h1000110014, 64'h1000100013, 64'h1000100013, 64'hf00100013, 64'hf00100013, 64'he000e0013, 64'he000e0011, 64'hd000f0010, 64'he000f0011, 64'h1100120014, 64'h1100130014, 64'h1100120014, 64'h1100130014, 64'hc000d0013, 64'hfff5fff60005, 64'hfff4fff80000, 64'h60004, 64'hffff00020001, 64'hffff00000000, 64'hc000d000d, 64'h1300150015, 64'h1100130015, 64'h1200140016, 64'h1100120014, 64'h9000a000b, 64'h1300140016, 64'h1300140015, 64'h1200130015, 64'h1100120015, 64'h1100120015, 64'h1100110014, 64'h1000110014, 64'h1000100013, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'he000f0012, 64'he000f0010, 64'hd000f000f, 64'he000f0011, 64'h1100120014, 64'h1100120014, 64'h1100120014, 64'h1100120014, 64'h1300130016, 64'h8000c0012, 64'hffedfff30000, 64'hfff4fffa0000, 64'h100030007, 64'h3, 64'hfffcfffdfffd, 64'h8000a000a, 64'h1400150017, 64'h1100110015, 64'h200030005, 64'hfff5fff7fff9, 64'h300040006, 64'h1000110013, 64'h1100120014, 64'h1100110014, 64'h1100120015, 64'h1100110014, 64'h1000110014, 64'h1000110014, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'he000f0011, 64'hd000e0010, 64'hd000e0010, 64'he000f0010, 64'h1000110013, 64'h1100120014, 64'h1100120014, 64'h1100120014, 64'h1200120013, 64'h1000140013, 64'h4000a000f, 64'hfff0fff20003, 64'hfff6fff70003, 64'h20006, 64'hfffe00000001, 64'hfffbfffdfffd, 64'h200030004, 64'hfffbfffbffff, 64'hfff3fff3fff7, 64'hffebffebffee, 64'hfff9fff9fffc, 64'h1000100014, 64'hd000e0010, 64'he000f0012, 64'h1200130015, 64'h1100110014, 64'h1000110014, 64'h1000110014, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'he000f0012, 64'hd000e0010, 64'hd000e0011, 64'he000e0012, 64'hd000e0011, 64'h1000110013, 64'h1000110013, 64'h1000110013, 64'h1100120014, 64'h1200130014, 64'h1200120014, 64'h1100130014, 64'h400060010, 64'hffeefff10000, 64'hfff7fff80002, 64'hfffe00000003, 64'hfffe0000ffff, 64'hfff5fff6fff6, 64'hffedffedffef, 64'hfffafffafffd, 64'hfffafffbfffe, 64'hffffffff0003, 64'h1400140017, 64'hd000d0010, 64'ha000a000d, 64'h1000110013, 64'h1000110014, 64'h1000110014, 64'h1000110014, 64'h1000100013, 64'hf00100013, 64'hf00100013, 64'hf00100013, 64'he000e0011, 64'hb000b0011, 64'h900090010, 64'hc000c0011, 64'hf00110013, 64'h1000110013, 64'h1000110013, 64'h1000110013, 64'h1100110014, 64'h1300110015, 64'h1300110014, 64'h1100150015, 64'h3000c, 64'hfff1fff1fffb, 64'hfffeffff0003, 64'hfffcfffefffd, 64'hfff7fff8fff7, 64'hfff9fff9fffa, 64'hfffbfffcffff, 64'h70008000a, 64'h100020005, 64'hc000c000f, 64'hfff6fff6fffa, 64'hfff2fff2fff7, 64'h60007000a, 64'h1100130014, 64'h1000110013, 64'h1000110013, 64'hf00100013, 64'h1000100013, 64'hf00100013, 64'ha000a000e, 64'hfffefffe0003, 64'hffefffeffff7, 64'hffe7ffe7fff1, 64'h100010009, 64'hf00100011, 64'hf00110011, 64'hf00110012, 64'h1000120013, 64'h1000120013, 64'h1100120013, 64'h1100120013, 64'h1100120013, 64'h1100120014, 64'h300040007, 64'hfffcfffdffff, 64'hfffbfffdfffd, 64'hfffafffcfffb, 64'hfffeffffffff, 64'hfffafffbfffd, 64'hfffcfffdffff, 64'h100020004, 64'hfffafffbfffd, 64'hffeeffeefff3, 64'hffedffedfff2, 64'ha000b000d, 64'h1100120012, 64'h1000110012, 64'h1000110012, 64'hf00100012, 64'hb000c000f, 64'h10005, 64'hfff0fff1fff5, 64'hffe5ffe6ffe9, 64'hffd9ffdbffe1, 64'hffdeffe0ffe9, 64'h30005000b, 64'he000f000f, 64'he000f0010, 64'hf00100010, 64'hf00110011, 64'h1000110011, 64'h1000110011, 64'h1100110012, 64'h1100120012, 64'h1100110012, 64'hf00100011, 64'h10002, 64'hfff8fff9fffa, 64'hfffdfffffffe, 64'hfffeffffffff, 64'hffff00000002, 64'hfffcfffdffff, 64'hfff4fff5fff7, 64'hfff5fff6fff8, 64'h100010004, 64'hfff9fff9fffd, 64'h9000a000b, 64'h1000110012, 64'hf00100013, 64'he000f0011, 64'h200040006, 64'hfff3fff5fff8, 64'hffe9ffebffed, 64'hffe3ffe4ffe7, 64'hffdaffdcffdb, 64'hffd1ffd3ffd4, 64'hffeffff2fff5, 64'hc000e000f, 64'he000e000e, 64'he000e000e, 64'hf000f000f, 64'hf000f000f, 64'hf000f000f, 64'h1000100010, 64'h1100110011, 64'h1100110011, 64'h1000100011, 64'h1000110011, 64'hf00100010, 64'hffff00010000, 64'hfff9fffafffa, 64'hfffeffffffff, 64'h400050006, 64'hffff00000002, 64'hfffcfffdfffe, 64'hfff7fff7fff9, 64'h100020003, 64'h600070008, 64'h80009000b, 64'hf00100013, 64'h90009000e, 64'hfff7fff9fffc, 64'hffe5ffe9ffea, 64'hffe7ffeaffeb, 64'hfff1fff4fff5, 64'hfffcfffeffff, 64'hffeeffefffee, 64'hffedffeeffee, 64'h700070009, 64'ha000b000b, 64'he000d000d, 64'he000d000d, 64'hf000e000e, 64'hf000e000e, 64'hf000e000e, 64'hf000f000e, 64'h10000f000f, 64'h10000f000f, 64'h100010000f, 64'hf0010000f, 64'h100010000f, 64'hb000c000c, 64'hfffdfffefffd, 64'hfffafffbfffc, 64'hffff00000002, 64'hfffcfffdfffe, 64'hfffeffff0001, 64'hfffeffff0000, 64'hfff8fff9fff9, 64'h700080009, 64'ha000a000d, 64'h4, 64'hfff1fff2fff5, 64'hffe9ffecffee, 64'hfff3fff6fff8, 64'h300050006, 64'h9000a000b, 64'h400040004, 64'hfffcfffbfffc, 64'h800050007, 64'hb0008000a, 64'ha0008000a, 64'hd000b000a, 64'hd000b000b, 64'he000c000b, 64'he000c000c, 64'he000d000c, 64'he000d000d, 64'hf000e000d, 64'hf000e000d, 64'he000e000d, 64'he000f000c, 64'he000e000c, 64'he000e000e, 64'h900090009, 64'hfffafffafffc, 64'hfff9fff9fffb, 64'hfffeffff0000, 64'h100020004, 64'h300040006, 64'hfff8fff9fffa, 64'hfff7fff8fff9, 64'hfff2fff2fff6, 64'hffebffebffef, 64'hfff3fff4fff7, 64'h300040006, 64'hb000d000f, 64'h80009000a, 64'hffffffff, 64'hfffefffe, 64'h700050006, 64'hb00070008, 64'hb00060006, 64'hb00070007, 64'hb00090008, 64'hb000a0008, 64'hc000a0009, 64'hc000a000a, 64'hd000b000a, 64'hd000c000a, 64'hd000d000b, 64'hd000d000b, 64'hd000d000b, 64'hd000d000a, 64'hd000d000a, 64'hc000c000a, 64'hd000c000b, 64'h600060006, 64'hfffcfffdffff, 64'h200030004, 64'h100020004, 64'hfff5fff5fff7, 64'hffe9ffebffec, 64'hffe8ffe9ffeb, 64'hffe9ffe9ffed, 64'hfffafffafffe, 64'he00100011, 64'hd000e000e, 64'hffffffff0001, 64'hfffafff9fffa, 64'h500030000, 64'hb00080006, 64'ha00070005, 64'h900060003, 64'ha00050002, 64'ha00060004, 64'ha00080004, 64'hb00090005, 64'hb00090006, 64'hb00090007, 64'hd00090006, 64'hc000a0006, 64'hb000b0008, 64'hc000b0008, 64'hd000b0008, 64'he000a0008, 64'hd000a0008, 64'hc000a0008, 64'hb00090008, 64'h900080008, 64'hfff9fff9fffc, 64'hfff2fff3fff5, 64'hffe9ffebffed, 64'hffe6ffe7ffe9, 64'hffe9ffebffec, 64'hfff9fffafffc, 64'h80007000b, 64'hc000c000f, 64'h200050006, 64'hfffcfffffffd, 64'hfffdfffcffff, 64'hfffbfffcfffe, 64'h40004ffff, 64'h900050002, 64'h800040001, 64'h800040000, 64'h700040000, 64'h800050001, 64'ha00060000, 64'hb00070001, 64'hb00070002, 64'hc00070003, 64'hc00070003, 64'hb00080004, 64'hb00090004, 64'hd00090004, 64'he00090004, 64'he00090004, 64'hc00080004, 64'ha00080005, 64'h900080008, 64'h600060007, 64'hffeffff0fff3, 64'hffdfffe0ffe3, 64'hffe3ffe5ffe8, 64'hfff2fff4fff8, 64'h300060009, 64'hc000e0010, 64'h80007000b, 64'hfffcfffbfffd, 64'hfff6fff8fff7, 64'h100040004, 64'hfff9fffbffff, 64'hffeaffebffed, 64'hfffcfffcfff8, 64'h800040000, 64'h70002fffe, 64'h70003fffd, 64'h60002fffc, 64'h70002fffd, 64'hb0004fffd, 64'ha0005ffff, 64'hb0005ffff, 64'hd0005fffe, 64'hb00050000, 64'hb00050000, 64'hb0006ffff, 64'he00070000, 64'he00060000, 64'hc00060000, 64'hb00070003, 64'h900060005, 64'h1, 64'hfff3fff4fff7, 64'hffe6ffe8ffeb, 64'hffe9ffebffee, 64'hfffe00010004, 64'he00100014, 64'ha000d000f, 64'hfffcfffd0000, 64'hfffafffafffd, 64'hfffefffeffff, 64'hfff8fff9fff7, 64'hfff9fffafffa, 64'hfff8fff8fff9, 64'hfff1ffefffed, 64'hfff9fff6fff1, 64'h70002fffa, 64'h60001fff9, 64'h60001fff9, 64'h60000fff8, 64'h60001fff9, 64'h80001fffb, 64'h70002fffe, 64'h80003fffd, 64'hb0004fffc, 64'hb0004fffd, 64'hb0004fffc, 64'hc0005fffb, 64'hb0005fffd, 64'hb0004ffff, 64'h900050001, 64'h40001fffe, 64'hfff8fff7fff7, 64'hffedffedffef, 64'hffeefff0fff2, 64'hfffbfffdfffe, 64'h9000a000b, 64'hd000d000d, 64'h500040002, 64'hfffafff9fff8, 64'hfffdfffcfffd, 64'h500060008, 64'h600070008, 64'hfffbfffcfffb, 64'hfff9fff8fff6, 64'hfffdfffbfff6, 64'h2fffdfff7, 64'hfff9fff3ffee, 64'h2fffcfff3, 64'h70000fff6, 64'h6fffffff4, 64'h6fffffff4, 64'h70000fff5, 64'h1fffcfff9, 64'h400000000, 64'h40001fffe, 64'h70001fffa, 64'ha0002fff9, 64'hb0003fff8, 64'hb0003fff7, 64'h90003fffb, 64'h40001fffd, 64'hfff8fff7fff7, 64'hffeeffedffee, 64'hffedffeeffef, 64'hfff5fff6fff9, 64'h500070009, 64'hb000d000e, 64'h500050003, 64'h2fffefff9, 64'h3fffefff5, 64'h1fffcfff5, 64'hfffefffbfff9, 64'h10001, 64'hfffe00000001, 64'hfffeffff0000, 64'hfffcfffafffb, 64'hfffcfffafff4, 64'h40000fffa, 64'hfffcfff8fff7, 64'hfff6fff3ffef, 64'h4fffdfff1, 64'h6fffefff1, 64'h5fffdfff0, 64'h6fffefff1, 64'h1fffafff5, 64'hfffffffafffc, 64'h200010004, 64'h40001fffe, 64'h6fffffff7, 64'h80001fff4, 64'ha0003fff7, 64'hfffefffafff4, 64'hffedffedffec, 64'hffe7ffe9ffeb, 64'hfff5fff7fff8, 64'h600080009, 64'hd000e000f, 64'h600060005, 64'hfffefffcfff7, 64'hfffffffbfff3, 64'h5fffefff3, 64'h9fffffff2, 64'h8fffefff2, 64'hfffffff9fff2, 64'hfffafff8fff6, 64'hfffcfffeffff, 64'hffff00010003, 64'hffffffff0002, 64'hfffafffafff9, 64'hfffffffefffb, 64'hfff6fff5fff8, 64'hffeaffebffe9, 64'hfffaffed, 64'h6fffdffee, 64'h4fffcffed, 64'h6fffdffed, 64'h9fffdfff0, 64'hfff8fff4, 64'hfffafffaffff, 64'h100020004, 64'h60002ffff, 64'h50000fff8, 64'hfffcfff8fff2, 64'hffeeffecffed, 64'hfff1fff3fff5, 64'h200030004, 64'ha000b000b, 64'h800080006, 64'h1fffffffa, 64'hfffffffafff2, 64'h5fffdfff0, 64'h8fffffff1, 64'h9ffffffef, 64'h8fffdffed, 64'h9fffeffed, 64'h8fffdfff0, 64'hfffafff2, 64'hfffdfffbfff9, 64'h2, 64'h200030004, 64'hfffdfffdfffe, 64'hfff8fff7fff5, 64'hfff9fff8fff5, 64'hfff6fff3ffeb, 64'hfffffff7ffe8, 64'h5fffbffeb, 64'h4fffaffe9, 64'h6fffaffe9, 64'h9fffcffeb, 64'h5fffcffee, 64'hfffafff7fff3, 64'hfffdfffcfffb, 64'h700040002, 64'hfffffffefffa, 64'hfff4fff4fff4, 64'hfffbfffafffd, 64'hfffffffffffe, 64'hfffffffd, 64'hfffdfff9, 64'hfffafff1, 64'h4fffbffee, 64'h8fffeffee, 64'h8fffeffee, 64'h8fffeffee, 64'h8fffdffed, 64'h8fffdffec, 64'h8fffdffec, 64'h8fffcffed, 64'h6fffbffed, 64'hfffffff8ffef, 64'hfffffffdfffa, 64'hfffe0000ffff, 64'hfff8fffcfff8, 64'hfffafff8fff8, 64'hfffcfff6ffed, 64'h2fff8ffe9, 64'h2fff6ffe6, 64'h5fff9ffe7, 64'h4fff8ffe6, 64'h5fff8ffe6, 64'h9fffaffe7, 64'h6fffcffe6, 64'h1fffaffeb, 64'hfffdfff7fff2, 64'hfffdfffafff9, 64'hfff5fff8fff8, 64'hfff3fff7fffa, 64'hffefffeffff2, 64'hfff4fff0ffeb, 64'hfffffff7ffec, 64'h4fffaffed, 64'h8fffcffec, 64'h9fffcffea, 64'h8fffcffea, 64'h7fffcffeb, 64'h7fffcffea, 64'h8fffbffe9, 64'h8fffbffe8, 64'h6fffaffe9, 64'h8fffaffe9, 64'hafffbffe6, 64'h6fff9ffe8, 64'hfffbfff5ffed, 64'hfff5fff7fff8, 64'hfff7fffcffff, 64'hfff8fff8fffb, 64'hfffcfff7ffec, 64'h4fff8ffe3, 64'h5fff8ffe5, 64'h4fff7ffe4, 64'h4fff6ffe2, 64'h5fff7ffe2, 64'h8fff9ffe5, 64'h6fffbffe1, 64'h6fffbffe4, 64'hfffcfff4ffeb, 64'hffebffe9ffe9, 64'hffe6ffe9ffe9, 64'hffe9ffebffee, 64'hfff2fff2fff4, 64'hfffbfff7fff0, 64'h7fffaffea, 64'hbfffcffe8, 64'hafffbffe6, 64'h6fffaffe7, 64'h5fff9ffe8, 64'h6fffaffe8, 64'h7fffaffe7, 64'h8fffaffe6, 64'h8fffaffe5, 64'h6fff9ffe6, 64'h8fff9ffe5, 64'hafff9ffe2, 64'h8fff9ffe3, 64'h1fff7ffe7, 64'hfff3ffefffed, 64'hfff1fff1fffc, 64'hfff3fff7fffa, 64'hfff8fff7fff2, 64'hfffefff6ffe4, 64'h3fff7ffe1, 64'h3fff5ffe1, 64'h3fff5ffe0, 64'h5fff6ffe0, 64'h5fff7ffe3, 64'h5fff8ffe1, 64'h8fff9ffe1, 64'hfffbfff2ffe5, 64'hffe1ffe1ffe2, 64'hffe0ffe2ffe2, 64'hffeeffedffeb, 64'hfffbfff9fffa, 64'hfffefffcfff8, 64'h1fff8ffeb, 64'h6fff8ffe6, 64'h9fff9ffe3, 64'h8fff9ffe3, 64'h5fff8ffe4, 64'h5fff8ffe4, 64'h6fff8ffe3, 64'h6fff8ffe3, 64'h7fff8ffe2, 64'h6fff8ffe2, 64'h6fff8ffe2, 64'h6fff7ffe1, 64'h6fff7ffe1, 64'h5fff7ffe1, 64'hfffffff3ffe6, 64'hfff3ffeeffee, 64'hffeeffeffff6, 64'hfff3fff4fff8, 64'hfffbfff5ffee, 64'hfffffff4ffdf, 64'h1fff4ffde, 64'h1fff4ffdd, 64'h3fff5ffdd, 64'h3fff5ffe1, 64'h4fff6ffe0, 64'h8fff7ffde, 64'hfff8fff0ffe3, 64'hffe0ffe1ffe3, 64'hffe7ffe7ffe4, 64'hfff7fff1ffe8, 64'hfffafff3ffec, 64'hfffdfff9fff4, 64'hfffbfff4, 64'h1fff6ffe7, 64'h7fff7ffe1, 64'h9fff8ffdf, 64'h7fff7ffe0, 64'h5fff7ffe1, 64'h5fff6ffe0, 64'h6fff6ffe0, 64'h6fff6ffe0, 64'h6fff6ffdf, 64'h5fff6ffdf, 64'h4fff5ffe0, 64'h4fff5ffdf, 64'h6fff5ffdd, 64'h6fff5ffdd, 64'hfffdfff4ffe0, 64'hfff0ffecffed, 64'hfff1ffeffff8, 64'hfffafff7fffa, 64'hfffefff4ffe4, 64'hfffffff2ffdd, 64'h1fff3ffdc, 64'h3fff4ffdb, 64'h3fff4ffdf, 64'h4fff5ffdd, 64'h7fff6ffdb, 64'hfff4ffedffe3, 64'hffdfffe1ffe3, 64'hffedffe9ffe2, 64'h2fff4ffe2, 64'h3fff4ffe0, 64'hfffffff4ffe5, 64'hfff7ffec, 64'h2fff5ffe4, 64'h6fff5ffde, 64'h6fff6ffdd, 64'h5fff5ffde, 64'h6fff5ffde, 64'h6fff5ffde, 64'h5fff5ffdd, 64'h5fff5ffdd, 64'h5fff4ffdd, 64'h5fff4ffdd, 64'h5fff4ffdd, 64'h5fff4ffdd, 64'h5fff4ffdd, 64'h5fff4ffdc, 64'h2fff5ffda, 64'hfffafff1ffe1, 64'hfff3ffecffed, 64'hfff8fff4fff3, 64'hfffefff4ffe7, 64'hfffefff1ffdd, 64'h2fff2ffda, 64'h4fff2ffda, 64'h3fff3ffdd, 64'h3fff3ffdb, 64'h5fff4ffda, 64'hfff4ffecffe0, 64'hffe6ffe4ffe0, 64'hfff4ffedffe1, 64'h4fff4ffdd, 64'h6fff5ffdc, 64'h1fff3ffdf, 64'hfff3ffe1, 64'h4fff4ffde, 64'h6fff4ffdc, 64'h4fff4ffdc, 64'h3fff4ffdd, 64'h5fff4ffdc, 64'h5fff4ffdc, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h4fff3ffdc, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h6fff2ffdc, 64'h5fff3ffd8, 64'h2fff2ffdb, 64'hfffdffefffe1, 64'hfffcfff1ffdf, 64'hfffefff1ffdd, 64'hfffffff1ffda, 64'h1fff1ffd8, 64'h2fff1ffd8, 64'h3fff2ffdb, 64'h4fff2ffda, 64'h5fff3ffda, 64'hfff9ffedffdd, 64'hfff2ffebffde, 64'hfffdfff2ffdf, 64'h5fff4ffda, 64'h6fff4ffd8, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h6fff3ffda, 64'h6fff4ffda, 64'h4fff3ffdb, 64'h3fff3ffdc, 64'h4fff3ffdb, 64'h4fff3ffdb, 64'h4fff2ffda, 64'h4fff2ffda, 64'h4fff2ffda, 64'h4fff3ffda, 64'h4fff2ffda, 64'h4fff2ffda, 64'h4fff2ffda, 64'h4fff1ffda, 64'h5fff2ffd7, 64'h4fff2ffd7, 64'h4fff1ffda, 64'h4fff1ffd7, 64'h2fff1ffd8, 64'hfff0ffd7, 64'hfff0ffd6, 64'hfff0ffd7, 64'h3fff1ffda, 64'h4fff1ffda, 64'h4fff1ffda, 64'hfff1ffdc, 64'hfffdfff1ffdd, 64'h1fff2ffdb, 64'h5fff3ffd8, 64'h6fff3ffd8, 64'h5fff3ffd8, 64'h5fff3ffd8, 64'h6fff3ffd8, 64'h5fff3ffd8, 64'h4fff2ffd9, 64'h3fff2ffda, 64'h4fff2ffd9, 64'h4fff2ffd9, 64'h4fff2ffd9, 64'h4fff2ffd9, 64'h4fff2ffd9, 64'h3fff2ffd8, 64'h3fff1ffd8, 64'h3fff1ffd8, 64'h3fff1ffd8, 64'h2fff1ffd7, 64'h1fff1ffd6, 64'h2fff1ffd8, 64'h3ffefffd9, 64'h3ffeeffd9, 64'h2ffefffd6, 64'hffefffd5, 64'hffffffeeffd5, 64'hffffffeeffd6, 64'h3fff0ffd7, 64'h4ffefffd8, 64'h2ffefffda, 64'h2fff1ffd9, 64'h2fff1ffd9, 64'h2fff1ffd9, 64'h4fff1ffd8, 64'h4fff2ffd8, 64'h4fff2ffd8, 64'h4fff2ffd7, 64'h4fff2ffd7, 64'h4fff1ffd8, 64'h4fff1ffd8, 64'h4fff1ffd8, 64'h3fff1ffd8, 64'h3fff1ffd8, 64'h3fff1ffd7, 64'h3fff1ffd7, 64'h3fff1ffd7, 64'h2fff0ffd7, 64'h2fff0ffd7, 64'h2fff0ffd7, 64'h2fff0ffd7, 64'h1fff0ffd6, 64'hffefffd7, 64'hffefffd7, 64'hffeeffd7, 64'hffedffd7, 64'hffedffd6, 64'hffffffedffd5, 64'hfffdffecffd5, 64'hffedffd5};

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
	 byte_addr = (i % 8);
         tb.hm_put_byte(.addr(host_memory_buffer_address), .d( airplane4_image[( i >> 3 ) % 1024][(byte_addr*8 + 7):byte_addr*8]));
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

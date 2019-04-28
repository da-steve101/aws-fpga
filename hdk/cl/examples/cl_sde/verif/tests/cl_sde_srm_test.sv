`timescale 1 ns/1 ps

module cl_sde_srm_test;

wire [47:0] airplane4_image [1023:0] = { 48'h1100120014, 48'h1100130014, 48'h1200130015, 48'h1200130015, 48'h1300140015, 48'h1200130015, 48'h1200130015, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1400150016, 48'h1400150016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1200130015, 48'h1200130015, 48'h1100120014, 48'h1100120014, 48'h1100120014, 48'h1100110014, 48'h1000110014, 48'h1000100013, 48'hf000f0012, 48'he000f0011, 48'he000e0011, 48'hd000e0011, 48'he000f0011, 48'h1100120014, 48'h1100130014, 48'h1200130015, 48'h1300130015, 48'h1300140015, 48'hf00100011, 48'hd000e000f, 48'h1200130015, 48'h1400150016, 48'h1300140015, 48'h1300140016, 48'h1300140015, 48'h1300140015, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140016, 48'h1300140015, 48'h1200130015, 48'h1200130015, 48'h1100120014, 48'h1100120014, 48'h1100110014, 48'h1000110014, 48'h1000100013, 48'hf00100013, 48'hf00100013, 48'he000f0012, 48'he000f0011, 48'hd000e0011, 48'he000f0011, 48'h1100120014, 48'h1100130014, 48'h1100130014, 48'h1300140016, 48'h9000b000f, 48'h600090009, 48'h500050008, 48'h600060009, 48'h1000120013, 48'h1400150016, 48'h1300140015, 48'h1300140015, 48'h1200140015, 48'h1300150015, 48'h1300140015, 48'h1300140015, 48'h1300140015, 48'h1300140015, 48'h1200130015, 48'h1200130015, 48'h1100130015, 48'h1100120014, 48'h1100120014, 48'h1100110014, 48'h1000110014, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'he000e0012, 48'hd000e0011, 48'hd000e0010, 48'he000f0012, 48'h1100120014, 48'h1100130014, 48'h1100120014, 48'h1200140015, 48'hfffe00020008, 48'hfff7fff90001, 48'h400040008, 48'h100020004, 48'h200040004, 48'hf000f0010, 48'h1400140015, 48'h1200140015, 48'h1100140014, 48'h1200150015, 48'h1000120013, 48'hf00100011, 48'h1200130015, 48'h1200130015, 48'h1100130014, 48'h1100120015, 48'h1100120015, 48'h1100120015, 48'h1100110014, 48'h1000110014, 48'h1000100013, 48'h1000100013, 48'hf00100013, 48'hf00100013, 48'he000e0013, 48'he000e0011, 48'hd000f0010, 48'he000f0011, 48'h1100120014, 48'h1100130014, 48'h1100120014, 48'h1100130014, 48'hc000d0013, 48'hfff5fff60005, 48'hfff4fff80000, 48'h60004, 48'hffff00020001, 48'hffff00000000, 48'hc000d000d, 48'h1300150015, 48'h1100130015, 48'h1200140016, 48'h1100120014, 48'h9000a000b, 48'h1300140016, 48'h1300140015, 48'h1200130015, 48'h1100120015, 48'h1100120015, 48'h1100110014, 48'h1000110014, 48'h1000100013, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'he000f0012, 48'he000f0010, 48'hd000f000f, 48'he000f0011, 48'h1100120014, 48'h1100120014, 48'h1100120014, 48'h1100120014, 48'h1300130016, 48'h8000c0012, 48'hffedfff30000, 48'hfff4fffa0000, 48'h100030007, 48'h3, 48'hfffcfffdfffd, 48'h8000a000a, 48'h1400150017, 48'h1100110015, 48'h200030005, 48'hfff5fff7fff9, 48'h300040006, 48'h1000110013, 48'h1100120014, 48'h1100110014, 48'h1100120015, 48'h1100110014, 48'h1000110014, 48'h1000110014, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'he000f0011, 48'hd000e0010, 48'hd000e0010, 48'he000f0010, 48'h1000110013, 48'h1100120014, 48'h1100120014, 48'h1100120014, 48'h1200120013, 48'h1000140013, 48'h4000a000f, 48'hfff0fff20003, 48'hfff6fff70003, 48'h20006, 48'hfffe00000001, 48'hfffbfffdfffd, 48'h200030004, 48'hfffbfffbffff, 48'hfff3fff3fff7, 48'hffebffebffee, 48'hfff9fff9fffc, 48'h1000100014, 48'hd000e0010, 48'he000f0012, 48'h1200130015, 48'h1100110014, 48'h1000110014, 48'h1000110014, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'he000f0012, 48'hd000e0010, 48'hd000e0011, 48'he000e0012, 48'hd000e0011, 48'h1000110013, 48'h1000110013, 48'h1000110013, 48'h1100120014, 48'h1200130014, 48'h1200120014, 48'h1100130014, 48'h400060010, 48'hffeefff10000, 48'hfff7fff80002, 48'hfffe00000003, 48'hfffe0000ffff, 48'hfff5fff6fff6, 48'hffedffedffef, 48'hfffafffafffd, 48'hfffafffbfffe, 48'hffffffff0003, 48'h1400140017, 48'hd000d0010, 48'ha000a000d, 48'h1000110013, 48'h1000110014, 48'h1000110014, 48'h1000110014, 48'h1000100013, 48'hf00100013, 48'hf00100013, 48'hf00100013, 48'he000e0011, 48'hb000b0011, 48'h900090010, 48'hc000c0011, 48'hf00110013, 48'h1000110013, 48'h1000110013, 48'h1000110013, 48'h1100110014, 48'h1300110015, 48'h1300110014, 48'h1100150015, 48'h3000c, 48'hfff1fff1fffb, 48'hfffeffff0003, 48'hfffcfffefffd, 48'hfff7fff8fff7, 48'hfff9fff9fffa, 48'hfffbfffcffff, 48'h70008000a, 48'h100020005, 48'hc000c000f, 48'hfff6fff6fffa, 48'hfff2fff2fff7, 48'h60007000a, 48'h1100130014, 48'h1000110013, 48'h1000110013, 48'hf00100013, 48'h1000100013, 48'hf00100013, 48'ha000a000e, 48'hfffefffe0003, 48'hffefffeffff7, 48'hffe7ffe7fff1, 48'h100010009, 48'hf00100011, 48'hf00110011, 48'hf00110012, 48'h1000120013, 48'h1000120013, 48'h1100120013, 48'h1100120013, 48'h1100120013, 48'h1100120014, 48'h300040007, 48'hfffcfffdffff, 48'hfffbfffdfffd, 48'hfffafffcfffb, 48'hfffeffffffff, 48'hfffafffbfffd, 48'hfffcfffdffff, 48'h100020004, 48'hfffafffbfffd, 48'hffeeffeefff3, 48'hffedffedfff2, 48'ha000b000d, 48'h1100120012, 48'h1000110012, 48'h1000110012, 48'hf00100012, 48'hb000c000f, 48'h10005, 48'hfff0fff1fff5, 48'hffe5ffe6ffe9, 48'hffd9ffdbffe1, 48'hffdeffe0ffe9, 48'h30005000b, 48'he000f000f, 48'he000f0010, 48'hf00100010, 48'hf00110011, 48'h1000110011, 48'h1000110011, 48'h1100110012, 48'h1100120012, 48'h1100110012, 48'hf00100011, 48'h10002, 48'hfff8fff9fffa, 48'hfffdfffffffe, 48'hfffeffffffff, 48'hffff00000002, 48'hfffcfffdffff, 48'hfff4fff5fff7, 48'hfff5fff6fff8, 48'h100010004, 48'hfff9fff9fffd, 48'h9000a000b, 48'h1000110012, 48'hf00100013, 48'he000f0011, 48'h200040006, 48'hfff3fff5fff8, 48'hffe9ffebffed, 48'hffe3ffe4ffe7, 48'hffdaffdcffdb, 48'hffd1ffd3ffd4, 48'hffeffff2fff5, 48'hc000e000f, 48'he000e000e, 48'he000e000e, 48'hf000f000f, 48'hf000f000f, 48'hf000f000f, 48'h1000100010, 48'h1100110011, 48'h1100110011, 48'h1000100011, 48'h1000110011, 48'hf00100010, 48'hffff00010000, 48'hfff9fffafffa, 48'hfffeffffffff, 48'h400050006, 48'hffff00000002, 48'hfffcfffdfffe, 48'hfff7fff7fff9, 48'h100020003, 48'h600070008, 48'h80009000b, 48'hf00100013, 48'h90009000e, 48'hfff7fff9fffc, 48'hffe5ffe9ffea, 48'hffe7ffeaffeb, 48'hfff1fff4fff5, 48'hfffcfffeffff, 48'hffeeffefffee, 48'hffedffeeffee, 48'h700070009, 48'ha000b000b, 48'he000d000d, 48'he000d000d, 48'hf000e000e, 48'hf000e000e, 48'hf000e000e, 48'hf000f000e, 48'h10000f000f, 48'h10000f000f, 48'h100010000f, 48'hf0010000f, 48'h100010000f, 48'hb000c000c, 48'hfffdfffefffd, 48'hfffafffbfffc, 48'hffff00000002, 48'hfffcfffdfffe, 48'hfffeffff0001, 48'hfffeffff0000, 48'hfff8fff9fff9, 48'h700080009, 48'ha000a000d, 48'h4, 48'hfff1fff2fff5, 48'hffe9ffecffee, 48'hfff3fff6fff8, 48'h300050006, 48'h9000a000b, 48'h400040004, 48'hfffcfffbfffc, 48'h800050007, 48'hb0008000a, 48'ha0008000a, 48'hd000b000a, 48'hd000b000b, 48'he000c000b, 48'he000c000c, 48'he000d000c, 48'he000d000d, 48'hf000e000d, 48'hf000e000d, 48'he000e000d, 48'he000f000c, 48'he000e000c, 48'he000e000e, 48'h900090009, 48'hfffafffafffc, 48'hfff9fff9fffb, 48'hfffeffff0000, 48'h100020004, 48'h300040006, 48'hfff8fff9fffa, 48'hfff7fff8fff9, 48'hfff2fff2fff6, 48'hffebffebffef, 48'hfff3fff4fff7, 48'h300040006, 48'hb000d000f, 48'h80009000a, 48'hffffffff, 48'hfffefffe, 48'h700050006, 48'hb00070008, 48'hb00060006, 48'hb00070007, 48'hb00090008, 48'hb000a0008, 48'hc000a0009, 48'hc000a000a, 48'hd000b000a, 48'hd000c000a, 48'hd000d000b, 48'hd000d000b, 48'hd000d000b, 48'hd000d000a, 48'hd000d000a, 48'hc000c000a, 48'hd000c000b, 48'h600060006, 48'hfffcfffdffff, 48'h200030004, 48'h100020004, 48'hfff5fff5fff7, 48'hffe9ffebffec, 48'hffe8ffe9ffeb, 48'hffe9ffe9ffed, 48'hfffafffafffe, 48'he00100011, 48'hd000e000e, 48'hffffffff0001, 48'hfffafff9fffa, 48'h500030000, 48'hb00080006, 48'ha00070005, 48'h900060003, 48'ha00050002, 48'ha00060004, 48'ha00080004, 48'hb00090005, 48'hb00090006, 48'hb00090007, 48'hd00090006, 48'hc000a0006, 48'hb000b0008, 48'hc000b0008, 48'hd000b0008, 48'he000a0008, 48'hd000a0008, 48'hc000a0008, 48'hb00090008, 48'h900080008, 48'hfff9fff9fffc, 48'hfff2fff3fff5, 48'hffe9ffebffed, 48'hffe6ffe7ffe9, 48'hffe9ffebffec, 48'hfff9fffafffc, 48'h80007000b, 48'hc000c000f, 48'h200050006, 48'hfffcfffffffd, 48'hfffdfffcffff, 48'hfffbfffcfffe, 48'h40004ffff, 48'h900050002, 48'h800040001, 48'h800040000, 48'h700040000, 48'h800050001, 48'ha00060000, 48'hb00070001, 48'hb00070002, 48'hc00070003, 48'hc00070003, 48'hb00080004, 48'hb00090004, 48'hd00090004, 48'he00090004, 48'he00090004, 48'hc00080004, 48'ha00080005, 48'h900080008, 48'h600060007, 48'hffeffff0fff3, 48'hffdfffe0ffe3, 48'hffe3ffe5ffe8, 48'hfff2fff4fff8, 48'h300060009, 48'hc000e0010, 48'h80007000b, 48'hfffcfffbfffd, 48'hfff6fff8fff7, 48'h100040004, 48'hfff9fffbffff, 48'hffeaffebffed, 48'hfffcfffcfff8, 48'h800040000, 48'h70002fffe, 48'h70003fffd, 48'h60002fffc, 48'h70002fffd, 48'hb0004fffd, 48'ha0005ffff, 48'hb0005ffff, 48'hd0005fffe, 48'hb00050000, 48'hb00050000, 48'hb0006ffff, 48'he00070000, 48'he00060000, 48'hc00060000, 48'hb00070003, 48'h900060005, 48'h1, 48'hfff3fff4fff7, 48'hffe6ffe8ffeb, 48'hffe9ffebffee, 48'hfffe00010004, 48'he00100014, 48'ha000d000f, 48'hfffcfffd0000, 48'hfffafffafffd, 48'hfffefffeffff, 48'hfff8fff9fff7, 48'hfff9fffafffa, 48'hfff8fff8fff9, 48'hfff1ffefffed, 48'hfff9fff6fff1, 48'h70002fffa, 48'h60001fff9, 48'h60001fff9, 48'h60000fff8, 48'h60001fff9, 48'h80001fffb, 48'h70002fffe, 48'h80003fffd, 48'hb0004fffc, 48'hb0004fffd, 48'hb0004fffc, 48'hc0005fffb, 48'hb0005fffd, 48'hb0004ffff, 48'h900050001, 48'h40001fffe, 48'hfff8fff7fff7, 48'hffedffedffef, 48'hffeefff0fff2, 48'hfffbfffdfffe, 48'h9000a000b, 48'hd000d000d, 48'h500040002, 48'hfffafff9fff8, 48'hfffdfffcfffd, 48'h500060008, 48'h600070008, 48'hfffbfffcfffb, 48'hfff9fff8fff6, 48'hfffdfffbfff6, 48'h2fffdfff7, 48'hfff9fff3ffee, 48'h2fffcfff3, 48'h70000fff6, 48'h6fffffff4, 48'h6fffffff4, 48'h70000fff5, 48'h1fffcfff9, 48'h400000000, 48'h40001fffe, 48'h70001fffa, 48'ha0002fff9, 48'hb0003fff8, 48'hb0003fff7, 48'h90003fffb, 48'h40001fffd, 48'hfff8fff7fff7, 48'hffeeffedffee, 48'hffedffeeffef, 48'hfff5fff6fff9, 48'h500070009, 48'hb000d000e, 48'h500050003, 48'h2fffefff9, 48'h3fffefff5, 48'h1fffcfff5, 48'hfffefffbfff9, 48'h10001, 48'hfffe00000001, 48'hfffeffff0000, 48'hfffcfffafffb, 48'hfffcfffafff4, 48'h40000fffa, 48'hfffcfff8fff7, 48'hfff6fff3ffef, 48'h4fffdfff1, 48'h6fffefff1, 48'h5fffdfff0, 48'h6fffefff1, 48'h1fffafff5, 48'hfffffffafffc, 48'h200010004, 48'h40001fffe, 48'h6fffffff7, 48'h80001fff4, 48'ha0003fff7, 48'hfffefffafff4, 48'hffedffedffec, 48'hffe7ffe9ffeb, 48'hfff5fff7fff8, 48'h600080009, 48'hd000e000f, 48'h600060005, 48'hfffefffcfff7, 48'hfffffffbfff3, 48'h5fffefff3, 48'h9fffffff2, 48'h8fffefff2, 48'hfffffff9fff2, 48'hfffafff8fff6, 48'hfffcfffeffff, 48'hffff00010003, 48'hffffffff0002, 48'hfffafffafff9, 48'hfffffffefffb, 48'hfff6fff5fff8, 48'hffeaffebffe9, 48'hfffaffed, 48'h6fffdffee, 48'h4fffcffed, 48'h6fffdffed, 48'h9fffdfff0, 48'hfff8fff4, 48'hfffafffaffff, 48'h100020004, 48'h60002ffff, 48'h50000fff8, 48'hfffcfff8fff2, 48'hffeeffecffed, 48'hfff1fff3fff5, 48'h200030004, 48'ha000b000b, 48'h800080006, 48'h1fffffffa, 48'hfffffffafff2, 48'h5fffdfff0, 48'h8fffffff1, 48'h9ffffffef, 48'h8fffdffed, 48'h9fffeffed, 48'h8fffdfff0, 48'hfffafff2, 48'hfffdfffbfff9, 48'h2, 48'h200030004, 48'hfffdfffdfffe, 48'hfff8fff7fff5, 48'hfff9fff8fff5, 48'hfff6fff3ffeb, 48'hfffffff7ffe8, 48'h5fffbffeb, 48'h4fffaffe9, 48'h6fffaffe9, 48'h9fffcffeb, 48'h5fffcffee, 48'hfffafff7fff3, 48'hfffdfffcfffb, 48'h700040002, 48'hfffffffefffa, 48'hfff4fff4fff4, 48'hfffbfffafffd, 48'hfffffffffffe, 48'hfffffffd, 48'hfffdfff9, 48'hfffafff1, 48'h4fffbffee, 48'h8fffeffee, 48'h8fffeffee, 48'h8fffeffee, 48'h8fffdffed, 48'h8fffdffec, 48'h8fffdffec, 48'h8fffcffed, 48'h6fffbffed, 48'hfffffff8ffef, 48'hfffffffdfffa, 48'hfffe0000ffff, 48'hfff8fffcfff8, 48'hfffafff8fff8, 48'hfffcfff6ffed, 48'h2fff8ffe9, 48'h2fff6ffe6, 48'h5fff9ffe7, 48'h4fff8ffe6, 48'h5fff8ffe6, 48'h9fffaffe7, 48'h6fffcffe6, 48'h1fffaffeb, 48'hfffdfff7fff2, 48'hfffdfffafff9, 48'hfff5fff8fff8, 48'hfff3fff7fffa, 48'hffefffeffff2, 48'hfff4fff0ffeb, 48'hfffffff7ffec, 48'h4fffaffed, 48'h8fffcffec, 48'h9fffcffea, 48'h8fffcffea, 48'h7fffcffeb, 48'h7fffcffea, 48'h8fffbffe9, 48'h8fffbffe8, 48'h6fffaffe9, 48'h8fffaffe9, 48'hafffbffe6, 48'h6fff9ffe8, 48'hfffbfff5ffed, 48'hfff5fff7fff8, 48'hfff7fffcffff, 48'hfff8fff8fffb, 48'hfffcfff7ffec, 48'h4fff8ffe3, 48'h5fff8ffe5, 48'h4fff7ffe4, 48'h4fff6ffe2, 48'h5fff7ffe2, 48'h8fff9ffe5, 48'h6fffbffe1, 48'h6fffbffe4, 48'hfffcfff4ffeb, 48'hffebffe9ffe9, 48'hffe6ffe9ffe9, 48'hffe9ffebffee, 48'hfff2fff2fff4, 48'hfffbfff7fff0, 48'h7fffaffea, 48'hbfffcffe8, 48'hafffbffe6, 48'h6fffaffe7, 48'h5fff9ffe8, 48'h6fffaffe8, 48'h7fffaffe7, 48'h8fffaffe6, 48'h8fffaffe5, 48'h6fff9ffe6, 48'h8fff9ffe5, 48'hafff9ffe2, 48'h8fff9ffe3, 48'h1fff7ffe7, 48'hfff3ffefffed, 48'hfff1fff1fffc, 48'hfff3fff7fffa, 48'hfff8fff7fff2, 48'hfffefff6ffe4, 48'h3fff7ffe1, 48'h3fff5ffe1, 48'h3fff5ffe0, 48'h5fff6ffe0, 48'h5fff7ffe3, 48'h5fff8ffe1, 48'h8fff9ffe1, 48'hfffbfff2ffe5, 48'hffe1ffe1ffe2, 48'hffe0ffe2ffe2, 48'hffeeffedffeb, 48'hfffbfff9fffa, 48'hfffefffcfff8, 48'h1fff8ffeb, 48'h6fff8ffe6, 48'h9fff9ffe3, 48'h8fff9ffe3, 48'h5fff8ffe4, 48'h5fff8ffe4, 48'h6fff8ffe3, 48'h6fff8ffe3, 48'h7fff8ffe2, 48'h6fff8ffe2, 48'h6fff8ffe2, 48'h6fff7ffe1, 48'h6fff7ffe1, 48'h5fff7ffe1, 48'hfffffff3ffe6, 48'hfff3ffeeffee, 48'hffeeffeffff6, 48'hfff3fff4fff8, 48'hfffbfff5ffee, 48'hfffffff4ffdf, 48'h1fff4ffde, 48'h1fff4ffdd, 48'h3fff5ffdd, 48'h3fff5ffe1, 48'h4fff6ffe0, 48'h8fff7ffde, 48'hfff8fff0ffe3, 48'hffe0ffe1ffe3, 48'hffe7ffe7ffe4, 48'hfff7fff1ffe8, 48'hfffafff3ffec, 48'hfffdfff9fff4, 48'hfffbfff4, 48'h1fff6ffe7, 48'h7fff7ffe1, 48'h9fff8ffdf, 48'h7fff7ffe0, 48'h5fff7ffe1, 48'h5fff6ffe0, 48'h6fff6ffe0, 48'h6fff6ffe0, 48'h6fff6ffdf, 48'h5fff6ffdf, 48'h4fff5ffe0, 48'h4fff5ffdf, 48'h6fff5ffdd, 48'h6fff5ffdd, 48'hfffdfff4ffe0, 48'hfff0ffecffed, 48'hfff1ffeffff8, 48'hfffafff7fffa, 48'hfffefff4ffe4, 48'hfffffff2ffdd, 48'h1fff3ffdc, 48'h3fff4ffdb, 48'h3fff4ffdf, 48'h4fff5ffdd, 48'h7fff6ffdb, 48'hfff4ffedffe3, 48'hffdfffe1ffe3, 48'hffedffe9ffe2, 48'h2fff4ffe2, 48'h3fff4ffe0, 48'hfffffff4ffe5, 48'hfff7ffec, 48'h2fff5ffe4, 48'h6fff5ffde, 48'h6fff6ffdd, 48'h5fff5ffde, 48'h6fff5ffde, 48'h6fff5ffde, 48'h5fff5ffdd, 48'h5fff5ffdd, 48'h5fff4ffdd, 48'h5fff4ffdd, 48'h5fff4ffdd, 48'h5fff4ffdd, 48'h5fff4ffdd, 48'h5fff4ffdc, 48'h2fff5ffda, 48'hfffafff1ffe1, 48'hfff3ffecffed, 48'hfff8fff4fff3, 48'hfffefff4ffe7, 48'hfffefff1ffdd, 48'h2fff2ffda, 48'h4fff2ffda, 48'h3fff3ffdd, 48'h3fff3ffdb, 48'h5fff4ffda, 48'hfff4ffecffe0, 48'hffe6ffe4ffe0, 48'hfff4ffedffe1, 48'h4fff4ffdd, 48'h6fff5ffdc, 48'h1fff3ffdf, 48'hfff3ffe1, 48'h4fff4ffde, 48'h6fff4ffdc, 48'h4fff4ffdc, 48'h3fff4ffdd, 48'h5fff4ffdc, 48'h5fff4ffdc, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h4fff3ffdc, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h6fff2ffdc, 48'h5fff3ffd8, 48'h2fff2ffdb, 48'hfffdffefffe1, 48'hfffcfff1ffdf, 48'hfffefff1ffdd, 48'hfffffff1ffda, 48'h1fff1ffd8, 48'h2fff1ffd8, 48'h3fff2ffdb, 48'h4fff2ffda, 48'h5fff3ffda, 48'hfff9ffedffdd, 48'hfff2ffebffde, 48'hfffdfff2ffdf, 48'h5fff4ffda, 48'h6fff4ffd8, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h6fff3ffda, 48'h6fff4ffda, 48'h4fff3ffdb, 48'h3fff3ffdc, 48'h4fff3ffdb, 48'h4fff3ffdb, 48'h4fff2ffda, 48'h4fff2ffda, 48'h4fff2ffda, 48'h4fff3ffda, 48'h4fff2ffda, 48'h4fff2ffda, 48'h4fff2ffda, 48'h4fff1ffda, 48'h5fff2ffd7, 48'h4fff2ffd7, 48'h4fff1ffda, 48'h4fff1ffd7, 48'h2fff1ffd8, 48'hfff0ffd7, 48'hfff0ffd6, 48'hfff0ffd7, 48'h3fff1ffda, 48'h4fff1ffda, 48'h4fff1ffda, 48'hfff1ffdc, 48'hfffdfff1ffdd, 48'h1fff2ffdb, 48'h5fff3ffd8, 48'h6fff3ffd8, 48'h5fff3ffd8, 48'h5fff3ffd8, 48'h6fff3ffd8, 48'h5fff3ffd8, 48'h4fff2ffd9, 48'h3fff2ffda, 48'h4fff2ffd9, 48'h4fff2ffd9, 48'h4fff2ffd9, 48'h4fff2ffd9, 48'h4fff2ffd9, 48'h3fff2ffd8, 48'h3fff1ffd8, 48'h3fff1ffd8, 48'h3fff1ffd8, 48'h2fff1ffd7, 48'h1fff1ffd6, 48'h2fff1ffd8, 48'h3ffefffd9, 48'h3ffeeffd9, 48'h2ffefffd6, 48'hffefffd5, 48'hffffffeeffd5, 48'hffffffeeffd6, 48'h3fff0ffd7, 48'h4ffefffd8, 48'h2ffefffda, 48'h2fff1ffd9, 48'h2fff1ffd9, 48'h2fff1ffd9, 48'h4fff1ffd8, 48'h4fff2ffd8, 48'h4fff2ffd8, 48'h4fff2ffd7, 48'h4fff2ffd7, 48'h4fff1ffd8, 48'h4fff1ffd8, 48'h4fff1ffd8, 48'h3fff1ffd8, 48'h3fff1ffd8, 48'h3fff1ffd7, 48'h3fff1ffd7, 48'h3fff1ffd7, 48'h2fff0ffd7, 48'h2fff0ffd7, 48'h2fff0ffd7, 48'h2fff0ffd7, 48'h1fff0ffd6, 48'hffefffd7, 48'hffefffd7, 48'hffeeffd7, 48'hffedffd7, 48'hffedffd6, 48'hffffffedffd5, 48'hfffdffecffd5, 48'hffedffd5};

// This is the expected output
wire [15:0] airplane4_pred [9:0] = { 16'h000c, 16'hffc7, 16'hfeab, 16'hfe39, 16'hfec7, 16'hfe4b, 16'hfe0b, 16'hfe85, 16'hff62, 16'h03d2 };

   reg         clock;
   reg 	       reset;
   wire        rdy_in;
   reg 	       vld_in;
   reg 	       rdy_out;
   wire        vld_out;
   wire [15:0] bits_out [9:0];

   reg [6:0]   img_cntr;
   wire        bits_out_0_correct;
   wire [511:0] data_in;
   wire [511:0] data_out;
   wire [9:0] 	cnt_0;
   assign cnt_0 = img_cntr*8;
   wire [9:0] 	cnt_1;
   assign cnt_1 = (img_cntr*8) + 1;
   wire [9:0] 	cnt_2;
   assign cnt_2 = (img_cntr*8) + 2;
   wire [9:0] 	cnt_3;
   assign cnt_3 = (img_cntr*8) + 3;
   wire [9:0] 	cnt_4;
   assign cnt_4 = (img_cntr*8) + 4;
   wire [9:0] 	cnt_5;
   assign cnt_5 = (img_cntr*8) + 5;
   wire [9:0] 	cnt_6;
   assign cnt_6 = (img_cntr*8) + 6;
   wire [9:0] 	cnt_7;
   assign cnt_7 = (img_cntr*8) + 7;
   
   assign data_in[47:0] = airplane4_image[cnt_0];
   assign data_in[63:48] = 0;
   assign data_in[111:64] = airplane4_image[cnt_1];
   assign data_in[127:112] = 0;
   assign data_in[175:128] = airplane4_image[cnt_2];
   assign data_in[191:176] = 0;
   assign data_in[239:192] = airplane4_image[cnt_3];
   assign data_in[255:240] = 0;
   assign data_in[303:256] = airplane4_image[cnt_4];
   assign data_in[319:304] = 0;
   assign data_in[367:320] = airplane4_image[cnt_5];
   assign data_in[383:368] = 0;
   assign data_in[431:384] = airplane4_image[cnt_6];
   assign data_in[447:432] = 0;
   assign data_in[495:448] = airplane4_image[cnt_7];
   assign data_in[511:496] = 0;

   assign bits_out_0_correct = ( bits_out == airplane4_pred );
   assign bits_out[0] = data_out[15:0];
   assign bits_out[1] = data_out[31:16];
   assign bits_out[2] = data_out[47:32];
   assign bits_out[3] = data_out[63:48];
   assign bits_out[4] = data_out[79:64];
   assign bits_out[5] = data_out[95:80];
   assign bits_out[6] = data_out[111:96];
   assign bits_out[7] = data_out[127:112];
   assign bits_out[8] = data_out[143:128];
   assign bits_out[9] = data_out[159:144];

   /* Instantiation of top level design */
cl_sde_srm
dut (
     .clk( clock ),
     .rst_n( !reset ),
     .ins_valid( vld_in ),
     .ins_ready( rdy_in ),
     .ins_data( data_in ),
     .ins_keep(64'hffffffffffffffff),
     .ins_user(64'h0),
     .ins_last( img_cntr == 127 ),
     .ots_valid(vld_out),
     .ots_data( data_out ),
     .ots_ready( rdy_out )
   );

reg [1:0] mbuf_hdr;
   
always @(posedge clock)
  begin
     if ( reset ) begin
	mbuf_hdr <= 2;
     end else begin
	if ( vld_in & rdy_in ) begin
	   mbuf_hdr <= { 0, mbuf_hdr[1] };
	end
     end
     if ( vld_in & rdy_in & ( mbuf_hdr == 0 ) )
       begin
	  img_cntr <= img_cntr + 1'h1;
       end
     if ( vld_out )
       begin
	  if ( bits_out_0_correct )
	    begin
	       $display("ASSERTION PASSED: %h == %h", bits_out[0], airplane4_pred[0]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[1], airplane4_pred[1]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[2], airplane4_pred[2]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[3], airplane4_pred[3]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[4], airplane4_pred[4]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[5], airplane4_pred[5]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[6], airplane4_pred[6]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[7], airplane4_pred[7]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[8], airplane4_pred[8]);
	       $display("ASSERTION PASSED: %h == %h", bits_out[9], airplane4_pred[9]);
	    end else begin
	       $display("ASSERTION FAILED: %h == %h", bits_out[0], airplane4_pred[0]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[1], airplane4_pred[1]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[2], airplane4_pred[2]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[3], airplane4_pred[3]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[4], airplane4_pred[4]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[5], airplane4_pred[5]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[6], airplane4_pred[6]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[7], airplane4_pred[7]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[8], airplane4_pred[8]);
	       $display("ASSERTION FAILED: %h == %h", bits_out[9], airplane4_pred[9]);
	    end
	  $finish;
       end
  end

// 125MHz clock
always #4 clock = ~clock;

initial begin
   clock = 0;
   reset = 1;
   vld_in = 0;
   rdy_out = 1;
   img_cntr = 0;
   #32
   reset = 0;
   #32 // wait a little more for the fifos
   vld_in = 1;
end

endmodule


module DenseBlackBox255c5dd06e(
  input clock,
  input [6:0] readAddr,
  output [19:0] out
);

reg [19:0] rom_uints [127:0];
initial
begin
rom_uints[0] = 20'h43d0;
rom_uints[1] = 20'hf130;
rom_uints[2] = 20'h4c13;
rom_uints[3] = 20'h1d33;
rom_uints[4] = 20'hd1d3;
rom_uints[5] = 20'hc31;
rom_uints[6] = 20'h300c1;
rom_uints[7] = 20'hf40;
rom_uints[8] = 20'h1d0;
rom_uints[9] = 20'h4f0f1;
rom_uints[10] = 20'hcd0;
rom_uints[11] = 20'hc0f04;
rom_uints[12] = 20'h10d0;
rom_uints[13] = 20'h1f301;
rom_uints[14] = 20'h133c1;
rom_uints[15] = 20'h34c;
rom_uints[16] = 20'h13c0;
rom_uints[17] = 20'h1303;
rom_uints[18] = 20'h4cc0;
rom_uints[19] = 20'hfc004;
rom_uints[20] = 20'h43f37;
rom_uints[21] = 20'h11c0;
rom_uints[22] = 20'h3c341;
rom_uints[23] = 20'hf1;
rom_uints[24] = 20'h4c300;
rom_uints[25] = 20'hcc43;
rom_uints[26] = 20'hd703;
rom_uints[27] = 20'hf3503;
rom_uints[28] = 20'h44c3;
rom_uints[29] = 20'h14c03;
rom_uints[30] = 20'h3f111;
rom_uints[31] = 20'h4fc04;
rom_uints[32] = 20'h3300d;
rom_uints[33] = 20'hc031;
rom_uints[34] = 20'hf1c04;
rom_uints[35] = 20'hc473;
rom_uints[36] = 20'h4cd0;
rom_uints[37] = 20'hf4d;
rom_uints[38] = 20'h53c03;
rom_uints[39] = 20'h1c003;
rom_uints[40] = 20'hd0c;
rom_uints[41] = 20'h4000c;
rom_uints[42] = 20'h10f0;
rom_uints[43] = 20'h10ff1;
rom_uints[44] = 20'h403c0;
rom_uints[45] = 20'h1;
rom_uints[46] = 20'h100cc;
rom_uints[47] = 20'hd1034;
rom_uints[48] = 20'h10f40;
rom_uints[49] = 20'h14f0;
rom_uints[50] = 20'h10f0;
rom_uints[51] = 20'h3dc10;
rom_uints[52] = 20'h70f04;
rom_uints[53] = 20'hd0c00;
rom_uints[54] = 20'h33034;
rom_uints[55] = 20'hf744f;
rom_uints[56] = 20'h44f0;
rom_uints[57] = 20'h1f0;
rom_uints[58] = 20'hc1d0;
rom_uints[59] = 20'hd0f1c;
rom_uints[60] = 20'h304c1;
rom_uints[61] = 20'h104c0;
rom_uints[62] = 20'h1c03c;
rom_uints[63] = 20'h10037;
rom_uints[64] = 20'h1c0;
rom_uints[65] = 20'h1c30;
rom_uints[66] = 20'h77c0;
rom_uints[67] = 20'h743f7;
rom_uints[68] = 20'hc13;
rom_uints[69] = 20'hd33;
rom_uints[70] = 20'h4f0;
rom_uints[71] = 20'h7d0;
rom_uints[72] = 20'h4c0c0;
rom_uints[73] = 20'h4c0;
rom_uints[74] = 20'hf70;
rom_uints[75] = 20'h41300;
rom_uints[76] = 20'h1fff5;
rom_uints[77] = 20'h3d40;
rom_uints[78] = 20'h5ff0;
rom_uints[79] = 20'h400c0;
rom_uints[80] = 20'h7c0;
rom_uints[81] = 20'h3010;
rom_uints[82] = 20'h31c;
rom_uints[83] = 20'h1d00;
rom_uints[84] = 20'hc74;
rom_uints[85] = 20'h103c7;
rom_uints[86] = 20'h3d13c;
rom_uints[87] = 20'h70d3;
rom_uints[88] = 20'hcf1;
rom_uints[89] = 20'hdc1dc;
rom_uints[90] = 20'hf40f1;
rom_uints[91] = 20'hc40;
rom_uints[92] = 20'h473;
rom_uints[93] = 20'hcd700;
rom_uints[94] = 20'h4c0c7;
rom_uints[95] = 20'h3cd53;
rom_uints[96] = 20'hfc134;
rom_uints[97] = 20'h313;
rom_uints[98] = 20'hc4ccc;
rom_uints[99] = 20'h3340;
rom_uints[100] = 20'h310d0;
rom_uints[101] = 20'h3d0;
rom_uints[102] = 20'hf3c11;
rom_uints[103] = 20'h5033c;
rom_uints[104] = 20'hdc10;
rom_uints[105] = 20'hfc740;
rom_uints[106] = 20'h314c1;
rom_uints[107] = 20'h4cf0;
rom_uints[108] = 20'h700c0;
rom_uints[109] = 20'hc744f;
rom_uints[110] = 20'hc7c0;
rom_uints[111] = 20'h400c0;
rom_uints[112] = 20'hc41c3;
rom_uints[113] = 20'hf470;
rom_uints[114] = 20'h7703c;
rom_uints[115] = 20'hc130;
rom_uints[116] = 20'hc70;
rom_uints[117] = 20'hc7dc0;
rom_uints[118] = 20'h7131;
rom_uints[119] = 20'hd0;
rom_uints[120] = 20'hc3007;
rom_uints[121] = 20'h130f;
rom_uints[122] = 20'hd0c31;
rom_uints[123] = 20'h433c;
rom_uints[124] = 20'hc1c70;
rom_uints[125] = 20'hcf010;
rom_uints[126] = 20'hc0004;
rom_uints[127] = 20'h13430;
end

reg [19:0] outputReg;
assign out = outputReg;
always @(posedge clock)
begin
  outputReg <= rom_uints[readAddr];
end
endmodule

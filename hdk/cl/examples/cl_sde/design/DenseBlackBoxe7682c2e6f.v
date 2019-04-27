
module DenseBlackBoxe7682c2e6f(
  input clock,
  input [6:0] readAddr,
  output [15:0] out
);

reg [15:0] rom_uints [127:0];
initial
begin
rom_uints[0] = 16'h8;
rom_uints[1] = 16'h9;
rom_uints[2] = 16'h7;
rom_uints[3] = 16'h6;
rom_uints[4] = 16'h5;
rom_uints[5] = 16'h7;
rom_uints[6] = 16'h8;
rom_uints[7] = 16'h9;
rom_uints[8] = 16'h7;
rom_uints[9] = 16'h7;
rom_uints[10] = 16'h9;
rom_uints[11] = 16'h6;
rom_uints[12] = 16'h7;
rom_uints[13] = 16'h6;
rom_uints[14] = 16'h8;
rom_uints[15] = 16'h8;
rom_uints[16] = 16'h8;
rom_uints[17] = 16'h6;
rom_uints[18] = 16'h8;
rom_uints[19] = 16'h8;
rom_uints[20] = 16'h6;
rom_uints[21] = 16'h7;
rom_uints[22] = 16'h7;
rom_uints[23] = 16'ha;
rom_uints[24] = 16'h7;
rom_uints[25] = 16'h6;
rom_uints[26] = 16'h7;
rom_uints[27] = 16'h7;
rom_uints[28] = 16'h6;
rom_uints[29] = 16'h8;
rom_uints[30] = 16'h7;
rom_uints[31] = 16'h8;
rom_uints[32] = 16'h7;
rom_uints[33] = 16'ha;
rom_uints[34] = 16'h7;
rom_uints[35] = 16'h6;
rom_uints[36] = 16'h7;
rom_uints[37] = 16'h6;
rom_uints[38] = 16'h8;
rom_uints[39] = 16'h9;
rom_uints[40] = 16'h8;
rom_uints[41] = 16'h8;
rom_uints[42] = 16'h8;
rom_uints[43] = 16'h7;
rom_uints[44] = 16'h7;
rom_uints[45] = 16'ha;
rom_uints[46] = 16'h7;
rom_uints[47] = 16'h8;
rom_uints[48] = 16'h7;
rom_uints[49] = 16'h7;
rom_uints[50] = 16'h8;
rom_uints[51] = 16'h6;
rom_uints[52] = 16'h7;
rom_uints[53] = 16'hb;
rom_uints[54] = 16'h7;
rom_uints[55] = 16'h7;
rom_uints[56] = 16'h7;
rom_uints[57] = 16'h8;
rom_uints[58] = 16'h7;
rom_uints[59] = 16'h7;
rom_uints[60] = 16'h7;
rom_uints[61] = 16'h7;
rom_uints[62] = 16'h8;
rom_uints[63] = 16'h7;
rom_uints[64] = 16'h7;
rom_uints[65] = 16'h9;
rom_uints[66] = 16'h6;
rom_uints[67] = 16'h7;
rom_uints[68] = 16'h8;
rom_uints[69] = 16'h7;
rom_uints[70] = 16'h8;
rom_uints[71] = 16'h6;
rom_uints[72] = 16'h9;
rom_uints[73] = 16'h8;
rom_uints[74] = 16'h8;
rom_uints[75] = 16'h7;
rom_uints[76] = 16'h7;
rom_uints[77] = 16'h6;
rom_uints[78] = 16'h7;
rom_uints[79] = 16'h9;
rom_uints[80] = 16'ha;
rom_uints[81] = 16'h7;
rom_uints[82] = 16'h8;
rom_uints[83] = 16'h7;
rom_uints[84] = 16'h8;
rom_uints[85] = 16'h9;
rom_uints[86] = 16'h6;
rom_uints[87] = 16'h7;
rom_uints[88] = 16'h8;
rom_uints[89] = 16'h6;
rom_uints[90] = 16'h7;
rom_uints[91] = 16'h8;
rom_uints[92] = 16'h8;
rom_uints[93] = 16'h7;
rom_uints[94] = 16'h7;
rom_uints[95] = 16'h6;
rom_uints[96] = 16'h8;
rom_uints[97] = 16'h7;
rom_uints[98] = 16'h9;
rom_uints[99] = 16'h8;
rom_uints[100] = 16'h7;
rom_uints[101] = 16'h9;
rom_uints[102] = 16'h7;
rom_uints[103] = 16'h7;
rom_uints[104] = 16'h7;
rom_uints[105] = 16'h6;
rom_uints[106] = 16'h8;
rom_uints[107] = 16'h7;
rom_uints[108] = 16'h7;
rom_uints[109] = 16'h5;
rom_uints[110] = 16'h7;
rom_uints[111] = 16'h7;
rom_uints[112] = 16'h7;
rom_uints[113] = 16'h7;
rom_uints[114] = 16'h7;
rom_uints[115] = 16'h8;
rom_uints[116] = 16'h8;
rom_uints[117] = 16'h7;
rom_uints[118] = 16'h7;
rom_uints[119] = 16'h9;
rom_uints[120] = 16'h7;
rom_uints[121] = 16'h7;
rom_uints[122] = 16'h6;
rom_uints[123] = 16'h7;
rom_uints[124] = 16'h6;
rom_uints[125] = 16'h8;
rom_uints[126] = 16'ha;
rom_uints[127] = 16'h7;
end

reg [15:0] outputReg;
assign out = outputReg;
always @(posedge clock)
begin
  outputReg <= rom_uints[readAddr];
end
endmodule

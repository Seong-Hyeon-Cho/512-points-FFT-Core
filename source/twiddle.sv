`timescale 1ns/1ps

module twidle1_3#(
    parameter IN_WIDTH = 14,
    parameter OUT_WIDTH = 23
)(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [IN_WIDTH-1:0] din_i[15:0],
    input logic signed [IN_WIDTH-1:0] din_q[15:0],
    output logic signed [OUT_WIDTH-1:0] dout_i[15:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[15:0],
    output logic o_valid
);

    wire signed [8:0] factor_re [0:63];
    wire signed [8:0] factor_im [0:63];

    // assign 초기화
    assign factor_re[0] = 9'sd128;  assign factor_im[0] = 9'sd0;
    assign factor_re[1] = 9'sd128;  assign factor_im[1] = 9'sd0;
    assign factor_re[2] = 9'sd128;  assign factor_im[2] = 9'sd0;
    assign factor_re[3] = 9'sd128;  assign factor_im[3] = 9'sd0;
    assign factor_re[4] = 9'sd128;  assign factor_im[4] = 9'sd0;
    assign factor_re[5] = 9'sd128;  assign factor_im[5] = 9'sd0;
    assign factor_re[6] = 9'sd128;  assign factor_im[6] = 9'sd0;
    assign factor_re[7] = 9'sd128;  assign factor_im[7] = 9'sd0;
    assign factor_re[8] = 9'sd128;  assign factor_im[8] = 9'sd0;
    assign factor_re[9] = 9'sd118;  assign factor_im[9] = -9'sd49;
    assign factor_re[10] = 9'sd91;  assign factor_im[10] = -9'sd91;
    assign factor_re[11] = 9'sd49;  assign factor_im[11] = -9'sd118;
    assign factor_re[12] = 9'sd0;   assign factor_im[12] = -9'sd128;
    assign factor_re[13] = -9'sd49; assign factor_im[13] = -9'sd118;
    assign factor_re[14] = -9'sd91; assign factor_im[14] = -9'sd91;
    assign factor_re[15] = -9'sd118; assign factor_im[15] = -9'sd49;
    assign factor_re[16] = 9'sd128;  assign factor_im[16] = 9'sd0;
    assign factor_re[17] = 9'sd126;  assign factor_im[17] = -9'sd25;
    assign factor_re[18] = 9'sd118;  assign factor_im[18] = -9'sd49;
    assign factor_re[19] = 9'sd106;  assign factor_im[19] = -9'sd71;
    assign factor_re[20] = 9'sd91;   assign factor_im[20] = -9'sd91;
    assign factor_re[21] = 9'sd71;   assign factor_im[21] = -9'sd106;
    assign factor_re[22] = 9'sd49;   assign factor_im[22] = -9'sd118;
    assign factor_re[23] = 9'sd25;   assign factor_im[23] = -9'sd126;
    assign factor_re[24] = 9'sd128;  assign factor_im[24] = 9'sd0;
    assign factor_re[25] = 9'sd106;  assign factor_im[25] = -9'sd71;
    assign factor_re[26] = 9'sd49;   assign factor_im[26] = -9'sd118;
    assign factor_re[27] = -9'sd25;  assign factor_im[27] = -9'sd126;
    assign factor_re[28] = -9'sd91;  assign factor_im[28] = -9'sd91;
    assign factor_re[29] = -9'sd126; assign factor_im[29] = -9'sd25;
    assign factor_re[30] = -9'sd118; assign factor_im[30] = 9'sd49;
    assign factor_re[31] = -9'sd71;  assign factor_im[31] = 9'sd106;
    assign factor_re[32] = 9'sd128;  assign factor_im[32] = 9'sd0;
    assign factor_re[33] = 9'sd127;  assign factor_im[33] = -9'sd13;
    assign factor_re[34] = 9'sd126;  assign factor_im[34] = -9'sd25;
    assign factor_re[35] = 9'sd122;  assign factor_im[35] = -9'sd37;
    assign factor_re[36] = 9'sd118;  assign factor_im[36] = -9'sd49;
    assign factor_re[37] = 9'sd113;  assign factor_im[37] = -9'sd60;
    assign factor_re[38] = 9'sd106;  assign factor_im[38] = -9'sd71;
    assign factor_re[39] = 9'sd99;   assign factor_im[39] = -9'sd81;
    assign factor_re[40] = 9'sd128;  assign factor_im[40] = 9'sd0;
    assign factor_re[41] = 9'sd113;  assign factor_im[41] = -9'sd60;
    assign factor_re[42] = 9'sd71;   assign factor_im[42] = -9'sd106;
    assign factor_re[43] = 9'sd13;   assign factor_im[43] = -9'sd127;
    assign factor_re[44] = -9'sd49;  assign factor_im[44] = -9'sd118;
    assign factor_re[45] = -9'sd99;  assign factor_im[45] = -9'sd81;
    assign factor_re[46] = -9'sd126; assign factor_im[46] = -9'sd25;
    assign factor_re[47] = -9'sd122; assign factor_im[47] = 9'sd37;
    assign factor_re[48] = 9'sd128;  assign factor_im[48] = 9'sd0;
    assign factor_re[49] = 9'sd122;  assign factor_im[49] = -9'sd37;
    assign factor_re[50] = 9'sd106;  assign factor_im[50] = -9'sd71;
    assign factor_re[51] = 9'sd81;   assign factor_im[51] = -9'sd99;
    assign factor_re[52] = 9'sd49;   assign factor_im[52] = -9'sd118;
    assign factor_re[53] = 9'sd13;   assign factor_im[53] = -9'sd127;
    assign factor_re[54] = -9'sd25;  assign factor_im[54] = -9'sd126;
    assign factor_re[55] = -9'sd60;  assign factor_im[55] = -9'sd113;
    assign factor_re[56] = 9'sd128;  assign factor_im[56] = 9'sd0;
    assign factor_re[57] = 9'sd99;   assign factor_im[57] = -9'sd81;
    assign factor_re[58] = 9'sd25;   assign factor_im[58] = -9'sd126;
    assign factor_re[59] = -9'sd60;  assign factor_im[59] = -9'sd113;
    assign factor_re[60] = -9'sd118; assign factor_im[60] = -9'sd49;
    assign factor_re[61] = -9'sd122; assign factor_im[61] = 9'sd37;
    assign factor_re[62] = -9'sd71;  assign factor_im[62] = 9'sd106;
    assign factor_re[63] = 9'sd13;   assign factor_im[63] = 9'sd127;

    
    // 내부 카운터: 0~511 (64개씩 순환)
    reg [8:0] data_idx;
    integer i;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_idx <= 0;
            for (i = 0; i < 16; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
            o_valid <= 0;
        end else begin
            if (i_valid) begin
                for (i = 0; i < 16; i++) begin
                    // 64개씩 순환하는 인덱스 사용
                    dout_i[i] <= din_i[i] * factor_re[(data_idx + i) % 64] - din_q[i] * factor_im[(data_idx + i) % 64];
                    dout_q[i] <= din_i[i] * factor_im[(data_idx + i) % 64] + din_q[i] * factor_re[(data_idx + i) % 64];
                end
                
                if (data_idx >= 512 - 16) begin  // 마지막 블록 처리 후
                    data_idx <= 0;  // 리셋
                end else begin
                    data_idx <= data_idx + 16;
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule


module twidle0_3 #(
    parameter IN_WIDTH = 14,
    parameter OUT_WIDTH = 23
)(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [IN_WIDTH-1:0] din_i[15:0],
    input logic signed [IN_WIDTH-1:0] din_q[15:0],
    output logic signed [OUT_WIDTH-1:0] dout_i[15:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[15:0],
    output logic o_valid
);

    logic signed [8:0] factor_re [0:511];
    logic signed [8:0] factor_im [0:511];

    
    assign factor_re[0] = 9'sd128; assign factor_im[0] = 9'sd0;
    assign factor_re[1] = 9'sd128; assign factor_im[1] = 9'sd0;
    assign factor_re[2] = 9'sd128; assign factor_im[2] = 9'sd0;
    assign factor_re[3] = 9'sd128; assign factor_im[3] = 9'sd0;
    assign factor_re[4] = 9'sd128; assign factor_im[4] = 9'sd0;
    assign factor_re[5] = 9'sd128; assign factor_im[5] = 9'sd0;
    assign factor_re[6] = 9'sd128; assign factor_im[6] = 9'sd0;
    assign factor_re[7] = 9'sd128; assign factor_im[7] = 9'sd0;
    assign factor_re[8] = 9'sd128; assign factor_im[8] = 9'sd0;
    assign factor_re[9] = 9'sd128; assign factor_im[9] = 9'sd0;
    assign factor_re[10] = 9'sd128; assign factor_im[10] = 9'sd0;
    assign factor_re[11] = 9'sd128; assign factor_im[11] = 9'sd0;
    assign factor_re[12] = 9'sd128; assign factor_im[12] = 9'sd0;
    assign factor_re[13] = 9'sd128; assign factor_im[13] = 9'sd0;
    assign factor_re[14] = 9'sd128; assign factor_im[14] = 9'sd0;
    assign factor_re[15] = 9'sd128; assign factor_im[15] = 9'sd0;
    assign factor_re[16] = 9'sd128; assign factor_im[16] = 9'sd0;
    assign factor_re[17] = 9'sd128; assign factor_im[17] = 9'sd0;
    assign factor_re[18] = 9'sd128; assign factor_im[18] = 9'sd0;
    assign factor_re[19] = 9'sd128; assign factor_im[19] = 9'sd0;
    assign factor_re[20] = 9'sd128; assign factor_im[20] = 9'sd0;
    assign factor_re[21] = 9'sd128; assign factor_im[21] = 9'sd0;
    assign factor_re[22] = 9'sd128; assign factor_im[22] = 9'sd0;
    assign factor_re[23] = 9'sd128; assign factor_im[23] = 9'sd0;
    assign factor_re[24] = 9'sd128; assign factor_im[24] = 9'sd0;
    assign factor_re[25] = 9'sd128; assign factor_im[25] = 9'sd0;
    assign factor_re[26] = 9'sd128; assign factor_im[26] = 9'sd0;
    assign factor_re[27] = 9'sd128; assign factor_im[27] = 9'sd0;
    assign factor_re[28] = 9'sd128; assign factor_im[28] = 9'sd0;
    assign factor_re[29] = 9'sd128; assign factor_im[29] = 9'sd0;
    assign factor_re[30] = 9'sd128; assign factor_im[30] = 9'sd0;
    assign factor_re[31] = 9'sd128; assign factor_im[31] = 9'sd0;
    assign factor_re[32] = 9'sd128; assign factor_im[32] = 9'sd0;
    assign factor_re[33] = 9'sd128; assign factor_im[33] = 9'sd0;
    assign factor_re[34] = 9'sd128; assign factor_im[34] = 9'sd0;
    assign factor_re[35] = 9'sd128; assign factor_im[35] = 9'sd0;
    assign factor_re[36] = 9'sd128; assign factor_im[36] = 9'sd0;
    assign factor_re[37] = 9'sd128; assign factor_im[37] = 9'sd0;
    assign factor_re[38] = 9'sd128; assign factor_im[38] = 9'sd0;
    assign factor_re[39] = 9'sd128; assign factor_im[39] = 9'sd0;
    assign factor_re[40] = 9'sd128; assign factor_im[40] = 9'sd0;
    assign factor_re[41] = 9'sd128; assign factor_im[41] = 9'sd0;
    assign factor_re[42] = 9'sd128; assign factor_im[42] = 9'sd0;
    assign factor_re[43] = 9'sd128; assign factor_im[43] = 9'sd0;
    assign factor_re[44] = 9'sd128; assign factor_im[44] = 9'sd0;
    assign factor_re[45] = 9'sd128; assign factor_im[45] = 9'sd0;
    assign factor_re[46] = 9'sd128; assign factor_im[46] = 9'sd0;
    assign factor_re[47] = 9'sd128; assign factor_im[47] = 9'sd0;
    assign factor_re[48] = 9'sd128; assign factor_im[48] = 9'sd0;
    assign factor_re[49] = 9'sd128; assign factor_im[49] = 9'sd0;
    assign factor_re[50] = 9'sd128; assign factor_im[50] = 9'sd0;
    assign factor_re[51] = 9'sd128; assign factor_im[51] = 9'sd0;
    assign factor_re[52] = 9'sd128; assign factor_im[52] = 9'sd0;
    assign factor_re[53] = 9'sd128; assign factor_im[53] = 9'sd0;
    assign factor_re[54] = 9'sd128; assign factor_im[54] = 9'sd0;
    assign factor_re[55] = 9'sd128; assign factor_im[55] = 9'sd0;
    assign factor_re[56] = 9'sd128; assign factor_im[56] = 9'sd0;
    assign factor_re[57] = 9'sd128; assign factor_im[57] = 9'sd0;
    assign factor_re[58] = 9'sd128; assign factor_im[58] = 9'sd0;
    assign factor_re[59] = 9'sd128; assign factor_im[59] = 9'sd0;
    assign factor_re[60] = 9'sd128; assign factor_im[60] = 9'sd0;
    assign factor_re[61] = 9'sd128; assign factor_im[61] = 9'sd0;
    assign factor_re[62] = 9'sd128; assign factor_im[62] = 9'sd0;
    assign factor_re[63] = 9'sd128; assign factor_im[63] = 9'sd0;
    assign factor_re[64] = 9'sd128; assign factor_im[64] = 9'sd0;
    assign factor_re[65] = 9'sd128; assign factor_im[65] = -9'sd6;
    assign factor_re[66] = 9'sd127; assign factor_im[66] = -9'sd13;
    assign factor_re[67] = 9'sd127; assign factor_im[67] = -9'sd19;
    assign factor_re[68] = 9'sd126; assign factor_im[68] = -9'sd25;
    assign factor_re[69] = 9'sd124; assign factor_im[69] = -9'sd31;
    assign factor_re[70] = 9'sd122; assign factor_im[70] = -9'sd37;
    assign factor_re[71] = 9'sd121; assign factor_im[71] = -9'sd43;
    assign factor_re[72] = 9'sd118; assign factor_im[72] = -9'sd49;
    assign factor_re[73] = 9'sd116; assign factor_im[73] = -9'sd55;
    assign factor_re[74] = 9'sd113; assign factor_im[74] = -9'sd60;
    assign factor_re[75] = 9'sd110; assign factor_im[75] = -9'sd66;
    assign factor_re[76] = 9'sd106; assign factor_im[76] = -9'sd71;
    assign factor_re[77] = 9'sd103; assign factor_im[77] = -9'sd76;
    assign factor_re[78] = 9'sd99; assign factor_im[78] = -9'sd81;
    assign factor_re[79] = 9'sd95; assign factor_im[79] = -9'sd86;
    assign factor_re[80] = 9'sd91; assign factor_im[80] = -9'sd91;
    assign factor_re[81] = 9'sd86; assign factor_im[81] = -9'sd95;
    assign factor_re[82] = 9'sd81; assign factor_im[82] = -9'sd99;
    assign factor_re[83] = 9'sd76; assign factor_im[83] = -9'sd103;
    assign factor_re[84] = 9'sd71; assign factor_im[84] = -9'sd106;
    assign factor_re[85] = 9'sd66; assign factor_im[85] = -9'sd110;
    assign factor_re[86] = 9'sd60; assign factor_im[86] = -9'sd113;
    assign factor_re[87] = 9'sd55; assign factor_im[87] = -9'sd116;
    assign factor_re[88] = 9'sd49; assign factor_im[88] = -9'sd118;
    assign factor_re[89] = 9'sd43; assign factor_im[89] = -9'sd121;
    assign factor_re[90] = 9'sd37; assign factor_im[90] = -9'sd122;
    assign factor_re[91] = 9'sd31; assign factor_im[91] = -9'sd124;
    assign factor_re[92] = 9'sd25; assign factor_im[92] = -9'sd126;
    assign factor_re[93] = 9'sd19; assign factor_im[93] = -9'sd127;
    assign factor_re[94] = 9'sd13; assign factor_im[94] = -9'sd127;
    assign factor_re[95] = 9'sd6; assign factor_im[95] = -9'sd128;
    assign factor_re[96] = 9'sd0; assign factor_im[96] = -9'sd128;
    assign factor_re[97] = -9'sd6; assign factor_im[97] = -9'sd128;
    assign factor_re[98] = -9'sd13; assign factor_im[98] = -9'sd127;
    assign factor_re[99] = -9'sd19; assign factor_im[99] = -9'sd127;
    assign factor_re[100] = -9'sd25; assign factor_im[100] = -9'sd126;
    assign factor_re[101] = -9'sd31; assign factor_im[101] = -9'sd124;
    assign factor_re[102] = -9'sd37; assign factor_im[102] = -9'sd122;
    assign factor_re[103] = -9'sd43; assign factor_im[103] = -9'sd121;
    assign factor_re[104] = -9'sd49; assign factor_im[104] = -9'sd118;
    assign factor_re[105] = -9'sd55; assign factor_im[105] = -9'sd116;
    assign factor_re[106] = -9'sd60; assign factor_im[106] = -9'sd113;
    assign factor_re[107] = -9'sd66; assign factor_im[107] = -9'sd110;
    assign factor_re[108] = -9'sd71; assign factor_im[108] = -9'sd106;
    assign factor_re[109] = -9'sd76; assign factor_im[109] = -9'sd103;
    assign factor_re[110] = -9'sd81; assign factor_im[110] = -9'sd99;
    assign factor_re[111] = -9'sd86; assign factor_im[111] = -9'sd95;
    assign factor_re[112] = -9'sd91; assign factor_im[112] = -9'sd91;
    assign factor_re[113] = -9'sd95; assign factor_im[113] = -9'sd86;
    assign factor_re[114] = -9'sd99; assign factor_im[114] = -9'sd81;
    assign factor_re[115] = -9'sd103; assign factor_im[115] = -9'sd76;
    assign factor_re[116] = -9'sd106; assign factor_im[116] = -9'sd71;
    assign factor_re[117] = -9'sd110; assign factor_im[117] = -9'sd66;
    assign factor_re[118] = -9'sd113; assign factor_im[118] = -9'sd60;
    assign factor_re[119] = -9'sd116; assign factor_im[119] = -9'sd55;
    assign factor_re[120] = -9'sd118; assign factor_im[120] = -9'sd49;
    assign factor_re[121] = -9'sd121; assign factor_im[121] = -9'sd43;
    assign factor_re[122] = -9'sd122; assign factor_im[122] = -9'sd37;
    assign factor_re[123] = -9'sd124; assign factor_im[123] = -9'sd31;
    assign factor_re[124] = -9'sd126; assign factor_im[124] = -9'sd25;
    assign factor_re[125] = -9'sd127; assign factor_im[125] = -9'sd19;
    assign factor_re[126] = -9'sd127; assign factor_im[126] = -9'sd13;
    assign factor_re[127] = -9'sd128; assign factor_im[127] = -9'sd6;
    assign factor_re[128] = 9'sd128; assign factor_im[128] = 9'sd0;
    assign factor_re[129] = 9'sd128; assign factor_im[129] = -9'sd3;
    assign factor_re[130] = 9'sd128; assign factor_im[130] = -9'sd6;
    assign factor_re[131] = 9'sd128; assign factor_im[131] = -9'sd9;
    assign factor_re[132] = 9'sd127; assign factor_im[132] = -9'sd13;
    assign factor_re[133] = 9'sd127; assign factor_im[133] = -9'sd16;
    assign factor_re[134] = 9'sd127; assign factor_im[134] = -9'sd19;
    assign factor_re[135] = 9'sd126; assign factor_im[135] = -9'sd22;
    assign factor_re[136] = 9'sd126; assign factor_im[136] = -9'sd25;
    assign factor_re[137] = 9'sd125; assign factor_im[137] = -9'sd28;
    assign factor_re[138] = 9'sd124; assign factor_im[138] = -9'sd31;
    assign factor_re[139] = 9'sd123; assign factor_im[139] = -9'sd34;
    assign factor_re[140] = 9'sd122; assign factor_im[140] = -9'sd37;
    assign factor_re[141] = 9'sd122; assign factor_im[141] = -9'sd40;
    assign factor_re[142] = 9'sd121; assign factor_im[142] = -9'sd43;
    assign factor_re[143] = 9'sd119; assign factor_im[143] = -9'sd46;
    assign factor_re[144] = 9'sd118; assign factor_im[144] = -9'sd49;
    assign factor_re[145] = 9'sd117; assign factor_im[145] = -9'sd52;
    assign factor_re[146] = 9'sd116; assign factor_im[146] = -9'sd55;
    assign factor_re[147] = 9'sd114; assign factor_im[147] = -9'sd58;
    assign factor_re[148] = 9'sd113; assign factor_im[148] = -9'sd60;
    assign factor_re[149] = 9'sd111; assign factor_im[149] = -9'sd63;
    assign factor_re[150] = 9'sd110; assign factor_im[150] = -9'sd66;
    assign factor_re[151] = 9'sd108; assign factor_im[151] = -9'sd68;
    assign factor_re[152] = 9'sd106; assign factor_im[152] = -9'sd71;
    assign factor_re[153] = 9'sd105; assign factor_im[153] = -9'sd74;
    assign factor_re[154] = 9'sd103; assign factor_im[154] = -9'sd76;
    assign factor_re[155] = 9'sd101; assign factor_im[155] = -9'sd79;
    assign factor_re[156] = 9'sd99; assign factor_im[156] = -9'sd81;
    assign factor_re[157] = 9'sd97; assign factor_im[157] = -9'sd84;
    assign factor_re[158] = 9'sd95; assign factor_im[158] = -9'sd86;
    assign factor_re[159] = 9'sd93; assign factor_im[159] = -9'sd88;
    assign factor_re[160] = 9'sd91; assign factor_im[160] = -9'sd91;
    assign factor_re[161] = 9'sd88; assign factor_im[161] = -9'sd93;
    assign factor_re[162] = 9'sd86; assign factor_im[162] = -9'sd95;
    assign factor_re[163] = 9'sd84; assign factor_im[163] = -9'sd97;
    assign factor_re[164] = 9'sd81; assign factor_im[164] = -9'sd99;
    assign factor_re[165] = 9'sd79; assign factor_im[165] = -9'sd101;
    assign factor_re[166] = 9'sd76; assign factor_im[166] = -9'sd103;
    assign factor_re[167] = 9'sd74; assign factor_im[167] = -9'sd105;
    assign factor_re[168] = 9'sd71; assign factor_im[168] = -9'sd106;
    assign factor_re[169] = 9'sd68; assign factor_im[169] = -9'sd108;
    assign factor_re[170] = 9'sd66; assign factor_im[170] = -9'sd110;
    assign factor_re[171] = 9'sd63; assign factor_im[171] = -9'sd111;
    assign factor_re[172] = 9'sd60; assign factor_im[172] = -9'sd113;
    assign factor_re[173] = 9'sd58; assign factor_im[173] = -9'sd114;
    assign factor_re[174] = 9'sd55; assign factor_im[174] = -9'sd116;
    assign factor_re[175] = 9'sd52; assign factor_im[175] = -9'sd117;
    assign factor_re[176] = 9'sd49; assign factor_im[176] = -9'sd118;
    assign factor_re[177] = 9'sd46; assign factor_im[177] = -9'sd119;
    assign factor_re[178] = 9'sd43; assign factor_im[178] = -9'sd121;
    assign factor_re[179] = 9'sd40; assign factor_im[179] = -9'sd122;
    assign factor_re[180] = 9'sd37; assign factor_im[180] = -9'sd122;
    assign factor_re[181] = 9'sd34; assign factor_im[181] = -9'sd123;
    assign factor_re[182] = 9'sd31; assign factor_im[182] = -9'sd124;
    assign factor_re[183] = 9'sd28; assign factor_im[183] = -9'sd125;
    assign factor_re[184] = 9'sd25; assign factor_im[184] = -9'sd126;
    assign factor_re[185] = 9'sd22; assign factor_im[185] = -9'sd126;
    assign factor_re[186] = 9'sd19; assign factor_im[186] = -9'sd127;
    assign factor_re[187] = 9'sd16; assign factor_im[187] = -9'sd127;
    assign factor_re[188] = 9'sd13; assign factor_im[188] = -9'sd127;
    assign factor_re[189] = 9'sd9; assign factor_im[189] = -9'sd128;
    assign factor_re[190] = 9'sd6; assign factor_im[190] = -9'sd128;
    assign factor_re[191] = 9'sd3; assign factor_im[191] = -9'sd128;
    assign factor_re[192] = 9'sd128; assign factor_im[192] = 9'sd0;
    assign factor_re[193] = 9'sd128; assign factor_im[193] = -9'sd9;
    assign factor_re[194] = 9'sd127; assign factor_im[194] = -9'sd19;
    assign factor_re[195] = 9'sd125; assign factor_im[195] = -9'sd28;
    assign factor_re[196] = 9'sd122; assign factor_im[196] = -9'sd37;
    assign factor_re[197] = 9'sd119; assign factor_im[197] = -9'sd46;
    assign factor_re[198] = 9'sd116; assign factor_im[198] = -9'sd55;
    assign factor_re[199] = 9'sd111; assign factor_im[199] = -9'sd63;
    assign factor_re[200] = 9'sd106; assign factor_im[200] = -9'sd71;
    assign factor_re[201] = 9'sd101; assign factor_im[201] = -9'sd79;
    assign factor_re[202] = 9'sd95; assign factor_im[202] = -9'sd86;
    assign factor_re[203] = 9'sd88; assign factor_im[203] = -9'sd93;
    assign factor_re[204] = 9'sd81; assign factor_im[204] = -9'sd99;
    assign factor_re[205] = 9'sd74; assign factor_im[205] = -9'sd105;
    assign factor_re[206] = 9'sd66; assign factor_im[206] = -9'sd110;
    assign factor_re[207] = 9'sd58; assign factor_im[207] = -9'sd114;
    assign factor_re[208] = 9'sd49; assign factor_im[208] = -9'sd118;
    assign factor_re[209] = 9'sd40; assign factor_im[209] = -9'sd122;
    assign factor_re[210] = 9'sd31; assign factor_im[210] = -9'sd124;
    assign factor_re[211] = 9'sd22; assign factor_im[211] = -9'sd126;
    assign factor_re[212] = 9'sd13; assign factor_im[212] = -9'sd127;
    assign factor_re[213] = 9'sd3; assign factor_im[213] = -9'sd128;
    assign factor_re[214] = -9'sd6; assign factor_im[214] = -9'sd128;
    assign factor_re[215] = -9'sd16; assign factor_im[215] = -9'sd127;
    assign factor_re[216] = -9'sd25; assign factor_im[216] = -9'sd126;
    assign factor_re[217] = -9'sd34; assign factor_im[217] = -9'sd123;
    assign factor_re[218] = -9'sd43; assign factor_im[218] = -9'sd121;
    assign factor_re[219] = -9'sd52; assign factor_im[219] = -9'sd117;
    assign factor_re[220] = -9'sd60; assign factor_im[220] = -9'sd113;
    assign factor_re[221] = -9'sd68; assign factor_im[221] = -9'sd108;
    assign factor_re[222] = -9'sd76; assign factor_im[222] = -9'sd103;
    assign factor_re[223] = -9'sd84; assign factor_im[223] = -9'sd97;
    assign factor_re[224] = -9'sd91; assign factor_im[224] = -9'sd91;
    assign factor_re[225] = -9'sd97; assign factor_im[225] = -9'sd84;
    assign factor_re[226] = -9'sd103; assign factor_im[226] = -9'sd76;
    assign factor_re[227] = -9'sd108; assign factor_im[227] = -9'sd68;
    assign factor_re[228] = -9'sd113; assign factor_im[228] = -9'sd60;
    assign factor_re[229] = -9'sd117; assign factor_im[229] = -9'sd52;
    assign factor_re[230] = -9'sd121; assign factor_im[230] = -9'sd43;
    assign factor_re[231] = -9'sd123; assign factor_im[231] = -9'sd34;
    assign factor_re[232] = -9'sd126; assign factor_im[232] = -9'sd25;
    assign factor_re[233] = -9'sd127; assign factor_im[233] = -9'sd16;
    assign factor_re[234] = -9'sd128; assign factor_im[234] = -9'sd6;
    assign factor_re[235] = -9'sd128; assign factor_im[235] = 9'sd3;
    assign factor_re[236] = -9'sd127; assign factor_im[236] = 9'sd13;
    assign factor_re[237] = -9'sd126; assign factor_im[237] = 9'sd22;
    assign factor_re[238] = -9'sd124; assign factor_im[238] = 9'sd31;
    assign factor_re[239] = -9'sd122; assign factor_im[239] = 9'sd40;
    assign factor_re[240] = -9'sd118; assign factor_im[240] = 9'sd49;
    assign factor_re[241] = -9'sd114; assign factor_im[241] = 9'sd58;
    assign factor_re[242] = -9'sd110; assign factor_im[242] = 9'sd66;
    assign factor_re[243] = -9'sd105; assign factor_im[243] = 9'sd74;
    assign factor_re[244] = -9'sd99; assign factor_im[244] = 9'sd81;
    assign factor_re[245] = -9'sd93; assign factor_im[245] = 9'sd88;
    assign factor_re[246] = -9'sd86; assign factor_im[246] = 9'sd95;
    assign factor_re[247] = -9'sd79; assign factor_im[247] = 9'sd101;
    assign factor_re[248] = -9'sd71; assign factor_im[248] = 9'sd106;
    assign factor_re[249] = -9'sd63; assign factor_im[249] = 9'sd111;
    assign factor_re[250] = -9'sd55; assign factor_im[250] = 9'sd116;
    assign factor_re[251] = -9'sd46; assign factor_im[251] = 9'sd119;
    assign factor_re[252] = -9'sd37; assign factor_im[252] = 9'sd122;
    assign factor_re[253] = -9'sd28; assign factor_im[253] = 9'sd125;
    assign factor_re[254] = -9'sd19; assign factor_im[254] = 9'sd127;
    assign factor_re[255] = -9'sd9; assign factor_im[255] = 9'sd128;
    assign factor_re[256] = 9'sd128; assign factor_im[256] = 9'sd0;
    assign factor_re[257] = 9'sd128; assign factor_im[257] = -9'sd2;
    assign factor_re[258] = 9'sd128; assign factor_im[258] = -9'sd3;
    assign factor_re[259] = 9'sd128; assign factor_im[259] = -9'sd5;
    assign factor_re[260] = 9'sd128; assign factor_im[260] = -9'sd6;
    assign factor_re[261] = 9'sd128; assign factor_im[261] = -9'sd8;
    assign factor_re[262] = 9'sd128; assign factor_im[262] = -9'sd9;
    assign factor_re[263] = 9'sd128; assign factor_im[263] = -9'sd11;
    assign factor_re[264] = 9'sd127; assign factor_im[264] = -9'sd13;
    assign factor_re[265] = 9'sd127; assign factor_im[265] = -9'sd14;
    assign factor_re[266] = 9'sd127; assign factor_im[266] = -9'sd16;
    assign factor_re[267] = 9'sd127; assign factor_im[267] = -9'sd17;
    assign factor_re[268] = 9'sd127; assign factor_im[268] = -9'sd19;
    assign factor_re[269] = 9'sd126; assign factor_im[269] = -9'sd20;
    assign factor_re[270] = 9'sd126; assign factor_im[270] = -9'sd22;
    assign factor_re[271] = 9'sd126; assign factor_im[271] = -9'sd23;
    assign factor_re[272] = 9'sd126; assign factor_im[272] = -9'sd25;
    assign factor_re[273] = 9'sd125; assign factor_im[273] = -9'sd27;
    assign factor_re[274] = 9'sd125; assign factor_im[274] = -9'sd28;
    assign factor_re[275] = 9'sd125; assign factor_im[275] = -9'sd30;
    assign factor_re[276] = 9'sd124; assign factor_im[276] = -9'sd31;
    assign factor_re[277] = 9'sd124; assign factor_im[277] = -9'sd33;
    assign factor_re[278] = 9'sd123; assign factor_im[278] = -9'sd34;
    assign factor_re[279] = 9'sd123; assign factor_im[279] = -9'sd36;
    assign factor_re[280] = 9'sd122; assign factor_im[280] = -9'sd37;
    assign factor_re[281] = 9'sd122; assign factor_im[281] = -9'sd39;
    assign factor_re[282] = 9'sd122; assign factor_im[282] = -9'sd40;
    assign factor_re[283] = 9'sd121; assign factor_im[283] = -9'sd42;
    assign factor_re[284] = 9'sd121; assign factor_im[284] = -9'sd43;
    assign factor_re[285] = 9'sd120; assign factor_im[285] = -9'sd45;
    assign factor_re[286] = 9'sd119; assign factor_im[286] = -9'sd46;
    assign factor_re[287] = 9'sd119; assign factor_im[287] = -9'sd48;
    assign factor_re[288] = 9'sd118; assign factor_im[288] = -9'sd49;
    assign factor_re[289] = 9'sd118; assign factor_im[289] = -9'sd50;
    assign factor_re[290] = 9'sd117; assign factor_im[290] = -9'sd52;
    assign factor_re[291] = 9'sd116; assign factor_im[291] = -9'sd53;
    assign factor_re[292] = 9'sd116; assign factor_im[292] = -9'sd55;
    assign factor_re[293] = 9'sd115; assign factor_im[293] = -9'sd56;
    assign factor_re[294] = 9'sd114; assign factor_im[294] = -9'sd58;
    assign factor_re[295] = 9'sd114; assign factor_im[295] = -9'sd59;
    assign factor_re[296] = 9'sd113; assign factor_im[296] = -9'sd60;
    assign factor_re[297] = 9'sd112; assign factor_im[297] = -9'sd62;
    assign factor_re[298] = 9'sd111; assign factor_im[298] = -9'sd63;
    assign factor_re[299] = 9'sd111; assign factor_im[299] = -9'sd64;
    assign factor_re[300] = 9'sd110; assign factor_im[300] = -9'sd66;
    assign factor_re[301] = 9'sd109; assign factor_im[301] = -9'sd67;
    assign factor_re[302] = 9'sd108; assign factor_im[302] = -9'sd68;
    assign factor_re[303] = 9'sd107; assign factor_im[303] = -9'sd70;
    assign factor_re[304] = 9'sd106; assign factor_im[304] = -9'sd71;
    assign factor_re[305] = 9'sd106; assign factor_im[305] = -9'sd72;
    assign factor_re[306] = 9'sd105; assign factor_im[306] = -9'sd74;
    assign factor_re[307] = 9'sd104; assign factor_im[307] = -9'sd75;
    assign factor_re[308] = 9'sd103; assign factor_im[308] = -9'sd76;
    assign factor_re[309] = 9'sd102; assign factor_im[309] = -9'sd78;
    assign factor_re[310] = 9'sd101; assign factor_im[310] = -9'sd79;
    assign factor_re[311] = 9'sd100; assign factor_im[311] = -9'sd80;
    assign factor_re[312] = 9'sd99; assign factor_im[312] = -9'sd81;
    assign factor_re[313] = 9'sd98; assign factor_im[313] = -9'sd82;
    assign factor_re[314] = 9'sd97; assign factor_im[314] = -9'sd84;
    assign factor_re[315] = 9'sd96; assign factor_im[315] = -9'sd85;
    assign factor_re[316] = 9'sd95; assign factor_im[316] = -9'sd86;
    assign factor_re[317] = 9'sd94; assign factor_im[317] = -9'sd87;
    assign factor_re[318] = 9'sd93; assign factor_im[318] = -9'sd88;
    assign factor_re[319] = 9'sd92; assign factor_im[319] = -9'sd89;
    assign factor_re[320] = 9'sd128; assign factor_im[320] = 9'sd0;
    assign factor_re[321] = 9'sd128; assign factor_im[321] = -9'sd8;
    assign factor_re[322] = 9'sd127; assign factor_im[322] = -9'sd16;
    assign factor_re[323] = 9'sd126; assign factor_im[323] = -9'sd23;
    assign factor_re[324] = 9'sd124; assign factor_im[324] = -9'sd31;
    assign factor_re[325] = 9'sd122; assign factor_im[325] = -9'sd39;
    assign factor_re[326] = 9'sd119; assign factor_im[326] = -9'sd46;
    assign factor_re[327] = 9'sd116; assign factor_im[327] = -9'sd53;
    assign factor_re[328] = 9'sd113; assign factor_im[328] = -9'sd60;
    assign factor_re[329] = 9'sd109; assign factor_im[329] = -9'sd67;
    assign factor_re[330] = 9'sd105; assign factor_im[330] = -9'sd74;
    assign factor_re[331] = 9'sd100; assign factor_im[331] = -9'sd80;
    assign factor_re[332] = 9'sd95; assign factor_im[332] = -9'sd86;
    assign factor_re[333] = 9'sd89; assign factor_im[333] = -9'sd92;
    assign factor_re[334] = 9'sd84; assign factor_im[334] = -9'sd97;
    assign factor_re[335] = 9'sd78; assign factor_im[335] = -9'sd102;
    assign factor_re[336] = 9'sd71; assign factor_im[336] = -9'sd106;
    assign factor_re[337] = 9'sd64; assign factor_im[337] = -9'sd111;
    assign factor_re[338] = 9'sd58; assign factor_im[338] = -9'sd114;
    assign factor_re[339] = 9'sd50; assign factor_im[339] = -9'sd118;
    assign factor_re[340] = 9'sd43; assign factor_im[340] = -9'sd121;
    assign factor_re[341] = 9'sd36; assign factor_im[341] = -9'sd123;
    assign factor_re[342] = 9'sd28; assign factor_im[342] = -9'sd125;
    assign factor_re[343] = 9'sd20; assign factor_im[343] = -9'sd126;
    assign factor_re[344] = 9'sd13; assign factor_im[344] = -9'sd127;
    assign factor_re[345] = 9'sd5; assign factor_im[345] = -9'sd128;
    assign factor_re[346] = -9'sd3; assign factor_im[346] = -9'sd128;
    assign factor_re[347] = -9'sd11; assign factor_im[347] = -9'sd128;
    assign factor_re[348] = -9'sd19; assign factor_im[348] = -9'sd127;
    assign factor_re[349] = -9'sd27; assign factor_im[349] = -9'sd125;
    assign factor_re[350] = -9'sd34; assign factor_im[350] = -9'sd123;
    assign factor_re[351] = -9'sd42; assign factor_im[351] = -9'sd121;
    assign factor_re[352] = -9'sd49; assign factor_im[352] = -9'sd118;
    assign factor_re[353] = -9'sd56; assign factor_im[353] = -9'sd115;
    assign factor_re[354] = -9'sd63; assign factor_im[354] = -9'sd111;
    assign factor_re[355] = -9'sd70; assign factor_im[355] = -9'sd107;
    assign factor_re[356] = -9'sd76; assign factor_im[356] = -9'sd103;
    assign factor_re[357] = -9'sd82; assign factor_im[357] = -9'sd98;
    assign factor_re[358] = -9'sd88; assign factor_im[358] = -9'sd93;
    assign factor_re[359] = -9'sd94; assign factor_im[359] = -9'sd87;
    assign factor_re[360] = -9'sd99; assign factor_im[360] = -9'sd81;
    assign factor_re[361] = -9'sd104; assign factor_im[361] = -9'sd75;
    assign factor_re[362] = -9'sd108; assign factor_im[362] = -9'sd68;
    assign factor_re[363] = -9'sd112; assign factor_im[363] = -9'sd62;
    assign factor_re[364] = -9'sd116; assign factor_im[364] = -9'sd55;
    assign factor_re[365] = -9'sd119; assign factor_im[365] = -9'sd48;
    assign factor_re[366] = -9'sd122; assign factor_im[366] = -9'sd40;
    assign factor_re[367] = -9'sd124; assign factor_im[367] = -9'sd33;
    assign factor_re[368] = -9'sd126; assign factor_im[368] = -9'sd25;
    assign factor_re[369] = -9'sd127; assign factor_im[369] = -9'sd17;
    assign factor_re[370] = -9'sd128; assign factor_im[370] = -9'sd9;
    assign factor_re[371] = -9'sd128; assign factor_im[371] = -9'sd2;
    assign factor_re[372] = -9'sd128; assign factor_im[372] = 9'sd6;
    assign factor_re[373] = -9'sd127; assign factor_im[373] = 9'sd14;
    assign factor_re[374] = -9'sd126; assign factor_im[374] = 9'sd22;
    assign factor_re[375] = -9'sd125; assign factor_im[375] = 9'sd30;
    assign factor_re[376] = -9'sd122; assign factor_im[376] = 9'sd37;
    assign factor_re[377] = -9'sd120; assign factor_im[377] = 9'sd45;
    assign factor_re[378] = -9'sd117; assign factor_im[378] = 9'sd52;
    assign factor_re[379] = -9'sd114; assign factor_im[379] = 9'sd59;
    assign factor_re[380] = -9'sd110; assign factor_im[380] = 9'sd66;
    assign factor_re[381] = -9'sd106; assign factor_im[381] = 9'sd72;
    assign factor_re[382] = -9'sd101; assign factor_im[382] = 9'sd79;
    assign factor_re[383] = -9'sd96; assign factor_im[383] = 9'sd85;
    assign factor_re[384] = 9'sd128; assign factor_im[384] = 9'sd0;
    assign factor_re[385] = 9'sd128; assign factor_im[385] = -9'sd5;
    assign factor_re[386] = 9'sd128; assign factor_im[386] = -9'sd9;
    assign factor_re[387] = 9'sd127; assign factor_im[387] = -9'sd14;
    assign factor_re[388] = 9'sd127; assign factor_im[388] = -9'sd19;
    assign factor_re[389] = 9'sd126; assign factor_im[389] = -9'sd23;
    assign factor_re[390] = 9'sd125; assign factor_im[390] = -9'sd28;
    assign factor_re[391] = 9'sd124; assign factor_im[391] = -9'sd33;
    assign factor_re[392] = 9'sd122; assign factor_im[392] = -9'sd37;
    assign factor_re[393] = 9'sd121; assign factor_im[393] = -9'sd42;
    assign factor_re[394] = 9'sd119; assign factor_im[394] = -9'sd46;
    assign factor_re[395] = 9'sd118; assign factor_im[395] = -9'sd50;
    assign factor_re[396] = 9'sd116; assign factor_im[396] = -9'sd55;
    assign factor_re[397] = 9'sd114; assign factor_im[397] = -9'sd59;
    assign factor_re[398] = 9'sd111; assign factor_im[398] = -9'sd63;
    assign factor_re[399] = 9'sd109; assign factor_im[399] = -9'sd67;
    assign factor_re[400] = 9'sd106; assign factor_im[400] = -9'sd71;
    assign factor_re[401] = 9'sd104; assign factor_im[401] = -9'sd75;
    assign factor_re[402] = 9'sd101; assign factor_im[402] = -9'sd79;
    assign factor_re[403] = 9'sd98; assign factor_im[403] = -9'sd82;
    assign factor_re[404] = 9'sd95; assign factor_im[404] = -9'sd86;
    assign factor_re[405] = 9'sd92; assign factor_im[405] = -9'sd89;
    assign factor_re[406] = 9'sd88; assign factor_im[406] = -9'sd93;
    assign factor_re[407] = 9'sd85; assign factor_im[407] = -9'sd96;
    assign factor_re[408] = 9'sd81; assign factor_im[408] = -9'sd99;
    assign factor_re[409] = 9'sd78; assign factor_im[409] = -9'sd102;
    assign factor_re[410] = 9'sd74; assign factor_im[410] = -9'sd105;
    assign factor_re[411] = 9'sd70; assign factor_im[411] = -9'sd107;
    assign factor_re[412] = 9'sd66; assign factor_im[412] = -9'sd110;
    assign factor_re[413] = 9'sd62; assign factor_im[413] = -9'sd112;
    assign factor_re[414] = 9'sd58; assign factor_im[414] = -9'sd114;
    assign factor_re[415] = 9'sd53; assign factor_im[415] = -9'sd116;
    assign factor_re[416] = 9'sd49; assign factor_im[416] = -9'sd118;
    assign factor_re[417] = 9'sd45; assign factor_im[417] = -9'sd120;
    assign factor_re[418] = 9'sd40; assign factor_im[418] = -9'sd122;
    assign factor_re[419] = 9'sd36; assign factor_im[419] = -9'sd123;
    assign factor_re[420] = 9'sd31; assign factor_im[420] = -9'sd124;
    assign factor_re[421] = 9'sd27; assign factor_im[421] = -9'sd125;
    assign factor_re[422] = 9'sd22; assign factor_im[422] = -9'sd126;
    assign factor_re[423] = 9'sd17; assign factor_im[423] = -9'sd127;
    assign factor_re[424] = 9'sd13; assign factor_im[424] = -9'sd127;
    assign factor_re[425] = 9'sd8; assign factor_im[425] = -9'sd128;
    assign factor_re[426] = 9'sd3; assign factor_im[426] = -9'sd128;
    assign factor_re[427] = -9'sd2; assign factor_im[427] = -9'sd128;
    assign factor_re[428] = -9'sd6; assign factor_im[428] = -9'sd128;
    assign factor_re[429] = -9'sd11; assign factor_im[429] = -9'sd128;
    assign factor_re[430] = -9'sd16; assign factor_im[430] = -9'sd127;
    assign factor_re[431] = -9'sd20; assign factor_im[431] = -9'sd126;
    assign factor_re[432] = -9'sd25; assign factor_im[432] = -9'sd126;
    assign factor_re[433] = -9'sd30; assign factor_im[433] = -9'sd125;
    assign factor_re[434] = -9'sd34; assign factor_im[434] = -9'sd123;
    assign factor_re[435] = -9'sd39; assign factor_im[435] = -9'sd122;
    assign factor_re[436] = -9'sd43; assign factor_im[436] = -9'sd121;
    assign factor_re[437] = -9'sd48; assign factor_im[437] = -9'sd119;
    assign factor_re[438] = -9'sd52; assign factor_im[438] = -9'sd117;
    assign factor_re[439] = -9'sd56; assign factor_im[439] = -9'sd115;
    assign factor_re[440] = -9'sd60; assign factor_im[440] = -9'sd113;
    assign factor_re[441] = -9'sd64; assign factor_im[441] = -9'sd111;
    assign factor_re[442] = -9'sd68; assign factor_im[442] = -9'sd108;
    assign factor_re[443] = -9'sd72; assign factor_im[443] = -9'sd106;
    assign factor_re[444] = -9'sd76; assign factor_im[444] = -9'sd103;
    assign factor_re[445] = -9'sd80; assign factor_im[445] = -9'sd100;
    assign factor_re[446] = -9'sd84; assign factor_im[446] = -9'sd97;
    assign factor_re[447] = -9'sd87; assign factor_im[447] = -9'sd94;
    assign factor_re[448] = 9'sd128; assign factor_im[448] = 9'sd0;
    assign factor_re[449] = 9'sd128; assign factor_im[449] = -9'sd11;
    assign factor_re[450] = 9'sd126; assign factor_im[450] = -9'sd22;
    assign factor_re[451] = 9'sd124; assign factor_im[451] = -9'sd33;
    assign factor_re[452] = 9'sd121; assign factor_im[452] = -9'sd43;
    assign factor_re[453] = 9'sd116; assign factor_im[453] = -9'sd53;
    assign factor_re[454] = 9'sd111; assign factor_im[454] = -9'sd63;
    assign factor_re[455] = 9'sd106; assign factor_im[455] = -9'sd72;
    assign factor_re[456] = 9'sd99; assign factor_im[456] = -9'sd81;
    assign factor_re[457] = 9'sd92; assign factor_im[457] = -9'sd89;
    assign factor_re[458] = 9'sd84; assign factor_im[458] = -9'sd97;
    assign factor_re[459] = 9'sd75; assign factor_im[459] = -9'sd104;
    assign factor_re[460] = 9'sd66; assign factor_im[460] = -9'sd110;
    assign factor_re[461] = 9'sd56; assign factor_im[461] = -9'sd115;
    assign factor_re[462] = 9'sd46; assign factor_im[462] = -9'sd119;
    assign factor_re[463] = 9'sd36; assign factor_im[463] = -9'sd123;
    assign factor_re[464] = 9'sd25; assign factor_im[464] = -9'sd126;
    assign factor_re[465] = 9'sd14; assign factor_im[465] = -9'sd127;
    assign factor_re[466] = 9'sd3; assign factor_im[466] = -9'sd128;
    assign factor_re[467] = -9'sd8; assign factor_im[467] = -9'sd128;
    assign factor_re[468] = -9'sd19; assign factor_im[468] = -9'sd127;
    assign factor_re[469] = -9'sd30; assign factor_im[469] = -9'sd125;
    assign factor_re[470] = -9'sd40; assign factor_im[470] = -9'sd122;
    assign factor_re[471] = -9'sd50; assign factor_im[471] = -9'sd118;
    assign factor_re[472] = -9'sd60; assign factor_im[472] = -9'sd113;
    assign factor_re[473] = -9'sd70; assign factor_im[473] = -9'sd107;
    assign factor_re[474] = -9'sd79; assign factor_im[474] = -9'sd101;
    assign factor_re[475] = -9'sd87; assign factor_im[475] = -9'sd94;
    assign factor_re[476] = -9'sd95; assign factor_im[476] = -9'sd86;
    assign factor_re[477] = -9'sd102; assign factor_im[477] = -9'sd78;
    assign factor_re[478] = -9'sd108; assign factor_im[478] = -9'sd68;
    assign factor_re[479] = -9'sd114; assign factor_im[479] = -9'sd59;
    assign factor_re[480] = -9'sd118; assign factor_im[480] = -9'sd49;
    assign factor_re[481] = -9'sd122; assign factor_im[481] = -9'sd39;
    assign factor_re[482] = -9'sd125; assign factor_im[482] = -9'sd28;
    assign factor_re[483] = -9'sd127; assign factor_im[483] = -9'sd17;
    assign factor_re[484] = -9'sd128; assign factor_im[484] = -9'sd6;
    assign factor_re[485] = -9'sd128; assign factor_im[485] = 9'sd5;
    assign factor_re[486] = -9'sd127; assign factor_im[486] = 9'sd16;
    assign factor_re[487] = -9'sd125; assign factor_im[487] = 9'sd27;
    assign factor_re[488] = -9'sd122; assign factor_im[488] = 9'sd37;
    assign factor_re[489] = -9'sd119; assign factor_im[489] = 9'sd48;
    assign factor_re[490] = -9'sd114; assign factor_im[490] = 9'sd58;
    assign factor_re[491] = -9'sd109; assign factor_im[491] = 9'sd67;
    assign factor_re[492] = -9'sd103; assign factor_im[492] = 9'sd76;
    assign factor_re[493] = -9'sd96; assign factor_im[493] = 9'sd85;
    assign factor_re[494] = -9'sd88; assign factor_im[494] = 9'sd93;
    assign factor_re[495] = -9'sd80; assign factor_im[495] = 9'sd100;
    assign factor_re[496] = -9'sd71; assign factor_im[496] = 9'sd106;
    assign factor_re[497] = -9'sd62; assign factor_im[497] = 9'sd112;
    assign factor_re[498] = -9'sd52; assign factor_im[498] = 9'sd117;
    assign factor_re[499] = -9'sd42; assign factor_im[499] = 9'sd121;
    assign factor_re[500] = -9'sd31; assign factor_im[500] = 9'sd124;
    assign factor_re[501] = -9'sd20; assign factor_im[501] = 9'sd126;
    assign factor_re[502] = -9'sd9; assign factor_im[502] = 9'sd128;
    assign factor_re[503] = 9'sd2; assign factor_im[503] = 9'sd128;
    assign factor_re[504] = 9'sd13; assign factor_im[504] = 9'sd127;
    assign factor_re[505] = 9'sd23; assign factor_im[505] = 9'sd126;
    assign factor_re[506] = 9'sd34; assign factor_im[506] = 9'sd123;
    assign factor_re[507] = 9'sd45; assign factor_im[507] = 9'sd120;
    assign factor_re[508] = 9'sd55; assign factor_im[508] = 9'sd116;
    assign factor_re[509] = 9'sd64; assign factor_im[509] = 9'sd111;
    assign factor_re[510] = 9'sd74; assign factor_im[510] = 9'sd105;
    assign factor_re[511] = 9'sd82; assign factor_im[511] = 9'sd98;
    
    // 내부 카운터: 0~511
    reg [8:0] data_idx;
    integer i;
    
    // 중간 계산 결과를 위한 더 큰 비트폭 사용 (오버플로우 방지)
    logic signed [IN_WIDTH+9-1:0] mult_re_i [15:0];
    logic signed [IN_WIDTH+9-1:0] mult_im_i [15:0];
    logic signed [IN_WIDTH+9-1:0] mult_re_q [15:0];
    logic signed [IN_WIDTH+9-1:0] mult_im_q [15:0];
    
    // 최종 결과를 위한 임시 변수
    logic signed [IN_WIDTH+9:0] temp_i [15:0];
    logic signed [IN_WIDTH+9:0] temp_q [15:0];

    // 순차 로직으로 계산
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_idx <= 0;
            o_valid <= 0;
            for (i = 0; i < 16; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 입력 데이터를 그대로 사용 (비트값 유지)
                for (i = 0; i < 16; i++) begin
                    logic signed [IN_WIDTH-1:0] round_din_i, round_din_q;
                    round_din_i = din_i[i];  // 원본 데이터 유지
                    round_din_q = din_q[i];  // 원본 데이터 유지
                    
                    // 곱셈 결과를 더 큰 비트폭으로 계산
                    mult_re_i[i] = round_din_i * factor_re[data_idx + i];
                    mult_im_i[i] = round_din_i * factor_im[data_idx + i];
                    mult_re_q[i] = round_din_q * factor_re[data_idx + i];
                    mult_im_q[i] = round_din_q * factor_im[data_idx + i];
                    
                    // 복소수 곱셈: (a+bi)(c+di) = (ac-bd) + (ad+bc)i
                    temp_i[i] = mult_re_i[i] - mult_im_q[i];
                    temp_q[i] = mult_im_i[i] + mult_re_q[i];
                    
                    // 결과를 출력 비트폭에 맞게 클리핑
                    if (temp_i[i] > ((1 << (OUT_WIDTH-1)) - 1)) begin
                        dout_i[i] <= (1 << (OUT_WIDTH-1)) - 1;
                    end else if (temp_i[i] < -(1 << (OUT_WIDTH-1))) begin
                        dout_i[i] <= -(1 << (OUT_WIDTH-1));
                    end else begin
                        dout_i[i] <= temp_i[i][OUT_WIDTH-1:0];
                    end
                    
                    if (temp_q[i] > ((1 << (OUT_WIDTH-1)) - 1)) begin
                        dout_q[i] <= (1 << (OUT_WIDTH-1)) - 1;
                    end else if (temp_q[i] < -(1 << (OUT_WIDTH-1))) begin
                        dout_q[i] <= -(1 << (OUT_WIDTH-1));
                    end else begin
                        dout_q[i] <= temp_q[i][OUT_WIDTH-1:0];
                    end
                end
                
                // 카운터 업데이트
                if (data_idx >= 512 - 16) begin  
                    data_idx <= 0;  
                end else begin
                    data_idx <= data_idx + 16;
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule





module shift_processor #(
    parameter IN_WIDTH = 20,
    parameter OUT_WIDTH = 12
)(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [IN_WIDTH-1:0] din_i[15:0],  // 곱셈 결과
    input logic signed [IN_WIDTH-1:0] din_q[15:0],  // 곱셈 결과
    output logic signed [OUT_WIDTH-1:0] dout_i[15:0], // 시프트 후 결과
    output logic signed [OUT_WIDTH-1:0] dout_q[15:0], // 시프트 후 결과
    output logic o_valid
);
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < 16; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 256으로 나누기: >>8 (고정소수점 1.8)
                for (i = 0; i < 16; i++) begin
                    dout_i[i] <= (din_i[i] + 8'd128) >>> 8;
                    dout_q[i] <= (din_q[i] + 8'd128) >>> 8;
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule




module stage_2_1_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [13:0] din_i[15:0],
    input logic signed [13:0] din_q[15:0],
    output logic signed [22:0] dout_i[15:0],
    output logic signed [22:0] dout_q[15:0],
    output logic o_valid
);
    // fac8_1: 8개 고정소수점(1.8) 트위들 팩터 (실수/허수)
    wire signed [9:0] fac8_1_re[0:7];
    wire signed [9:0] fac8_1_im[0:7];

    assign fac8_1_re[0] = 256; assign fac8_1_im[0] = 0;
    assign fac8_1_re[1] = 256; assign fac8_1_im[1] = 0;
    assign fac8_1_re[2] = 256; assign fac8_1_im[2] = 0;
    assign fac8_1_re[3] = 0;   assign fac8_1_im[3] = -256;
    assign fac8_1_re[4] = 256; assign fac8_1_im[4] = 0;
    assign fac8_1_re[5] = 181; assign fac8_1_im[5] = -181;
    assign fac8_1_re[6] = 256; assign fac8_1_im[6] = 0;
    assign fac8_1_re[7] = -181; assign fac8_1_im[7] = -181;

    logic signed [22:0] fac_reg_i[15:0];
    logic signed [22:0] fac_reg_q[15:0];
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 순환 구조: 0~7, 8~15에 각각 fac8_1[0]~fac8_1[7] 순서대로 적용
                // 0~7: fac8_1[0]~fac8_1[7] 순서대로
                for (i = 0; i < 8; i++) begin
                    fac_reg_i[i] <= din_i[i] * fac8_1_re[i] - din_q[i] * fac8_1_im[i];
                    fac_reg_q[i] <= din_i[i] * fac8_1_im[i] + din_q[i] * fac8_1_re[i];
                end
                // 8~15: fac8_1[0]~fac8_1[7] 다시 순서대로
                for (i = 8; i < 16; i++) begin
                    fac_reg_i[i] <= din_i[i] * fac8_1_re[i-8] - din_q[i] * fac8_1_im[i-8];
                    fac_reg_q[i] <= din_i[i] * fac8_1_im[i-8] + din_q[i] * fac8_1_re[i-8];
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end

    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule



module stage_0_1_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [10:0] din_i[15:0],
    input logic signed [10:0] din_q[15:0],
    output logic signed [19:0] dout_i[15:0],
    output logic signed [19:0] dout_q[15:0],
    output logic o_valid
);
    // fac8_1: 8개 고정소수점(1.8) 트위들 팩터 (실수/허수)
    wire signed [9:0] fac8_1_re[0:7];
    wire signed [9:0] fac8_1_im[0:7];

    assign fac8_1_re[0] = 256; assign fac8_1_im[0] = 0;
    assign fac8_1_re[1] = 256; assign fac8_1_im[1] = 0;
    assign fac8_1_re[2] = 256; assign fac8_1_im[2] = 0;
    assign fac8_1_re[3] = 0;   assign fac8_1_im[3] = -256;
    assign fac8_1_re[4] = 256; assign fac8_1_im[4] = 0;
    assign fac8_1_re[5] = 181; assign fac8_1_im[5] = -181;
    assign fac8_1_re[6] = 256; assign fac8_1_im[6] = 0;
    assign fac8_1_re[7] = -181; assign fac8_1_im[7] = -181;

    logic signed [19:0] fac_reg_i[15:0];
    logic signed [19:0] fac_reg_q[15:0];

    reg [2:0] fac_idx; // 0~7, 트위들 팩터 인덱스
    reg [2:0] fac_idx_next; // fac_idx + 1을 위한 별도 변수
    reg [6:0] blk_cnt; // 0~31, 32블록(16개씩)
    reg valid;
    integer i;
    
    // i_valid_d1, i_valid_d2 삭제

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fac_idx <= 0;
            fac_idx_next <= 1;  // fac_idx + 1 초기화
            blk_cnt <= 0;
            valid <= 0;
            for (i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin // i_valid가 1이면 곱셈 연산 시작
                // 4클럭마다 트위들 팩터 인덱스 증가 (64/16=4)
                if (blk_cnt != 0 && blk_cnt % 4 == 0)
                    fac_idx <= fac_idx + 1;

                for (i = 0; i < 16; i++) begin
                    fac_reg_i[i] <= din_i[i] * fac8_1_re[fac_idx] - din_q[i] * fac8_1_im[fac_idx];
                    fac_reg_q[i] <= din_i[i] * fac8_1_im[fac_idx] + din_q[i] * fac8_1_re[fac_idx];
                end
                valid <= 1; // 원래대로 복원
                
                if (blk_cnt == 32) begin
                    blk_cnt <= 0;
                    fac_idx <= 0;
                    // valid는 한 클럭 더 유지 (32번째 블록 결과 전달을 위해)
                end else begin
                    blk_cnt <= blk_cnt + 1;
                end
            end else begin
                // 32번째 블록 처리 후에는 valid를 유지
                if (blk_cnt == 32) begin
                    valid <= 1; // 마지막 블록 결과 전달을 위해 유지
                end else begin
                    valid <= 0;
                end
            end
        end
    end

    // o_valid만 한 클럭 늦게 출력
    reg valid_d;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_d <= 0;
        end else begin
            valid_d <= valid; // valid를 한 클럭 지연
        end
    end

    assign o_valid = valid_d;
    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule

module stage_2_0_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [12:0] din_i[15:0],
    input logic signed [12:0] din_q[15:0],
    output logic signed [12:0] dout_i[15:0],
    output logic signed [12:0] dout_q[15:0],
    output logic o_valid
);
    logic signed [12:0] fac_reg_i [15:0];
    logic signed [12:0] fac_reg_q [15:0];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (int i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin

                for (int i = 0; i < 6; i++) begin
                    fac_reg_i[i] <= din_i[i];
                    fac_reg_q[i] <= din_q[i];
                end
                fac_reg_i[6] <= din_q[6];
                fac_reg_q[6] <= -din_i[6];
                fac_reg_i[7] <= din_q[7];
                fac_reg_q[7] <= -din_i[7];
                
                for (int i = 8; i < 14; i++) begin
                    fac_reg_i[i] <= din_i[i];
                    fac_reg_q[i] <= din_q[i];
                end
                fac_reg_i[14] <= din_q[14];
                fac_reg_q[14] <= -din_i[14];
                fac_reg_i[15] <= din_q[15];
                fac_reg_q[15] <= -din_i[15];
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end

    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule



module stage_1_0_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [11:0] din_i[15:0],
    input logic signed [11:0] din_q[15:0],
    output logic signed [11:0] dout_i[15:0],
    output logic signed [11:0] dout_q[15:0],
    output logic o_valid
);
     typedef enum logic [1:0] {FAC_0 = 0, FAC_1 = 1, FAC_2 = 2, FAC_3 = 3} state_t;
    state_t state;

    logic signed [11:0] fac_reg_i [15:0];
    logic signed [11:0] fac_reg_q [15:0];

    reg valid;
    reg [3:0] cycle_counter; 

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= FAC_0;
            valid <= 0;
            cycle_counter <= 0;
            for (int i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            case (state)
                FAC_0: begin
                    if (i_valid) begin
                        for (int i = 0; i < 16; i++) begin
                            fac_reg_i[i] <= din_i[i];
                            fac_reg_q[i] <= din_q[i];
                        end
                        valid <= 1;
                        state <= FAC_1;
                    if (cycle_counter == 8) begin
                        valid <= 0;  // 8번 완료 시 바로 valid 내림
                        cycle_counter <= 0;
                        state <= FAC_0;
                    end 
                    end
                end
                FAC_1, FAC_2: begin
                    for (int i = 0; i < 16; i++) begin
                        fac_reg_i[i] <= din_i[i];
                        fac_reg_q[i] <= din_q[i];
                    end
                    valid <= 1;
                    state <= state_t'(state + 1);
                end
                FAC_3: begin
                    for (int i = 0; i < 16; i++) begin
                        fac_reg_i[i] <= din_q[i];
                        fac_reg_q[i] <= -din_i[i];
                    end
                    valid <= 1;
                    
                    cycle_counter <= cycle_counter + 1;
                    state <= FAC_0;
                    
                end
            endcase
        end
    end

    assign o_valid = valid;
    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule



module stage_1_1_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [12:0] din_i[15:0],
    input logic signed [12:0] din_q[15:0],
    output logic signed [22:0] dout_i[15:0],
    output logic signed [22:0] dout_q[15:0],
    output logic o_valid
);
    // fac8_1: 8개 고정소수점(1.8) 트위들 팩터 (실수/허수)
    wire signed [9:0] fac8_1_re[0:7];
    wire signed [9:0] fac8_1_im[0:7];

    assign fac8_1_re[0] = 256; assign fac8_1_im[0] = 0;
    assign fac8_1_re[1] = 256; assign fac8_1_im[1] = 0;
    assign fac8_1_re[2] = 256; assign fac8_1_im[2] = 0;
    assign fac8_1_re[3] = 0;   assign fac8_1_im[3] = -256;
    assign fac8_1_re[4] = 256; assign fac8_1_im[4] = 0;
    assign fac8_1_re[5] = 181; assign fac8_1_im[5] = -181;
    assign fac8_1_re[6] = 256; assign fac8_1_im[6] = 0;
    assign fac8_1_re[7] = -181; assign fac8_1_im[7] = -181;
    

    logic signed [22:0] fac_reg_i[15:0];
    logic signed [22:0] fac_reg_q[15:0];

    reg [2:0] fac_idx; // 0~7, 트위들 팩터 인덱스
    reg [2:0] fac_idx_next; // fac_idx + 1을 위한 별도 변수
    reg [5:0] blk_cnt; // 0~31, 32블록(16개씩)
    reg valid;
    integer i;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fac_idx <= 0;
            fac_idx_next <= 1;  // fac_idx + 1 초기화
            blk_cnt <= 0;
            valid <= 0;
            for (i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin // i_valid가 1이면 곱셈 연산 시작
                // 1단계: fac_idx 증가 (연산 전)
                if (blk_cnt >= 0) begin
                    if (fac_idx >= 6) begin
                        fac_idx <= 0;  // 6->0으로만 순환
                        fac_idx_next <= 1;  // 0+1
                    end else begin
                        fac_idx <= fac_idx + 2;  // 0->2, 2->4, 4->6
                        fac_idx_next <= fac_idx + 3;  // 2+1, 4+1, 6+1
                    end
                end

                // 앞 8개: fac_idx 적용
                for (i = 0; i < 8; i++) begin
                    fac_reg_i[i] <= din_i[i] * fac8_1_re[fac_idx] - din_q[i] * fac8_1_im[fac_idx];
                    fac_reg_q[i] <= din_i[i] * fac8_1_im[fac_idx] + din_q[i] * fac8_1_re[fac_idx];
                end
                
                // 뒤 8개: fac_idx_next 적용 (더 안전한 방식)
                for (i = 8; i < 16; i++) begin
                    fac_reg_i[i] <= din_i[i] * fac8_1_re[fac_idx_next] - din_q[i] * fac8_1_im[fac_idx_next];
                    fac_reg_q[i] <= din_i[i] * fac8_1_im[fac_idx_next] + din_q[i] * fac8_1_re[fac_idx_next];
                end
                
                valid <= 1;
            end else begin
                valid <= 0;
            end
            
            // valid가 1일 때만 blk_cnt 증가
            if (valid) begin
                if (blk_cnt == 31) begin
                    valid <= 0;  // 31일 때 valid 내림
                    blk_cnt <= blk_cnt + 1;
                end else if (blk_cnt == 32) begin
                    blk_cnt <= 0;
                    fac_idx <= 0;
                    fac_idx_next <= 1;  // 리셋 시에도 초기화
                end else begin
                    blk_cnt <= blk_cnt + 1;
                end
            end
        end
    end
    

    assign o_valid = valid;
    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule



module stage_0_0_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [9:0] din_i[15:0],
    input logic signed [9:0] din_q[15:0],
    output logic signed [9:0] dout_i[15:0],
    output logic signed [9:0] dout_q[15:0],
    output logic o_valid
);
    typedef enum logic [1:0] {FAC_0 = 0, FAC_1 = 1, FAC_2 = 2, FAC_3 = 3} state_t;
    state_t state;

    logic signed [9:0] fac_reg_i [15:0];
    logic signed [9:0] fac_reg_q [15:0];

    reg [2:0] cnt; // 0~7, 8번 반복
    reg [2:0] total_cnt; // 0~7, 8클럭 카운트로 변경
    reg valid;
    reg i_valid_d; // i_valid 딜레이용
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            i_valid_d <= 0;
        end else begin
            i_valid_d <= i_valid;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt <= 0;
            total_cnt <= 0;
            state <= FAC_0;
            valid <= 0;
            for (int i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            case (state)
                FAC_0: begin
                    if (i_valid_d) begin // 한 클럭 딜레이된 신호로 연산
                        for (int i = 0; i < 16; i++) begin
                            fac_reg_i[i] <= din_i[i];
                            fac_reg_q[i] <= din_q[i];
                        end
                        valid <= 1;
                        if (total_cnt == 7) begin
                            total_cnt <= 0;
                            cnt <= 0;
                            state <= FAC_1;
                        end else begin
                            total_cnt <= total_cnt + 1;
                        end
                    end else begin
                        valid <= 0;
                    end
                end
                FAC_1, FAC_2: begin
                    for (int i = 0; i < 16; i++) begin
                        fac_reg_i[i] <= din_i[i];
                        fac_reg_q[i] <= din_q[i];
                    end
                    valid <= 1;
                    if (total_cnt == 7) begin
                        total_cnt <= 0;
                        cnt <= 0;
                        state <= state_t'(state + 1);
                    end else begin
                        total_cnt <= total_cnt + 1;
                    end
                end
                FAC_3: begin
                    for (int i = 0; i < 16; i++) begin
                        fac_reg_i[i] <= din_q[i];
                        fac_reg_q[i] <= -din_i[i];
                    end
                    valid <= 1;
                    if (total_cnt == 7) begin
                        total_cnt <= 0;
                        cnt <= 0;
                        state <= FAC_0;
                    end else begin
                        total_cnt <= total_cnt + 1;
                    end
                end
            endcase
        end
    end

    assign o_valid = valid;
    assign dout_i = fac_reg_i;
    assign dout_q = fac_reg_q;
endmodule



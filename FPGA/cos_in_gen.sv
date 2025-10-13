`timescale 1ns/10ps

module cos_in_gen #(
    parameter integer N = 512,
    parameter integer DATA_PER_CLK = 16
)(
    input  logic clk,
    input  logic rstn,
    input  logic start,          // Start signal 추가
    output logic valid_out,
    output logic signed [8:0] dout_i[0:DATA_PER_CLK-1], //<3.6> 
    output logic signed [8:0] dout_q[0:DATA_PER_CLK-1]   
);

    // ROM에 사전 계산된 <3.6> 고정소수점 값 저장 (델타 딜레이 시뮬레이션용)
    logic signed [8:0] cos_fixed_re [0:N-1];
    logic signed [8:0] cos_fixed_im [0:N-1];
    
    // ROM 접근 지연을 위한 신호
    logic signed [8:0] rom_data_re [0:DATA_PER_CLK-1];
    logic signed [8:0] rom_data_im [0:DATA_PER_CLK-1];
    
genvar addr;
generate
	for(addr = 0; addr < N; addr++) begin :gen_rom
    		cos_rom U_cos_rom(addr,cos_fixed_re[addr], cos_fixed_im[addr]);
	end
endgenerate

    // 내부 인덱스와 유효 제어
    logic valid_out_next;
    logic [8:0] idx;         // 0~511
    logic [5:0] cycle_cnt;   // 0~31
    logic [3:0] unable_cnt ; //0~7
    integer j,k;
    localparam IDLE = 0, SIG_ON = 1, SIG_OFF = 2;
    logic [1:0] state;
    
    // 데이터 출력을 위한 내부 신호
    logic signed [8:0] dout_i_next [0:DATA_PER_CLK-1];
    logic signed [8:0] dout_q_next [0:DATA_PER_CLK-1];
    
    // 네거티브 엣지에서 데이터와 valid_out 출력
    always_ff @(negedge clk or negedge rstn) begin
        integer i;
        if (!rstn) begin
            valid_out <= '0;
            for (i = 0; i < DATA_PER_CLK; i++) begin
                dout_i[i] <= '0;
                dout_q[i] <= '0;
            end
        end else begin
            valid_out <= valid_out_next;
            for (i = 0; i < DATA_PER_CLK; i++) begin
                dout_i[i] <= dout_i_next[i];
                dout_q[i] <= dout_q_next[i];
            end
        end
    end
    
    // 포지티브 엣지에서 상태 머신과 다음 데이터 계산
    always_ff @(posedge clk or negedge rstn) begin
        integer i;
        if (!rstn) begin
            idx <= '0;
            cycle_cnt <= '0;
            unable_cnt <= '0;
            state <= IDLE;
            valid_out_next <= 0;
            for (i = 0; i < DATA_PER_CLK; i++) begin
                dout_i_next[i] <= '0;
                dout_q_next[i] <= '0;
            end
        end else begin
            case(state)
                IDLE: begin
                    if (start) begin
                        state <= SIG_ON;
                        valid_out_next <= 1'b1;
                        idx <= DATA_PER_CLK;  // 다음 데이터부터 시작하도록 수정
                        cycle_cnt <= '0;
                        unable_cnt <= '0;
                        // 첫 번째 데이터 설정
                        for (j = 0; j < DATA_PER_CLK; j++) begin
                            dout_i_next[j] <= cos_fixed_re[j];
                            dout_q_next[j] <= cos_fixed_im[j];
                        end
                    end else begin
                        valid_out_next <= 1'b0;
                        for (i = 0; i < DATA_PER_CLK; i++) begin
                            dout_i_next[i] <= '0;
                            dout_q_next[i] <= '0;
                        end
                    end
                end
                SIG_ON: begin
                    valid_out_next <= 1'b1;
                    if (cycle_cnt != 31) begin
                        for (j = 0; j < DATA_PER_CLK; j++) begin
                            dout_i_next[j] <= cos_fixed_re[idx + j];
                            dout_q_next[j] <= cos_fixed_im[idx + j];
                        end
                        if(idx != 512-DATA_PER_CLK -1) idx <= idx + DATA_PER_CLK;
                        else idx <= '0;
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end else begin
                        // 마지막 데이터를 한 클럭 더 출력
                        for (j = 0; j < DATA_PER_CLK; j++) begin
                            dout_i_next[j] <= cos_fixed_re[idx + j];
                            dout_q_next[j] <= cos_fixed_im[idx + j];
                        end
                        cycle_cnt <= '0;
                        valid_out_next <= 1'b1;  // 한 클럭 더 유지
                        state <= SIG_OFF;
                        idx <= '0;
                    end
                end
                SIG_OFF: begin
                    if(unable_cnt == 0) begin
                        // 첫 번째 클럭에서는 valid를 유지하고 데이터는 0으로
                        valid_out_next <= 1'b1;
                        for(k = 0;k < DATA_PER_CLK;k++) begin
                            dout_i_next[k] <= '0;
                            dout_q_next[k] <= '0;
                        end
                        unable_cnt <= unable_cnt + 1'b1;
                    end else if(unable_cnt != 7) begin
                        valid_out_next <= 1'b0;  // valid를 0으로 설정
                        for(k = 0;k < DATA_PER_CLK;k++) begin
                            dout_i_next[k] <= '0;
                            dout_q_next[k] <= '0;
                        end
                        unable_cnt <= unable_cnt + 1'b1;
                    end else begin
                        valid_out_next <= 1'b1;
                        state <= SIG_ON;
                        unable_cnt <= '0;
                        idx <= DATA_PER_CLK;  // 다음 데이터부터 시작하도록 수정
                        // 다음 사이클 데이터 설정
                        for (j = 0; j < DATA_PER_CLK; j++) begin
                            dout_i_next[j] <= cos_fixed_re[j];
                            dout_q_next[j] <= cos_fixed_im[j];
                        end
                    end
                end
            endcase
        end
    end
endmodule


module cos_rom#(
parameter TOTAL = 512
)(
	input logic [$clog2(TOTAL) -1 :0] addr,
	//input logic signed [8:0] in_fixed_re,
	//input logic signed [8:0] in_fixed_im,
	output logic signed [8:0] fixed_re,
	output logic signed [8:0] fixed_im
);
//logic [$clog2(TOTAL)-1:0] addr;
logic signed [8:0] cos_fixed_re[TOTAL -1:0];
logic signed [8:0] cos_fixed_im[TOTAL -1 :0];

assign cos_fixed_re[0] = 9'sd63;  assign cos_fixed_im[0] = 9'sd0;
assign cos_fixed_re[1] = 9'sd64;  assign cos_fixed_im[1] = 9'sd0;
assign cos_fixed_re[2] = 9'sd64;  assign cos_fixed_im[2] = 9'sd0;
assign cos_fixed_re[3] = 9'sd64;  assign cos_fixed_im[3] = 9'sd0;
assign cos_fixed_re[4] = 9'sd64;  assign cos_fixed_im[4] = 9'sd0;
assign cos_fixed_re[5] = 9'sd64;  assign cos_fixed_im[5] = 9'sd0;
assign cos_fixed_re[6] = 9'sd64;  assign cos_fixed_im[6] = 9'sd0;
assign cos_fixed_re[7] = 9'sd64;  assign cos_fixed_im[7] = 9'sd0;
assign cos_fixed_re[8] = 9'sd64;  assign cos_fixed_im[8] = 9'sd0;
assign cos_fixed_re[9] = 9'sd64;  assign cos_fixed_im[9] = 9'sd0;
assign cos_fixed_re[10] = 9'sd64;  assign cos_fixed_im[10] = 9'sd0;
assign cos_fixed_re[11] = 9'sd63;  assign cos_fixed_im[11] = 9'sd0;
assign cos_fixed_re[12] = 9'sd63;  assign cos_fixed_im[12] = 9'sd0;
assign cos_fixed_re[13] = 9'sd63;  assign cos_fixed_im[13] = 9'sd0;
assign cos_fixed_re[14] = 9'sd63;  assign cos_fixed_im[14] = 9'sd0;
assign cos_fixed_re[15] = 9'sd63;  assign cos_fixed_im[15] = 9'sd0;
assign cos_fixed_re[16] = 9'sd63;  assign cos_fixed_im[16] = 9'sd0;
assign cos_fixed_re[17] = 9'sd63;  assign cos_fixed_im[17] = 9'sd0;
assign cos_fixed_re[18] = 9'sd62;  assign cos_fixed_im[18] = 9'sd0;
assign cos_fixed_re[19] = 9'sd62;  assign cos_fixed_im[19] = 9'sd0;
assign cos_fixed_re[20] = 9'sd62;  assign cos_fixed_im[20] = 9'sd0;
assign cos_fixed_re[21] = 9'sd62;  assign cos_fixed_im[21] = 9'sd0;
assign cos_fixed_re[22] = 9'sd62;  assign cos_fixed_im[22] = 9'sd0;
assign cos_fixed_re[23] = 9'sd61;  assign cos_fixed_im[23] = 9'sd0;
assign cos_fixed_re[24] = 9'sd61;  assign cos_fixed_im[24] = 9'sd0;
assign cos_fixed_re[25] = 9'sd61;  assign cos_fixed_im[25] = 9'sd0;
assign cos_fixed_re[26] = 9'sd61;  assign cos_fixed_im[26] = 9'sd0;
assign cos_fixed_re[27] = 9'sd61;  assign cos_fixed_im[27] = 9'sd0;
assign cos_fixed_re[28] = 9'sd60;  assign cos_fixed_im[28] = 9'sd0;
assign cos_fixed_re[29] = 9'sd60;  assign cos_fixed_im[29] = 9'sd0;
assign cos_fixed_re[30] = 9'sd60;  assign cos_fixed_im[30] = 9'sd0;
assign cos_fixed_re[31] = 9'sd59;  assign cos_fixed_im[31] = 9'sd0;
assign cos_fixed_re[32] = 9'sd59;  assign cos_fixed_im[32] = 9'sd0;
assign cos_fixed_re[33] = 9'sd59;  assign cos_fixed_im[33] = 9'sd0;
assign cos_fixed_re[34] = 9'sd59;  assign cos_fixed_im[34] = 9'sd0;
assign cos_fixed_re[35] = 9'sd58;  assign cos_fixed_im[35] = 9'sd0;
assign cos_fixed_re[36] = 9'sd58;  assign cos_fixed_im[36] = 9'sd0;
assign cos_fixed_re[37] = 9'sd58;  assign cos_fixed_im[37] = 9'sd0;
assign cos_fixed_re[38] = 9'sd57;  assign cos_fixed_im[38] = 9'sd0;
assign cos_fixed_re[39] = 9'sd57;  assign cos_fixed_im[39] = 9'sd0;
assign cos_fixed_re[40] = 9'sd56;  assign cos_fixed_im[40] = 9'sd0;
assign cos_fixed_re[41] = 9'sd56;  assign cos_fixed_im[41] = 9'sd0;
assign cos_fixed_re[42] = 9'sd56;  assign cos_fixed_im[42] = 9'sd0;
assign cos_fixed_re[43] = 9'sd55;  assign cos_fixed_im[43] = 9'sd0;
assign cos_fixed_re[44] = 9'sd55;  assign cos_fixed_im[44] = 9'sd0;
assign cos_fixed_re[45] = 9'sd54;  assign cos_fixed_im[45] = 9'sd0;
assign cos_fixed_re[46] = 9'sd54;  assign cos_fixed_im[46] = 9'sd0;
assign cos_fixed_re[47] = 9'sd54;  assign cos_fixed_im[47] = 9'sd0;
assign cos_fixed_re[48] = 9'sd53;  assign cos_fixed_im[48] = 9'sd0;
assign cos_fixed_re[49] = 9'sd53;  assign cos_fixed_im[49] = 9'sd0;
assign cos_fixed_re[50] = 9'sd52;  assign cos_fixed_im[50] = 9'sd0;
assign cos_fixed_re[51] = 9'sd52;  assign cos_fixed_im[51] = 9'sd0;
assign cos_fixed_re[52] = 9'sd51;  assign cos_fixed_im[52] = 9'sd0;
assign cos_fixed_re[53] = 9'sd51;  assign cos_fixed_im[53] = 9'sd0;
assign cos_fixed_re[54] = 9'sd50;  assign cos_fixed_im[54] = 9'sd0;
assign cos_fixed_re[55] = 9'sd50;  assign cos_fixed_im[55] = 9'sd0;
assign cos_fixed_re[56] = 9'sd49;  assign cos_fixed_im[56] = 9'sd0;
assign cos_fixed_re[57] = 9'sd49;  assign cos_fixed_im[57] = 9'sd0;
assign cos_fixed_re[58] = 9'sd48;  assign cos_fixed_im[58] = 9'sd0;
assign cos_fixed_re[59] = 9'sd48;  assign cos_fixed_im[59] = 9'sd0;
assign cos_fixed_re[60] = 9'sd47;  assign cos_fixed_im[60] = 9'sd0;
assign cos_fixed_re[61] = 9'sd47;  assign cos_fixed_im[61] = 9'sd0;
assign cos_fixed_re[62] = 9'sd46;  assign cos_fixed_im[62] = 9'sd0;
assign cos_fixed_re[63] = 9'sd46;  assign cos_fixed_im[63] = 9'sd0;
assign cos_fixed_re[64] = 9'sd45;  assign cos_fixed_im[64] = 9'sd0;
assign cos_fixed_re[65] = 9'sd45;  assign cos_fixed_im[65] = 9'sd0;
assign cos_fixed_re[66] = 9'sd44;  assign cos_fixed_im[66] = 9'sd0;
assign cos_fixed_re[67] = 9'sd44;  assign cos_fixed_im[67] = 9'sd0;
assign cos_fixed_re[68] = 9'sd43;  assign cos_fixed_im[68] = 9'sd0;
assign cos_fixed_re[69] = 9'sd42;  assign cos_fixed_im[69] = 9'sd0;
assign cos_fixed_re[70] = 9'sd42;  assign cos_fixed_im[70] = 9'sd0;
assign cos_fixed_re[71] = 9'sd41;  assign cos_fixed_im[71] = 9'sd0;
assign cos_fixed_re[72] = 9'sd41;  assign cos_fixed_im[72] = 9'sd0;
assign cos_fixed_re[73] = 9'sd40;  assign cos_fixed_im[73] = 9'sd0;
assign cos_fixed_re[74] = 9'sd39;  assign cos_fixed_im[74] = 9'sd0;
assign cos_fixed_re[75] = 9'sd39;  assign cos_fixed_im[75] = 9'sd0;
assign cos_fixed_re[76] = 9'sd38;  assign cos_fixed_im[76] = 9'sd0;
assign cos_fixed_re[77] = 9'sd37;  assign cos_fixed_im[77] = 9'sd0;
assign cos_fixed_re[78] = 9'sd37;  assign cos_fixed_im[78] = 9'sd0;
assign cos_fixed_re[79] = 9'sd36;  assign cos_fixed_im[79] = 9'sd0;
assign cos_fixed_re[80] = 9'sd36;  assign cos_fixed_im[80] = 9'sd0;
assign cos_fixed_re[81] = 9'sd35;  assign cos_fixed_im[81] = 9'sd0;
assign cos_fixed_re[82] = 9'sd34;  assign cos_fixed_im[82] = 9'sd0;
assign cos_fixed_re[83] = 9'sd34;  assign cos_fixed_im[83] = 9'sd0;
assign cos_fixed_re[84] = 9'sd33;  assign cos_fixed_im[84] = 9'sd0;
assign cos_fixed_re[85] = 9'sd32;  assign cos_fixed_im[85] = 9'sd0;
assign cos_fixed_re[86] = 9'sd32;  assign cos_fixed_im[86] = 9'sd0;
assign cos_fixed_re[87] = 9'sd31;  assign cos_fixed_im[87] = 9'sd0;
assign cos_fixed_re[88] = 9'sd30;  assign cos_fixed_im[88] = 9'sd0;
assign cos_fixed_re[89] = 9'sd29;  assign cos_fixed_im[89] = 9'sd0;
assign cos_fixed_re[90] = 9'sd29;  assign cos_fixed_im[90] = 9'sd0;
assign cos_fixed_re[91] = 9'sd28;  assign cos_fixed_im[91] = 9'sd0;
assign cos_fixed_re[92] = 9'sd27;  assign cos_fixed_im[92] = 9'sd0;
assign cos_fixed_re[93] = 9'sd27;  assign cos_fixed_im[93] = 9'sd0;
assign cos_fixed_re[94] = 9'sd26;  assign cos_fixed_im[94] = 9'sd0;
assign cos_fixed_re[95] = 9'sd25;  assign cos_fixed_im[95] = 9'sd0;
assign cos_fixed_re[96] = 9'sd24;  assign cos_fixed_im[96] = 9'sd0;
assign cos_fixed_re[97] = 9'sd24;  assign cos_fixed_im[97] = 9'sd0;
assign cos_fixed_re[98] = 9'sd23;  assign cos_fixed_im[98] = 9'sd0;
assign cos_fixed_re[99] = 9'sd22;  assign cos_fixed_im[99] = 9'sd0;
assign cos_fixed_re[100] = 9'sd22;  assign cos_fixed_im[100] = 9'sd0;
assign cos_fixed_re[101] = 9'sd21;  assign cos_fixed_im[101] = 9'sd0;
assign cos_fixed_re[102] = 9'sd20;  assign cos_fixed_im[102] = 9'sd0;
assign cos_fixed_re[103] = 9'sd19;  assign cos_fixed_im[103] = 9'sd0;
assign cos_fixed_re[104] = 9'sd19;  assign cos_fixed_im[104] = 9'sd0;
assign cos_fixed_re[105] = 9'sd18;  assign cos_fixed_im[105] = 9'sd0;
assign cos_fixed_re[106] = 9'sd17;  assign cos_fixed_im[106] = 9'sd0;
assign cos_fixed_re[107] = 9'sd16;  assign cos_fixed_im[107] = 9'sd0;
assign cos_fixed_re[108] = 9'sd16;  assign cos_fixed_im[108] = 9'sd0;
assign cos_fixed_re[109] = 9'sd15;  assign cos_fixed_im[109] = 9'sd0;
assign cos_fixed_re[110] = 9'sd14;  assign cos_fixed_im[110] = 9'sd0;
assign cos_fixed_re[111] = 9'sd13;  assign cos_fixed_im[111] = 9'sd0;
assign cos_fixed_re[112] = 9'sd12;  assign cos_fixed_im[112] = 9'sd0;
assign cos_fixed_re[113] = 9'sd12;  assign cos_fixed_im[113] = 9'sd0;
assign cos_fixed_re[114] = 9'sd11;  assign cos_fixed_im[114] = 9'sd0;
assign cos_fixed_re[115] = 9'sd10;  assign cos_fixed_im[115] = 9'sd0;
assign cos_fixed_re[116] = 9'sd9;  assign cos_fixed_im[116] = 9'sd0;
assign cos_fixed_re[117] = 9'sd9;  assign cos_fixed_im[117] = 9'sd0;
assign cos_fixed_re[118] = 9'sd8;  assign cos_fixed_im[118] = 9'sd0;
assign cos_fixed_re[119] = 9'sd7;  assign cos_fixed_im[119] = 9'sd0;
assign cos_fixed_re[120] = 9'sd6;  assign cos_fixed_im[120] = 9'sd0;
assign cos_fixed_re[121] = 9'sd5;  assign cos_fixed_im[121] = 9'sd0;
assign cos_fixed_re[122] = 9'sd5;  assign cos_fixed_im[122] = 9'sd0;
assign cos_fixed_re[123] = 9'sd4;  assign cos_fixed_im[123] = 9'sd0;
assign cos_fixed_re[124] = 9'sd3;  assign cos_fixed_im[124] = 9'sd0;
assign cos_fixed_re[125] = 9'sd2;  assign cos_fixed_im[125] = 9'sd0;
assign cos_fixed_re[126] = 9'sd2;  assign cos_fixed_im[126] = 9'sd0;
assign cos_fixed_re[127] = 9'sd1;  assign cos_fixed_im[127] = 9'sd0;
assign cos_fixed_re[128] = 9'sd0;  assign cos_fixed_im[128] = 9'sd0;
assign cos_fixed_re[129] = -9'sd1;  assign cos_fixed_im[129] = 9'sd0;
assign cos_fixed_re[130] = -9'sd2;  assign cos_fixed_im[130] = 9'sd0;
assign cos_fixed_re[131] = -9'sd2;  assign cos_fixed_im[131] = 9'sd0;
assign cos_fixed_re[132] = -9'sd3;  assign cos_fixed_im[132] = 9'sd0;
assign cos_fixed_re[133] = -9'sd4;  assign cos_fixed_im[133] = 9'sd0;
assign cos_fixed_re[134] = -9'sd5;  assign cos_fixed_im[134] = 9'sd0;
assign cos_fixed_re[135] = -9'sd5;  assign cos_fixed_im[135] = 9'sd0;
assign cos_fixed_re[136] = -9'sd6;  assign cos_fixed_im[136] = 9'sd0;
assign cos_fixed_re[137] = -9'sd7;  assign cos_fixed_im[137] = 9'sd0;
assign cos_fixed_re[138] = -9'sd8;  assign cos_fixed_im[138] = 9'sd0;
assign cos_fixed_re[139] = -9'sd9;  assign cos_fixed_im[139] = 9'sd0;
assign cos_fixed_re[140] = -9'sd9;  assign cos_fixed_im[140] = 9'sd0;
assign cos_fixed_re[141] = -9'sd10;  assign cos_fixed_im[141] = 9'sd0;
assign cos_fixed_re[142] = -9'sd11;  assign cos_fixed_im[142] = 9'sd0;
assign cos_fixed_re[143] = -9'sd12;  assign cos_fixed_im[143] = 9'sd0;
assign cos_fixed_re[144] = -9'sd12;  assign cos_fixed_im[144] = 9'sd0;
assign cos_fixed_re[145] = -9'sd13;  assign cos_fixed_im[145] = 9'sd0;
assign cos_fixed_re[146] = -9'sd14;  assign cos_fixed_im[146] = 9'sd0;
assign cos_fixed_re[147] = -9'sd15;  assign cos_fixed_im[147] = 9'sd0;
assign cos_fixed_re[148] = -9'sd16;  assign cos_fixed_im[148] = 9'sd0;
assign cos_fixed_re[149] = -9'sd16;  assign cos_fixed_im[149] = 9'sd0;
assign cos_fixed_re[150] = -9'sd17;  assign cos_fixed_im[150] = 9'sd0;
assign cos_fixed_re[151] = -9'sd18;  assign cos_fixed_im[151] = 9'sd0;
assign cos_fixed_re[152] = -9'sd19;  assign cos_fixed_im[152] = 9'sd0;
assign cos_fixed_re[153] = -9'sd19;  assign cos_fixed_im[153] = 9'sd0;
assign cos_fixed_re[154] = -9'sd20;  assign cos_fixed_im[154] = 9'sd0;
assign cos_fixed_re[155] = -9'sd21;  assign cos_fixed_im[155] = 9'sd0;
assign cos_fixed_re[156] = -9'sd22;  assign cos_fixed_im[156] = 9'sd0;
assign cos_fixed_re[157] = -9'sd22;  assign cos_fixed_im[157] = 9'sd0;
assign cos_fixed_re[158] = -9'sd23;  assign cos_fixed_im[158] = 9'sd0;
assign cos_fixed_re[159] = -9'sd24;  assign cos_fixed_im[159] = 9'sd0;
assign cos_fixed_re[160] = -9'sd24;  assign cos_fixed_im[160] = 9'sd0;
assign cos_fixed_re[161] = -9'sd25;  assign cos_fixed_im[161] = 9'sd0;
assign cos_fixed_re[162] = -9'sd26;  assign cos_fixed_im[162] = 9'sd0;
assign cos_fixed_re[163] = -9'sd27;  assign cos_fixed_im[163] = 9'sd0;
assign cos_fixed_re[164] = -9'sd27;  assign cos_fixed_im[164] = 9'sd0;
assign cos_fixed_re[165] = -9'sd28;  assign cos_fixed_im[165] = 9'sd0;
assign cos_fixed_re[166] = -9'sd29;  assign cos_fixed_im[166] = 9'sd0;
assign cos_fixed_re[167] = -9'sd29;  assign cos_fixed_im[167] = 9'sd0;
assign cos_fixed_re[168] = -9'sd30;  assign cos_fixed_im[168] = 9'sd0;
assign cos_fixed_re[169] = -9'sd31;  assign cos_fixed_im[169] = 9'sd0;
assign cos_fixed_re[170] = -9'sd32;  assign cos_fixed_im[170] = 9'sd0;
assign cos_fixed_re[171] = -9'sd32;  assign cos_fixed_im[171] = 9'sd0;
assign cos_fixed_re[172] = -9'sd33;  assign cos_fixed_im[172] = 9'sd0;
assign cos_fixed_re[173] = -9'sd34;  assign cos_fixed_im[173] = 9'sd0;
assign cos_fixed_re[174] = -9'sd34;  assign cos_fixed_im[174] = 9'sd0;
assign cos_fixed_re[175] = -9'sd35;  assign cos_fixed_im[175] = 9'sd0;
assign cos_fixed_re[176] = -9'sd36;  assign cos_fixed_im[176] = 9'sd0;
assign cos_fixed_re[177] = -9'sd36;  assign cos_fixed_im[177] = 9'sd0;
assign cos_fixed_re[178] = -9'sd37;  assign cos_fixed_im[178] = 9'sd0;
assign cos_fixed_re[179] = -9'sd37;  assign cos_fixed_im[179] = 9'sd0;
assign cos_fixed_re[180] = -9'sd38;  assign cos_fixed_im[180] = 9'sd0;
assign cos_fixed_re[181] = -9'sd39;  assign cos_fixed_im[181] = 9'sd0;
assign cos_fixed_re[182] = -9'sd39;  assign cos_fixed_im[182] = 9'sd0;
assign cos_fixed_re[183] = -9'sd40;  assign cos_fixed_im[183] = 9'sd0;
assign cos_fixed_re[184] = -9'sd41;  assign cos_fixed_im[184] = 9'sd0;
assign cos_fixed_re[185] = -9'sd41;  assign cos_fixed_im[185] = 9'sd0;
assign cos_fixed_re[186] = -9'sd42;  assign cos_fixed_im[186] = 9'sd0;
assign cos_fixed_re[187] = -9'sd42;  assign cos_fixed_im[187] = 9'sd0;
assign cos_fixed_re[188] = -9'sd43;  assign cos_fixed_im[188] = 9'sd0;
assign cos_fixed_re[189] = -9'sd44;  assign cos_fixed_im[189] = 9'sd0;
assign cos_fixed_re[190] = -9'sd44;  assign cos_fixed_im[190] = 9'sd0;
assign cos_fixed_re[191] = -9'sd45;  assign cos_fixed_im[191] = 9'sd0;
assign cos_fixed_re[192] = -9'sd45;  assign cos_fixed_im[192] = 9'sd0;
assign cos_fixed_re[193] = -9'sd46;  assign cos_fixed_im[193] = 9'sd0;
assign cos_fixed_re[194] = -9'sd46;  assign cos_fixed_im[194] = 9'sd0;
assign cos_fixed_re[195] = -9'sd47;  assign cos_fixed_im[195] = 9'sd0;
assign cos_fixed_re[196] = -9'sd47;  assign cos_fixed_im[196] = 9'sd0;
assign cos_fixed_re[197] = -9'sd48;  assign cos_fixed_im[197] = 9'sd0;
assign cos_fixed_re[198] = -9'sd48;  assign cos_fixed_im[198] = 9'sd0;
assign cos_fixed_re[199] = -9'sd49;  assign cos_fixed_im[199] = 9'sd0;
assign cos_fixed_re[200] = -9'sd49;  assign cos_fixed_im[200] = 9'sd0;
assign cos_fixed_re[201] = -9'sd50;  assign cos_fixed_im[201] = 9'sd0;
assign cos_fixed_re[202] = -9'sd50;  assign cos_fixed_im[202] = 9'sd0;
assign cos_fixed_re[203] = -9'sd51;  assign cos_fixed_im[203] = 9'sd0;
assign cos_fixed_re[204] = -9'sd51;  assign cos_fixed_im[204] = 9'sd0;
assign cos_fixed_re[205] = -9'sd52;  assign cos_fixed_im[205] = 9'sd0;
assign cos_fixed_re[206] = -9'sd52;  assign cos_fixed_im[206] = 9'sd0;
assign cos_fixed_re[207] = -9'sd53;  assign cos_fixed_im[207] = 9'sd0;
assign cos_fixed_re[208] = -9'sd53;  assign cos_fixed_im[208] = 9'sd0;
assign cos_fixed_re[209] = -9'sd54;  assign cos_fixed_im[209] = 9'sd0;
assign cos_fixed_re[210] = -9'sd54;  assign cos_fixed_im[210] = 9'sd0;
assign cos_fixed_re[211] = -9'sd54;  assign cos_fixed_im[211] = 9'sd0;
assign cos_fixed_re[212] = -9'sd55;  assign cos_fixed_im[212] = 9'sd0;
assign cos_fixed_re[213] = -9'sd55;  assign cos_fixed_im[213] = 9'sd0;
assign cos_fixed_re[214] = -9'sd56;  assign cos_fixed_im[214] = 9'sd0;
assign cos_fixed_re[215] = -9'sd56;  assign cos_fixed_im[215] = 9'sd0;
assign cos_fixed_re[216] = -9'sd56;  assign cos_fixed_im[216] = 9'sd0;
assign cos_fixed_re[217] = -9'sd57;  assign cos_fixed_im[217] = 9'sd0;
assign cos_fixed_re[218] = -9'sd57;  assign cos_fixed_im[218] = 9'sd0;
assign cos_fixed_re[219] = -9'sd58;  assign cos_fixed_im[219] = 9'sd0;
assign cos_fixed_re[220] = -9'sd58;  assign cos_fixed_im[220] = 9'sd0;
assign cos_fixed_re[221] = -9'sd58;  assign cos_fixed_im[221] = 9'sd0;
assign cos_fixed_re[222] = -9'sd59;  assign cos_fixed_im[222] = 9'sd0;
assign cos_fixed_re[223] = -9'sd59;  assign cos_fixed_im[223] = 9'sd0;
assign cos_fixed_re[224] = -9'sd59;  assign cos_fixed_im[224] = 9'sd0;
assign cos_fixed_re[225] = -9'sd59;  assign cos_fixed_im[225] = 9'sd0;
assign cos_fixed_re[226] = -9'sd60;  assign cos_fixed_im[226] = 9'sd0;
assign cos_fixed_re[227] = -9'sd60;  assign cos_fixed_im[227] = 9'sd0;
assign cos_fixed_re[228] = -9'sd60;  assign cos_fixed_im[228] = 9'sd0;
assign cos_fixed_re[229] = -9'sd61;  assign cos_fixed_im[229] = 9'sd0;
assign cos_fixed_re[230] = -9'sd61;  assign cos_fixed_im[230] = 9'sd0;
assign cos_fixed_re[231] = -9'sd61;  assign cos_fixed_im[231] = 9'sd0;
assign cos_fixed_re[232] = -9'sd61;  assign cos_fixed_im[232] = 9'sd0;
assign cos_fixed_re[233] = -9'sd61;  assign cos_fixed_im[233] = 9'sd0;
assign cos_fixed_re[234] = -9'sd62;  assign cos_fixed_im[234] = 9'sd0;
assign cos_fixed_re[235] = -9'sd62;  assign cos_fixed_im[235] = 9'sd0;
assign cos_fixed_re[236] = -9'sd62;  assign cos_fixed_im[236] = 9'sd0;
assign cos_fixed_re[237] = -9'sd62;  assign cos_fixed_im[237] = 9'sd0;
assign cos_fixed_re[238] = -9'sd62;  assign cos_fixed_im[238] = 9'sd0;
assign cos_fixed_re[239] = -9'sd63;  assign cos_fixed_im[239] = 9'sd0;
assign cos_fixed_re[240] = -9'sd63;  assign cos_fixed_im[240] = 9'sd0;
assign cos_fixed_re[241] = -9'sd63;  assign cos_fixed_im[241] = 9'sd0;
assign cos_fixed_re[242] = -9'sd63;  assign cos_fixed_im[242] = 9'sd0;
assign cos_fixed_re[243] = -9'sd63;  assign cos_fixed_im[243] = 9'sd0;
assign cos_fixed_re[244] = -9'sd63;  assign cos_fixed_im[244] = 9'sd0;
assign cos_fixed_re[245] = -9'sd63;  assign cos_fixed_im[245] = 9'sd0;
assign cos_fixed_re[246] = -9'sd64;  assign cos_fixed_im[246] = 9'sd0;
assign cos_fixed_re[247] = -9'sd64;  assign cos_fixed_im[247] = 9'sd0;
assign cos_fixed_re[248] = -9'sd64;  assign cos_fixed_im[248] = 9'sd0;
assign cos_fixed_re[249] = -9'sd64;  assign cos_fixed_im[249] = 9'sd0;
assign cos_fixed_re[250] = -9'sd64;  assign cos_fixed_im[250] = 9'sd0;
assign cos_fixed_re[251] = -9'sd64;  assign cos_fixed_im[251] = 9'sd0;
assign cos_fixed_re[252] = -9'sd64;  assign cos_fixed_im[252] = 9'sd0;
assign cos_fixed_re[253] = -9'sd64;  assign cos_fixed_im[253] = 9'sd0;
assign cos_fixed_re[254] = -9'sd64;  assign cos_fixed_im[254] = 9'sd0;
assign cos_fixed_re[255] = -9'sd64;  assign cos_fixed_im[255] = 9'sd0;
assign cos_fixed_re[256] = -9'sd64;  assign cos_fixed_im[256] = 9'sd0;
assign cos_fixed_re[257] = -9'sd64;  assign cos_fixed_im[257] = 9'sd0;
assign cos_fixed_re[258] = -9'sd64;  assign cos_fixed_im[258] = 9'sd0;
assign cos_fixed_re[259] = -9'sd64;  assign cos_fixed_im[259] = 9'sd0;
assign cos_fixed_re[260] = -9'sd64;  assign cos_fixed_im[260] = 9'sd0;
assign cos_fixed_re[261] = -9'sd64;  assign cos_fixed_im[261] = 9'sd0;
assign cos_fixed_re[262] = -9'sd64;  assign cos_fixed_im[262] = 9'sd0;
assign cos_fixed_re[263] = -9'sd64;  assign cos_fixed_im[263] = 9'sd0;
assign cos_fixed_re[264] = -9'sd64;  assign cos_fixed_im[264] = 9'sd0;
assign cos_fixed_re[265] = -9'sd64;  assign cos_fixed_im[265] = 9'sd0;
assign cos_fixed_re[266] = -9'sd64;  assign cos_fixed_im[266] = 9'sd0;
assign cos_fixed_re[267] = -9'sd63;  assign cos_fixed_im[267] = 9'sd0;
assign cos_fixed_re[268] = -9'sd63;  assign cos_fixed_im[268] = 9'sd0;
assign cos_fixed_re[269] = -9'sd63;  assign cos_fixed_im[269] = 9'sd0;
assign cos_fixed_re[270] = -9'sd63;  assign cos_fixed_im[270] = 9'sd0;
assign cos_fixed_re[271] = -9'sd63;  assign cos_fixed_im[271] = 9'sd0;
assign cos_fixed_re[272] = -9'sd63;  assign cos_fixed_im[272] = 9'sd0;
assign cos_fixed_re[273] = -9'sd63;  assign cos_fixed_im[273] = 9'sd0;
assign cos_fixed_re[274] = -9'sd62;  assign cos_fixed_im[274] = 9'sd0;
assign cos_fixed_re[275] = -9'sd62;  assign cos_fixed_im[275] = 9'sd0;
assign cos_fixed_re[276] = -9'sd62;  assign cos_fixed_im[276] = 9'sd0;
assign cos_fixed_re[277] = -9'sd62;  assign cos_fixed_im[277] = 9'sd0;
assign cos_fixed_re[278] = -9'sd62;  assign cos_fixed_im[278] = 9'sd0;
assign cos_fixed_re[279] = -9'sd61;  assign cos_fixed_im[279] = 9'sd0;
assign cos_fixed_re[280] = -9'sd61;  assign cos_fixed_im[280] = 9'sd0;
assign cos_fixed_re[281] = -9'sd61;  assign cos_fixed_im[281] = 9'sd0;
assign cos_fixed_re[282] = -9'sd61;  assign cos_fixed_im[282] = 9'sd0;
assign cos_fixed_re[283] = -9'sd61;  assign cos_fixed_im[283] = 9'sd0;
assign cos_fixed_re[284] = -9'sd60;  assign cos_fixed_im[284] = 9'sd0;
assign cos_fixed_re[285] = -9'sd60;  assign cos_fixed_im[285] = 9'sd0;
assign cos_fixed_re[286] = -9'sd60;  assign cos_fixed_im[286] = 9'sd0;
assign cos_fixed_re[287] = -9'sd59;  assign cos_fixed_im[287] = 9'sd0;
assign cos_fixed_re[288] = -9'sd59;  assign cos_fixed_im[288] = 9'sd0;
assign cos_fixed_re[289] = -9'sd59;  assign cos_fixed_im[289] = 9'sd0;
assign cos_fixed_re[290] = -9'sd59;  assign cos_fixed_im[290] = 9'sd0;
assign cos_fixed_re[291] = -9'sd58;  assign cos_fixed_im[291] = 9'sd0;
assign cos_fixed_re[292] = -9'sd58;  assign cos_fixed_im[292] = 9'sd0;
assign cos_fixed_re[293] = -9'sd58;  assign cos_fixed_im[293] = 9'sd0;
assign cos_fixed_re[294] = -9'sd57;  assign cos_fixed_im[294] = 9'sd0;
assign cos_fixed_re[295] = -9'sd57;  assign cos_fixed_im[295] = 9'sd0;
assign cos_fixed_re[296] = -9'sd56;  assign cos_fixed_im[296] = 9'sd0;
assign cos_fixed_re[297] = -9'sd56;  assign cos_fixed_im[297] = 9'sd0;
assign cos_fixed_re[298] = -9'sd56;  assign cos_fixed_im[298] = 9'sd0;
assign cos_fixed_re[299] = -9'sd55;  assign cos_fixed_im[299] = 9'sd0;
assign cos_fixed_re[300] = -9'sd55;  assign cos_fixed_im[300] = 9'sd0;
assign cos_fixed_re[301] = -9'sd54;  assign cos_fixed_im[301] = 9'sd0;
assign cos_fixed_re[302] = -9'sd54;  assign cos_fixed_im[302] = 9'sd0;
assign cos_fixed_re[303] = -9'sd54;  assign cos_fixed_im[303] = 9'sd0;
assign cos_fixed_re[304] = -9'sd53;  assign cos_fixed_im[304] = 9'sd0;
assign cos_fixed_re[305] = -9'sd53;  assign cos_fixed_im[305] = 9'sd0;
assign cos_fixed_re[306] = -9'sd52;  assign cos_fixed_im[306] = 9'sd0;
assign cos_fixed_re[307] = -9'sd52;  assign cos_fixed_im[307] = 9'sd0;
assign cos_fixed_re[308] = -9'sd51;  assign cos_fixed_im[308] = 9'sd0;
assign cos_fixed_re[309] = -9'sd51;  assign cos_fixed_im[309] = 9'sd0;
assign cos_fixed_re[310] = -9'sd50;  assign cos_fixed_im[310] = 9'sd0;
assign cos_fixed_re[311] = -9'sd50;  assign cos_fixed_im[311] = 9'sd0;
assign cos_fixed_re[312] = -9'sd49;  assign cos_fixed_im[312] = 9'sd0;
assign cos_fixed_re[313] = -9'sd49;  assign cos_fixed_im[313] = 9'sd0;
assign cos_fixed_re[314] = -9'sd48;  assign cos_fixed_im[314] = 9'sd0;
assign cos_fixed_re[315] = -9'sd48;  assign cos_fixed_im[315] = 9'sd0;
assign cos_fixed_re[316] = -9'sd47;  assign cos_fixed_im[316] = 9'sd0;
assign cos_fixed_re[317] = -9'sd47;  assign cos_fixed_im[317] = 9'sd0;
assign cos_fixed_re[318] = -9'sd46;  assign cos_fixed_im[318] = 9'sd0;
assign cos_fixed_re[319] = -9'sd46;  assign cos_fixed_im[319] = 9'sd0;
assign cos_fixed_re[320] = -9'sd45;  assign cos_fixed_im[320] = 9'sd0;
assign cos_fixed_re[321] = -9'sd45;  assign cos_fixed_im[321] = 9'sd0;
assign cos_fixed_re[322] = -9'sd44;  assign cos_fixed_im[322] = 9'sd0;
assign cos_fixed_re[323] = -9'sd44;  assign cos_fixed_im[323] = 9'sd0;
assign cos_fixed_re[324] = -9'sd43;  assign cos_fixed_im[324] = 9'sd0;
assign cos_fixed_re[325] = -9'sd42;  assign cos_fixed_im[325] = 9'sd0;
assign cos_fixed_re[326] = -9'sd42;  assign cos_fixed_im[326] = 9'sd0;
assign cos_fixed_re[327] = -9'sd41;  assign cos_fixed_im[327] = 9'sd0;
assign cos_fixed_re[328] = -9'sd41;  assign cos_fixed_im[328] = 9'sd0;
assign cos_fixed_re[329] = -9'sd40;  assign cos_fixed_im[329] = 9'sd0;
assign cos_fixed_re[330] = -9'sd39;  assign cos_fixed_im[330] = 9'sd0;
assign cos_fixed_re[331] = -9'sd39;  assign cos_fixed_im[331] = 9'sd0;
assign cos_fixed_re[332] = -9'sd38;  assign cos_fixed_im[332] = 9'sd0;
assign cos_fixed_re[333] = -9'sd37;  assign cos_fixed_im[333] = 9'sd0;
assign cos_fixed_re[334] = -9'sd37;  assign cos_fixed_im[334] = 9'sd0;
assign cos_fixed_re[335] = -9'sd36;  assign cos_fixed_im[335] = 9'sd0;
assign cos_fixed_re[336] = -9'sd36;  assign cos_fixed_im[336] = 9'sd0;
assign cos_fixed_re[337] = -9'sd35;  assign cos_fixed_im[337] = 9'sd0;
assign cos_fixed_re[338] = -9'sd34;  assign cos_fixed_im[338] = 9'sd0;
assign cos_fixed_re[339] = -9'sd34;  assign cos_fixed_im[339] = 9'sd0;
assign cos_fixed_re[340] = -9'sd33;  assign cos_fixed_im[340] = 9'sd0;
assign cos_fixed_re[341] = -9'sd32;  assign cos_fixed_im[341] = 9'sd0;
assign cos_fixed_re[342] = -9'sd32;  assign cos_fixed_im[342] = 9'sd0;
assign cos_fixed_re[343] = -9'sd31;  assign cos_fixed_im[343] = 9'sd0;
assign cos_fixed_re[344] = -9'sd30;  assign cos_fixed_im[344] = 9'sd0;
assign cos_fixed_re[345] = -9'sd29;  assign cos_fixed_im[345] = 9'sd0;
assign cos_fixed_re[346] = -9'sd29;  assign cos_fixed_im[346] = 9'sd0;
assign cos_fixed_re[347] = -9'sd28;  assign cos_fixed_im[347] = 9'sd0;
assign cos_fixed_re[348] = -9'sd27;  assign cos_fixed_im[348] = 9'sd0;
assign cos_fixed_re[349] = -9'sd27;  assign cos_fixed_im[349] = 9'sd0;
assign cos_fixed_re[350] = -9'sd26;  assign cos_fixed_im[350] = 9'sd0;
assign cos_fixed_re[351] = -9'sd25;  assign cos_fixed_im[351] = 9'sd0;
assign cos_fixed_re[352] = -9'sd24;  assign cos_fixed_im[352] = 9'sd0;
assign cos_fixed_re[353] = -9'sd24;  assign cos_fixed_im[353] = 9'sd0;
assign cos_fixed_re[354] = -9'sd23;  assign cos_fixed_im[354] = 9'sd0;
assign cos_fixed_re[355] = -9'sd22;  assign cos_fixed_im[355] = 9'sd0;
assign cos_fixed_re[356] = -9'sd22;  assign cos_fixed_im[356] = 9'sd0;
assign cos_fixed_re[357] = -9'sd21;  assign cos_fixed_im[357] = 9'sd0;
assign cos_fixed_re[358] = -9'sd20;  assign cos_fixed_im[358] = 9'sd0;
assign cos_fixed_re[359] = -9'sd19;  assign cos_fixed_im[359] = 9'sd0;
assign cos_fixed_re[360] = -9'sd19;  assign cos_fixed_im[360] = 9'sd0;
assign cos_fixed_re[361] = -9'sd18;  assign cos_fixed_im[361] = 9'sd0;
assign cos_fixed_re[362] = -9'sd17;  assign cos_fixed_im[362] = 9'sd0;
assign cos_fixed_re[363] = -9'sd16;  assign cos_fixed_im[363] = 9'sd0;
assign cos_fixed_re[364] = -9'sd16;  assign cos_fixed_im[364] = 9'sd0;
assign cos_fixed_re[365] = -9'sd15;  assign cos_fixed_im[365] = 9'sd0;
assign cos_fixed_re[366] = -9'sd14;  assign cos_fixed_im[366] = 9'sd0;
assign cos_fixed_re[367] = -9'sd13;  assign cos_fixed_im[367] = 9'sd0;
assign cos_fixed_re[368] = -9'sd12;  assign cos_fixed_im[368] = 9'sd0;
assign cos_fixed_re[369] = -9'sd12;  assign cos_fixed_im[369] = 9'sd0;
assign cos_fixed_re[370] = -9'sd11;  assign cos_fixed_im[370] = 9'sd0;
assign cos_fixed_re[371] = -9'sd10;  assign cos_fixed_im[371] = 9'sd0;
assign cos_fixed_re[372] = -9'sd9;  assign cos_fixed_im[372] = 9'sd0;
assign cos_fixed_re[373] = -9'sd9;  assign cos_fixed_im[373] = 9'sd0;
assign cos_fixed_re[374] = -9'sd8;  assign cos_fixed_im[374] = 9'sd0;
assign cos_fixed_re[375] = -9'sd7;  assign cos_fixed_im[375] = 9'sd0;
assign cos_fixed_re[376] = -9'sd6;  assign cos_fixed_im[376] = 9'sd0;
assign cos_fixed_re[377] = -9'sd5;  assign cos_fixed_im[377] = 9'sd0;
assign cos_fixed_re[378] = -9'sd5;  assign cos_fixed_im[378] = 9'sd0;
assign cos_fixed_re[379] = -9'sd4;  assign cos_fixed_im[379] = 9'sd0;
assign cos_fixed_re[380] = -9'sd3;  assign cos_fixed_im[380] = 9'sd0;
assign cos_fixed_re[381] = -9'sd2;  assign cos_fixed_im[381] = 9'sd0;
assign cos_fixed_re[382] = -9'sd2;  assign cos_fixed_im[382] = 9'sd0;
assign cos_fixed_re[383] = -9'sd1;  assign cos_fixed_im[383] = 9'sd0;
assign cos_fixed_re[384] = 9'sd0;  assign cos_fixed_im[384] = 9'sd0;
assign cos_fixed_re[385] = 9'sd1;  assign cos_fixed_im[385] = 9'sd0;
assign cos_fixed_re[386] = 9'sd2;  assign cos_fixed_im[386] = 9'sd0;
assign cos_fixed_re[387] = 9'sd2;  assign cos_fixed_im[387] = 9'sd0;
assign cos_fixed_re[388] = 9'sd3;  assign cos_fixed_im[388] = 9'sd0;
assign cos_fixed_re[389] = 9'sd4;  assign cos_fixed_im[389] = 9'sd0;
assign cos_fixed_re[390] = 9'sd5;  assign cos_fixed_im[390] = 9'sd0;
assign cos_fixed_re[391] = 9'sd5;  assign cos_fixed_im[391] = 9'sd0;
assign cos_fixed_re[392] = 9'sd6;  assign cos_fixed_im[392] = 9'sd0;
assign cos_fixed_re[393] = 9'sd7;  assign cos_fixed_im[393] = 9'sd0;
assign cos_fixed_re[394] = 9'sd8;  assign cos_fixed_im[394] = 9'sd0;
assign cos_fixed_re[395] = 9'sd9;  assign cos_fixed_im[395] = 9'sd0;
assign cos_fixed_re[396] = 9'sd9;  assign cos_fixed_im[396] = 9'sd0;
assign cos_fixed_re[397] = 9'sd10;  assign cos_fixed_im[397] = 9'sd0;
assign cos_fixed_re[398] = 9'sd11;  assign cos_fixed_im[398] = 9'sd0;
assign cos_fixed_re[399] = 9'sd12;  assign cos_fixed_im[399] = 9'sd0;
assign cos_fixed_re[400] = 9'sd12;  assign cos_fixed_im[400] = 9'sd0;
assign cos_fixed_re[401] = 9'sd13;  assign cos_fixed_im[401] = 9'sd0;
assign cos_fixed_re[402] = 9'sd14;  assign cos_fixed_im[402] = 9'sd0;
assign cos_fixed_re[403] = 9'sd15;  assign cos_fixed_im[403] = 9'sd0;
assign cos_fixed_re[404] = 9'sd16;  assign cos_fixed_im[404] = 9'sd0;
assign cos_fixed_re[405] = 9'sd16;  assign cos_fixed_im[405] = 9'sd0;
assign cos_fixed_re[406] = 9'sd17;  assign cos_fixed_im[406] = 9'sd0;
assign cos_fixed_re[407] = 9'sd18;  assign cos_fixed_im[407] = 9'sd0;
assign cos_fixed_re[408] = 9'sd19;  assign cos_fixed_im[408] = 9'sd0;
assign cos_fixed_re[409] = 9'sd19;  assign cos_fixed_im[409] = 9'sd0;
assign cos_fixed_re[410] = 9'sd20;  assign cos_fixed_im[410] = 9'sd0;
assign cos_fixed_re[411] = 9'sd21;  assign cos_fixed_im[411] = 9'sd0;
assign cos_fixed_re[412] = 9'sd22;  assign cos_fixed_im[412] = 9'sd0;
assign cos_fixed_re[413] = 9'sd22;  assign cos_fixed_im[413] = 9'sd0;
assign cos_fixed_re[414] = 9'sd23;  assign cos_fixed_im[414] = 9'sd0;
assign cos_fixed_re[415] = 9'sd24;  assign cos_fixed_im[415] = 9'sd0;
assign cos_fixed_re[416] = 9'sd24;  assign cos_fixed_im[416] = 9'sd0;
assign cos_fixed_re[417] = 9'sd25;  assign cos_fixed_im[417] = 9'sd0;
assign cos_fixed_re[418] = 9'sd26;  assign cos_fixed_im[418] = 9'sd0;
assign cos_fixed_re[419] = 9'sd27;  assign cos_fixed_im[419] = 9'sd0;
assign cos_fixed_re[420] = 9'sd27;  assign cos_fixed_im[420] = 9'sd0;
assign cos_fixed_re[421] = 9'sd28;  assign cos_fixed_im[421] = 9'sd0;
assign cos_fixed_re[422] = 9'sd29;  assign cos_fixed_im[422] = 9'sd0;
assign cos_fixed_re[423] = 9'sd29;  assign cos_fixed_im[423] = 9'sd0;
assign cos_fixed_re[424] = 9'sd30;  assign cos_fixed_im[424] = 9'sd0;
assign cos_fixed_re[425] = 9'sd31;  assign cos_fixed_im[425] = 9'sd0;
assign cos_fixed_re[426] = 9'sd32;  assign cos_fixed_im[426] = 9'sd0;
assign cos_fixed_re[427] = 9'sd32;  assign cos_fixed_im[427] = 9'sd0;
assign cos_fixed_re[428] = 9'sd33;  assign cos_fixed_im[428] = 9'sd0;
assign cos_fixed_re[429] = 9'sd34;  assign cos_fixed_im[429] = 9'sd0;
assign cos_fixed_re[430] = 9'sd34;  assign cos_fixed_im[430] = 9'sd0;
assign cos_fixed_re[431] = 9'sd35;  assign cos_fixed_im[431] = 9'sd0;
assign cos_fixed_re[432] = 9'sd36;  assign cos_fixed_im[432] = 9'sd0;
assign cos_fixed_re[433] = 9'sd36;  assign cos_fixed_im[433] = 9'sd0;
assign cos_fixed_re[434] = 9'sd37;  assign cos_fixed_im[434] = 9'sd0;
assign cos_fixed_re[435] = 9'sd37;  assign cos_fixed_im[435] = 9'sd0;
assign cos_fixed_re[436] = 9'sd38;  assign cos_fixed_im[436] = 9'sd0;
assign cos_fixed_re[437] = 9'sd39;  assign cos_fixed_im[437] = 9'sd0;
assign cos_fixed_re[438] = 9'sd39;  assign cos_fixed_im[438] = 9'sd0;
assign cos_fixed_re[439] = 9'sd40;  assign cos_fixed_im[439] = 9'sd0;
assign cos_fixed_re[440] = 9'sd41;  assign cos_fixed_im[440] = 9'sd0;
assign cos_fixed_re[441] = 9'sd41;  assign cos_fixed_im[441] = 9'sd0;
assign cos_fixed_re[442] = 9'sd42;  assign cos_fixed_im[442] = 9'sd0;
assign cos_fixed_re[443] = 9'sd42;  assign cos_fixed_im[443] = 9'sd0;
assign cos_fixed_re[444] = 9'sd43;  assign cos_fixed_im[444] = 9'sd0;
assign cos_fixed_re[445] = 9'sd44;  assign cos_fixed_im[445] = 9'sd0;
assign cos_fixed_re[446] = 9'sd44;  assign cos_fixed_im[446] = 9'sd0;
assign cos_fixed_re[447] = 9'sd45;  assign cos_fixed_im[447] = 9'sd0;
assign cos_fixed_re[448] = 9'sd45;  assign cos_fixed_im[448] = 9'sd0;
assign cos_fixed_re[449] = 9'sd46;  assign cos_fixed_im[449] = 9'sd0;
assign cos_fixed_re[450] = 9'sd46;  assign cos_fixed_im[450] = 9'sd0;
assign cos_fixed_re[451] = 9'sd47;  assign cos_fixed_im[451] = 9'sd0;
assign cos_fixed_re[452] = 9'sd47;  assign cos_fixed_im[452] = 9'sd0;
assign cos_fixed_re[453] = 9'sd48;  assign cos_fixed_im[453] = 9'sd0;
assign cos_fixed_re[454] = 9'sd48;  assign cos_fixed_im[454] = 9'sd0;
assign cos_fixed_re[455] = 9'sd49;  assign cos_fixed_im[455] = 9'sd0;
assign cos_fixed_re[456] = 9'sd49;  assign cos_fixed_im[456] = 9'sd0;
assign cos_fixed_re[457] = 9'sd50;  assign cos_fixed_im[457] = 9'sd0;
assign cos_fixed_re[458] = 9'sd50;  assign cos_fixed_im[458] = 9'sd0;
assign cos_fixed_re[459] = 9'sd51;  assign cos_fixed_im[459] = 9'sd0;
assign cos_fixed_re[460] = 9'sd51;  assign cos_fixed_im[460] = 9'sd0;
assign cos_fixed_re[461] = 9'sd52;  assign cos_fixed_im[461] = 9'sd0;
assign cos_fixed_re[462] = 9'sd52;  assign cos_fixed_im[462] = 9'sd0;
assign cos_fixed_re[463] = 9'sd53;  assign cos_fixed_im[463] = 9'sd0;
assign cos_fixed_re[464] = 9'sd53;  assign cos_fixed_im[464] = 9'sd0;
assign cos_fixed_re[465] = 9'sd54;  assign cos_fixed_im[465] = 9'sd0;
assign cos_fixed_re[466] = 9'sd54;  assign cos_fixed_im[466] = 9'sd0;
assign cos_fixed_re[467] = 9'sd54;  assign cos_fixed_im[467] = 9'sd0;
assign cos_fixed_re[468] = 9'sd55;  assign cos_fixed_im[468] = 9'sd0;
assign cos_fixed_re[469] = 9'sd55;  assign cos_fixed_im[469] = 9'sd0;
assign cos_fixed_re[470] = 9'sd56;  assign cos_fixed_im[470] = 9'sd0;
assign cos_fixed_re[471] = 9'sd56;  assign cos_fixed_im[471] = 9'sd0;
assign cos_fixed_re[472] = 9'sd56;  assign cos_fixed_im[472] = 9'sd0;
assign cos_fixed_re[473] = 9'sd57;  assign cos_fixed_im[473] = 9'sd0;
assign cos_fixed_re[474] = 9'sd57;  assign cos_fixed_im[474] = 9'sd0;
assign cos_fixed_re[475] = 9'sd58;  assign cos_fixed_im[475] = 9'sd0;
assign cos_fixed_re[476] = 9'sd58;  assign cos_fixed_im[476] = 9'sd0;
assign cos_fixed_re[477] = 9'sd58;  assign cos_fixed_im[477] = 9'sd0;
assign cos_fixed_re[478] = 9'sd59;  assign cos_fixed_im[478] = 9'sd0;
assign cos_fixed_re[479] = 9'sd59;  assign cos_fixed_im[479] = 9'sd0;
assign cos_fixed_re[480] = 9'sd59;  assign cos_fixed_im[480] = 9'sd0;
assign cos_fixed_re[481] = 9'sd59;  assign cos_fixed_im[481] = 9'sd0;
assign cos_fixed_re[482] = 9'sd60;  assign cos_fixed_im[482] = 9'sd0;
assign cos_fixed_re[483] = 9'sd60;  assign cos_fixed_im[483] = 9'sd0;
assign cos_fixed_re[484] = 9'sd60;  assign cos_fixed_im[484] = 9'sd0;
assign cos_fixed_re[485] = 9'sd61;  assign cos_fixed_im[485] = 9'sd0;
assign cos_fixed_re[486] = 9'sd61;  assign cos_fixed_im[486] = 9'sd0;
assign cos_fixed_re[487] = 9'sd61;  assign cos_fixed_im[487] = 9'sd0;
assign cos_fixed_re[488] = 9'sd61;  assign cos_fixed_im[488] = 9'sd0;
assign cos_fixed_re[489] = 9'sd61;  assign cos_fixed_im[489] = 9'sd0;
assign cos_fixed_re[490] = 9'sd62;  assign cos_fixed_im[490] = 9'sd0;
assign cos_fixed_re[491] = 9'sd62;  assign cos_fixed_im[491] = 9'sd0;
assign cos_fixed_re[492] = 9'sd62;  assign cos_fixed_im[492] = 9'sd0;
assign cos_fixed_re[493] = 9'sd62;  assign cos_fixed_im[493] = 9'sd0;
assign cos_fixed_re[494] = 9'sd62;  assign cos_fixed_im[494] = 9'sd0;
assign cos_fixed_re[495] = 9'sd63;  assign cos_fixed_im[495] = 9'sd0;
assign cos_fixed_re[496] = 9'sd63;  assign cos_fixed_im[496] = 9'sd0;
assign cos_fixed_re[497] = 9'sd63;  assign cos_fixed_im[497] = 9'sd0;
assign cos_fixed_re[498] = 9'sd63;  assign cos_fixed_im[498] = 9'sd0;
assign cos_fixed_re[499] = 9'sd63;  assign cos_fixed_im[499] = 9'sd0;
assign cos_fixed_re[500] = 9'sd63;  assign cos_fixed_im[500] = 9'sd0;
assign cos_fixed_re[501] = 9'sd63;  assign cos_fixed_im[501] = 9'sd0;
assign cos_fixed_re[502] = 9'sd64;  assign cos_fixed_im[502] = 9'sd0;
assign cos_fixed_re[503] = 9'sd64;  assign cos_fixed_im[503] = 9'sd0;
assign cos_fixed_re[504] = 9'sd64;  assign cos_fixed_im[504] = 9'sd0;
assign cos_fixed_re[505] = 9'sd64;  assign cos_fixed_im[505] = 9'sd0;
assign cos_fixed_re[506] = 9'sd64;  assign cos_fixed_im[506] = 9'sd0;
assign cos_fixed_re[507] = 9'sd64;  assign cos_fixed_im[507] = 9'sd0;
assign cos_fixed_re[508] = 9'sd64;  assign cos_fixed_im[508] = 9'sd0;
assign cos_fixed_re[509] = 9'sd64;  assign cos_fixed_im[509] = 9'sd0;
assign cos_fixed_re[510] = 9'sd64;  assign cos_fixed_im[510] = 9'sd0;
assign cos_fixed_re[511] = 9'sd64;  assign cos_fixed_im[511] = 9'sd0;


assign fixed_re = cos_fixed_re[addr];
assign fixed_im = cos_fixed_im[addr];
endmodule

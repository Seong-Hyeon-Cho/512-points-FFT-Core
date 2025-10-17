`timescale 1ns / 1ps


// indexsum_re 계산을 위한 조합논리 모듈
module indexsum_calculator #(
    parameter SHIFT_WIDTH = 5,
    parameter TOTAL_SIZE = 512,
    parameter DATA_PER_CLK = 16
)(
    input logic [8:0] internal_cycle_idx,
    input logic [SHIFT_WIDTH-1:0] applied_shift_out_0 [TOTAL_SIZE],
    input logic [SHIFT_WIDTH-1:0] applied_shift_out_1 [TOTAL_SIZE],
    output logic [SHIFT_WIDTH:0] indexsum_re [DATA_PER_CLK-1:0],
    output logic [SHIFT_WIDTH:0] indexsum_im [DATA_PER_CLK-1:0]
);

    integer i;
    integer global_idx;
    logic [8:0] reverse_idx [DATA_PER_CLK-1:0];

    always_comb begin
        for (i = 0; i < DATA_PER_CLK; i++) begin
            global_idx = internal_cycle_idx * DATA_PER_CLK + i;
            // applied_shift_out 접근 인덱스를 511부터 거꾸로
            reverse_idx[i] = TOTAL_SIZE - 1 - global_idx;  // 511부터 0까지

            indexsum_re[i] = applied_shift_out_0[reverse_idx[i]] + applied_shift_out_1[reverse_idx[i]];
            indexsum_im[i] = applied_shift_out_0[reverse_idx[i]] + applied_shift_out_1[reverse_idx[i]];
        end
    end

endmodule

module final_cbfp_scaler #(
    parameter IN_WIDTH      = 16,
    parameter OUT_WIDTH     = 13,
    parameter SHIFT_WIDTH   = 5,
    parameter DATA_PER_CLK  = 16,
    parameter TOTAL_SIZE    = 512
)(
    input  logic                      clk,
    input  logic                      rstn,
    input  logic                      valid_in,
    input  logic signed [IN_WIDTH-1:0]  din_i [DATA_PER_CLK],
    input  logic signed [IN_WIDTH-1:0]  din_q [DATA_PER_CLK],
    input  logic [SHIFT_WIDTH-1:0]      applied_shift_out_0 [TOTAL_SIZE],
    input  logic [SHIFT_WIDTH-1:0]      applied_shift_out_1 [TOTAL_SIZE],
    output logic signed [OUT_WIDTH-1:0] dout_i [DATA_PER_CLK],
    output logic signed [OUT_WIDTH-1:0] dout_q [DATA_PER_CLK],
    output logic                      valid_out
);

    // 내부 카운터 - valid_in이 들어올 때만 증가
    logic [8:0] internal_cycle_idx;
    // valid_out 제어를 위한 카운터
    logic [5:0] valid_counter;
    logic valid_out_active;
    
    // indexsum 계산을 위한 조합논리 모듈 인스턴스
    logic [SHIFT_WIDTH:0] indexsum_re [DATA_PER_CLK-1:0], indexsum_im [DATA_PER_CLK-1:0];
    
    indexsum_calculator #(
        .SHIFT_WIDTH(SHIFT_WIDTH),
        .TOTAL_SIZE(TOTAL_SIZE),
        .DATA_PER_CLK(DATA_PER_CLK)
    ) indexsum_calc (
        .internal_cycle_idx(internal_cycle_idx),
        .applied_shift_out_0(applied_shift_out_0),
        .applied_shift_out_1(applied_shift_out_1),
        .indexsum_re(indexsum_re),
        .indexsum_im(indexsum_im)
    );
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            internal_cycle_idx <= 0;
            valid_counter <= 0;
            valid_out_active <= 1'b0;
        end else begin
            if (valid_in) begin
            internal_cycle_idx <= internal_cycle_idx + 1;
                // valid_in이 들어오면 valid_out_active 시작
                if (!valid_out_active) begin
                    valid_out_active <= 1'b1;
                    valid_counter <= 0;
                end
            end
            
            // valid_out_active가 활성화되면 카운터 증가
            if (valid_out_active) begin
                if (valid_counter < 32) begin
                    valid_counter <= valid_counter + 1;
                end else begin
                    valid_out_active <= 1'b0;  // 32클럭 후 비활성화
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        integer i;
        logic signed [6:0] shift_amt_re, shift_amt_im;
        if (!rstn) begin
            valid_out <= 1'b0;
            for (i = 0; i < DATA_PER_CLK; i++) begin
                dout_i[i] <= {OUT_WIDTH{1'b0}};
                dout_q[i] <= {OUT_WIDTH{1'b0}};
            end
        end else begin
            if (valid_in) begin
                // valid_in이 들어오면 다음 클럭에 valid_out 활성화
                valid_out <= 1'b1;
                
                for (i = 0; i < DATA_PER_CLK; i++) begin
                    // Real Part (I) - din은 15부터 0까지, indexsum은 0부터 15까지 매칭
                    shift_amt_re = 7'd9 - indexsum_re[i];
                    if (indexsum_re[i] >= 23)
                        dout_i[i] <= {OUT_WIDTH{1'b0}};
                    else if (shift_amt_re[6])  // 음수인 경우 (MSB가 1)
                        dout_i[i] <= din_i[DATA_PER_CLK-1-i] >>> (-shift_amt_re);
                    else  // 양수인 경우
                        dout_i[i] <= din_i[DATA_PER_CLK-1-i] <<< shift_amt_re;

                    // Imaginary Part (Q) - din은 15부터 0까지, indexsum은 0부터 15까지 매칭
                    shift_amt_im = 7'd9 - indexsum_im[i];
                    if (indexsum_im[i] >= 23)
                        dout_q[i] <= {OUT_WIDTH{1'b0}};
                    else if (shift_amt_im[6])  // 음수인 경우 (MSB가 1)
                        dout_q[i] <= din_q[DATA_PER_CLK-1-i] >>> (-shift_amt_im);
                    else  // 양수인 경우
                        dout_q[i] <= din_q[DATA_PER_CLK-1-i] <<< shift_amt_im;
                end
            end else begin
                // 32클럭 후에는 무조건 valid_out 비활성화
                if (valid_counter >= 32) begin
                    valid_out <= 1'b0;
                end else begin
                    valid_out <= valid_out;  // 이전 값 유지
                end
            end
        end
    end

endmodule

module fft_cbfp_module1 (
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input  logic signed [24:0] pre_bfly12_real_in [15:0],  // 16개의 25bit 실수부 입력
    input  logic signed [24:0] pre_bfly12_imag_in [15:0],  // 16개의 25bit 허수부 입력
    output logic [4:0] applied_shift_out_2 [511:0],
    output logic valid_out,
    output logic signed [11:0] bfly12_real_out [15:0],     // 16개의 12bit 실수부 출력
    output logic signed [11:0] bfly12_imag_out [15:0]      // 16개의 12bit 허수부 출력
);

    // Parameters
    localparam int DATA_WIDTH = 25;
    localparam int OUTPUT_WIDTH = 12;
    localparam int SHIFT_WIDTH = 5;
    localparam int DATA_PER_CLK = 16;
    localparam int GROUP_SIZE = 8;              // 각 블록당 8개 데이터
    localparam int NUM_8_GROUPS = 2;            // 16개 데이터를 8개씩 2그룹으로 처리
    localparam int TARGET_SHIFT = 13;           // 스케일링 기준값
    localparam int NUM_64_BLOCKS = 64;          // 총 64개 블록

    // =============== 스트리밍 처리용 변수들 ===============
    logic [8:0] data_counter;                  // 데이터 카운터 (0~511)
    logic [5:0] valid_counter;                 // valid 제어용 카운터

    function automatic logic [4:0] magnitude_detector;
        input logic signed [24:0] input_data;
        logic [24:0] d;
        logic [4:0] count;
        logic s;
        begin
            d = input_data;
            s = d[24]; // sign bit

            // leading sign extension count
            count = (d[23] != s) ? 5'd0  :
                    (d[22] != s) ? 5'd1  :
                    (d[21] != s) ? 5'd2  :
                    (d[20] != s) ? 5'd3  :
                    (d[19] != s) ? 5'd4  :
                    (d[18] != s) ? 5'd5  :
                    (d[17] != s) ? 5'd6  :
                    (d[16] != s) ? 5'd7  :
                    (d[15] != s) ? 5'd8  :
                    (d[14] != s) ? 5'd9  :
                    (d[13] != s) ? 5'd10 :
                    (d[12] != s) ? 5'd11 :
                    (d[11] != s) ? 5'd12 :
                    (d[10] != s) ? 5'd13 :
                    (d[9]  != s) ? 5'd14 :
                    (d[8]  != s) ? 5'd15 :
                    (d[7]  != s) ? 5'd16 :
                    (d[6]  != s) ? 5'd17 :
                    (d[5]  != s) ? 5'd18 :
                    (d[4]  != s) ? 5'd19 :
                    (d[3]  != s) ? 5'd20 :
                    (d[2]  != s) ? 5'd21 :
                    (d[1]  != s) ? 5'd22 :
                    (d[0]  != s) ? 5'd23 :
                                   5'd24 ;  // all bits match sign
            magnitude_detector = count;
        end
    endfunction

    // =============== 8개 값 중 최솟값 찾기 (조합논리) ===============
    function automatic logic [SHIFT_WIDTH-1:0] minimum_finder_8;
        input [SHIFT_WIDTH-1:0] input_array[7:0];
        logic [SHIFT_WIDTH-1:0] level1 [3:0];
        logic [SHIFT_WIDTH-1:0] level2 [1:0];
        logic [SHIFT_WIDTH-1:0] result;
        begin
            for (int i = 0; i < 4; i++) begin
                level1[i] = (input_array[i*2] < input_array[i*2+1]) ? input_array[i*2] : input_array[i*2+1];
            end
            for (int i = 0; i < 2; i++) begin
                level2[i] = (level1[i*2] < level1[i*2+1]) ? level1[i*2] : level1[i*2+1];
            end
            result = (level2[0] < level2[1]) ? level2[0] : level2[1];
            minimum_finder_8 = result;
        end
    endfunction

    // =============== Barrel Shifter (조합논리) ===============
    function automatic logic [OUTPUT_WIDTH-1:0] barrel_shifter_normalize;
        input [DATA_WIDTH-1:0] input_data;
        input [SHIFT_WIDTH-1:0] shift_amount;
        logic signed [63:0] temp_result;
        begin
            temp_result = input_data;
            if (shift_amount > TARGET_SHIFT) begin
                // 유효비트수가 작음 -> 왼쪽 시프트 후 오른쪽 시프트
                temp_result = temp_result <<< (shift_amount - TARGET_SHIFT);
            end else begin
                // 오른쪽 시프트로 12비트 스케일링
                temp_result = temp_result >>> (TARGET_SHIFT - shift_amount);
            end
            barrel_shifter_normalize = temp_result[OUTPUT_WIDTH-1:0];
        end
    endfunction

    // =============== 스트리밍 입력 처리 (블록 단위 최적화 유지) ===============
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_counter <= 0;
            valid_counter <= 0;
            // applied_shift_out_2 초기화
            for (int i = 0; i < 512; i++) begin
                applied_shift_out_2[i] <= 5'd25;
            end
        end else if (valid_in) begin
            // 16개 데이터를 8개씩 2그룹으로 나누어 처리 (기존 로직 유지)
            logic [4:0] mag_real[15:0], mag_imag[15:0];
            logic [4:0] mag_real_grp0[7:0], mag_real_grp1[7:0];
            logic [4:0] mag_imag_grp0[7:0], mag_imag_grp1[7:0];
            logic [4:0] min_real_grp0, min_real_grp1;
            logic [4:0] min_imag_grp0, min_imag_grp1;
            logic [4:0] final_min_blk0, final_min_blk1;
            
            // 현재 입력 데이터의 magnitude 계산
            for (int i = 0; i < 16; i++) begin
                mag_real[i] = magnitude_detector(pre_bfly12_real_in[i]);
                mag_imag[i] = magnitude_detector(pre_bfly12_imag_in[i]);
            end

            // 그룹별로 분리 (0~7, 8~15)
            for (int i = 0; i < 8; i++) begin
                mag_real_grp0[i] = mag_real[i];      // 0~7
                mag_real_grp1[i] = mag_real[i+8];    // 8~15
                mag_imag_grp0[i] = mag_imag[i];      // 0~7
                mag_imag_grp1[i] = mag_imag[i+8];    // 8~15
            end

            // 각 그룹별 최솟값 찾기
            min_real_grp0 = minimum_finder_8(mag_real_grp0);
            min_real_grp1 = minimum_finder_8(mag_real_grp1);
            min_imag_grp0 = minimum_finder_8(mag_imag_grp0);
            min_imag_grp1 = minimum_finder_8(mag_imag_grp1);

            // 각 블록별 최종 최솟값 (실수부와 허수부 중 작은 값)
            final_min_blk0 = (min_real_grp0 < min_imag_grp0) ? min_real_grp0 : min_imag_grp0;
            final_min_blk1 = (min_real_grp1 < min_imag_grp1) ? min_real_grp1 : min_imag_grp1;
            
            // applied_shift_out_2에 블록 단위 shift값 저장
            for (int i = 0; i < 8; i++) begin
                applied_shift_out_2[data_counter + i] <= final_min_blk0;      // 0~7
                applied_shift_out_2[data_counter + i + 8] <= final_min_blk1;  // 8~15
            end
            
            // 데이터 카운터 업데이트
            data_counter <= data_counter + 16;
            
            // valid 카운터 업데이트 (32클럭 제한)
            if (valid_counter < 32) begin
                valid_counter <= valid_counter + 1;
            end
        end
    end

    // =============== 스트리밍 출력 처리 (블록 단위 최적화 유지) ===============
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            // 출력 초기화
            for (int i = 0; i < 16; i++) begin
                bfly12_real_out[i] <= 0;
                bfly12_imag_out[i] <= 0;
            end
        end else if (valid_in) begin
            // 16개 데이터를 8개씩 2그룹으로 나누어 처리 (기존 로직 유지)
            logic [4:0] mag_real[15:0], mag_imag[15:0];
            logic [4:0] mag_real_grp0[7:0], mag_real_grp1[7:0];
            logic [4:0] mag_imag_grp0[7:0], mag_imag_grp1[7:0];
            logic [4:0] min_real_grp0, min_real_grp1;
            logic [4:0] min_imag_grp0, min_imag_grp1;
            logic [4:0] final_min_blk0, final_min_blk1;
            
            // 현재 입력 데이터의 magnitude 계산
            for (int i = 0; i < 16; i++) begin
                mag_real[i] = magnitude_detector(pre_bfly12_real_in[i]);
                mag_imag[i] = magnitude_detector(pre_bfly12_imag_in[i]);
            end

            // 그룹별로 분리 (0~7, 8~15)
            for (int i = 0; i < 8; i++) begin
                mag_real_grp0[i] = mag_real[i];      // 0~7
                mag_real_grp1[i] = mag_real[i+8];    // 8~15
                mag_imag_grp0[i] = mag_imag[i];      // 0~7
                mag_imag_grp1[i] = mag_imag[i+8];    // 8~15
            end

            // 각 그룹별 최솟값 찾기
            min_real_grp0 = minimum_finder_8(mag_real_grp0);
            min_real_grp1 = minimum_finder_8(mag_real_grp1);
            min_imag_grp0 = minimum_finder_8(mag_imag_grp0);
            min_imag_grp1 = minimum_finder_8(mag_imag_grp1);

            // 각 블록별 최종 최솟값 (실수부와 허수부 중 작은 값)
            final_min_blk0 = (min_real_grp0 < min_imag_grp0) ? min_real_grp0 : min_imag_grp0;
            final_min_blk1 = (min_real_grp1 < min_imag_grp1) ? min_real_grp1 : min_imag_grp1;
            
            // 블록 단위 shift값으로 정규화하여 출력
            for (int i = 0; i < 8; i++) begin
                // 첫 번째 블록 (0~7) - final_min_blk0 적용
                bfly12_real_out[i] <= barrel_shifter_normalize(pre_bfly12_real_in[i], final_min_blk0);
                bfly12_imag_out[i] <= barrel_shifter_normalize(pre_bfly12_imag_in[i], final_min_blk0);
                
                // 두 번째 블록 (8~15) - final_min_blk1 적용
                bfly12_real_out[i + 8] <= barrel_shifter_normalize(pre_bfly12_real_in[i + 8], final_min_blk1);
                bfly12_imag_out[i + 8] <= barrel_shifter_normalize(pre_bfly12_imag_in[i + 8], final_min_blk1);
            end
            
            // valid_out 제어 (32클럭 제한)
            if (valid_counter < 32) begin
                valid_out <= 1;
            end else begin
                valid_out <= 0;
            end
        end else begin
            valid_out <= 0;
        end
    end



endmodule


module fft_cbfp_module0 (
    input logic clk,
    input logic rstn,
    input logic valid_in,
    input  logic signed [22:0] pre_bfly02_real_in [15:0],  // 16개의 23bit 실수부 입력
    input  logic signed [22:0] pre_bfly02_imag_in [15:0],  // 16개의 23bit 허수부 입력
    output logic [4:0] applied_shift_out [511:0],
    output logic valid_out,
    output logic signed [10:0] bfly02_real_out [15:0],     // 16개의 11bit 실수부 출력
    output logic signed [10:0] bfly02_imag_out [15:0]      // 16개의 11bit 허수부 출력
);

    // Parameters
    localparam int DATA_WIDTH = 23;
    localparam int OUTPUT_WIDTH = 11;
    localparam int SHIFT_WIDTH = 5;
    localparam int DATA_PER_CLK = 16;
    localparam int GROUP_SIZE = 64;
    localparam int NUM_16_GROUPS = 4;
    localparam int TARGET_SHIFT = 12;
    localparam int NUM_64_BLOCKS = 8;

    // =============== Block Storage 구조 (8개 블록) ===============
    logic signed[DATA_WIDTH-1:0] block_storage_real [NUM_64_BLOCKS-1:0][GROUP_SIZE-1:0];
    logic signed[DATA_WIDTH-1:0] block_storage_imag [NUM_64_BLOCKS-1:0][GROUP_SIZE-1:0];

    // 입력 제어 변수들
    logic [1:0] input_group_counter;  // 현재 입력받는 그룹 (0~3)
    logic [2:0] input_block_counter;  // 현재 입력받는 블록 (0~7)

    // =============== 파이프라인 버퍼 레지스터들 ===============
    // Stage 1: 입력 데이터 버퍼 (조합논리 처리 위한 1클럭 지연)
    logic signed[DATA_WIDTH-1:0] stage1_buffer_real[DATA_PER_CLK-1:0];
    logic signed [DATA_WIDTH-1:0] stage1_buffer_imag[DATA_PER_CLK-1:0];
    logic [1:0] stage1_group_counter;
    logic [2:0] stage1_block_counter;
    logic stage1_valid;

    // 각 블록별 16개 그룹의 min값 저장
    logic signed [SHIFT_WIDTH-1:0] block_group_min_real [NUM_64_BLOCKS-1:0][NUM_16_GROUPS-1:0];
    logic signed [SHIFT_WIDTH-1:0] block_group_min_imag [NUM_64_BLOCKS-1:0][NUM_16_GROUPS-1:0];
    logic [NUM_64_BLOCKS-1:0][NUM_16_GROUPS-1:0] group_min_valid;

    // 각 블록별 최종 shift값
    logic [SHIFT_WIDTH-1:0] block_shift_value[NUM_64_BLOCKS-1:0];
    logic [NUM_64_BLOCKS-1:0] block_shift_ready;//array vs bit -> compare

    // 출력 제어
    logic [2:0] output_block_counter;
    logic [1:0] output_group_counter;
    logic output_active;
    logic [5:0] pipeline_delay_counter;  // 파이프라인 지연 카운터
    logic [5:0] output_counter;  // 출력 카운터 (32클럭 카운트)

    function automatic logic [4:0] magnitude_detector;
        input logic signed [22:0] input_data;
        logic [22:0] d;
        logic [4:0] count;
        logic s;
        begin
            d = input_data;
            // sign bit
            s = d[22];

            // leading sign extension count
            count = (d[21] != s) ? 5'd0  :
                    (d[20] != s) ? 5'd1  :
                    (d[19] != s) ? 5'd2  :
                    (d[18] != s) ? 5'd3  :
                    (d[17] != s) ? 5'd4  :
                    (d[16] != s) ? 5'd5  :
                    (d[15] != s) ? 5'd6  :
                    (d[14] != s) ? 5'd7  :
                    (d[13] != s) ? 5'd8  :
                    (d[12] != s) ? 5'd9  :
                    (d[11] != s) ? 5'd10 :
                    (d[10] != s) ? 5'd11 :
                    (d[9]  != s) ? 5'd12 :
                    (d[8]  != s) ? 5'd13 :
                    (d[7]  != s) ? 5'd14 :
                    (d[6]  != s) ? 5'd15 :
                    (d[5]  != s) ? 5'd16 :
                    (d[4]  != s) ? 5'd17 :
                    (d[3]  != s) ? 5'd18 :
                    (d[2]  != s) ? 5'd19 :
                    (d[1]  != s) ? 5'd20 :
                    (d[0]  != s) ? 5'd21 :
                                   5'd22 ;  // all bits match sign
            magnitude_detector = count;
        end
    endfunction

    // =============== 16개 값 중 최솟값 찾기 (조합논리) ===============
    function automatic logic [SHIFT_WIDTH-1:0] minimum_finder_16;
        input [SHIFT_WIDTH-1:0] input_array[15:0];

        logic [SHIFT_WIDTH-1:0] level1 [7:0];
        logic [SHIFT_WIDTH-1:0] level2 [3:0];
        logic [SHIFT_WIDTH-1:0] level3 [1:0];
        logic [SHIFT_WIDTH-1:0] result;

        begin
            for (int i = 0; i < 8; i++) begin
                level1[i] = (input_array[i*2] < input_array[i*2+1]) ? input_array[i*2] : input_array[i*2+1];
            end

            for (int i = 0; i < 4; i++) begin
                level2[i] = (level1[i*2] < level1[i*2+1]) ? level1[i*2] : level1[i*2+1];
            end

            for (int i = 0; i < 2; i++) begin
                level3[i] = (level2[i*2] < level2[i*2+1]) ? level2[i*2] : level2[i*2+1];
            end

            result = (level3[0] < level3[1]) ? level3[0] : level3[1];
            minimum_finder_16 = result;
        end
    endfunction

    // =============== 4개 값 중 최솟값 찾기 (조합논리) ===============
    function automatic logic [SHIFT_WIDTH-1:0] minimum_finder_4;
        input [SHIFT_WIDTH-1:0] input_array[3:0];

        logic [SHIFT_WIDTH-1:0] level1 [1:0];
        logic [SHIFT_WIDTH-1:0] result;

        begin
            level1[0] = (input_array[0] < input_array[1]) ? input_array[0] : input_array[1];
            level1[1] = (input_array[2] < input_array[3]) ? input_array[2] : input_array[3];
            result = (level1[0] < level1[1]) ? level1[0] : level1[1];
            minimum_finder_4 = result;
        end
    endfunction

    // =============== Barrel Shifter (조합논리) ===============
    function automatic logic [OUTPUT_WIDTH-1:0] barrel_shifter_normalize;
        input [DATA_WIDTH-1:0] input_data;
        input [SHIFT_WIDTH-1:0] shift_amount;

        logic signed [63:0] temp_result;
        begin
            temp_result = input_data;

            if (shift_amount > TARGET_SHIFT) begin
                // 유효비트수가 작음 -> 왼쪽 시프트 후 오른쪽 시프트
                temp_result = temp_result <<< (shift_amount - TARGET_SHIFT);
            end else begin
                // 오른쪽 시프트로 11비트 스케일링
                temp_result = temp_result >>> (TARGET_SHIFT - shift_amount);
            end

            barrel_shifter_normalize = temp_result[OUTPUT_WIDTH-1:0];
        end
    endfunction

    // =============== 입력 및 Block Storage (매 클럭) ===============
    int i, j, b, k, l, m, n, d, c,i1;
    int storage_index;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_group_counter <= 0;
            input_block_counter <= 0;
        end else if (valid_in) begin
            // Block Storage에 512개 총 저장(16클럭동안)
            for (i = 0; i < DATA_PER_CLK; i++) begin
                storage_index = input_group_counter * DATA_PER_CLK + i;
                block_storage_real[input_block_counter][storage_index] <= pre_bfly02_real_in[i];
                block_storage_imag[input_block_counter][storage_index] <= pre_bfly02_imag_in[i];
            end

       

            // 카운터 업데이트
            if (input_group_counter == 3) begin
                input_group_counter <= 0;
                if (input_block_counter == 7) begin
                    input_block_counter <= 0;
                end else begin
                    input_block_counter <= input_block_counter + 1;
                end
            end else begin
                input_group_counter <= input_group_counter + 1;
            end
        end
    end

    // =============== Stage 1: 파이프라인 버퍼 ===============
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage1_valid <= 0;
            stage1_group_counter <= 0;
            stage1_block_counter <= 0;
        end else begin
            stage1_valid <= valid_in;
            stage1_group_counter <= input_group_counter;
            stage1_block_counter <= input_block_counter;

            if (valid_in) begin  //16개만 따로 저장
                for (j = 0; j < DATA_PER_CLK; j++) begin
                    stage1_buffer_real[j] <= pre_bfly02_real_in[j];
                    stage1_buffer_imag[j] <= pre_bfly02_imag_in[j];
                end
      
            end
        end
    end

    // =============== Magnitude Detection & Min Finding (조합논리 + 레지스터) ===============
    // 조합논리 처리
    logic [SHIFT_WIDTH-1:0] current_mag_real[DATA_PER_CLK-1:0];
    logic [SHIFT_WIDTH-1:0] current_mag_imag[DATA_PER_CLK-1:0];
    logic [SHIFT_WIDTH-1:0] current_min_real, current_min_imag;

    // Magnitude Detection (조합논리)
    always_comb begin
        for (k = 0; k < DATA_PER_CLK; k++) begin
            current_mag_real[k] = magnitude_detector(stage1_buffer_real[k]);
            current_mag_imag[k] = magnitude_detector(stage1_buffer_imag[k]);
        end
    end

    // Min Finding (조합논리)
    always_comb begin  //타이밍 의심할 것
        current_min_real = minimum_finder_16(current_mag_real);
        current_min_imag = minimum_finder_16(current_mag_imag);
    end

    // 결과 저장 (레지스터)
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            
            //block_group_min_real <= '{default:5'd23};
            //block_group_min_imag <= '{default:5'd23};
            //group_min_valid <= '{default:0}'
            
            for (b = 0; b < NUM_64_BLOCKS; b++) begin
                for (int g = 0; g < NUM_16_GROUPS; g++) begin
                    block_group_min_real[b][g] <= 5'd23;
                    block_group_min_imag[b][g] <= 5'd23;
                    group_min_valid[b][g] <= 0;
                end
            end
        end else if (stage1_valid) begin
            // 해당 블록의 해당 그룹에 min값 저장
            block_group_min_real[stage1_block_counter][stage1_group_counter] <= current_min_real;
            block_group_min_imag[stage1_block_counter][stage1_group_counter] <= current_min_imag;
            group_min_valid[stage1_block_counter][stage1_group_counter] <= 1;
        end
    end

    // =============== 블록별 최종 Min값 결정 ===============
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            /*
            block_shift_value <= '{default: 5'd23};
            block_shift_ready <= '{default: 0};
            */
            for (l = 0; l < NUM_64_BLOCKS; l++) begin
                block_shift_value[l] <= 5'd23;
                block_shift_ready[l] <= 0;
            end
        end else begin
            // 각 블록에 대해 4개 그룹이 모두 완료되었는지 확인
            for (m = 0; m < NUM_64_BLOCKS; m++) begin
                if (!block_shift_ready[m] && 
                    group_min_valid[m][0] && group_min_valid[m][1] && 
                    group_min_valid[m][2] && group_min_valid[m][3]) begin

                    // 4개 그룹의 min값들 중 최솟값 찾기 (조합논리)
                    logic [SHIFT_WIDTH-1:0] temp_real_array[3:0];
                    logic [SHIFT_WIDTH-1:0] temp_imag_array[3:0];
                    logic [SHIFT_WIDTH-1:0]
                        final_min_real, final_min_imag, final_min;

                    temp_real_array[0] = block_group_min_real[m][0];
                    temp_real_array[1] = block_group_min_real[m][1];
                    temp_real_array[2] = block_group_min_real[m][2];
                    temp_real_array[3] = block_group_min_real[m][3];

                    temp_imag_array[0] = block_group_min_imag[m][0];
                    temp_imag_array[1] = block_group_min_imag[m][1];
                    temp_imag_array[2] = block_group_min_imag[m][2];
                    temp_imag_array[3] = block_group_min_imag[m][3];

                    final_min_real = minimum_finder_4(temp_real_array);
                    final_min_imag = minimum_finder_4(temp_imag_array);

                    // 실수부와 허수부 중 더 작은 값으로 통일
                    final_min = (final_min_real <= final_min_imag) ? final_min_real : final_min_imag;

                    block_shift_value[m] <= final_min;
                    block_shift_ready[m] <= 1;

        
                end
            end
        end
    end
    logic block_ready;
    assign block_ready = block_shift_ready[output_block_counter];

    // =============== Applied Shift Amount mapping 로직 ===============
    // 각 블록별 shift amount(8개)를 512개 데이터 포인트(8*64)에 매핑

    int block_idx_shift, data_idx_shift, global_index_shift, init_idx_shift;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 초기화
            for (init_idx_shift = 0; init_idx_shift < 512; init_idx_shift++) begin
                applied_shift_out[init_idx_shift] <= 5'd23;  // 초기값: 최대 shift
            end
        end else begin
            // 블록 shift ready =1 -> 해당 블록의 64개 데이터에 매핑
            for (block_idx_shift = 0; block_idx_shift < NUM_64_BLOCKS; block_idx_shift++) begin
                if (block_shift_ready[block_idx_shift]) begin
                    // 각 블록의 64개 데이터 포인트에 동일한 shift amount 적용
                    for (data_idx_shift = 0; data_idx_shift < GROUP_SIZE; data_idx_shift++) begin
                        global_index_shift = block_idx_shift * GROUP_SIZE + data_idx_shift;
                        applied_shift_out[global_index_shift] <= block_shift_value[block_idx_shift];
                    end
                end
            end
        end
    end
    
    // =============== 출력 제어 (연속 출력) ===============
    int output_storage_index;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            output_block_counter <= 0;
            output_group_counter <= 0;
            output_active <= 0;
            valid_out <= 0;
            output_counter <= 0;
            pipeline_delay_counter <= 0;
            // 출력 초기화
            for (n = 0; n < DATA_PER_CLK; n++) begin
                bfly02_real_out[n] <= 11'b0;
                bfly02_imag_out[n] <= 11'b0;
            end
        end else begin
            // 파이프라인 지연 후 출력 시작 (새로운 입력이 들어오면 다시 시작)
            if (valid_in && pipeline_delay_counter < 6) begin
                pipeline_delay_counter <= pipeline_delay_counter + 1;
            end else if (pipeline_delay_counter == 6 && !output_active) begin
                output_active <= 1;
                pipeline_delay_counter <= 0;
                output_counter <= 0;  // 새로운 입력 시작 시 카운터 리셋
            end 
        

            // 연속 출력 (all enable 상태)
            if (output_active && block_shift_ready[output_block_counter] && output_counter < 33) begin
                valid_out <= 1;
                output_counter <= output_counter + 1;  // 출력 카운터 증가

                // Barrel Shifter로 정규화하여 출력
                for (c = 0; c < DATA_PER_CLK; c++) begin
                    output_storage_index = output_group_counter * DATA_PER_CLK + c;

                    bfly02_real_out[c] <= barrel_shifter_normalize(
                        block_storage_real[output_block_counter][output_storage_index],
                        block_shift_value[output_block_counter]
                    );
                    bfly02_imag_out[c] <= barrel_shifter_normalize(
                        block_storage_imag[output_block_counter][output_storage_index],
                        block_shift_value[output_block_counter]
                    );
                end

                // 다음 그룹으로 진행
                if (output_group_counter == 3) begin
                    output_group_counter <= 0;
                                    if (output_block_counter == 7) begin
                    output_block_counter <= 0;
                    // output_active <= 0;  // 전체 완료 후에도 비활성화하지 않음 - 다음 입력 대기
                        // valid_out은 output_counter로 제어하므로 여기서는 설정하지 않음       
                        // 연속 처리를 위해 output_active는 유지
                    end else begin
                        output_block_counter <= output_block_counter + 1;
                    end
                end else begin
                    output_group_counter <= output_group_counter + 1;
                end
            end else begin
                // 33클럭 후 무조건 valid_out을 0으로 설정
                if (output_counter >= 33) begin
                    valid_out <= 0;
                    output_active <= 0;  // 33클럭 후 output_active 비활성화
                    // output_counter <= 0;  // 카운터 리셋 제거 - 다음 입력 대기
                end else begin
                    valid_out <= 0;  // shift값이 준비되지 않았으면 대기
                end
                // 출력 데이터는 이전 값 유지  
                for (d = 0; d < DATA_PER_CLK; d++) begin
                    bfly02_real_out[d] <= bfly02_real_out[d];  // 이전 값 유지
                    bfly02_imag_out[d] <= bfly02_imag_out[d];  // 이전 값 유지
                end
            end
        end
    end
  
endmodule

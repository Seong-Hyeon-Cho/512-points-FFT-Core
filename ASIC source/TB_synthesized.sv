`timescale 1ns / 10ps

// 144비트 → 9비트 × 16개 배열 매크로 (입력용) - 비트 순서 뒤집기
`define GET_DIN_I(idx) din_i[((15-(idx))+1)*9-1:(15-(idx))*9]
`define GET_DIN_Q(idx) din_q[((15-(idx))+1)*9-1:(15-(idx))*9]

// 208비트 → 13비트 × 16개 배열 매크로 (출력용) - 비트 순서 뒤집기
`define GET_DOUT_I(idx) dout_i[((15-(idx))+1)*13-1:(15-(idx))*13]
`define GET_DOUT_Q(idx) dout_q[((15-(idx))+1)*13-1:(15-(idx))*13]

// 설정용 매크로
`define SET_DIN_I(idx, val) din_i[((15-(idx))+1)*9-1:(15-(idx))*9] = val
`define SET_DIN_Q(idx, val) din_q[((15-(idx))+1)*9-1:(15-(idx))*9] = val

module tb_fft_synthesized;

    // 파라미터
    parameter N = 512;
    parameter BLK_SIZE = 16;
    parameter CLK_PERIOD = 10;

    // DUT 포트 (합성된 모듈의 벡터 포트에 맞춤)
    reg clk, rstn;
    reg i_valid;
    reg [143:0] din_i;  // 144비트 (9비트 × 16개)
    reg [143:0] din_q;  // 144비트 (9비트 × 16개)  
    wire [207:0] dout_i;
    wire [207:0] dout_q;
    wire o_valid;


    // 파일 핸들
    integer fp_real, fp_imag, fp_out_real, fp_out_imag, i, j;
    integer output_count;
    reg signed [15:0] in_real [0:N-1];
    reg signed [15:0] in_imag [0:N-1];
    
    // Verdi에서 파형 보기용 배열 (매크로로 접근)
    wire signed [8:0] din_i_array [15:0];   // 9비트 × 16개
    wire signed [12:0] dout_i_array [15:0]; // 13비트 × 16개
    wire signed [8:0] din_q_array [15:0];   // 9비트 × 16개
    wire signed [12:0] dout_q_array [15:0]; // 13비트 × 16개
    
    // 배열 연결
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : array_conn
            assign din_i_array[k] = `GET_DIN_I(k);
            assign din_q_array[k] = `GET_DIN_Q(k);
            assign dout_i_array[k] = `GET_DOUT_I(k);
            assign dout_q_array[k] = `GET_DOUT_Q(k);
        end
    endgenerate
     
    top dut (
        .clk(clk),
        .rstn(rstn),
        .i_valid(i_valid),
        .din_i(din_i),
        .din_q(din_q),
        .dout_i(dout_i),
        .dout_q(dout_q),
        .o_valid(o_valid)
    );

    // 클럭 생성
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // 입력 벡터 읽기
    initial begin
        // 실수부 파일 읽기
        fp_real = $fopen("cos_fixed_real.txt", "r");
        if (fp_real == 0) begin
            $display("실수부 파일 열기 실패!");
            $finish;
        end
        for (i = 0; i < N; i = i + 1) begin
            $fscanf(fp_real, "%d\n", in_real[i]);
        end
        $fclose(fp_real);
        
        // 허수부 파일 읽기
        fp_imag = $fopen("cos_fixed_imag.txt", "r");
        if (fp_imag == 0) begin
            $display("허수부 파일 열기 실패!");
            $finish;
        end
        for (i = 0; i < N; i = i + 1) begin
            $fscanf(fp_imag, "%d\n", in_imag[i]);
        end
        $fclose(fp_imag);
    end

    // 시뮬레이션
    initial begin
        // 출력 파일 열기
        fp_out_real = $fopen("fft_synthesized_output_real.txt", "w");
        fp_out_imag = $fopen("fft_synthesized_output_imag.txt", "w");
        if (fp_out_real == 0 || fp_out_imag == 0) begin
            $display("출력 파일 열기 실패!");
            $finish;
        end
        
        // 모든 입력 신호 초기화
        rstn = 0;
        i_valid = 0;
        din_i = 0;
        din_q = 0;
        # (CLK_PERIOD*5);
        rstn = 1;
        # (CLK_PERIOD*2);

        // 입력 적용 - 배열 인덱스 순서대로 저장 (0→15)
        i_valid = 1;
        for (i = 0; i < N/BLK_SIZE; i = i + 1) begin
            // 16개 데이터를 144비트 벡터로 할당 (인덱스 순서대로)
            din_i = {in_real[i*BLK_SIZE + 0][8:0], in_real[i*BLK_SIZE + 1][8:0],
                     in_real[i*BLK_SIZE + 2][8:0], in_real[i*BLK_SIZE + 3][8:0],
                     in_real[i*BLK_SIZE + 4][8:0], in_real[i*BLK_SIZE + 5][8:0],
                     in_real[i*BLK_SIZE + 6][8:0], in_real[i*BLK_SIZE + 7][8:0],
                     in_real[i*BLK_SIZE + 8][8:0], in_real[i*BLK_SIZE + 9][8:0],
                     in_real[i*BLK_SIZE + 10][8:0], in_real[i*BLK_SIZE + 11][8:0],
                     in_real[i*BLK_SIZE + 12][8:0], in_real[i*BLK_SIZE + 13][8:0],
                     in_real[i*BLK_SIZE + 14][8:0], in_real[i*BLK_SIZE + 15][8:0]};
            din_q = {in_imag[i*BLK_SIZE + 0][8:0], in_imag[i*BLK_SIZE + 1][8:0],
                     in_imag[i*BLK_SIZE + 2][8:0], in_imag[i*BLK_SIZE + 3][8:0],
                     in_imag[i*BLK_SIZE + 4][8:0], in_imag[i*BLK_SIZE + 5][8:0],
                     in_imag[i*BLK_SIZE + 6][8:0], in_imag[i*BLK_SIZE + 7][8:0],
                     in_imag[i*BLK_SIZE + 8][8:0], in_imag[i*BLK_SIZE + 9][8:0],
                     in_imag[i*BLK_SIZE + 10][8:0], in_imag[i*BLK_SIZE + 11][8:0],
                     in_imag[i*BLK_SIZE + 12][8:0], in_imag[i*BLK_SIZE + 13][8:0],
                     in_imag[i*BLK_SIZE + 14][8:0], in_imag[i*BLK_SIZE + 15][8:0]};
            @(posedge clk);
        end
        // OUTSUM 구간 동안도 i_valid=1 유지
        for (i = 0; i < N/BLK_SIZE; i = i + 1) begin
            @(posedge clk);
        end
        i_valid = 0;

        // o_valid 대기 후 512개 출력 완료까지 대기
        wait(o_valid == 1);
        
        // 정확히 512개 데이터만 카운트하여 출력
        output_count = 0;
        while (output_count < N) begin
            if (o_valid) begin
                // case 문을 사용하여 16개씩 출력 데이터 읽기
                for (j = 0; j < BLK_SIZE; j = j + 1) begin
                    // case 문으로 각 인덱스별 비트 슬라이싱
                    case (j)
                        0: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[12:0]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[12:0]));
                            if (j < 4) begin
                                $display("dout_i[%d] = %d (0x%h)", j, $signed(dout_i[12:0]), dout_i[12:0]);
                                $display("dout_q[%d] = %d (0x%h)", j, $signed(dout_q[12:0]), dout_q[12:0]);
                            end
                        end
                        1: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[25:13]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[25:13]));
                            if (j < 4) begin
                                $display("dout_i[%d] = %d (0x%h)", j, $signed(dout_i[25:13]), dout_i[25:13]);
                                $display("dout_q[%d] = %d (0x%h)", j, $signed(dout_q[25:13]), dout_q[25:13]);
                            end
                        end
                        2: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[38:26]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[38:26]));
                            if (j < 4) begin
                                $display("dout_i[%d] = %d (0x%h)", j, $signed(dout_i[38:26]), dout_i[38:26]);
                                $display("dout_q[%d] = %d (0x%h)", j, $signed(dout_q[38:26]), dout_q[38:26]);
                            end
                        end
                        3: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[51:39]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[51:39]));
                            if (j < 4) begin
                                $display("dout_i[%d] = %d (0x%h)", j, $signed(dout_i[51:39]), dout_i[51:39]);
                                $display("dout_q[%d] = %d (0x%h)", j, $signed(dout_q[51:39]), dout_q[51:39]);
                            end
                        end
                        4: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[64:52]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[64:52]));
                        end
                        5: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[77:65]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[77:65]));
                        end
                        6: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[90:78]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[90:78]));
                        end
                        7: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[103:91]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[103:91]));
                        end
                        8: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[116:104]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[116:104]));
                        end
                        9: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[129:117]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[129:117]));
                        end
                        10: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[142:130]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[142:130]));
                        end
                        11: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[155:143]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[155:143]));
                        end
                        12: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[168:156]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[168:156]));
                        end
                        13: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[181:169]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[181:169]));
                        end
                        14: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[194:182]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[194:182]));
                        end
                        15: begin
                            $fdisplay(fp_out_real, "%d", $signed(dout_i[207:195]));
                            $fdisplay(fp_out_imag, "%d", $signed(dout_q[207:195]));
                        end
                    endcase
                end
                
                $display("Output block %0d: dout_i[0]=%d, dout_q[0]=%d", 
                        output_count/BLK_SIZE, $signed(dout_i[12:0]), $signed(dout_q[12:0]));
                output_count = output_count + BLK_SIZE;
            end
            @(posedge clk);
        end
        
        // 파일 닫기
        $fclose(fp_out_real);
        $fclose(fp_out_imag);
        
        $display("합성된 FFT 모듈 테스트 완료! 파일에 저장됨.");
        
        // 클럭을 몇 번 더 동작시켜서 마지막 하강 엣지까지 완료
        repeat(5) @(posedge clk);
        
        $stop;
    end

endmodule

`timescale 1ns / 10ps

module tb_fft;

    // 파라미터
    parameter N = 512;
    parameter BLK_SIZE = 16;
    parameter CLK_PERIOD = 10;

    // DUT 포트
    reg clk, rstn;
    reg i_valid;
    reg signed [8:0] din_i [0:BLK_SIZE-1];
    reg signed [8:0] din_q [0:BLK_SIZE-1];
    wire signed [12:0] dout_i [0:15];
    wire signed [12:0] dout_q [0:15];
    wire o_valid;

    // 파일 핸들
    integer fp_real, fp_imag, fp_out_real, fp_out_imag, i, j;
    integer num_in, num_out;
    integer output_count;  // 출력 카운터 변수 선언
    reg signed [15:0] in_real [0:N-1];
    reg signed [15:0] in_imag [0:N-1];
    reg signed [10:0] out_real [0:N-1];
    reg signed [10:0] out_imag [0:N-1];
    
    // 비트 리버스 순서로 재배열된 데이터

    // DUT 인스턴스 (포트명/비트수 맞게 수정)
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

    // 입력 벡터 읽기 - 실수부와 허수부를 별도 파일에서 읽기
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
        fp_out_real = $fopen("fft_output_real.txt", "w");
        fp_out_imag = $fopen("fft_output_imag.txt", "w");
        if (fp_out_real == 0 || fp_out_imag == 0) begin
            $display("출력 파일 열기 실패!");
            $finish;
        end
        
        rstn = 0;
        i_valid = 0;
        # (CLK_PERIOD*5);
        rstn = 1;
        # (CLK_PERIOD*2);

        // 입력 적용 (34클럭 동안만 i_valid=1 유지)
        num_in = 0;
        num_out = 0;
        i_valid = 1;
        for (i = 0; i < 34; i = i + 1) begin  // 정확히 34클럭만
            if (i < N/BLK_SIZE) begin  // 데이터가 있는 동안만 데이터 적용
                for (j = 0; j < BLK_SIZE; j = j + 1) begin
                    //din_i[j] = in_real[i*BLK_SIZE + (BLK_SIZE-1-j)][8:0];
                    //din_q[j] = in_imag[i*BLK_SIZE + (BLK_SIZE-1-j)][8:0];
                    din_i[j] = in_real[i*BLK_SIZE + j][8:0];
                    din_q[j] = in_imag[i*BLK_SIZE + j][8:0];
                end
            end else begin  // 데이터가 없는 동안은 0으로 설정
                for (j = 0; j < BLK_SIZE; j = j + 1) begin
                    din_i[j] = 0;
                    din_q[j] = 0;
                end
            end
            @(posedge clk);
        end
        i_valid = 0;

        // o_valid 대기 후 512개 출력 완료까지 대기
        wait(o_valid == 1);  // 첫 번째 출력 대기
        
        // 정확히 512개 데이터만 카운트하여 출력
        output_count = 0;
        while (output_count < N) begin  // 512개까지만
            if (o_valid) begin
                // 16개 데이터를 파일에 저장 (0~15 순서대로)
                for (j = 0; j < BLK_SIZE; j = j + 1) begin
                    $fdisplay(fp_out_real, "%d", dout_i[j]);
                    $fdisplay(fp_out_imag, "%d", dout_q[j]);
                end
                $display("Output %0d: dout_i[0]=%d, dout_q[0]=%d", output_count, dout_i[0], dout_q[0]);
                output_count = output_count + BLK_SIZE;  // 16개씩 증가
            end
            @(posedge clk);
        end
        
        // 파일 닫기
        $fclose(fp_out_real);
        $fclose(fp_out_imag);
        
        $display("모든 512개 데이터 출력 완료! 파일에 저장됨.");
        
        // 클럭을 몇 번 더 동작시켜서 마지막 하강 엣지까지 완료
        repeat(5) @(posedge clk);
        
        // $finish;  // 시뮬레이션 종료 - 클럭 멈춤
        $stop;      // 시뮬레이션 일시정지 - 클럭 계속 동작
    end

endmodule

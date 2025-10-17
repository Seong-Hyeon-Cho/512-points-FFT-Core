`timescale 1ns/1ps

//
// 파라미터화된 FFT 스테이지 버퍼 모듈
module stage_buffer #(
    parameter IN_WIDTH = 9,
    parameter OUT_WIDTH = 10,
    parameter NUM_ELEMS = 256, // 버퍼 깊이 (ex: 256, 128, 64 ...)
    parameter BLK_SIZE = 16,   // 한 번에 처리하는 데이터 개수
    parameter PIPELINE_DEPTH = 0, // 파이프라인 딜레이 클럭 수
    parameter VALID_DELAY = 0  // o_valid 추가 지연 클럭 수 (0: 기본, 1: 한 클럭 지연)
) (
    input clk,
    input rstn,
    input logic signed [IN_WIDTH-1:0] din_i[0:BLK_SIZE-1],
    input logic signed [IN_WIDTH-1:0] din_q[0:BLK_SIZE-1],
    input i_valid,
    output logic signed [OUT_WIDTH-1:0] dout_i[BLK_SIZE-1:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[BLK_SIZE-1:0],
    output logic o_valid
);
    typedef enum logic [1:0] {INMODE = 0, OUTSUM = 1, OUTMINUS = 2} state_t;
    state_t state;

    // FIFO RAM for input buffer
    logic signed [IN_WIDTH-1:0] ram_i [0:NUM_ELEMS-1];
    logic signed [IN_WIDTH-1:0] ram_q [0:NUM_ELEMS-1];
    // Buffer for subtraction results
    logic signed [OUT_WIDTH-1:0] sub_buf_i [0:NUM_ELEMS-1];
    logic signed [OUT_WIDTH-1:0] sub_buf_q [0:NUM_ELEMS-1];

    logic signed [OUT_WIDTH-1:0] sreg_i2 [BLK_SIZE-1:0];
    logic signed [OUT_WIDTH-1:0] sreg_q2 [BLK_SIZE-1:0];

    integer i, d;
    reg [$clog2(NUM_ELEMS):0] wr_ptr; // write pointer
    reg [$clog2(NUM_ELEMS):0] rd_ptr; // read pointer
    reg [$clog2(NUM_ELEMS/BLK_SIZE):0] blk_cnt; // 블록 카운터
    reg valid;
    reg [9:0] total_input; // 누적 입력 개수 (최대 512)
    reg last_outminus; // 마지막 OUTMINUS 플래그
    reg [5:0] valid_timer; // 32클럭 타이머 (0~63)
    reg valid_start; // valid 시작 플래그
    // reg outsum_first; // 제거

    // 파이프라인 딜레이 레지스터
    logic signed [OUT_WIDTH-1:0] dout_i_pipe [0:PIPELINE_DEPTH][BLK_SIZE-1:0];
    logic signed [OUT_WIDTH-1:0] dout_q_pipe [0:PIPELINE_DEPTH][BLK_SIZE-1:0];
    logic o_valid_pipe [0:PIPELINE_DEPTH];
    
    // o_valid 추가 지연을 위한 레지스터 (VALID_DELAY > 0일 때만 사용)
    logic o_valid_delay;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= INMODE;
            valid <= 0;
            wr_ptr <= 0;
            rd_ptr <= 0;
            blk_cnt <= 0;
            total_input <= 0;
            last_outminus <= 0;
            valid_timer <= 0;
            valid_start <= 0;
            // outsum_first <= 0; // 제거
            for (i = 0; i < BLK_SIZE; i++) begin
                sreg_i2[i] <= 0;
                sreg_q2[i] <= 0;
            end
            for (d = 0; d <= PIPELINE_DEPTH; d++) begin
                for (i = 0; i < BLK_SIZE; i++) begin
                    dout_i_pipe[d][i] <= 0;
                    dout_q_pipe[d][i] <= 0;
                end
                o_valid_pipe[d] <= 0;
            end
            if (VALID_DELAY > 0) begin
                o_valid_delay <= 0;
            end
        end else begin
            case (state)
                INMODE: begin
                    if (i_valid && total_input < 512) begin
                        for (i = 0; i < BLK_SIZE; i++) begin
                            ram_i[(wr_ptr + i) % NUM_ELEMS] <= din_i[i];
                            ram_q[(wr_ptr + i) % NUM_ELEMS] <= din_q[i];
                        end
                        wr_ptr <= wr_ptr + BLK_SIZE;
                        blk_cnt <= blk_cnt + 1;
                        total_input <= total_input + BLK_SIZE;
                        if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                            wr_ptr <= 0;
                            rd_ptr <= 0;
                            blk_cnt <= 0;
                            state <= OUTSUM;
                            valid <= 1; // OUTSUM 진입 시 valid=1로 복구
                            valid_start <= 1; // valid 시작 플래그 설정
                            valid_timer <= 0; // 타이머 리셋
                            // outsum_first <= 1; // 제거
                        end
                    end
                end
                OUTSUM: begin
                    if (i_valid && total_input < 512) begin
                        for (i = 0; i < BLK_SIZE; i++) begin
                            sreg_i2[i] <= ram_i[(rd_ptr + i) % NUM_ELEMS] + din_i[i];
                            sreg_q2[i] <= ram_q[(rd_ptr + i) % NUM_ELEMS] + din_q[i];
                            sub_buf_i[(rd_ptr + i) % NUM_ELEMS] <= ram_i[(rd_ptr + i) % NUM_ELEMS] - din_i[i];
                            sub_buf_q[(rd_ptr + i) % NUM_ELEMS] <= ram_q[(rd_ptr + i) % NUM_ELEMS] - din_q[i];
                        end
                        total_input <= total_input + BLK_SIZE;
                    end
                    // outsum_first 관련 코드 제거
                    if (i_valid) begin
                        if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                            rd_ptr <= 0;
                            blk_cnt <= 0;
                            if (total_input == 512) begin
                                last_outminus <= 1;
                            end
                            state <= OUTMINUS;
                        end else begin
                            rd_ptr <= rd_ptr + BLK_SIZE;
                            blk_cnt <= blk_cnt + 1;
                        end
                    end
                end
                OUTMINUS: begin
                    if (!last_outminus) begin
                        if (i_valid && total_input < 512) begin
                            for (i = 0; i < BLK_SIZE; i++) begin
                                ram_i[(wr_ptr + i) % NUM_ELEMS] <= din_i[i];
                                ram_q[(wr_ptr + i) % NUM_ELEMS] <= din_q[i];
                            end
                            wr_ptr <= wr_ptr + BLK_SIZE;
                            total_input <= total_input + BLK_SIZE;
                        end
                    end
                    for (i = 0; i < BLK_SIZE; i++) begin
                        sreg_i2[i] <= sub_buf_i[(rd_ptr + i) % NUM_ELEMS];
                        sreg_q2[i] <= sub_buf_q[(rd_ptr + i) % NUM_ELEMS];
                    end
                    if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                        rd_ptr <= 0;
                        blk_cnt <= 0;
                        wr_ptr <= 0;
                        if (last_outminus) begin
                            state <= INMODE;
                            valid <= 0;
                            last_outminus <= 0;
                            total_input <= 0;
                            valid_start <= 0; // 타이머 정지
                            valid_timer <= 0; // 타이머 리셋
                        end else begin
                            state <= OUTSUM;
                        end
                    end else begin
                        rd_ptr <= rd_ptr + BLK_SIZE;
                        blk_cnt <= blk_cnt + 1;
                        if (!last_outminus) wr_ptr <= wr_ptr + BLK_SIZE;
                    end
                end
            endcase
            // 32클럭 타이머 로직
            if (valid_start) begin
                if (valid_timer < 32) begin
                    valid_timer <= valid_timer + 1;
                end else begin
                    valid <= 0; // 32클럭 후 valid 자동 해제
                    valid_start <= 0; // 타이머 정지
                end
            end
            
            // 파이프라인 딜레이 적용
            dout_i_pipe[0] <= sreg_i2;
            dout_q_pipe[0] <= sreg_q2;
            o_valid_pipe[0] <= valid;
            for (d = 1; d <= PIPELINE_DEPTH; d++) begin
                dout_i_pipe[d] <= dout_i_pipe[d-1];
                dout_q_pipe[d] <= dout_q_pipe[d-1];
                o_valid_pipe[d] <= o_valid_pipe[d-1];
            end
            
            // o_valid 추가 지연 (VALID_DELAY > 0일 때만)
            if (VALID_DELAY > 0) begin
                o_valid_delay <= o_valid_pipe[PIPELINE_DEPTH];
            end
        end
    end

    assign dout_i = dout_i_pipe[PIPELINE_DEPTH];
    assign dout_q = dout_q_pipe[PIPELINE_DEPTH];
    assign o_valid = (VALID_DELAY > 0) ? o_valid_delay : o_valid_pipe[PIPELINE_DEPTH];
endmodule



// 16개 입력을 즉시 8개씩 나누어 덧셈/뺄셈하는 모듈
module stage_buffer_und16 #(
    parameter IN_WIDTH = 9,
    parameter OUT_WIDTH = 10,
    parameter BLK_SIZE = 16   // 한 번에 처리하는 데이터 개수
) (
    input clk,
    input rstn,
    input logic signed [IN_WIDTH-1:0] din_i[BLK_SIZE-1:0],
    input logic signed [IN_WIDTH-1:0] din_q[BLK_SIZE-1:0],
    input i_valid,
    output logic signed [OUT_WIDTH-1:0] dout_i[BLK_SIZE-1:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[BLK_SIZE-1:0],
    output logic o_valid
);
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < BLK_SIZE; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 앞 8개: 덧셈 결과 (0~7)
                for (i = 0; i < 8; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+8];
                    dout_q[i] <= din_q[i] + din_q[i+8];
                end
                // 뒤 8개: 뺄셈 결과 (8~15)
                for (i = 8; i < BLK_SIZE; i++) begin
                    dout_i[i] <= din_i[i-8] - din_i[i];
                    dout_q[i] <= din_q[i-8] - din_q[i];
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule



// 16개 입력을 즉시 4개씩 나누어 덧셈/뺄셈하는 모듈
module stage_buffer_und8 #(
    parameter IN_WIDTH = 9,
    parameter OUT_WIDTH = 10,
    parameter BLK_SIZE = 16   // 한 번에 처리하는 데이터 개수
) (
    input clk,
    input rstn,
    input logic signed [IN_WIDTH-1:0] din_i[BLK_SIZE-1:0],
    input logic signed [IN_WIDTH-1:0] din_q[BLK_SIZE-1:0],
    input i_valid,
    output logic signed [OUT_WIDTH-1:0] dout_i[BLK_SIZE-1:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[BLK_SIZE-1:0],
    output logic o_valid
);
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < BLK_SIZE; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // MATLAB 로직: 8개씩 처리, 4개씩 2그룹으로 나누어 덧셈/뺄셈
                // 1번째 4개: 덧셈 결과 (0~3)
                for (i = 0; i < 4; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+4];
                    dout_q[i] <= din_q[i] + din_q[i+4];
                end
                // 2번째 4개: 뺄셈 결과 (4~7)
                for (i = 4; i < 8; i++) begin
                    dout_i[i] <= din_i[i-4] - din_i[i];
                    dout_q[i] <= din_q[i-4] - din_q[i];
                end
                // 3번째 4개: 덧셈 결과 (8~11)
                for (i = 8; i < 12; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+4];
                    dout_q[i] <= din_q[i] + din_q[i+4];
                end
                // 4번째 4개: 뺄셈 결과 (12~15)
                for (i = 12; i < BLK_SIZE; i++) begin
                    dout_i[i] <= din_i[i-4] - din_i[i];
                    dout_q[i] <= din_q[i-4] - din_q[i];
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule



// 16개 입력을 즉시 2개씩 나누어 덧셈/뺄셈하는 모듈
module stage_buffer_und4 #(
    parameter IN_WIDTH = 9,
    parameter OUT_WIDTH = 10,
    parameter BLK_SIZE = 16   // 한 번에 처리하는 데이터 개수
) (
    input clk,
    input rstn,
    input logic signed [IN_WIDTH-1:0] din_i[BLK_SIZE-1:0],
    input logic signed [IN_WIDTH-1:0] din_q[BLK_SIZE-1:0],
    input i_valid,
    output logic signed [OUT_WIDTH-1:0] dout_i[BLK_SIZE-1:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[BLK_SIZE-1:0],
    output logic o_valid
);
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < BLK_SIZE; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 1번째 2개: 덧셈 결과 (0~1)
                for (i = 0; i < 2; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+2];
                    dout_q[i] <= din_q[i] + din_q[i+2];
                end
                // 2번째 2개: 뺄셈 결과 (2~3)
                for (i = 2; i < 4; i++) begin
                    dout_i[i] <= din_i[i-2] - din_i[i];
                    dout_q[i] <= din_q[i-2] - din_q[i];
                end
                // 3번째 2개: 덧셈 결과 (4~5)
                for (i = 4; i < 6; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+2];
                    dout_q[i] <= din_q[i] + din_q[i+2];
                end
                // 4번째 2개: 뺄셈 결과 (6~7)
                for (i = 6; i < 8; i++) begin
                    dout_i[i] <= din_i[i-2] - din_i[i];
                    dout_q[i] <= din_q[i-2] - din_q[i];
                end
                // 5번째 2개: 덧셈 결과 (8~9)
                for (i = 8; i < 10; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+2];
                    dout_q[i] <= din_q[i] + din_q[i+2];
                end
                // 6번째 2개: 뺄셈 결과 (10~11)
                for (i = 10; i < 12; i++) begin
                    dout_i[i] <= din_i[i-2] - din_i[i];
                    dout_q[i] <= din_q[i-2] - din_q[i];
                end
                // 7번째 2개: 덧셈 결과 (12~13)
                for (i = 12; i < 14; i++) begin
                    dout_i[i] <= din_i[i] + din_i[i+2];
                    dout_q[i] <= din_q[i] + din_q[i+2];
                end
                // 8번째 2개: 뺄셈 결과 (14~15)
                for (i = 14; i < BLK_SIZE; i++) begin
                    dout_i[i] <= din_i[i-2] - din_i[i];
                    dout_q[i] <= din_q[i-2] - din_q[i];
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule


module stage_buffer_und2 #(
    parameter IN_WIDTH = 15,
    parameter OUT_WIDTH = 16,
    parameter BLK_SIZE = 16
) (
    input clk,
    input rstn,
    input logic signed [IN_WIDTH-1:0] din_i[BLK_SIZE-1:0],
    input logic signed [IN_WIDTH-1:0] din_q[BLK_SIZE-1:0],
    input i_valid,
    output logic signed [OUT_WIDTH-1:0] dout_i[BLK_SIZE-1:0],
    output logic signed [OUT_WIDTH-1:0] dout_q[BLK_SIZE-1:0],
    output logic o_valid
);
    integer i;
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_valid <= 0;
            for (i = 0; i < BLK_SIZE; i++) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                // 8개 그룹으로 나누어 2개씩 버터플라이
                for (i = 0; i < BLK_SIZE; i = i + 2) begin
                    // 덧셈
                    dout_i[i] <= din_i[i] + din_i[i+1];
                    dout_q[i] <= din_q[i] + din_q[i+1];
                    // 뺄셈
                    dout_i[i+1] <= din_i[i] - din_i[i+1];
                    dout_q[i+1] <= din_q[i] - din_q[i+1];
                end
                o_valid <= 1;
            end else begin
                o_valid <= 0;
            end
        end
    end
endmodule
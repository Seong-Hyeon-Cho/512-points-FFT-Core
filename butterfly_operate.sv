`timescale 1ns / 1ps

module module1(
    input clk,
    input rstn,
    input logic i_valid,
    input logic signed [8:0] din_i[15:0],
    input logic signed [8:0] din_q[15:0],
    output logic signed [10:0] dout_i[15:0],
    output logic signed [10:0] dout_q[15:0],
    output logic o_valid
);
    // 중간 신호 선언
    logic signed [9:0]  buf0_out_i[15:0], buf0_out_q[15:0];
    logic               buf0_valid;
    logic signed [9:0]  tw1_out_i[15:0], tw1_out_q[15:0];
    logic               tw1_valid;
    logic signed [10:0] buf1_out_i[15:0], buf1_out_q[15:0];
    logic               buf1_valid;
    logic signed [10:0] tw2_out_i[15:0], tw2_out_q[15:0];
    logic               tw2_valid;
    logic signed [10:0] buf2_out_i[15:0], buf2_out_q[15:0];
    logic               buf2_valid;

    // 1단계 버퍼
    stage_buffer #(
        .IN_WIDTH(9), .OUT_WIDTH(10), .NUM_ELEMS(256), .BLK_SIZE(16), .PIPELINE_DEPTH(0)
    ) u_stage_0_0_1(
        .clk(clk),
        .rstn(rstn),
        .din_i(din_i),
        .din_q(din_q),
        .i_valid(i_valid),
        .dout_i(buf0_out_i),
        .dout_q(buf0_out_q),
        .o_valid(buf0_valid)
    );

    // 1단계 트위들 팩터
    stage_0_0_2 u_twidle1(
        .clk(clk),
        .rstn(rstn),
        .i_valid(buf0_valid),
        .din_i(buf0_out_i),
        .din_q(buf0_out_q),
        .dout_i(tw1_out_i),
        .dout_q(tw1_out_q),
        .o_valid(tw1_valid)
    );

    // // 2단계 버퍼
    // stage_buffer #(
    //     .IN_WIDTH(10), .OUT_WIDTH(11), .NUM_ELEMS(128), .BLK_SIZE(16), .PIPELINE_DEPTH(0)
    // ) u_stage_0_1_1(
    //     .clk(clk),
    //     .rstn(rstn),
    //     .din_i(tw1_out_i),
    //     .din_q(tw1_out_q),
    //     .i_valid(tw1_valid),
    //     .dout_i(buf1_out_i),
    //     .dout_q(buf1_out_q),
    //     .o_valid(buf1_valid)
    // );

    // // 2단계 트위들 팩터
    // stage_0_1_2 u_twidle2(
    //     .clk(clk),
    //     .rstn(rstn),
    //     .i_valid(buf1_valid),
    //     .din_i(buf1_out_i),
    //     .din_q(buf1_out_q),
    //     .dout_i(tw2_out_i),
    //     .dout_q(tw2_out_q),
    //     .o_valid(tw2_valid)
    // );

    // // 3단계 버퍼
    // stage_buffer #(
    //     .IN_WIDTH(11), .OUT_WIDTH(11), .NUM_ELEMS(64), .BLK_SIZE(16), .PIPELINE_DEPTH(0)
    // ) u_stage_0_2_1(
    //     .clk(clk),
    //     .rstn(rstn),
    //     .din_i(tw2_out_i),
    //     .din_q(tw2_out_q),
    //     .i_valid(tw2_valid),
    //     .dout_i(buf2_out_i),
    //     .dout_q(buf2_out_q),
    //     .o_valid(buf2_valid)
    // );

    

    // 최종 출력 연결
    assign dout_i = tw1_out_i;
    assign dout_q = tw1_out_q;
    assign o_valid = tw1_valid;

endmodule


module saturate_13bit( 
    input clk,
    input rstn,
    input i_valid,
    input logic signed[10:0] din_i[15:0],
    input logic signed[10:0] din_q[15:0]
);

endmodule



module stage_0_1_2(
    input clk,
    input rstn,
    input i_valid,
    input logic signed [10:0] din_i[15:0],
    input logic signed [10:0] din_q[15:0],
    output logic signed [10:0] dout_i[15:0],
    output logic signed [10:0] dout_q[15:0],
    output logic o_valid
);
    // fac8_1: 8개 고정소수점(1.8) 트위들 팩터 (실수/허수)
    typedef struct packed {
        logic signed [8:0] re;
        logic signed [8:0] im;
    } complex9_t;
    localparam complex9_t fac8_1[0:7] = '{
        '{256,    0},           // 1
        '{256,    0},           // 1
        '{256,    0},           // 1
        '{0,   -256},           // -j
        '{256,    0},           // 1
        '{181, -181},           // 0.7071 - 0.7071j (고정소수점)
        '{256,    0},           // 1
        '{-181, -181}           // -0.7071 - 0.7071j
    };

    logic signed [19:0] mul_re[15:0];
    logic signed [19:0] mul_im[15:0];
    logic signed [10:0] fac_reg_i[15:0];
    logic signed [10:0] fac_reg_q[15:0];

    reg [2:0] fac_idx; // 0~7, 트위들 팩터 인덱스
    reg [5:0] blk_cnt; // 0~31, 32블록(16개씩)
    reg valid;
    integer i;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fac_idx <= 0;
            blk_cnt <= 0;
            valid <= 0;
            for (i = 0; i < 16; i++) begin
                fac_reg_i[i] <= 0;
                fac_reg_q[i] <= 0;
            end
        end else begin
            if (i_valid) begin
                valid <= 1;
                // 4클럭마다 트위들 팩터 인덱스 증가 (64/16=4)
                if (blk_cnt != 0 && blk_cnt % 4 == 0)
                    fac_idx <= fac_idx + 1;
                for (i = 0; i < 16; i++) begin
                    // (a+jb)*(c+jd) = (ac-bd) + j(ad+bc)
                    mul_re[i] = din_i[i]*fac8_1[fac_idx].re - din_q[i]*fac8_1[fac_idx].im;
                    mul_im[i] = din_i[i]*fac8_1[fac_idx].im + din_q[i]*fac8_1[fac_idx].re;
                    // 256로 나누기: >>8 (고정소수점 1.8)
                    fac_reg_i[i] <= mul_re[i] >>> 8;
                    fac_reg_q[i] <= mul_im[i] >>> 8;
                end
                if (blk_cnt == 31) begin
                    blk_cnt <= 0;
                    fac_idx <= 0;
                    valid <= 0;
                end else begin
                    blk_cnt <= blk_cnt + 1;
                end
            end else begin
                valid <= 0;
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
                        state <= state + 1;
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




// 파라미터화된 FFT 스테이지 버퍼 모듈
module stage_buffer #(
    parameter IN_WIDTH = 9,
    parameter OUT_WIDTH = 10,
    parameter NUM_ELEMS = 256, // 버퍼 깊이 (ex: 256, 128, 64 ...)
    parameter BLK_SIZE = 16,   // 한 번에 처리하는 데이터 개수
    parameter PIPELINE_DEPTH = 0 // 파이프라인 딜레이 클럭 수
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

    // 파이프라인 딜레이 레지스터
    logic signed [OUT_WIDTH-1:0] dout_i_pipe [0:PIPELINE_DEPTH][BLK_SIZE-1:0];
    logic signed [OUT_WIDTH-1:0] dout_q_pipe [0:PIPELINE_DEPTH][BLK_SIZE-1:0];
    logic o_valid_pipe [0:PIPELINE_DEPTH];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= INMODE;
            valid <= 0;
            wr_ptr <= 0;
            rd_ptr <= 0;
            blk_cnt <= 0;
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
        end else begin
            case (state)
                INMODE: begin
                    if (i_valid) begin
                        for (i = 0; i < BLK_SIZE; i++) begin
                            ram_i[wr_ptr + i] <= din_i[i];
                            ram_q[wr_ptr + i] <= din_q[i];
                        end
                        wr_ptr <= wr_ptr + BLK_SIZE; //16씩 증가
                        blk_cnt <= blk_cnt + 1;
                        if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                            wr_ptr <= 0;
                            //rd_ptr <= 0;
                            blk_cnt <= 0;
                            state <= OUTSUM;
                            valid <= 1;
                        end
                    end
                end
                OUTSUM: begin
                    if (i_valid) begin
                        for (i = 0; i < BLK_SIZE; i++) begin
                            sreg_i2[i] <= ram_i[rd_ptr + i] + din_i[i];
                            sreg_q2[i] <= ram_q[rd_ptr + i] + din_q[i];
                            sub_buf_i[rd_ptr + i] <= ram_i[rd_ptr + i] - din_i[i];
                            sub_buf_q[rd_ptr + i] <= ram_q[rd_ptr + i] - din_q[i];
                        end
                        if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                            rd_ptr <= 0;
                            blk_cnt <= 0;
                            state <= OUTMINUS;
                        end else begin
                            rd_ptr <= rd_ptr + BLK_SIZE;
                            blk_cnt <= blk_cnt + 1;
                        end
                    end
                end
                OUTMINUS: begin
                    for (i = 0; i < BLK_SIZE; i++) begin
                        sreg_i2[i] <= sub_buf_i[rd_ptr + i];
                        sreg_q2[i] <= sub_buf_q[rd_ptr + i];
                    end
                    if (blk_cnt == (NUM_ELEMS/BLK_SIZE)-1) begin
                        rd_ptr <= 0;
                        blk_cnt <= 0;
                        state <= INMODE;
                        valid <= 0;
                    end else begin
                        rd_ptr <= rd_ptr + BLK_SIZE;
                        blk_cnt <= blk_cnt + 1;
                    end
                end
            endcase
            // 파이프라인 딜레이 적용
            dout_i_pipe[0] <= sreg_i2;
            dout_q_pipe[0] <= sreg_q2;
            o_valid_pipe[0] <= valid;
            for (d = 1; d <= PIPELINE_DEPTH; d++) begin
                dout_i_pipe[d] <= dout_i_pipe[d-1];
                dout_q_pipe[d] <= dout_q_pipe[d-1];
                o_valid_pipe[d] <= o_valid_pipe[d-1];
            end
        end
    end

    assign dout_i = dout_i_pipe[PIPELINE_DEPTH];
    assign dout_q = dout_q_pipe[PIPELINE_DEPTH];
    assign o_valid = o_valid_pipe[PIPELINE_DEPTH];
endmodule

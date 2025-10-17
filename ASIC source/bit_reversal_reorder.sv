`timescale 1ns / 1ps

module streaming_bit_reversal #(
    parameter DATA_WIDTH = 13,
    parameter TOTAL_SIZE = 512,
    parameter DATA_PER_CLK = 16
)(
    input logic clk,
    input logic rstn,
    input logic valid_in,
    input logic signed [DATA_WIDTH-1:0] bfly22_i [DATA_PER_CLK],
    input logic signed [DATA_WIDTH-1:0] bfly22_q [DATA_PER_CLK],
    output logic signed [DATA_WIDTH-1:0] dout_i [DATA_PER_CLK],
    output logic signed [DATA_WIDTH-1:0] dout_q [DATA_PER_CLK],
    output logic valid_out
);

    // 비트 리버스 함수 (MATLAB과 동일)
    function automatic logic [8:0] bit_reverse;
        input logic [8:0] input_index;
        logic [8:0] reversed;
        begin
            // MATLAB: bitget(jj-1,9)*1 + bitget(jj-1,8)*2 + ... + bitget(jj-1,1)*256
            // SystemVerilog: input_index[8]*1 + input_index[7]*2 + ... + input_index[0]*256
            reversed = input_index[8]*9'd1 + input_index[7]*9'd2 + input_index[6]*9'd4 + 
                      input_index[5]*9'd8 + input_index[4]*9'd16 + input_index[3]*9'd32 + 
                      input_index[2]*9'd64 + input_index[1]*9'd128 + input_index[0]*9'd256;
            bit_reverse = reversed;
        end
    endfunction

    // 내부 저장소 (512개 데이터 저장)
    logic signed [DATA_WIDTH-1:0] storage_i [TOTAL_SIZE-1:0];
    logic signed [DATA_WIDTH-1:0] storage_q [TOTAL_SIZE-1:0];
    
    // 내부 카운터들
    logic [8:0] internal_cycle_idx;  // 0~31 (32사이클)
    logic [5:0] output_counter;
    logic storage_complete;
    logic output_active;
    integer j, k;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            internal_cycle_idx <= 0;
            output_counter <= 0;
            storage_complete <= 1'b0;
            output_active <= 1'b0;
            valid_out <= 1'b0;
            // 저장소 초기화
            for (k = 0; k < TOTAL_SIZE; k++) begin
                storage_i[k] <= {DATA_WIDTH{1'b0}};
                storage_q[k] <= {DATA_WIDTH{1'b0}};
            end
            // 출력 초기화
            for (k = 0; k < DATA_PER_CLK; k++) begin
                dout_i[k] <= {DATA_WIDTH{1'b0}};
                dout_q[k] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            // valid_in이 들어오면 internal_cycle_idx 증가
            if (valid_in) begin
                internal_cycle_idx <= internal_cycle_idx + 1;
            end
            
            // 512개 데이터 저장 (32클럭) - 비트 리버스 위치에 저장
            if (valid_in && !storage_complete) begin
                for (j = 0; j < DATA_PER_CLK; j++) begin
                    logic [12:0] original_idx;
                    logic [8:0] reversed_idx;
                    original_idx = (internal_cycle_idx << 4) + j;  // internal_cycle_idx * 16
                    reversed_idx = bit_reverse(original_idx[8:0]);  // 비트 리버스 위치
                    
                    // 디버깅 출력
                    if (internal_cycle_idx < 2) begin  // 처음 몇 개만 출력
                        $display("Time %t: original_idx=%d, reversed_idx=%d, bfly22_i[%d]=%d", 
                                $time, original_idx, reversed_idx, j, bfly22_i[j]);
                    end
                    
                    storage_i[reversed_idx] <= bfly22_i[j];
                    storage_q[reversed_idx] <= bfly22_q[j];
                end
                
                if (internal_cycle_idx >= 31) begin
                    storage_complete <= 1'b1;
                    output_active <= 1'b1;
                    output_counter <= 0;
                end
            end
            
            // 저장 완료 후 순차 출력 (이미 비트 리버스 위치에 저장됨)
            if (output_active) begin
                valid_out <= 1'b1;
                for (j = 0; j < DATA_PER_CLK; j++) begin
                    logic [8:0] output_idx;
                    output_idx = (output_counter << 4) + j;
                    dout_i[j] <= storage_i[output_idx];
                    dout_q[j] <= storage_q[output_idx];
                end

                output_counter <= output_counter + 1;

                if (output_counter >= 32) begin
                    output_active <= 1'b0;
                    valid_out <= 1'b0;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

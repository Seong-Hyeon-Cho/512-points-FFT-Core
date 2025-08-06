`timescale 1ps / 1fs

module TEST_FPGA();

    // Clock and reset signals
    logic clk;
    logic rstn;
    logic start_trigger;
    logic signed [12:0] dout_i [15:0];
    logic signed [12:0] dout_q [15:0];

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end

    // Reset generation
    initial begin
        rstn = 0;
        #100;
        rstn = 1;
    end

    // Test stimulus
    initial begin
        start_trigger = 0;
        
        // Wait for reset
        wait(rstn);
        #50;
        
        // Start trigger - cos_in_gen 시작
        start_trigger = 1;
        #10;
        start_trigger = 0;
        
        // cos_in_gen은 32 사이클 동안 데이터 생성 (32 * 10ns = 320ns)
        // 추가 여유 시간 포함하여 대기
        #500;
        
        // 두 번째 테스트 - 다시 시작
        start_trigger = 1;
        #10;
        start_trigger = 0;
        
        // 충분한 시간 대기
        #1000;
        
        // End simulation
        $finish;
    end

    
 

    // Instantiate DUT
    FPGA_TOP U_FPGA_TOP(
        .clk(clk),
        .rstn(rstn),
        .start_trigger(start_trigger),
        .dout_i(dout_i),
        .dout_q(dout_q)
    );

endmodule

`timescale 1ns / 1ps


module FPGA_TOP (
    //input clk,
    input clk_p,
    input clk_n,
    input rstn
);

    wire clk_out;
    wire vio_start, start_or;

    //assign start_or = start_trigger | vio_start;  // ?Ç¥Î∂? Í≤∞Ìï© ?ã†?ò∏


    logic signed [8:0] din_i[15:0];
    logic signed [8:0] din_q[15:0];
    logic signed [12:0] dout_i[15:0];
    logic signed [12:0] dout_q[15:0];
    logic i_valid;
    logic o_valid;

clk_wiz_0 u_clk_wiz (
    .clk_in1_p(clk_p),
    .clk_in1_n(clk_n),
    .resetn(rstn),
    .clk_out1(clk_out)
);

    cos_in_gen #(
        .N(512),
        .DATA_PER_CLK(16)
    ) u_cos_in_gen (
        .clk(clk_out),
        .rstn(rstn),
        .start(vio_start),
        .valid_out(i_valid),
        .dout_i(din_i),
        .dout_q(din_q)
    );


    top u_top (
        .clk(clk_out),
        .rstn(rstn),
        .i_valid(i_valid),
        .din_i(din_i),
        .din_q(din_q),
        .dout_i(dout_i),
        .dout_q(dout_q),
        .o_valid(o_valid)
    );


    vio_exam1 u_vio (
        .clk(clk_out),
        .probe_in0(o_valid),
        .probe_in1(dout_i[0]),
        .probe_in2(dout_i[1]),
        .probe_in3(dout_i[2]),
        .probe_in4(dout_i[3]),
        .probe_in5(dout_i[4]),
        .probe_in6(dout_i[5]),
        .probe_in7(dout_i[6]),
        .probe_in8(dout_i[7]),
        .probe_in9(dout_i[8]),
        .probe_in10(dout_i[9]),
        .probe_in11(dout_i[10]),
        .probe_in12(dout_i[11]),
        .probe_in13(dout_i[12]),
        .probe_in14(dout_i[13]),
        .probe_in15(dout_i[14]),
        .probe_in16(dout_i[15]),
        .probe_in17(dout_q[0]),
        .probe_in18(dout_q[1]),
        .probe_in19(dout_q[2]),
        .probe_in20(dout_q[3]),
        .probe_in21(dout_q[4]),
        .probe_in22(dout_q[5]),
        .probe_in23(dout_q[6]),
        .probe_in24(dout_q[7]),
        .probe_in25(dout_q[8]),
        .probe_in26(dout_q[9]),
        .probe_in27(dout_q[10]),
        .probe_in28(dout_q[11]),
        .probe_in29(dout_q[12]),
        .probe_in30(dout_q[13]),
        .probe_in31(dout_q[14]),
        .probe_in32(dout_q[15]),
        .probe_out0(vio_start)
    );

/*
    // ?îÑÎ°úÎ∏å ?è¨?ä∏ ?ó∞Í≤?
    assign probe_dout_i_0  = dout_i[0];
    assign probe_dout_i_1  = dout_i[1];
    assign probe_dout_i_2  = dout_i[2];
    assign probe_dout_i_3  = dout_i[3];
    assign probe_dout_i_4  = dout_i[4];
    assign probe_dout_i_5  = dout_i[5];
    assign probe_dout_i_6  = dout_i[6];
    assign probe_dout_i_7  = dout_i[7];
    assign probe_dout_i_8  = dout_i[8];
    assign probe_dout_i_9  = dout_i[9];
    assign probe_dout_i_10 = dout_i[10];
    assign probe_dout_i_11 = dout_i[11];
    assign probe_dout_i_12 = dout_i[12];
    assign probe_dout_i_13 = dout_i[13];
    assign probe_dout_i_14 = dout_i[14];
    assign probe_dout_i_15 = dout_i[15];

    assign probe_dout_q_0  = dout_q[0];
    assign probe_dout_q_1  = dout_q[1];
    assign probe_dout_q_2  = dout_q[2];
    assign probe_dout_q_3  = dout_q[3];
    assign probe_dout_q_4  = dout_q[4];
    assign probe_dout_q_5  = dout_q[5];
    assign probe_dout_q_6  = dout_q[6];
    assign probe_dout_q_7  = dout_q[7];
    assign probe_dout_q_8  = dout_q[8];
    assign probe_dout_q_9  = dout_q[9];
    assign probe_dout_q_10 = dout_q[10];
    assign probe_dout_q_11 = dout_q[11];
    assign probe_dout_q_12 = dout_q[12];
    assign probe_dout_q_13 = dout_q[13];
    assign probe_dout_q_14 = dout_q[14];
    assign probe_dout_q_15 = dout_q[15];

    assign probe_o_valid   = o_valid;
*/
endmodule

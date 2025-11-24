`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input btnC,
    input [7:0] sw,
    input RsRx,
    input s1,
    input s2,
    input key,
    output buzzer,
    output RsTx,
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,
    output ds_clk,
    output ds_rst,
    inout ds_dat   
    );

    wire [7:0] w_rx_data;
    wire [13:0] w_seg_data, w_rotary_seg;
    wire [13:0] w_send_data;
    wire [13:0] w_alarm_time, display_data;
    wire w_clean_btn, clean_s1, clean_s2, clean_key;
    wire w_rx_done, mode, alarm_set_done, alarm_trigger;

    assign display_data = (mode == 1) ? w_rotary_seg : w_seg_data;

    btn_debouncer u_button_debouncer (
        .clk(clk),
        .reset(reset),
        .btn(btnC),  // raw noisy button input
        .clean_btn(w_clean_btn)        
    );

    btn_debouncer u_s1_debouncer (
        .clk(clk),
        .reset(reset),
        .btn(s1),  // raw noisy button input
        .clean_btn(clean_s1)        
    );

    btn_debouncer u_s2_debouncer (
        .clk(clk),
        .reset(reset),
        .btn(s2),  // raw noisy button input
        .clean_btn(clean_s2)        
    );

    btn_debouncer u_key_debouncer (
        .clk(clk),
        .reset(reset),
        .btn(key),  // raw noisy button input
        .clean_btn(clean_key)        
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),   // btnU
        .in_data(display_data),
        .an(an),
        .seg(seg)
    );

    ds_rtc u_ds_rtc(
        .clk(clk),
        .reset(reset),
        .out_data(w_seg_data),
        .CE(ds_rst),
        .SCLK(ds_clk),
        .IO(ds_dat)
    );

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .send_data(w_seg_data),
        .rx(RsRx),
        .tx(RsTx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    change_mode u_mode(
        .clk(clk),
        .reset(reset),
        .btnC(btnC),
        .mode(mode)
    );

    rotary u_rotary(
        .clk(clk), .reset(reset),
        .clean_s1(clean_s1),
        .clean_s2(clean_s2),
        .clean_key(clean_key),
        .alarm_time(w_alarm_time),
        .setting_done(alarm_set_done),
        .seg(w_rotary_seg)
    );

    alarm_compare u_compare(
        .clk(clk),
        .reset(reset),
        .current_time(w_seg_data),
        .alarm_time(w_alarm_time),
        .alarm_enable(alarm_set_done),
        .alarm_trigger(alarm_trigger)
    );

    buzzer u_buzzer(
        .clk(clk), .reset(reset),
        .alarm_trigger(alarm_trigger),
        .buzzer_out(buzzer),
        .led(led)
    );
endmodule

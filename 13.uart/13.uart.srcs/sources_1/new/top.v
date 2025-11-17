`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input [2:0] btn,
    input [7:0] sw,
    input RsRx,
    output RsTx,
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,
    output uart_tx,
    output uart_rx
    );

    wire [7:0] w_rx_data;
    wire [13:0] w_seg_data;
    wire [2:0] w_btn_debounced;
    wire w_rx_done;

    debouncer u_button_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn[0]),
        .clean_btn(w_btn_debounced[0])
    );

    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),
        .btn(w_btn_debounced[0]),
        .sw(sw),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .seg_data(w_seg_data),
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .in_data(w_seg_data),
        .seg(seg),
        .an(an)
    );


    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .send_data(),
        .rx(RsRx),
        .tx(RsTx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    assign uart_tx = RsTx;
    assign uart_rx = RsRx;
endmodule

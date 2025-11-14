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
    output [15:0] led
    );

    wire [7:0] w_rx_data;
    wire w_rx_done;

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .send_data(),
        .rx(RsRx),
        .tx(RsTx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    assign led[7:0] = w_rx_data;
endmodule

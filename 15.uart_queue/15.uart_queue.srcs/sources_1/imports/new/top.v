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
    output uartTx,    // JB1  
    output uartRx    // JB2   
    );

    wire [7:0] w_rx_data;
    wire [13:0] w_seg_data;
    wire [2:0] w_clean_btn;
    wire w_rx_done;

    btn_debouncer u_button_debouncer (
        .clk(clk),
        .reset(reset),
        .btn(btn),  // raw noisy button input
        .clean_btn(w_clean_btn)        
    );

    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),   // btnU
        .btn(w_clean_btn),  // btn[0] : btnL btn[1] : btnC btn[2] : btnR
        .sw(sw),
        .rx_data(w_rx_data),   // for UART 
        .rx_done(w_rx_done),   // UART 
        .seg_data(w_seg_data),
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),   // btnU
        .in_data(w_seg_data),
        .an(an),
        .seg(seg)
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

    assign uartTx = RsTx; 
    assign uartRx = RsRx;   
endmodule

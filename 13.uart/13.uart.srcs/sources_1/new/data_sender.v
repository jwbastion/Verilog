`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [13:0] send_data,
    input tx_busy,
    input tx_done,
    output reg tx_start,
    output reg [7:0] tx_data
    );

    // CR, H, e, l, l, o, !, , J, W, Y, o, o, LF
    reg [7:0] msg[0:3];
    reg [3:0] r_data_cnt = 0;

    initial begin
        msg[0] = "J";
        msg[1] = "W";
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            tx_start <= 0;
            r_data_cnt <= 0;
        end else begin
            if(start_trigger && !tx_busy) begin
                tx_start <= 1'b1;
                tx_data <= msg[r_data_cnt];

                if(r_data_cnt == 1) begin
                    r_data_cnt <= 0;
                end else begin
                    r_data_cnt <= r_data_cnt + 1;
                end
            end else begin
                tx_start <= 1'b0;
            end
        end
    end
endmodule

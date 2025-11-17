`timescale 1ns / 1ps

module uart_rx #(
    parameter BPS = 9600,
    parameter SAMPLE = 16
)(
    input clk,
    input reset,
    input rx,
    output reg [7:0] data_out,
    output reg rx_done
    );

    reg [2:0] r_state;
    reg [3:0] r_bit_cnt;
    reg [7:0] r_data_reg;
    reg [15:0] r_baud_cnt;
    reg r_baud_tick;
    reg [3:0] r_baud_tick_cnt;

    parameter S_IDLE = 2'b00;
    parameter S_START_BIT = 2'b01;
    parameter S_DATA_8BITS = 2'b10;
    parameter S_STOP_BIT = 2'b11;

    parameter DIVIDER_COUNT = 100_000_000 / (BPS*SAMPLE);

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_baud_cnt <= 0;
            r_baud_tick <= 0;
        end else begin
            if(r_baud_cnt == DIVIDER_COUNT - 1) begin
                r_baud_cnt <= 0;
                r_baud_tick <= 1;
            end else begin
                r_baud_cnt <= r_baud_cnt + 1;
                r_baud_tick <= 0;
            end
        end
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_state <= S_IDLE;
            data_out <= 0;
            rx_done <= 0;
            r_bit_cnt <= 0;
            r_data_reg <= 0;
            r_baud_tick_cnt <= 0;
        end else begin
            rx_done <= 0;
            case(r_state)
            S_IDLE: begin
                if(!rx) begin
                    r_state <= S_START_BIT;
                    r_baud_tick_cnt <= 4'd0;
                end
            end
            S_START_BIT: begin
                if(r_baud_tick) begin
                    r_baud_tick_cnt <= r_baud_tick_cnt + 1;
                    if(r_baud_tick_cnt == 7) begin
                        r_state <= S_DATA_8BITS;
                        r_bit_cnt <= 0;
                        r_baud_tick_cnt <= 0;
                    end
                end
            end
            S_DATA_8BITS: begin
                if(r_baud_tick) begin
                    r_baud_tick_cnt <= r_baud_tick_cnt + 1;
                    if(r_baud_tick_cnt == 15) begin
                        r_data_reg[r_bit_cnt] <= rx;
                        r_baud_tick_cnt <= 0;
                        if(r_bit_cnt == 7) begin
                            r_state <= S_STOP_BIT;
                        end
                        else r_bit_cnt <= r_bit_cnt + 1;
                    end
                end
            end
            S_STOP_BIT: begin
                if(r_baud_tick) begin
                    r_baud_tick_cnt <= r_baud_tick_cnt + 1;
                    if(r_baud_tick_cnt == 15) begin
                        r_state <= S_IDLE;
                        data_out <= r_data_reg;
                        rx_done <= 1;
                    end
                end
            end
            default r_state <= S_IDLE;
            endcase
        end
    end
endmodule

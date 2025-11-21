`timescale 1ns / 1ps

module rotary(
    input clk,
    input reset,
    input clean_s1,
    input clean_s2,
    input clean_key,
    output reg [13:0] alarm_time,
    output reg setting_done,
    output reg [13:0] seg
    );

    reg[7:0] second = 0;
    reg[7:0] minute = 0;

    reg[1:0] r_prev_state = 2'b00;
    reg[1:0] r_curr_state = 2'b00;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            second <= 8'd0;
            minute <= 8'd0;
            r_prev_state <= 2'b00;
            r_curr_state <= 2'b00;
            setting_done <= 0;
            seg <= 0;
            alarm_time <= 0;
        end else begin
            r_prev_state <= r_curr_state;
            r_curr_state <= {clean_s2, clean_s1};

            case ({r_prev_state, r_curr_state})
                4'b0010,4'b1011,4'b1101,4'b0100: begin // CW: 증가
                    if(second < 59) second <= second + 1;
                    else begin second <= 0; minute <= (minute==59)?0:minute+1; end

                    setting_done <= 0;
                end 
                4'b0001,4'b0111,4'b1110,4'b1000: begin // CCW: 감소
                    if(second > 0) second <= second - 1;
                    else begin second <= 59; minute <= (minute==0)?59:minute-1; end

                    setting_done <= 0;
                end
            endcase

            if(clean_key) begin
                setting_done <= 1;
                alarm_time <= minute*100 + second;
            end

            seg <= minute*100 + second;
        end
    end
endmodule

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
    reg[7:0] minute = 30;

    reg[1:0] r_prev_state = 2'b00;
    reg[1:0] r_curr_state = 2'b00;

    reg prev_key = 0;        
    reg setting_mode = 1;   // 1 = 설정 모드, 0 = 동작 모드

    wire key_pressed = clean_key && !prev_key; // 1클럭 펄스

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            second <= 8'd0;
            minute <= 8'd0;
            r_prev_state <= 2'b00;
            r_curr_state <= 2'b00;
            setting_done <= 0;
            seg <= 0;
            alarm_time <= 0;
            setting_mode <= 1;
            prev_key <= 0;
        end else begin
            prev_key <= clean_key; // edge 검출 저장

            // clean_key를 눌릴 때마다 설정/동작 모드 전환
            if(key_pressed) begin
                setting_mode <= ~setting_mode;
                
                if(setting_mode) begin
                    // 설정 완료 → 동작 모드 전환
                    alarm_time <= minute*100 + second;
                    setting_done <= 1;
                end
                else begin
                    // 동작 → 설정 모드 복귀
                    setting_done <= 0;
                end
            end

            if(setting_mode) begin
                r_prev_state <= r_curr_state;
                r_curr_state <= {clean_s2, clean_s1};

                case ({r_prev_state, r_curr_state})
                    4'b0010,4'b1011,4'b1101,4'b0100: begin // CW: 증가
                        if(second < 59) second <= second + 1;
                        else begin second <= 0; minute <= (minute==59)?0:minute+1; end
                    end 
                    4'b0001,4'b0111,4'b1110,4'b1000: begin // CCW: 감소
                        if(second > 0) second <= second - 1;
                        else begin second <= 59; minute <= (minute==0)?59:minute-1; end
                    end
                endcase
            end

            seg <= minute*100 + second;
        end
    end
endmodule

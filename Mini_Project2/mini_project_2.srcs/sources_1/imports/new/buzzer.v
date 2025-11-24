`timescale 1ns / 1ps

module buzzer(
    input clk,
    input reset,
    input alarm_trigger,         // 1 클럭 동안 1 → 부저 동작 시작
    output reg buzzer_out,
    output reg [15:0] led
);

    reg [23:0] tone_cnt = 0;
    reg [26:0] dur_cnt = 0;
    reg playing = 0;

    //parameter [23:0] TONE_DIV = 24'd38222;   // 1kHz 부저 tone
    parameter [26:0] DURATION = 27'd30_000_000;  // 부저 울릴 시간 (조절 가능)

    reg [23:0] tone_div = 0;

    parameter C  = 24'd191571;   // 도 (523Hz)
    parameter D  = 24'd170648;   // 레 (587Hz)
    parameter E  = 24'd151515;   // 미 (659Hz)
    parameter F  = 24'd143266;   // 파 (698Hz)
    parameter G  = 24'd127551;   // 솔 (784Hz)
    parameter A  = 24'd113636;   // 라 (880Hz)
    parameter B  = 24'd101239;   // 시 (988Hz)

    reg [3:0] state = 0;
    localparam IDLE  = 4'd0,
               G1    = 4'd1,
               A1    = 4'd2,
               B1    = 4'd3,
               G2    = 4'd4,
               A2    = 4'd5,
               B2    = 4'd6,
               G3    = 4'd7,
               A3    = 4'd8,
               B3    = 4'd9,
               C1    = 4'd10,
               DONE  = 4'd11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tone_cnt <= 0;
            dur_cnt <= 0;
            tone_div <= 0;
            buzzer_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    buzzer_out <= 0;
                    tone_cnt <= 0;
                    dur_cnt <= 0;
                    if (alarm_trigger)
                        state <= G1;
                        led[0] <= ~led[0];
                end

                G1, G2, G3: tone_div <= G;
                A1, A2, A3: tone_div <= A;
                B1, B2, B3: tone_div <= B;
                C1: tone_div <= C;

                DONE: begin
                    buzzer_out <= 0;
                    if (!alarm_trigger)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase

            // ---- Tone 발생 ----
            if (state != IDLE && state != DONE) begin
                dur_cnt <= dur_cnt + 1;
                tone_cnt <= tone_cnt + 1;

                if (tone_cnt >= tone_div - 1) begin
                    tone_cnt <= 0;
                    buzzer_out <= ~buzzer_out;
                end

                // 0.3초 경과 시 다음 음으로 이동
                if (dur_cnt >= DURATION) begin
                    dur_cnt <= 0;
                    state <= state + 1;
                end
            end
            else if (state == DONE) begin
                buzzer_out <= 0;
                dur_cnt <= 0;
                tone_cnt <= 0;
                state <= IDLE;
            end
        end
    end
endmodule
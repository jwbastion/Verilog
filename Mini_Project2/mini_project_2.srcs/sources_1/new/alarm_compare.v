`timescale 1ns / 1ps

module alarm_compare(
    input [13:0] current_time,
    input [13:0] alarm_time,
    input alarm_enable,       // rotary에서 설정 완료 시 1
    output reg alarm_trigger
);
    always @(*) begin
        if(alarm_enable && (current_time == alarm_time))
            alarm_trigger = 1;
        else
            alarm_trigger = 0;
    end
endmodule

`timescale 1ns / 1ps

module change_mode(
    input clk,
    input reset,
    input btnC,          // clean_btnC 사용
    output reg mode      // 0 = current time mode, 1 = alarm set mode
);

    reg prev_btnC;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mode <= 0;
            prev_btnC <= 0;
        end
        else begin
            prev_btnC <= btnC;
            if (!prev_btnC && btnC) begin
                mode <= ~mode;   // toggle
            end
        end
    end
endmodule
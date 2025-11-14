`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    input [2:0] btn,
    input [7:0] sw,
    output [13:0] seg,
    output reg [15:0] led
    );

    // mode define
    parameter UP_COUNTER = 3'b001;
    parameter DOWN_COUNTER = 3'b010;
    parameter SLIDE_SW_READ = 3'b011;

    reg r_prev_btnL = 0;
    reg [2:0] r_mode = 3'b000;
    reg [19:0] r_counter;  // 10ms를 재기 위한 counter
    reg [13:0] r_ms_counter;  // 9999 10ms 될때마다 1증가

    //mode check
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_mode <= 0;
            r_prev_btnL <= 0;
        end else begin
            if(btn[0] && !r_prev_btnL)
                r_mode = (r_mode == SLIDE_SW_READ) ? UP_COUNTER : r_mode + 1;
        end
        r_prev_btnL <= btn[0];
    end

    //---- up counter ----
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_counter <= 0;
            r_ms_counter <= 0;
        end else if(r_mode == UP_COUNTER) begin
            if(r_counter == 20'd1_000_000-1) begin   //10ms reach
                r_counter <= 0;
                r_ms_counter <= r_ms_counter + 1;
            end else begin
            r_counter <= r_counter + 1;
            end
        end else begin
            r_counter <= 0;
            r_ms_counter <= 0;
        end
    end

    //----- led mode display -----
    always @(r_mode) begin
        case(r_mode)
        UP_COUNTER: begin
            led[15:13] = UP_COUNTER;
        end
        DOWN_COUNTER: begin
            led[15:13] = DOWN_COUNTER;
        end
        SLIDE_SW_READ: begin
            led[15:13] = SLIDE_SW_READ;
        end
        default:
            led[15:13] = 3'b000;
        endcase
    end

    assign seg = (r_mode == UP_COUNTER) ? r_ms_counter :
                      (r_mode == DOWN_COUNTER) ? r_ms_counter : sw; 
endmodule

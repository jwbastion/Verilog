`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,   // btnU
    input [2:0] btn,  // btn[0] : btnL btn[1] : btnC btn[2] : btnR
    input [7:0] sw,
    input [7:0] rx_data,   // for UART 
    input rx_done,   // UART 
    output [13:0] seg_data,
    output reg [15:0] led
    );
    // mode define 
    parameter UP_COUNTER = 3'b001;
    parameter DOWN_COUNTER = 3'b010;
    parameter SLIDE_SW_READ = 3'b011;

    reg r_prev_btnL=0;
    reg [2:0]  r_mode = 3'b000;
    reg [19:0] r_counter;   // 10ms를 재기 위한 counter
    reg [13:0] r_ms10_counter;   //  9999  10ms가 될때 마다 1증가

    // mode menu check 
    always @(posedge clk, posedge reset) begin
        if (reset)  begin
            r_mode <= 0;
            r_prev_btnL <= 0;
        end else begin
            if (btn[0] && !r_prev_btnL)   
                r_mode = (r_mode == SLIDE_SW_READ) ? UP_COUNTER : r_mode + 1; 
            
            if (rx_done && rx_data == 8'h4D)    // 4d --> 'M'  
                r_mode = (r_mode == SLIDE_SW_READ) ? UP_COUNTER : r_mode + 1; 
        end 
        r_prev_btnL <= btn[0];
    end

    //---- up counter -----
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_ms10_counter <= 0;
        end else if (r_mode == UP_COUNTER) begin
            if (r_counter == 20'd1_000_000-1) begin   // 10ms reach 
                r_counter <= 0;
                r_ms10_counter <= r_ms10_counter + 1; 
            end else begin
                r_counter <= r_counter + 1; 
            end 
        end else begin
            r_counter <= 0;
            r_ms10_counter <= 0;           
        end 
    end

    //------ led mode display 
    always @(r_mode) begin    // r_mode가 변경 될떄 마다 실행 
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
        
    assign seg_data = (r_mode == UP_COUNTER ) ? r_ms10_counter :
                      (r_mode == DOWN_COUNTER) ? r_ms10_counter : sw;
endmodule

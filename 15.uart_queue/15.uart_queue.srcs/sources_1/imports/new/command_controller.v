`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,   // btnU
    input [2:0] btn,  // btn[0] : btnL btn[1] : btnC btn[2] : btnR
    input [7:0] sw,
    input [7:0] rx_data,   // for UART 
    input rx_done,   // UART
    output [13:0] seg_data,
    output reg [15:0] led,

    // ★ data_sender로 보낼 메시지 (단순 출력만)
    output reg [511:0] uart_msg,
    output reg [7:0] msg_len
    );
    // mode define 
    parameter UP_COUNTER = 3'b001;
    parameter DOWN_COUNTER = 3'b010;
    parameter SLIDE_SW_READ = 3'b011;

    reg r_prev_btnL=0;
    reg [2:0]  r_mode = 3'b000;
    reg [19:0] r_counter;
    reg [13:0] r_ms10_counter;

    wire [7:0] digit_1000 = (r_ms10_counter / 1000) % 10 + 8'h30;
    wire [7:0] digit_100  = (r_ms10_counter / 100) % 10  + 8'h30;
    wire [7:0] digit_10   = (r_ms10_counter / 10) % 10   + 8'h30;
    wire [7:0] digit_1    = (r_ms10_counter % 10)        + 8'h30;

    //----------------------------
    // 1. UART Circular Buffer
    //----------------------------
    reg [7:0] cmd_buffer[0:31];  
    reg [4:0] wr_ptr = 0;        // write pointer
    reg [4:0] rd_ptr = 0;        // read pointer
    reg cmd_ready = 0;           

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            cmd_ready <= 0;
        end 
        else if (rx_done) begin
            cmd_buffer[wr_ptr] <= rx_data;
            wr_ptr <= wr_ptr + 1;
            if(wr_ptr > 31) begin
                wr_ptr <= 0;
            end

            if (rx_data == 8'h0A || rx_data == 8'h0D) begin
                cmd_ready <= 1;
            end
        end
        else if (cmd_ready) begin
            cmd_ready <= 0;
        end
    end


    //-----------------------------------
    // 2. Command Parsing & LED Control
    //-----------------------------------
    integer i;
    reg [7:0] cmd_string[0:31];
    reg [5:0] length;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            led <= 16'h0000;
            rd_ptr <= 0;
            msg_len <= 0;
        end
        else if (cmd_ready) begin
            length = (wr_ptr >= rd_ptr) ? (wr_ptr - rd_ptr) : (32 + wr_ptr - rd_ptr);
            for (i = 0; i < length; i = i + 1) begin
                cmd_string[i] <= cmd_buffer[(rd_ptr + i) % 32];
            end

            // rd_ptr 업데이트
            rd_ptr <= wr_ptr;

            // ===== LED ALL ON =====
            if (length >= 8 &&
                cmd_string[0]=="l"&&cmd_string[1]=="e"&&cmd_string[2]=="d"&&
                cmd_string[3]=="a"&&cmd_string[4]=="l"&&cmd_string[5]=="l"&&
                cmd_string[6]=="o"&&cmd_string[7]=="n") begin
                led <= 16'hFFFF;
                end

            // ===== LED ALL OFF =====
            else if (length >= 9 &&
                cmd_string[0]=="l"&&cmd_string[1]=="e"&&cmd_string[2]=="d"&&
                cmd_string[3]=="a"&&cmd_string[4]=="l"&&cmd_string[5]=="l"&&
                cmd_string[6]=="o"&&cmd_string[7]=="f"&&cmd_string[8]=="f") begin
                led <= 16'h0000;
                end
            
            // ===== LED 00 ON =====
            else if (length >= 7 &&
                cmd_string[0]=="l"&&cmd_string[1]=="e"&&cmd_string[2]=="d"&&
                cmd_string[3]=="0"&&cmd_string[4]=="0"&&cmd_string[5]=="o"&&
                cmd_string[6]=="n") begin
                led <= 16'h0001;
                end
            
            // ===== LED 00 OFF =====
            else if (length >= 8 &&
                cmd_string[0]=="l"&&cmd_string[1]=="e"&&cmd_string[2]=="d"&&
                cmd_string[3]=="0"&&cmd_string[4]=="0"&&cmd_string[5]=="o"&&
                cmd_string[6]=="f"&&cmd_string[7]=="f") begin
                led <= 16'h0000;
                end

            // ===== My Name =====
            else if (length >= 6 &&
                cmd_string[0]=="m"&&cmd_string[1]=="y"&&cmd_string[2]=="n"&&
                cmd_string[3]=="a"&&cmd_string[4]=="m"&&cmd_string[5]=="e") begin
                uart_msg <= {
                    "M","y"," ","n","a","m","e"," ",
                    "i","s"," ","J","W","\r","\n"
                };
                msg_len <= 15;
            end

            // ===== Up Counter =====
            else if (length >= 9 &&
                cmd_string[0]=="u"&&cmd_string[1]=="p"&&cmd_string[2]=="c"&&
                cmd_string[3]=="o"&&cmd_string[4]=="u"&&cmd_string[5]=="n"&&
                cmd_string[6]=="t"&&cmd_string[7]=="e"&&cmd_string[8]=="r") begin

                uart_msg <= {
                    "C","o","u","n","t","e","r",":"," ",
                    digit_1000,
                    digit_100,
                    digit_10,
                    digit_1,
                    "\r","\n"
                };
                msg_len <= 15;
            end

            // ===== Help =====
            else if (length >= 4 &&
                cmd_string[0]=="h"&&cmd_string[1]=="e"&&cmd_string[2]=="l"&&
                cmd_string[3]=="p") begin
                uart_msg <= {
                    "C","o","m","m","a","n","d","s",":"," ",
                    "m","y","n","a","m","e",","," ",
                    "u","p","c","o","u","n","t","e","r","\r","\n"
                };
                msg_len <= 29;
                end else begin
                    msg_len <= 0;
                end
        end
    end

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
        
    assign seg_data = (r_mode == UP_COUNTER ) ? r_ms10_counter :
                      (r_mode == DOWN_COUNTER) ? r_ms10_counter : sw;
endmodule
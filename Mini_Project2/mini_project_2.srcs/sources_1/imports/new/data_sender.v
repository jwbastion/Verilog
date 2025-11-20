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

    localparam IDLE = 0, SEND = 1;
    reg [1:0] state;

    reg [7:0] msg [0:12];
    reg [3:0] index;

    wire [3:0] min_ten  = (send_data / 1000) % 10;
    wire [3:0] min_one  = (send_data / 100) % 10;
    wire [3:0] sec_ten  = (send_data / 10) % 10;
    wire [3:0] sec_one  = (send_data / 1) % 10;

    always @(*) begin
        msg[0]  = "T";
        msg[1]  = "i";
        msg[2]  = "m";
        msg[3]  = "e";
        msg[4]  = ":";
        msg[5]  = " ";
        msg[6]  = min_ten + "0";
        msg[7]  = min_one + "0";
        msg[8]  = ":";
        msg[9]  = sec_ten + "0";
        msg[10] = sec_one + "0";
        msg[11] = 8'h0D; 
        msg[12] = 8'h0A; 
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_start <= 0;
            index <= 0;

        end else begin
            case(state)
            IDLE: begin
                tx_start <= 0;
                index <= 1;

                if (start_trigger && !tx_busy) begin
                    tx_data <= msg[0];
                    tx_start <= 1'b1;
                    state <= SEND;
                end
            end

            SEND: begin
                tx_start <= 0;

                if(tx_done && !tx_busy) begin
                    index <= index + 1;
                    if(index < 13) begin
                        tx_data <= msg[index];
                        tx_start <= 1;
                    end else begin
                        state <= IDLE;
                    end
                end
            end
            endcase
        end 
    end
endmodule

`timescale 1ns / 1ps

module tb_uart_rx;
    reg clk;
    reg reset;
    reg rx = 1;
    wire [7:0] data_out;
    wire rx_done;

    parameter BIT_PERIOD = 10416;

    uart_rx #(
        .BPS(9600),
        .SAMPLE(16)
    ) u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // UART TX Task (테스트벤치에서 rx 라인에 파형 생성)
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            rx <= 0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            rx <= 1;
            #(BIT_PERIOD);
        end
    endtask


    initial begin
        #100 reset = 1;
          #50
            reset = 0;

            rx = 1;
            #100000
            // '5' ==> 0x35 0011 0101
            uart_send_byte(8'h35);

          #200000
            $display("UART RX test finish");
            $finish;
    end
endmodule

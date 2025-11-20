`timescale 1ns / 1ps

module ds_rtc(
    input clk,
    input reset,
    output reg [13:0] out_data,   // MMSS (예: 1245 → 12:45)
    output reg CE,
    output reg SCLK,
    inout wire IO
);

    // FSM State 정의
    localparam IDLE          = 4'd0,
               READ_SEC_CMD  = 4'd1,
               READ_SEC_DATA = 4'd2,
               READ_SEC_RD0  = 4'd3,
               READ_SEC_RD1  = 4'd4,
               READ_MIN_CMD  = 4'd5,
               READ_MIN_DATA = 4'd6,
               READ_MIN_RD0  = 4'd7,
               READ_MIN_RD1  = 4'd8,
               DONE          = 4'd9;

    reg [3:0] state;
    reg init_done = 0;

    //------------------------------------------------------
    // 100MHz → 500kHz 통신용 tick 생성
    //------------------------------------------------------
    reg [7:0] clk_div;
    wire tick = (clk_div == 8'd199);
    always @(posedge clk or posedge reset) begin
        if (reset) clk_div <= 0;
        else clk_div <= tick ? 0 : clk_div + 1;
    end

    //------------------------------------------------------
    // 1Hz 타이머 : 매초 RTC 시간 갱신
    //------------------------------------------------------
    reg [26:0] sec_cnt;
    wire tick_1sec = (sec_cnt == 27'd99_999_999);
    always @(posedge clk or posedge reset) begin
        if (reset) sec_cnt <= 0;
        else sec_cnt <= tick_1sec ? 0 : sec_cnt + 1;
    end

    //------------------------------------------------------
    // DS1302 제어 신호 (IO 방향, SCLK, CE)
    //------------------------------------------------------
    reg io_dir;      
    reg io_out;      
    reg [7:0] tx_byte, rx_byte;
    reg [7:0] seconds_bcd, minutes_bcd;
    reg [2:0] bit_cnt;
    wire io_in = IO;

    assign IO = io_dir ? io_out : 1'bz;   // in/out 제어

    //------------------------------------------------------
    // 초기화 (CH 비트 + Write Protect 해제) → 단 1회만!
    //------------------------------------------------------
    task ds1302_init;
        begin
            // 1) Clock Halt 비트 해제
            CE <= 1;  io_dir <= 1;
            tx_byte <= 8'h80;  // Seconds Register Write
            write_byte(tx_byte);
            write_byte(8'h00); // CH = 0 (Clock Enable)
            CE <= 0;
            #200;

            // 2) Write Protect 해제
            CE <= 1;  io_dir <= 1;
            write_byte(8'h8E); // WP Register Write
            write_byte(8'h00); // WP = 0
            CE <= 0;
            #200;

            init_done <= 1;
        end
    endtask

    //------------------------------------------------------
    // 바이트 송신 (Write)
    //------------------------------------------------------
    task write_byte(input [7:0] data);
        integer i;
        begin
            for (i = 0; i < 8; i = i+1) begin
                io_out <= data[i];
                SCLK <= 0; #10;
                SCLK <= 1; #10;
            end
        end
    endtask

    //------------------------------------------------------
    // FSM & 동작 루프
    //------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            CE        <= 0;
            io_dir    <= 1;
            out_data  <= 0;
            bit_cnt   <= 0;
        end
        
        else if (tick) begin
            // 1️⃣ 최초 1번만 초기화 수행
            if (!init_done) begin
                ds1302_init();
            end

            case (state)

                //------------------------------------------------
                // 2️⃣ 1Hz마다 Seconds 읽기 시작
                //------------------------------------------------
                IDLE: begin
                    if (tick_1sec) begin
                        CE <= 1;
                        tx_byte <= 8'h81;  // Seconds Read
                        io_dir <= 1;
                        bit_cnt <= 0;
                        state <= READ_SEC_CMD;
                    end
                end

                READ_SEC_CMD: begin
                    io_out <= tx_byte[bit_cnt];
                    SCLK <= 0;
                    state <= READ_SEC_DATA;
                end
                READ_SEC_DATA: begin
                    SCLK <= 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        bit_cnt <= 0;
                        rx_byte <= 8'd0;
                        io_dir <= 0;
                        state <= READ_SEC_RD0;
                    end else begin
                        state <= READ_SEC_CMD;
                    end
                end
                READ_SEC_RD0: begin
                    SCLK <= 0;
                    state <= READ_SEC_RD1;
                end
                READ_SEC_RD1: begin
                    rx_byte[bit_cnt] <= io_in;
                    SCLK <= 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        seconds_bcd <= rx_byte;
                        CE <= 0;
                        #50;
                        CE <= 1;
                        tx_byte <= 8'h83; // Minutes Read
                        io_dir <= 1;
                        bit_cnt <= 0;
                        state <= READ_MIN_CMD;
                    end else begin
                        state <= READ_SEC_RD0;
                    end
                end

                //------------------------------------------------
                // 3️⃣ Minutes Read
                //------------------------------------------------
                READ_MIN_CMD: begin
                    io_out <= tx_byte[bit_cnt];
                    SCLK <= 0;
                    state <= READ_MIN_DATA;
                end
                READ_MIN_DATA: begin
                    SCLK <= 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        bit_cnt <= 0;
                        io_dir <= 0;
                        rx_byte <= 8'd0;
                        state <= READ_MIN_RD0;
                    end else begin
                        state <= READ_MIN_CMD;
                    end
                end
                READ_MIN_RD0: begin
                    SCLK <= 0;
                    state <= READ_MIN_RD1;
                end
                READ_MIN_RD1: begin
                    rx_byte[bit_cnt] <= io_in;
                    SCLK <= 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        minutes_bcd <= rx_byte;
                        CE <= 0;
                        state <= DONE;
                    end else begin
                        state <= READ_MIN_RD0;
                    end
                end

                //------------------------------------------------
                // 4️⃣ MMSS 데이터 계산 후 출력
                //------------------------------------------------
                DONE: begin
                    out_data <= (minutes_bcd[7:4] * 10 + minutes_bcd[3:0]) * 100 +
                                (seconds_bcd[7:4] * 10 + seconds_bcd[3:0]);
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

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
        
    assign seg_data = (r_mode == UP_COUNTER ) ? r_ms10_counter :
                      (r_mode == DOWN_COUNTER) ? r_ms10_counter : sw;

    
    //================================================================
    //== UART Command Parser (Circular Buffer + FSM)
    //================================================================
    
    // -- 1. Circular Buffer (FIFO) Parameters and Registers
    localparam QUEUE_DEPTH = 64;  // 큐 크기 (64 bytes)
    localparam PTR_WIDTH = 6;   // log2(QUEUE_DEPTH)
    
    reg [7:0] queue_mem [0:QUEUE_DEPTH-1]; // 큐 메모리
    reg [PTR_WIDTH-1:0] w_ptr = 0; // Write 포인터
    reg [PTR_WIDTH-1:0] r_ptr = 0; // Read 포인터
    reg [PTR_WIDTH:0] queue_count = 0; // 큐에 저장된 데이터 개수 (0 ~ 64)
    
    wire queue_empty = (queue_count == 0);
    wire queue_full = (queue_count == QUEUE_DEPTH);
    
    // -- 2. Command Parser Parameters and Registers
    localparam CMD_MAX_LEN = 16;  // 최대 명령어 길이
    localparam S_IDLE = 2'b00;    // FSM 상태: 대기
    localparam S_READ_CMD = 2'b01; // FSM 상태: 명령어 읽는 중
    localparam S_PARSE = 2'b10;  // FSM 상태: 명령어 파싱 (실행)

    reg [1:0] parse_state = S_IDLE;
    reg [7:0] cmd_buf [0:CMD_MAX_LEN-1]; // 명령어 임시 저장 버퍼
    reg [4:0] cmd_ptr = 0; // 명령어 버퍼 포인터
    
    wire [7:0] read_data = queue_mem[r_ptr]; // 큐에서 읽을 데이터
    reg read_enable; // 큐 읽기 신호

    // -- 3. FIFO Write Logic (UART -> Queue)
    // rx_done 신호가 오고 큐가 꽉 차지 않았으면 큐에 데이터 쓰기
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_ptr <= 0;
        end else if (rx_done && !queue_full) begin
            queue_mem[w_ptr] <= rx_data;
            w_ptr <= w_ptr + 1; // 6비트이므로 63 -> 0 자동 랩어라운드
        end
    end

    // -- 4. FIFO Counter Logic
    // 큐 쓰기(rx_done)와 읽기(read_enable)에 따라 카운트 조절
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            queue_count <= 0;
        end else begin
            casex ({rx_done && !queue_full, read_enable}) // {write, read}
                2'b10: queue_count <= queue_count + 1; // Write only
                2'b01: queue_count <= queue_count - 1; // Read only
                // 2'b11 (Write & Read): count stays same
                // 2'b00 (Neither): count stays same
            endcase
        end
    end

    // -- 5. Parser FSM & LED Control Logic
    // (기존의 led always 블록과 통합)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            led <= 16'h0000;
            parse_state <= S_IDLE;
            r_ptr <= 0;
            cmd_ptr <= 0;
            read_enable <= 0;
        end else begin 
            // --- 5-1. 파서 FSM 동작 ---
            read_enable <= 0; // 매 사이클 0으로 초기화
            
            case (parse_state)
                S_IDLE: begin
                    if (!queue_empty) begin // 큐에 데이터가 있으면 읽기 시작
                        parse_state <= S_READ_CMD;
                        cmd_ptr <= 0; // 명령어 버퍼 초기화
                    end
                end
                
                S_READ_CMD: begin
                    if (!queue_empty) begin
                        read_enable <= 1; // 큐에서 1바이트 읽음
                        
                        // 0x0D (CR) 또는 0x0A (LF) -> Enter 키
                        if (read_data == 8'h0D || read_data == 8'h0A) begin 
                            if (cmd_ptr > 0) begin // 빈 명령어가 아니면
                                parse_state <= S_PARSE; // 파싱 시작
                            end else begin
                                parse_state <= S_IDLE; // 빈 명령어는 무시
                            end
                        end
                        // 일반 문자
                        else if (cmd_ptr < CMD_MAX_LEN) begin
                            cmd_buf[cmd_ptr] <= read_data;
                            cmd_ptr <= cmd_ptr + 1;
                        end
                        // 명령어 버퍼 오버플로우 (무시하고 FSM 리셋)
                        else begin
                            parse_state <= S_IDLE;
                        end
                    end
                    // 큐가 비었는데 S_READ_CMD 상태인 경우 (예: Enter 없이 문자만 입력)
                    else begin
                        parse_state <= S_IDLE;
                    end
                end
                
                S_PARSE: begin
                    // --- 5-2. UART 명령어 실행 (LED 제어 우선권) ---
                    // "ledallon" (8글자)
                    if (cmd_ptr >= 8 && cmd_buf[3] == 8'h61 && cmd_buf[7] == 8'h6E) begin
                        
                        led <= 16'hFFFF;
                    end
                    // "ledalloff" (9글자)
                    else if (cmd_ptr >= 9 && cmd_buf[3] == 8'h61 && cmd_buf[8] == 8'h66) begin
                        
                        led <= 16'h0000;
                    end
                    // "led00on" (7글자)
                    else if (cmd_ptr >= 7 && cmd_buf[3] == 8'h30 && cmd_buf[6] == 8'h6E) begin
                        
                        led <= 16'h0001;
                    end
                    // "led00off" (8글자)
                    else if (cmd_ptr >= 8 && cmd_buf[3] == 8'h30 && cmd_buf[7] == 8'h66) begin
                        
                        led <= 16'h0000;
                    end
                    // "myname" (끝글자 'e' 0x65)
                    else if (cmd_ptr >= 6 && cmd_buf[0] == 8'h6D && cmd_buf[5] == 8'h65) begin
                    
                    end
                    // "upcounter" (끝글자 'r' 0x72)
                    else if (cmd_ptr >= 9 && cmd_buf[0] == 8'h75 && cmd_buf[8] == 8'h72) begin
                        
                    end
                    // "help" (끝글자 'p' 0x70)
                    else if (cmd_ptr >= 4 && cmd_buf[0] == 8'h68 && cmd_buf[3] == 8'h70) begin
                        
                    end
                    else begin
                        parse_state <= S_IDLE; // 파싱 완료, IDLE로 복귀
                    end
                end
                
            endcase
            // --- 5-3. 큐 Read 포인터 업데이트 ---
            if (read_enable) begin
                r_ptr <= r_ptr + 1; // 6비트이므로 63 -> 0 자동 랩어라운드
            end
        end
    end
endmodule

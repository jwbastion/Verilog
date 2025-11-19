`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [511:0] flat_data,
    input [7:0] msg_len,
    input tx_busy,
    input tx_done,
    output reg tx_start,
    output reg [7:0] tx_data
    );

    reg [7:0] index;
    
    // FSM States (안정적인 전송을 위해 상태머신 도입)
    localparam S_IDLE = 0;
    localparam S_PREP = 1; // 데이터 준비
    localparam S_SEND = 2; // 전송 시작 신호
    localparam S_WAIT = 3; // 전송 완료 대기
    
    reg [1:0] state;

    // start_trigger 엣지 검출 (Edge Detection)
    reg prev_trigger;
    wire trigger_pulse;
    
    always @(posedge clk or posedge reset) begin
        if(reset) 
            prev_trigger <= 0;
        else 
            prev_trigger <= start_trigger;
    end
    
    // 0 -> 1로 변하는 순간만 감지 (계속 1이어도 반복 실행 안됨)
    assign trigger_pulse = start_trigger && !prev_trigger;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tx_start <= 0;
            tx_data <= 0;
            index <= 0;
            state <= S_IDLE;
        end else begin
            case(state)
                S_IDLE: begin
                    tx_start <= 0;
                    index <= 0;
                    
                    // 트리거 펄스가 왔고, UART가 바쁘지 않으면 시작
                    if (trigger_pulse && !tx_busy) begin
                        state <= S_PREP;
                    end
                end

                S_PREP: begin
                    // 보낼 데이터 세팅 (MSB First 방식 유지)
                    tx_data <= flat_data[(msg_len - 1 - index)*8 +: 8];
                    state <= S_SEND;
                end

                S_SEND: begin
                    tx_start <= 1; // 전송 시작 (1클럭 펄스 준비)
                    state <= S_WAIT;
                end

                S_WAIT: begin
                    tx_start <= 0; // 펄스는 바로 내림
                    
                    // UART 모듈이 한 바이트 전송을 끝냈다는 신호(tx_done)가 오면
                    if (tx_done) begin
                        index <= index + 1; // 다음 글자로 이동

                        if (index + 1 < msg_len) begin 
                            // 아직 보낼 글자가 남았다면
                            state <= S_PREP; 
                        end else begin
                            // 다 보냈으면 대기 상태로 복귀
                            state <= S_IDLE;
                        end
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end 
    end
endmodule

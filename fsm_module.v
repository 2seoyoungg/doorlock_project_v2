// -----------------------------------------------------------------------------
// fsm_module.v
// Digital doorlock FSM with password comparator, password change logic,
// attempt counter, 10-second auto-lock timer, and 10-second input inactivity timer.
//
// Clock assumption: clk = 1 kHz.
// Default password: 1234, stored as 16'h1234 in 4-digit BCD format.
//
// Added behavior:
// - UNLOCK state: 10 seconds elapsed -> IDLE
// - INPUT state : no key/enter activity for 10 seconds -> cancel input and return IDLE
// - CHANGE state: no key/enter activity for 10 seconds -> cancel change and return IDLE
// -----------------------------------------------------------------------------
module fsm_module #(
parameter integer AUTO_LOCK_TICKS = 10000,
parameter integer INPUT_TIMEOUT_TICKS = 10000,
// [수정됨] ALARM 상태를 10초 동안만 유지하기 위한 타이머 파라미터 추가
parameter integer ALARM_TIMEOUT_TICKS = 10000
)(
input wire clk,
input wire rst,

input  wire [3:0] digit_in,
input  wire       key_valid,
input  wire       enter,
input  wire       change,
input  wire       auto_open,

output reg        unlock_on,
output reg        alarm_on,
output reg        key_led,
output reg  [3:0] input_count_led,
output reg  [2:0] state
);

localparam IDLE   = 3'd0;
localparam INPUT  = 3'd1;
localparam CHECK  = 3'd2;
localparam UNLOCK = 3'd3;
localparam ALARM  = 3'd4;
localparam CHANGE = 3'd5;

reg [15:0] input_buffer;
reg [15:0] saved_password;
reg [2:0]  digit_count;   // 0~4. 4 means exactly four digits have been entered.
reg [1:0]  fail_count;    // 0,1,2. If fail_count==2 and one more fail occurs -> ALARM.

reg key_prev;
reg enter_prev;
reg change_prev;
reg auto_open_prev;

wire key_pulse;
wire enter_pulse;
wire change_pulse;
wire auto_open_pulse;

wire auto_lock_enable;
wire auto_lock_timeout;

wire input_timer_enable;
wire input_timer_clear;
wire input_timeout;

// [수정됨] ALARM 전용 10초 타이머 신호 추가
wire alarm_timer_enable;
wire alarm_timeout;

assign key_pulse       = key_valid & ~key_prev;
assign enter_pulse     = enter & ~enter_prev;
assign change_pulse    = change & ~change_prev;
assign auto_open_pulse = auto_open & ~auto_open_prev;

// Door-open timer: counts only while the door is unlocked.
assign auto_lock_enable = (state == UNLOCK);

auto_lock_timer #(
    .TIMEOUT_TICKS(AUTO_LOCK_TICKS)
) AUTO_LOCK_TIMER (
    .clk(clk),
    .rst(rst),
    .enable(auto_lock_enable),
    .timeout(auto_lock_timeout)
);

// Input inactivity timer:
// INPUT  : user is entering the current password.
// CHANGE : user is entering a new password.
// Any key/enter/auto_open activity restarts the inactivity timer.
assign input_timer_enable = (state == INPUT) || (state == CHANGE);
assign input_timer_clear  = rst || key_pulse || enter_pulse || auto_open_pulse;

auto_lock_timer #(
    .TIMEOUT_TICKS(INPUT_TIMEOUT_TICKS)
) INPUT_TIMEOUT_TIMER (
    .clk(clk),
    .rst(input_timer_clear),
    .enable(input_timer_enable),
    .timeout(input_timeout)
);

// [수정됨] ALARM 상태일 때만 10초 타이머가 동작하도록 enable 조건 추가
assign alarm_timer_enable = (state == ALARM);

// [수정됨] ALARM 10초 지속 후 자동으로 IDLE로 복귀시키기 위한 타이머 추가
// 기존 auto_lock_timer 모듈을 재사용하므로 top_module은 수정하지 않아도 됩니다.
auto_lock_timer #(
    .TIMEOUT_TICKS(ALARM_TIMEOUT_TICKS)
) ALARM_TIMER (
    .clk(clk),
    .rst(rst),
    .enable(alarm_timer_enable),
    .timeout(alarm_timeout)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        key_prev       <= 1'b0;
        enter_prev     <= 1'b0;
        change_prev    <= 1'b0;
        auto_open_prev <= 1'b0;
    end else begin
        key_prev       <= key_valid;
        enter_prev     <= enter;
        change_prev    <= change;
        auto_open_prev <= auto_open;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state           <= IDLE;
        input_buffer    <= 16'd0;
        saved_password  <= 16'h1234;
        digit_count     <= 3'd0;
        fail_count      <= 2'd0;
        unlock_on       <= 1'b0;
        alarm_on        <= 1'b0;
        key_led         <= 1'b0;
        input_count_led <= 4'b0000;
    end else begin
        key_led <= 1'b0;

        case (state)
            IDLE: begin
                unlock_on       <= 1'b0;
                alarm_on        <= 1'b0;
                input_buffer    <= 16'd0;
                digit_count     <= 3'd0;
                input_count_led <= 4'b0000;

                if (auto_open_pulse) begin
                    unlock_on <= 1'b1;
                    state     <= UNLOCK;
                end else if (key_pulse) begin
                    input_buffer    <= {12'd0, digit_in};
                    digit_count     <= 3'd1;
                    input_count_led <= 4'b0001;
                    key_led         <= 1'b1;
                    state           <= INPUT;
                end
            end

            INPUT: begin
                if (input_timeout) begin
                    // 10 seconds with no input activity: cancel password entry.
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    unlock_on       <= 1'b0;
                    state           <= IDLE;
                end else if (auto_open_pulse) begin
                    unlock_on       <= 1'b1;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    state           <= UNLOCK;
                end else if (key_pulse) begin
                    key_led <= 1'b1;

                    // Accept up to exactly 4 digits. Extra digits are ignored until ENTER.
                    if (digit_count < 3'd4) begin
                        input_buffer <= {input_buffer[11:0], digit_in};
                        digit_count  <= digit_count + 3'd1;

                        case (digit_count + 3'd1)
                            3'd1: input_count_led <= 4'b0001;
                            3'd2: input_count_led <= 4'b0011;
                            3'd3: input_count_led <= 4'b0111;
                            default: input_count_led <= 4'b1111;
                        endcase
                    end
                end else if (enter_pulse && digit_count == 3'd4) begin
                    state <= CHECK;
                end
                // If ENTER is pressed before 4 digits, stay in INPUT and wait for more digits.
            end

            CHECK: begin
                // Password comparator.
                if (input_buffer == saved_password) begin
                    unlock_on  <= 1'b1;
                    alarm_on   <= 1'b0;
                    fail_count <= 2'd0;
                    state      <= UNLOCK;
                end else begin
                    unlock_on <= 1'b0;

                    // Attempt counter: 3rd failure enters ALARM.
                    if (fail_count == 2'd2) begin
                        alarm_on <= 1'b1;
                        state    <= ALARM;
                    end else begin
                        fail_count      <= fail_count + 2'd1;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end
                end
            end

            UNLOCK: begin
                unlock_on <= 1'b1;
                alarm_on  <= 1'b0;

                // Auto-lock has highest priority in UNLOCK state.
                if (auto_lock_timeout) begin
                    unlock_on       <= 1'b0;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    state           <= IDLE;
                end else if (change_pulse) begin
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    state           <= CHANGE;
                end else if (enter_pulse) begin
                    unlock_on       <= 1'b0;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    state           <= IDLE;
                end
            end

            ALARM: begin
                // [기존 코드]
                // alarm_on  <= 1'b1;
                // unlock_on <= 1'b0;
                // state     <= ALARM;
                //
                // [문제점]
                // 기존 코드는 ALARM 상태를 계속 유지하므로 RESET_N을 누르기 전까지 경보가 해제되지 않았습니다.
                //
                // [수정됨]
                // ALARM 상태에서는 별도의 키 입력 처리를 하지 않습니다.
                // 따라서 숫자키, ENTER, CHANGE, AUTO_OPEN 입력은 모두 무시됩니다.
                // alarm_timeout이 1이 되면, 즉 1kHz 기준 10000 tick = 10초가 지나면 IDLE로 복귀합니다.

                alarm_on        <= 1'b1;
                unlock_on       <= 1'b0;
                input_buffer    <= 16'd0;
                digit_count     <= 3'd0;
                input_count_led <= 4'b0000;

                if (alarm_timeout) begin
                    alarm_on   <= 1'b0;
                    fail_count <= 2'd0;
                    state      <= IDLE;
                end else begin
                    state <= ALARM;
                end
            end

            CHANGE: begin
                unlock_on <= 1'b1;
                alarm_on  <= 1'b0;

                if (input_timeout) begin
                    // 10 seconds with no input activity: cancel password change.
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    unlock_on       <= 1'b0;
                    state           <= IDLE;
                end else if (key_pulse) begin
                    key_led <= 1'b1;

                    // Accept up to exactly 4 digits. Extra digits are ignored until ENTER.
                    if (digit_count < 3'd4) begin
                        input_buffer <= {input_buffer[11:0], digit_in};
                        digit_count  <= digit_count + 3'd1;

                        case (digit_count + 3'd1)
                            3'd1: input_count_led <= 4'b0001;
                            3'd2: input_count_led <= 4'b0011;
                            3'd3: input_count_led <= 4'b0111;
                            default: input_count_led <= 4'b1111;
                        endcase
                    end
                end else if (enter_pulse && digit_count == 3'd4) begin
                    // Password change logic: save only after exactly four digits.
                    saved_password  <= input_buffer;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    unlock_on       <= 1'b0;
                    state           <= IDLE;
                end
                // If ENTER is pressed before 4 digits, stay in CHANGE and wait for more digits.
            end

            default: begin
                state           <= IDLE;
                input_buffer    <= 16'd0;
                digit_count     <= 3'd0;
                input_count_led <= 4'b0000;
                unlock_on       <= 1'b0;
                alarm_on        <= 1'b0;
            end
        endcase
    end
end
endmodule
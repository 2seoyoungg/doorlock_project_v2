// led_controller.v  (ASCII-only, comments removed for old Quartus)
// 16-LED state display. Same state encoding as the team FSM.
//   IDLE=all on, INPUT=progress bar, CHECK=lower 8, UNLOCK=all off,
//   ALARM=blink all, CHANGE=alternate upper/lower 8.

module led_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  state,
    input  wire [2:0]  input_cnt,
    input  wire        blink,
    output reg  [15:0] led
);
    localparam S_IDLE   = 3'd0, S_INPUT = 3'd1, S_CHECK = 3'd2,
               S_UNLOCK = 3'd3, S_ALARM = 3'd4, S_CHANGE = 3'd5;

    always @(*) begin
        case (state)
            S_IDLE   : led = 16'hFFFF;
            S_INPUT  : led = (16'h0001 << input_cnt) - 16'h0001;
            S_CHECK  : led = 16'h00FF;
            S_UNLOCK : led = 16'h0000;
            S_ALARM  : led = blink ? 16'hFFFF : 16'h0000;
            S_CHANGE : led = blink ? 16'h00FF : 16'hFF00;
            default  : led = 16'h0000;
        endcase
    end
endmodule
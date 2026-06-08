module fnd_driver #(
    parameter integer SCAN_DIV    = 1,
    parameter integer BLINK_DIV   = 100,
    parameter integer LOCK_CYCLES = 10000
) (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [2:0]  fsm_state,
    input  wire        mask_enable,
    input  wire [2:0]  input_count,
    input  wire [15:0] digit_data,
    input  wire        lock,
    output wire [7:0]  fnd_seg,
    output wire [3:0]  fnd_com,
    output wire [7:0]  fnd1_seg
);

    localparam [3:0] C_DASH  = 4'b1011;
    localparam [3:0] C_BLANK = 4'b1100;

    wire        s_scan_tick;
    wire        s_blink_tick;
    wire [1:0]  s_digit_sel;
    wire [15:0] s_disp_digits;
    reg  [3:0]  s_cur_digit;

    reg         lock_active;
    reg  [31:0] lock_cnt;
    reg         lock_d;
    wire        lock_rise = lock & ~lock_d;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lock_active <= 1'b0;
            lock_cnt    <= 32'd0;
            lock_d      <= 1'b0;
        end else begin
            lock_d <= lock;
            if (!lock_active) begin
                if (lock_rise) begin
                    lock_active <= 1'b1;
                    lock_cnt    <= 32'd0;
                end
            end else begin
                if (lock_cnt == (LOCK_CYCLES - 1)) begin
                    lock_active <= 1'b0;
                    lock_cnt    <= 32'd0;
                end else begin
                    lock_cnt <= lock_cnt + 32'd1;
                end
            end
        end
    end

    clk_divider #(
        .SCAN_DIV  (SCAN_DIV),
        .BLINK_DIV (BLINK_DIV)
    ) U_DIV (
        .clk        (clk),
        .reset_n    (reset_n),
        .scan_tick  (s_scan_tick),
        .blink_tick (s_blink_tick)
    );

    digit_scanner U_SCAN (
        .clk       (clk),
        .reset_n   (reset_n),
        .scan_tick (s_scan_tick),
        .digit_sel (s_digit_sel),
        .fnd_com   (fnd_com)
    );

    display_policy U_POL (
        .fsm_state   (fsm_state),
        .mask_enable (mask_enable),
        .input_count (input_count),
        .digit_data  (digit_data),
        .blink_tick  (s_blink_tick),
        .lockout     (lock_active),
        .disp_digits (s_disp_digits)
    );

    always @* begin
        case (s_digit_sel)
            2'b00  : s_cur_digit = s_disp_digits[15:12];
            2'b01  : s_cur_digit = s_disp_digits[11: 8];
            2'b10  : s_cur_digit = s_disp_digits[ 7: 4];
            2'b11  : s_cur_digit = s_disp_digits[ 3: 0];
            default: s_cur_digit = C_DASH;
        endcase
    end

    seg7_decoder U_DEC (
        .digit_in (s_cur_digit),
        .seg_out  (fnd_seg)
    );

    wire [3:0] s_fnd1_code = lock_active ? C_DASH : C_BLANK;

    seg7_decoder U_DEC1 (
        .digit_in (s_fnd1_code),
        .seg_out  (fnd1_seg)
    );

endmodule

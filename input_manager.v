module input_manager #(
    parameter integer CLK_FREQ_HZ  = 1000,
    parameter integer DEBOUNCE_MS  = 20,
    parameter integer LOCK_TIMEOUT = 10000  // 10s at 1 kHz
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire [12:0] tact_sw,
    input  wire        lock,
    output wire [3:0]  digit_in,
    output wire        key_valid,
    output wire        enter,
    output wire        change,
    output wire        auto_open
);
    wire [12:0] btn_state;
    genvar i;
    generate
        for (i = 0; i < 13; i = i + 1) begin : debouncers
            button_debounce #(
                .CLK_FREQ_HZ(CLK_FREQ_HZ),
                .DEBOUNCE_MS(DEBOUNCE_MS)
            ) u_db (
                .clk(clk),
                .reset_n(reset_n),
                .btn_in(tact_sw[i]),
                .btn_state(btn_state[i]),
                .btn_pulse()
            );
        end
    endgenerate

    // ---- ALARM lock timeout : release lock after LOCK_TIMEOUT ticks ----
    reg [13:0] lock_cnt;    // max 16383, enough for 10000
    reg        lock_prev;
    reg        lock_release;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lock_cnt    <= 14'd0;
            lock_prev   <= 1'b0;
            lock_release <= 1'b0;
        end else begin
            lock_prev <= lock;

            if (lock && !lock_prev) begin
                // rising edge of lock: start timer, clear release
                lock_cnt    <= 14'd0;
                lock_release <= 1'b0;
            end else if (lock && !lock_release) begin
                if (lock_cnt >= LOCK_TIMEOUT - 1) begin
                    lock_release <= 1'b1;
                end else begin
                    lock_cnt <= lock_cnt + 14'd1;
                end
            end else if (!lock) begin
                // lock deasserted (rst): reset everything
                lock_cnt    <= 14'd0;
                lock_release <= 1'b0;
            end
        end
    end

    // effective_lock: lock is active only while timer has not expired
    wire effective_lock = lock && !lock_release;

    assign key_valid = (|btn_state[9:0]) && !effective_lock;
    assign digit_in  =
        btn_state[0] ? 4'd0 :
        btn_state[1] ? 4'd1 :
        btn_state[2] ? 4'd2 :
        btn_state[3] ? 4'd3 :
        btn_state[4] ? 4'd4 :
        btn_state[5] ? 4'd5 :
        btn_state[6] ? 4'd6 :
        btn_state[7] ? 4'd7 :
        btn_state[8] ? 4'd8 :
        btn_state[9] ? 4'd9 :
                       4'd0;
    assign enter     = btn_state[10] && !effective_lock;
    assign change    = btn_state[11] && !effective_lock;
    assign auto_open = btn_state[12] && !effective_lock;

endmodule
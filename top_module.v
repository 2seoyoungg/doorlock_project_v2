module top_module(
    input  wire        clk_1khz,
    input  wire        RESET_N,
    input  wire [12:0] TACT_SW,

    output wire [15:0] LEDR,        // 16 board LEDs (LED1..LED16)
    output wire [7:0]  FND_SEG,
    output wire [3:0]  FND_COM,
	 output wire        lcd_rs,
	 output wire        lcd_rw,
	 output wire        lcd_e,
	 output wire [7:0]  lcd_data,

    output wire        piezo
);

    wire rst;
    assign rst = ~RESET_N;          // active-low board reset -> active-high rst

    // ---- input module (B, corrected): clean debounced signals ----
    wire        key_valid;
    wire [3:0]  digit_in;
    wire        enter;
    wire        change;
    wire        auto_open;

    input_manager #(.CLK_FREQ_HZ(1000), .DEBOUNCE_MS(20), .LOCK_TIMEOUT(10000)) U_INPUT (
        .clk(clk_1khz), .reset_n(RESET_N), .tact_sw(TACT_SW),
        .lock(alarm_on),
        .digit_in(digit_in), .key_valid(key_valid),
        .enter(enter), .change(change), .auto_open(auto_open)
    );

    // ---- main FSM (C: password logic + 10s auto-lock + input timeout) ----
    wire unlock_on, alarm_on, key_led;
    wire [3:0] input_count_led;
    wire [2:0] state;
    wire [15:0] disp_code;          // [FIX] carries entered digits FSM -> FND

    fsm_module #(.AUTO_LOCK_TICKS(10000), .INPUT_TIMEOUT_TICKS(10000)) FSM (
        .clk(clk_1khz), .rst(rst),
        .digit_in(digit_in), .key_valid(key_valid),
        .enter(enter), .change(change), .auto_open(auto_open),
        .unlock_on(unlock_on), .alarm_on(alarm_on), .key_led(key_led),
        .input_count_led(input_count_led), .state(state),
        .disp_code(disp_code)        // [FIX] expose entered digits to the FND
    );

    // ---- FND output (E adapter) ----
    fnd_team_adapter U_FND (
        .clk(clk_1khz), .rst(rst), .state(state),
        .input_count_led(input_count_led),
        // [FIX] alarm_on was left unconnected, so the adapter's lock input floated
        //       and forced display_policy into its lockout branch -> permanent dashes
        //       and an apparently "dead" FND. Connect it explicitly.
        .alarm_on(alarm_on),
        // [FIX] feed the real entered digits so the input value shows on the FND.
        .digit_data(disp_code),
        .fnd_seg(FND_SEG), .fnd_com(FND_COM)
    );

    // ---- digit count 0..4 (popcount of thermometer) for LED progress bar ----
    wire [2:0] input_cnt;
    assign input_cnt = {2'b00, input_count_led[0]} + {2'b00, input_count_led[1]}
                     + {2'b00, input_count_led[2]} + {2'b00, input_count_led[3]};

    // ---- blink generator ~3 Hz at 1 kHz (for LED ALARM/CHANGE) ----
    reg [9:0] blink_cnt;
    reg       blink;
    always @(posedge clk_1khz or posedge rst) begin
        if (rst) begin
            blink_cnt <= 10'd0;
            blink     <= 1'b0;
        end else if (blink_cnt >= 10'd166) begin   // 166 ms half-period
            blink_cnt <= 10'd0;
            blink     <= ~blink;
        end else begin
            blink_cnt <= blink_cnt + 10'd1;
        end
    end

    // ---- LED output (F, hyeon's approach): 16-LED state patterns ----
    led_controller U_LED (
        .clk(clk_1khz), .rst_n(RESET_N),
        .state(state), .input_cnt(input_cnt), .blink(blink),
        .led(LEDR)
    );

    // ---- Piezo alarm (F, adapted for 1 kHz): beeps while in ALARM ----
    piezo_alarm U_PIEZO (
        .clk(clk_1khz),
        .rst(rst),
        .alarm_on(alarm_on),
        .piezo(piezo)
    );
	 
	 // ---- LCD output (D) ----

	lcd_controller #(.CLK_HZ(1_000)) U_LCD (
		 .clk      (clk_1khz),
		 .rst_n    (RESET_N),         
		 .state    (state),
		 .input_cnt(input_count_led),
		 .lcd_rs   (lcd_rs),
		 .lcd_rw   (lcd_rw),
		 .lcd_e    (lcd_e),
		 .lcd_data (lcd_data)
	);
	 

endmodule

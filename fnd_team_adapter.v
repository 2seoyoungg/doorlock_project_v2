module fnd_team_adapter (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  state,
    input  wire [3:0]  input_count_led,
    input  wire        alarm_on,
    output wire [7:0]  fnd_seg,
    output wire [3:0]  fnd_com,
    output wire [7:0]  fnd1_seg
);

    wire reset_n_int = ~rst;

    wire [2:0] input_count_int =
          {2'b00, input_count_led[0]}
        + {2'b00, input_count_led[1]}
        + {2'b00, input_count_led[2]}
        + {2'b00, input_count_led[3]};

    fnd_driver #(
        .SCAN_DIV    (1),
        .BLINK_DIV   (100),
        .LOCK_CYCLES (10000)
    ) U_FND (
        .clk         (clk),
        .reset_n     (reset_n_int),
        .fsm_state   (state),
        .mask_enable (1'b0),
        .input_count (input_count_int),
        .digit_data  (16'h0000),
        .lock        (alarm_on),
        .fnd_seg     (fnd_seg),
        .fnd_com     (fnd_com),
        .fnd1_seg    (fnd1_seg)
    );

endmodule

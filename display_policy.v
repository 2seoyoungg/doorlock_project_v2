module display_policy (
    input  wire [2:0]  fsm_state,
    input  wire        mask_enable,
    input  wire [2:0]  input_count,
    input  wire [15:0] digit_data,
    input  wire        blink_tick,
    input  wire        lockout,
    output reg  [15:0] disp_digits
);

    localparam [3:0] C_DASH  = 4'b1011;
    localparam [3:0] C_BLANK = 4'b1100;

    localparam [2:0] ST_IDLE   = 3'b000;
    localparam [2:0] ST_INPUT  = 3'b001;
    localparam [2:0] ST_CHECK  = 3'b010;
    localparam [2:0] ST_UNLOCK = 3'b011;
    localparam [2:0] ST_ALARM  = 3'b100;
    localparam [2:0] ST_CHANGE = 3'b101;

    reg [3:0] g1, g2, g3, g4;
    always @* begin
        g1 = (input_count >= 3'd1) ? (mask_enable ? C_DASH : digit_data[15:12]) : C_DASH;
        g2 = (input_count >= 3'd2) ? (mask_enable ? C_DASH : digit_data[11: 8]) : C_DASH;
        g3 = (input_count >= 3'd3) ? (mask_enable ? C_DASH : digit_data[ 7: 4]) : C_DASH;
        g4 = (input_count >= 3'd4) ? (mask_enable ? C_DASH : digit_data[ 3: 0]) : C_DASH;
    end

    always @* begin
        disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};

        if (lockout) begin
            disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
        end else begin
            case (fsm_state)
                ST_IDLE: begin
                    disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
                end

                ST_INPUT, ST_CHANGE: begin
                    disp_digits = {g1, g2, g3, g4};
                end

                ST_CHECK: begin
                    if (blink_tick)
                        disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
                    else
                        disp_digits = {C_BLANK, C_BLANK, C_BLANK, C_BLANK};
                end

                ST_UNLOCK: begin
                    disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
                end

                ST_ALARM: begin
                    disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
                end

                default: begin
                    disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
                end
            endcase
        end
    end

endmodule

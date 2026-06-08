module clk_divider #(
    parameter integer SCAN_DIV  = 1000,
    parameter integer BLINK_DIV = 100000
) (
    input  wire clk,
    input  wire reset_n,
    output reg  scan_tick,
    output wire blink_tick
);

    reg [19:0] scan_cnt;
    reg [19:0] blink_cnt;
    reg        blink_lvl;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            scan_cnt  <= 20'd0;
            scan_tick <= 1'b0;
        end else begin
            if (scan_cnt == (SCAN_DIV - 1)) begin
                scan_cnt  <= 20'd0;
                scan_tick <= 1'b1;
            end else begin
                scan_cnt  <= scan_cnt + 20'd1;
                scan_tick <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            blink_cnt <= 20'd0;
            blink_lvl <= 1'b0;
        end else begin
            if (blink_cnt == (BLINK_DIV - 1)) begin
                blink_cnt <= 20'd0;
                blink_lvl <= ~blink_lvl;
            end else begin
                blink_cnt <= blink_cnt + 20'd1;
            end
        end
    end

    assign blink_tick = blink_lvl;

endmodule

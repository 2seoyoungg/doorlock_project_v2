module button_debounce #(
    parameter integer CLK_FREQ_HZ = 50000000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  wire clk,
    input  wire reset_n,
    input  wire btn_in,
    output reg  btn_state,
    output reg  btn_pulse
);

    localparam integer MAX_COUNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    reg sync_0;
    reg sync_1;
    reg prev_btn;
    reg [$clog2(MAX_COUNT + 1)-1:0] counter;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sync_0    <= 1'b0;
            sync_1    <= 1'b0;
            btn_state <= 1'b0;
            prev_btn  <= 1'b0;
            counter   <= {($clog2(MAX_COUNT + 1)){1'b0}};
            btn_pulse <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
            btn_pulse <= 1'b0;

            if (sync_1 == btn_state) begin
                counter <= {($clog2(MAX_COUNT + 1)){1'b0}};
            end else if (counter == MAX_COUNT[$clog2(MAX_COUNT + 1)-1:0]) begin
                btn_state <= sync_1;
                counter <= {($clog2(MAX_COUNT + 1)){1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end

            if (!prev_btn && btn_state) begin
                btn_pulse <= 1'b1;
            end

            prev_btn <= btn_state;
        end
    end

endmodule
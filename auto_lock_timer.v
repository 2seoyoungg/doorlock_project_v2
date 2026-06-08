// -----------------------------------------------------------------------------
// auto_lock_timer.v
// Auto-lock timer for the FPGA doorlock project.
// clk is assumed to be 1 kHz. 10 seconds = 10,000 ticks.
//
// enable=1  : timer counts
// enable=0  : timer clears
// timeout=1 : asserted after TIMEOUT_TICKS cycles while enable remains high
// -----------------------------------------------------------------------------
module auto_lock_timer #(
    parameter integer TIMEOUT_TICKS = 10000
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  timeout
);

    reg [31:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else if (!enable) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else if (count >= TIMEOUT_TICKS - 1) begin
            count   <= count;
            timeout <= 1'b1;
        end else begin
            count   <= count + 32'd1;
            timeout <= 1'b0;
        end
    end

endmodule

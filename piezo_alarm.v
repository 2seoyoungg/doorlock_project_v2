// piezo_alarm.v - audible alarm for a 1 kHz system clock.
// Adapted from the alarm teammate's "alarm_denied" concept. The original
// toggled the piezo every 50000 clocks, which assumes a fast (MHz) clock; at
// 1 kHz that would be a 100-second period (inaudible). Here the piezo is a
// ~500 Hz square wave (toggles each 1 kHz tick) that beeps on/off (~0.2 s)
// while alarm_on = 1, and is silent otherwise.
module piezo_alarm(
    input  wire clk,        // 1 kHz system clock
    input  wire rst,        // active-high reset
    input  wire alarm_on,   // from FSM: high in ALARM state
    output reg  piezo
);
    reg       tone;
    reg [7:0] beat;
    reg       gate;
	 reg [15:0] total;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tone  <= 1'b0;
            beat  <= 8'd0;
            gate  <= 1'b0;
				total <= 16'd0;
            piezo <= 1'b0;
	     end else begin
        tone <= ~tone;
        if (alarm_on && total < 16'd3000) begin
            total <= total + 16'd1;
            if (beat >= 8'd200) begin
                beat <= 8'd0;
                gate <= ~gate;
            end else begin
                beat <= beat + 8'd1;
            end
            piezo <= gate ? tone : 1'b0;
        end else begin
            beat  <= 8'd0;
            gate  <= 1'b0;
            piezo <= 1'b0;
        end
    end
end
endmodule
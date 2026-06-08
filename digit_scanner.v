module digit_scanner (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        scan_tick,
    output wire [1:0]  digit_sel,
    output reg  [3:0]  fnd_com
);

    reg [1:0] sel_r;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            sel_r <= 2'b00;
        else if (scan_tick)
            sel_r <= sel_r + 2'b01;
    end

    assign digit_sel = sel_r;

    always @* begin
        case (sel_r)
            2'b00  : fnd_com = 4'b1110;
            2'b01  : fnd_com = 4'b1101;
            2'b10  : fnd_com = 4'b1011;
            2'b11  : fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule

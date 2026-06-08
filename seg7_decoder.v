module seg7_decoder (
    input  wire [3:0] digit_in,
    output reg  [7:0] seg_out
);

    always @* begin
        case (digit_in)
            4'h0 : seg_out = 8'b11111100;
            4'h1 : seg_out = 8'b01100000;
            4'h2 : seg_out = 8'b11011010;
            4'h3 : seg_out = 8'b11110010;
            4'h4 : seg_out = 8'b01100110;
            4'h5 : seg_out = 8'b10110110;
            4'h6 : seg_out = 8'b10111110;
            4'h7 : seg_out = 8'b11100000;
            4'h8 : seg_out = 8'b11111110;
            4'h9 : seg_out = 8'b11110110;
            4'hA : seg_out = 8'b11111110;
            4'hB : seg_out = 8'b00000010;
            4'hC : seg_out = 8'b00000000;
            4'hD : seg_out = 8'b10001110;
            4'hE : seg_out = 8'b11101110;
            4'hF : seg_out = 8'b00011100;
            default: seg_out = 8'b00000000;
        endcase
    end

endmodule

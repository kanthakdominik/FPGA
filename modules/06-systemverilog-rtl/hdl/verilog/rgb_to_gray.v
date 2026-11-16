// Konwersja piksela RGB na odcień szarości — Verilog bez typów: pola wybierane wycinkami, tryby jako localparam.
`default_nettype none

module rgb_to_gray (
    input  wire [23:0] pix_raw,                    // {r, g, b}
    input  wire [1:0]  mode,
    output reg  [7:0]  y
);
    localparam [1:0] GRAY_AVG = 2'd0, GRAY_LUMA = 2'd1, GRAY_RED = 2'd2;

    wire [7:0]  r = pix_raw[23:16];
    wire [7:0]  g = pix_raw[15:8];
    wire [7:0]  b = pix_raw[7:0];
    wire [9:0]  sum  = r + 2 * g + b;              // lewa strona 10 bitów: suma się mieści
    wire [15:0] luma = 16'd77 * r + 16'd150 * g + 16'd29 * b;

    always @* begin
        case (mode)
            GRAY_AVG:  y = sum[9:2];
            GRAY_LUMA: y = luma[15:8];
            GRAY_RED:  y = r;
            default:   y = 8'd0;
        endcase
    end
endmodule

`default_nettype wire

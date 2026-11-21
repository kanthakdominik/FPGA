// Sprite 16×16 (24.03): obrazek 2 bity na piksel w ROM (0 — przezroczysty, 1–3 — indeks palety), położenie
// lewego górnego rogu (sx, sy). Dla piksela (x, y) wyjścia widoczny i kolor z opóźnieniem 1 taktu.
// Różnice x - sx, y - sy liczone modulo 2^12: piksele na lewo/powyżej dają duże liczby, więc wystarcza
// jedno porównanie < 16.
`default_nettype none

module sprite16 (
    input  wire        clk,
    input  wire [11:0] x,
    input  wire [11:0] y,
    input  wire [11:0] sx,
    input  wire [11:0] sy,
    output reg         widoczny,
    output reg  [1:0]  kolor
);
    function [31:0] wiersz(input [3:0] r);
        case (r)
            4'd0:  wiersz = 32'h00155400;   // .....aaaaaa.....
            4'd1:  wiersz = 32'h016AA940;   // ...aabbbbbbaa...
            4'd2:  wiersz = 32'h06AAAA90;   // ..abbbbbbbbbba..
            4'd3:  wiersz = 32'h1AAAAAA4;   // .abbbbbbbbbbbba.
            4'd4:  wiersz = 32'h1AFEBFA4;   // .abbcccbbcccbba.
            4'd5:  wiersz = 32'h6ADEB7A9;   // abbbcacbbcacbbba
            4'd6:  wiersz = 32'h6AFEBFA9;   // abbbcccbbcccbbba
            4'd7:  wiersz = 32'h6AAAAAA9;   // abbbbbbbbbbbbbba
            4'd8:  wiersz = 32'h6AAAAAA9;   // abbbbbbbbbbbbbba
            4'd9:  wiersz = 32'h6BAAAAE9;   // abbcbbbbbbbbcbba
            4'd10: wiersz = 32'h6AEAABA9;   // abbbcbbbbbbcbbba
            4'd11: wiersz = 32'h1ABFFEA4;   // .abbbccccccbbba.
            4'd12: wiersz = 32'h1AAAAAA4;   // .abbbbbbbbbbbba.
            4'd13: wiersz = 32'h06AAAA90;   // ..abbbbbbbbbba..
            4'd14: wiersz = 32'h016AA940;   // ...aabbbbbbaa...
            4'd15: wiersz = 32'h00155400;   // .....aaaaaa.....
        endcase
    endfunction

    wire [11:0] dx = x - sx;
    wire [11:0] dy = y - sy;
    wire        w  = (dx < 12'd16) && (dy < 12'd16);
    wire [31:0] r  = wiersz(dy[3:0]);
    wire [1:0]  k  = r[{~dx[3:0], 1'b1} -: 2];      // piksel 0 w bitach 31..30
    always @(posedge clk) begin
        widoczny <= w && (k != 2'd0);
        kolor    <= k;
    end
endmodule

`default_nettype wire

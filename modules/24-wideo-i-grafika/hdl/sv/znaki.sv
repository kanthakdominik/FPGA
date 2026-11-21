// Nakładka tekstowa (24.03): pamięć znaków KOL × WIER (kody ASCII), czcionka 5×7 w komórce 8×8 pikseli,
// powiększenie 2^SK (SK = 1: komórka 16×16). Wejście: współrzędne piksela (x, y) z generatora taktowania;
// wyjście piks z opóźnieniem 2 taktów (odczyt pamięci znaków, potem wiersz czcionki). Małe litery są
// wyświetlane jako wielkie; znaki spoza czcionki — puste. Zapis: we, wadr = wiersz·KOL + kolumna, wkod.
`default_nettype none

module znaki #(
    parameter integer KOL = 40,
    parameter integer WIER = 30,
    parameter integer SK = 1
) (
    input  logic        clk,
    input  logic        we,
    input  logic [10:0] wadr,
    input  logic [7:0]  wkod,
    input  logic [11:0] x,
    input  logic [11:0] y,
    output logic         piks
);
    logic [7:0] ram [0:KOL*WIER-1];
    integer i;
    initial for (i = 0; i < KOL * WIER; i = i + 1) ram[i] = 8'h20;

    always_ff @(posedge clk)
        if (we) ram[wadr] <= wkod;

    function [34:0] glif(input [7:0] k);
        case (k)
            8'h21:   glif = 35'b00100001000010000100001000000000100;   // !
            8'h2D:   glif = 35'b00000000000000011111000000000000000;   // -
            8'h2E:   glif = 35'b00000000000000000000000000110001100;   // .
            8'h30:   glif = 35'b01110100011001110101110011000101110;   // 0
            8'h31:   glif = 35'b00100011000010000100001000010001110;   // 1
            8'h32:   glif = 35'b01110100010000100010001000100011111;   // 2
            8'h33:   glif = 35'b11111000100010000010000011000101110;   // 3
            8'h34:   glif = 35'b00010001100101010010111110001000010;   // 4
            8'h35:   glif = 35'b11111100001111000001000011000101110;   // 5
            8'h36:   glif = 35'b00110010001000011110100011000101110;   // 6
            8'h37:   glif = 35'b11111000010001000100010000100001000;   // 7
            8'h38:   glif = 35'b01110100011000101110100011000101110;   // 8
            8'h39:   glif = 35'b01110100011000101111000010001001100;   // 9
            8'h3A:   glif = 35'b00000011000110000000011000110000000;   // :
            8'h3F:   glif = 35'b01110100010000100010001000000000100;   // ?
            8'h41:   glif = 35'b01110100011000111111100011000110001;   // A
            8'h42:   glif = 35'b11110100011000111110100011000111110;   // B
            8'h43:   glif = 35'b01110100011000010000100001000101110;   // C
            8'h44:   glif = 35'b11100100101000110001100011001011100;   // D
            8'h45:   glif = 35'b11111100001000011110100001000011111;   // E
            8'h46:   glif = 35'b11111100001000011110100001000010000;   // F
            8'h47:   glif = 35'b01110100011000010111100011000101111;   // G
            8'h48:   glif = 35'b10001100011000111111100011000110001;   // H
            8'h49:   glif = 35'b01110001000010000100001000010001110;   // I
            8'h4A:   glif = 35'b00111000100001000010000101001001100;   // J
            8'h4B:   glif = 35'b10001100101010011000101001001010001;   // K
            8'h4C:   glif = 35'b10000100001000010000100001000011111;   // L
            8'h4D:   glif = 35'b10001110111010110101100011000110001;   // M
            8'h4E:   glif = 35'b10001100011100110101100111000110001;   // N
            8'h4F:   glif = 35'b01110100011000110001100011000101110;   // O
            8'h50:   glif = 35'b11110100011000111110100001000010000;   // P
            8'h51:   glif = 35'b01110100011000110001101011001001101;   // Q
            8'h52:   glif = 35'b11110100011000111110101001001010001;   // R
            8'h53:   glif = 35'b01111100001000001110000010000111110;   // S
            8'h54:   glif = 35'b11111001000010000100001000010000100;   // T
            8'h55:   glif = 35'b10001100011000110001100011000101110;   // U
            8'h56:   glif = 35'b10001100011000110001100010101000100;   // V
            8'h57:   glif = 35'b10001100011000110101101011010101010;   // W
            8'h58:   glif = 35'b10001100010101000100010101000110001;   // X
            8'h59:   glif = 35'b10001100010101000100001000010000100;   // Y
            8'h5A:   glif = 35'b11111000010001000100010001000011111;   // Z
            default: glif = 35'd0;
        endcase
    endfunction

    // stopień 1: komórka i położenie w komórce
    logic [11:0] cx;
    assign cx = x >> (3 + SK);
    logic [11:0] cy;
    assign cy = y >> (3 + SK);
    /* verilator lint_off WIDTHTRUNC */
    localparam [11:0] KOLW = KOL;
    localparam [11:0] WIERW = WIER;
    logic [10:0] adr;
    assign adr = cy * KOLW + cx;
    /* verilator lint_on WIDTHTRUNC */
    logic  [7:0]  kod;
    logic  [2:0]  fx, fy;
    logic         w1;
    always_ff @(posedge clk) begin
        kod <= ram[adr];
        fx  <= x[SK +: 3];
        fy  <= y[SK +: 3];
        w1  <= (cx < KOLW) && (cy < WIERW);
    end

    // stopień 2: bit czcionki
    logic [7:0]  kod_w;
    assign kod_w = (kod >= 8'h61 && kod <= 8'h7A) ? kod - 8'h20 : kod;
    logic [34:0] g;
    assign g = glif(kod_w);
    logic [5:0]  idx;
    assign idx = {1'b0, fy, 2'b00} + {3'b000, fy} + {3'b000, fx};
    always_ff @(posedge clk)
        piks <= w1 && (fx < 3'd5) && (fy < 3'd7) && g[6'd34 - idx];
endmodule

`default_nettype wire

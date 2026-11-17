// Pułapka 2 (17.05): opóźnienia (#) w kodzie syntezowalnym. Symulator je wykonuje — tu wynik pojawia
// się 12 ns po zboczu, czyli po następnym zboczu zegara 10 ns; synteza je pomija i rejestr działa
// natychmiast. Model zachowuje się jak inny układ niż sprzęt.
`timescale 1ns / 1ps
`default_nettype none

module opoznienia_zle (
    input  wire       clk,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk) q <= #12 d;
endmodule

module opoznienia_dobrze (
    input  wire       clk,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk) q <= d;
endmodule

`default_nettype wire

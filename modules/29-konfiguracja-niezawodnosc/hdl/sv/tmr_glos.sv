// Głosowanie większościowe 2 z 3 (29.04): y = (a & b) | (a & c) | (b & c) bit po bicie; niezgodny = 1, gdy
// któraś kopia różni się od pozostałych (sygnał diagnostyczny — błąd pojedynczy jest maskowany).
`default_nettype none

module tmr_glos #(
    parameter integer W = 16
) (
    input  logic [W-1:0] a,
    input  logic [W-1:0] b,
    input  logic [W-1:0] c,
    output logic [W-1:0] y,
    output logic         niezgodny
);
    assign y         = (a & b) | (a & c) | (b & c);
    assign niezgodny = (a != b) || (a != c);
endmodule

`default_nettype wire

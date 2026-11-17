// Pułapka 3 (17.05): X-optymizm. Rejestr wyboru bez resetu ma w symulacji wartość X, a instrukcja if
// traktuje X jak fałsz — RTL wybiera gałąź else i wygląda poprawnie. Netlista (multiplekser) z X na
// wejściu wyboru daje X, a sprzęt — wartość zależną od stanu po konfiguracji. Błąd brakującego resetu
// jest ukryty w symulacji RTL.
`default_nettype none

module x_optymizm_zle (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire       sel_in,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
    reg sel_r;                                   // bez resetu
    always @(posedge clk) if (load) sel_r <= sel_in;
    always @(posedge clk) if (sel_r) y <= a; else y <= b;
endmodule

module x_optymizm_dobrze (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire       sel_in,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
    reg sel_r;
    always @(posedge clk)
        if (rst)       sel_r <= 1'b0;
        else if (load) sel_r <= sel_in;
    always @(posedge clk) if (sel_r) y <= a; else y <= b;
endmodule

`default_nettype wire

// Aproksymacja funkcji interpolacją liniową z tablic (19.06): x (F bitów bez znaku) dzielone na numer
// odcinka k (S starszych bitów) i położenie w odcinku frac (F-S bitów); y = baza[k] + nachyl[k]·frac / 2^(F-S)
// z zaokrągleniem i nasyceniem do 2^WY - 1. Tablice z plików (gen_aproks.py): domyślnie sin(πx/2)
// na [0, 1), 64 odcinki — największy błąd 3,8 LSB przy 16 bitach (sama tablica 64 słów: 804 LSB).
// Potok 3 takty: odczyt tablic (blok pamięci), mnożenie (blok mnożarki), dodawanie z nasyceniem.
`default_nettype none

module interp_lin #(
    parameter F      = 16,                 // bity wejścia
    parameter S      = 6,                  // bity numeru odcinka
    parameter WY     = 16,                 // bity wyjścia i tablicy bazy
    parameter WN     = 11,                 // bity tablicy nachyleń (bez znaku)
    parameter PLIK_B = "interp_baza.hex",
    parameter PLIK_N = "interp_nachyl.hex"
) (
    input  logic          clk,
    input  logic          in_valid,
    input  logic [F-1:0]  x,
    output logic           out_valid = 1'b0,
    output logic  [WY-1:0] y
);
    localparam FR = F - S;

    logic [WY-1:0] baza   [0:(1<<S)-1];
    logic [WN-1:0] nachyl [0:(1<<S)-1];
    initial begin
        $readmemh(PLIK_B, baza);
        $readmemh(PLIK_N, nachyl);
    end

    logic  [WY-1:0]    b1, b2;
    logic  [WN-1:0]    n1;
    logic  [FR-1:0]    f1;
    logic  [WN+FR-1:0] il2;
    logic              v1 = 1'b0, v2 = 1'b0;

    /* verilator lint_off UNUSEDSIGNAL */
    logic [WN+FR-1:0] il_zaokr;
    assign il_zaokr = il2 + {{WN{1'b0}}, 1'b1, {(FR-1){1'b0}}};   // + połowa LSB wyniku
    /* verilator lint_on UNUSEDSIGNAL */
    logic [WN:0]      przyrost;
    assign przyrost = {1'b0, il_zaokr[WN+FR-1:FR]};
    logic [WY:0]      suma;
    assign suma = {1'b0, b2} + {{(WY-WN){1'b0}}, przyrost};

    always_ff @(posedge clk) begin
        // 1: odczyt tablic (synchroniczny — blok pamięci)
        b1 <= baza[x[F-1:FR]];
        n1 <= nachyl[x[F-1:FR]];
        f1 <= x[FR-1:0];
        v1 <= in_valid;
        // 2: mnożenie nachylenie × położenie w odcinku
        /* verilator lint_off WIDTHEXPAND */
        il2 <= n1 * f1;
        /* verilator lint_on WIDTHEXPAND */
        b2  <= b1;
        v2  <= v1;
        // 3: dodawanie i nasycenie
        y         <= suma[WY] ? {WY{1'b1}} : suma[WY-1:0];
        out_valid <= v2;
    end
endmodule

`default_nettype wire

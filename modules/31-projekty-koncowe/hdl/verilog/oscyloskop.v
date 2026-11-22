// Projekt 2 (31.02): oscyloskop — akwizycja w domenie zegara ADC (zrzut), pamięć dwóch banków z dwoma zegarami
// (ram_2z), obraz w domenie zegara piksela (takt_wideo + ekran_osc). Przekazanie zrzutu między domenami:
// przełącznik gotowy_t i potwierdzenie potw_t przez synchronizatory, dane (bank, początek) stabilne do
// potwierdzenia, próbki w banku, którego obraz nie czyta.
`default_nettype none

module oscyloskop #(
    parameter integer AW     = 9,
    parameter integer PRZED  = 64,
    parameter integer AUTO   = 4096,
    parameter integer X0     = 64,
    parameter integer Y0     = 112,
    parameter integer H_AKT  = 640, parameter integer H_FP = 16, parameter integer H_SYNC = 96,
    parameter integer H_BP   = 48,
    parameter integer V_AKT  = 480, parameter integer V_FP = 10, parameter integer V_SYNC = 2,
    parameter integer V_BP   = 33
) (
    // domena akwizycji
    input  wire        clk_a,
    input  wire        rst_a,
    input  wire        we,
    input  wire [11:0] probka,
    input  wire [11:0] poziom,
    input  wire [7:0]  dziel,
    input  wire        tryb_auto,
    output wire        wyzwolony,
    // domena obrazu
    input  wire        clk_v,
    input  wire        rst_v,
    output wire [23:0] rgb,
    output wire        hs,
    output wire        vs,
    output wire        de,
    output wire [15:0] nr_zrzutu
);
    wire          ram_we, bank_gotowy, gotowy_t, potw_t;
    wire [AW:0]   ram_wadr, ram_radr;
    wire [7:0]    ram_wdane, ram_rdane;
    wire [AW-1:0] poczatek;

    /* verilator lint_off PINCONNECTEMPTY */
    zrzut #(.AW(AW), .PRZED(PRZED), .AUTO(AUTO)) u_zrzut (.clk(clk_a), .rst(rst_a), .we(we), .probka(probka),
        .poziom(poziom), .dziel(dziel), .tryb_auto(tryb_auto), .ram_we(ram_we), .ram_adr(ram_wadr),
        .ram_dane(ram_wdane), .bank_gotowy(bank_gotowy), .poczatek(poczatek), .wyzwolony(wyzwolony),
        .gotowy_t(gotowy_t), .potw_t(potw_t), .zajety());
    /* verilator lint_on PINCONNECTEMPTY */
    ram_2z #(.AW(AW + 1), .DW(8)) u_ram (.clk_a(clk_a), .we(ram_we), .wadr(ram_wadr), .wdane(ram_wdane),
        .clk_b(clk_v), .radr(ram_radr), .rdane(ram_rdane));

    // poziom wyzwalania do obrazu: wolnozmienne nastawy — synchronizacja dwoma przerzutnikami wystarcza do
    // pokazania linii (chwilowy błąd jednej ramki przy zmianie jest bez znaczenia)
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [11:0] poz_s1 = 12'd0;
    reg [11:0] poz_s2 = 12'd0;
    always @(posedge clk_v) begin poz_s1 <= poziom; poz_s2 <= poz_s1; end

    wire        t_hs, t_vs, t_de, t_nowa;
    wire [11:0] tx, ty;
    takt_wideo #(.H_AKT(H_AKT), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP), .V_AKT(V_AKT), .V_FP(V_FP),
                 .V_SYNC(V_SYNC), .V_BP(V_BP)) u_takt (.clk(clk_v), .rst(rst_v), .hs(t_hs), .vs(t_vs), .de(t_de),
                 .x(tx), .y(ty), .nowa_ramka(t_nowa));
    ekran_osc #(.AW(AW), .PRZED(PRZED), .X0(X0), .Y0(Y0)) u_ekran (.clk(clk_v), .rst(rst_v), .hs_we(t_hs), .vs_we(t_vs),
        .de_we(t_de), .x(tx), .y(ty), .nowa_ramka(t_nowa), .poziom(poz_s2), .gotowy_t(gotowy_t),
        .bank_gotowy(bank_gotowy), .poczatek(poczatek), .potw_t(potw_t), .ram_adr(ram_radr), .ram_dane(ram_rdane),
        .rgb(rgb), .hs(hs), .vs(vs), .de(de), .nr_zrzutu(nr_zrzutu));
endmodule

`default_nettype wire

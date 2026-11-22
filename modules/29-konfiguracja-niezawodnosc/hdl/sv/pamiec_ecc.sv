// Pamięć z ECC SECDED (39,32) i czyszczeniem w tle (scrubbing) (29.04).
//   Port użytkownika: zapis (we, adr, wdane) koduje słowo; odczyt (rd) — dane po korekcji takt później
//   (r_wazne) z flagami r_poprawiony (błąd pojedynczy, poprawiony w odczycie) i r_podwojny (wykryty, nie do poprawy).
//   Czyszczenie (czysc_en): kolejne adresy czytane drugim portem; słowo z błędem pojedynczym zapisywane z
//   powrotem poprawione — inaczej drugi błąd w tym samym słowie zrobiłby z niego błąd podwójny. Zapis
//   użytkownika ma pierwszeństwo: jeśli trafił w ten sam adres między odczytem a zapisem zwrotnym, zapis
//   zwrotny jest pomijany. skorygowane / podwojne — liczniki zdarzeń wykrytych przez czyszczenie.
//   wstrzyk — port testowy: XOR maski do zapisanego słowa (symulacja SEU w pamięci).
`default_nettype none

module pamiec_ecc #(
    parameter integer SLOWA = 64
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     we,
    input  logic                     rd,
    input  logic [$clog2(SLOWA)-1:0] adr,
    input  logic [31:0]              wdane,
    output logic [31:0]              rdane,
    output logic                     r_poprawiony,
    output logic                     r_podwojny,
    output logic                      r_wazne,
    input  logic                     czysc_en,
    output logic  [$clog2(SLOWA)-1:0] czysc_adr,
    output logic  [15:0]              skorygowane,
    output logic  [15:0]              podwojne,
    input  logic                     wstrzyk,
    input  logic [$clog2(SLOWA)-1:0] wstrzyk_adr,
    input  logic [38:0]              wstrzyk_maska
);
    localparam integer AW = $clog2(SLOWA);
    logic [38:0] pam [0:SLOWA-1];
    integer i;
    initial for (i = 0; i < SLOWA; i = i + 1) pam[i] = 39'd0;

    logic [38:0] kw;
    secded_koder u_kod (.d(wdane), .c(kw));

    // port użytkownika: odczyt rejestrowany, dekodowanie na wyjściu
    logic  [38:0] odcz_a;
    secded_dekoder u_dek_a (.c(odcz_a), .d(rdane), .poprawiony(r_poprawiony), .podwojny(r_podwojny));

    // czyszczenie: odczyt (etap 1), dekodowanie i ewentualny zapis zwrotny (etap 2)
    logic  [38:0]   odcz_b;
    logic  [AW-1:0] adr_b;
    logic           v_b, kolizja_b;
    logic [31:0]   d_b;
    logic          pop_b, podw_b;
    secded_dekoder u_dek_b (.c(odcz_b), .d(d_b), .poprawiony(pop_b), .podwojny(podw_b));
    logic [38:0]   kw_b;
    secded_koder u_kod_b (.d(d_b), .c(kw_b));
    logic          zwrot;
    assign zwrot = v_b && pop_b && !kolizja_b && !(we && adr == adr_b);

    always_ff @(posedge clk) begin
        // zapisy do pamięci: zapis zwrotny, potem wstrzyknięcie, potem użytkownik (ostatni wygrywa)
        if (zwrot) pam[adr_b] <= kw_b;
        if (wstrzyk) pam[wstrzyk_adr] <= pam[wstrzyk_adr] ^ wstrzyk_maska;
        if (we) pam[adr] <= kw;
        if (rd) odcz_a <= pam[adr];
        odcz_b <= pam[czysc_adr];
        adr_b  <= czysc_adr;
    end

    always_ff @(posedge clk)
        if (rst) begin
            r_wazne <= 1'b0; v_b <= 1'b0; kolizja_b <= 1'b0; czysc_adr <= {AW{1'b0}};
            skorygowane <= 16'd0; podwojne <= 16'd0;
        end else begin
            r_wazne   <= rd;
            v_b       <= czysc_en;
            kolizja_b <= we && adr == czysc_adr;           // zapis użytkownika w takcie odczytu czyszczenia
            if (czysc_en) czysc_adr <= czysc_adr + 1'b1;
            if (zwrot) skorygowane <= skorygowane + 16'd1;
            if (v_b && podw_b) podwojne <= podwojne + 16'd1;
        end
endmodule

`default_nettype wire

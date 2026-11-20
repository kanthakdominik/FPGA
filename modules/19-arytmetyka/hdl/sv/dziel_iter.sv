// Dzielenie iteracyjne z odtwarzaniem reszty (19.03): jeden bit ilorazu na takt, W taktów na wynik.
// ZNAK = 1: liczby ze znakiem — dzielenie modułów i poprawka znaków, iloraz zaokrąglony w stronę zera,
// reszta ma znak dzielnej (jak w C i w RISC-V). Dzielenie przez zero: iloraz = same jedynki (-1 ze
// znakiem), reszta = dzielna, flaga dziel_zero (konwencja RISC-V). -2^(W-1) / -1 daje -2^(W-1), reszta 0.
// Interfejs: start w takcie, gdy busy = 0; done przez jeden takt z wynikiem; wynik trzymany do startu.
`default_nettype none

module dziel_iter #(
    parameter W    = 16,
    parameter ZNAK = 0
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic [W-1:0] dzielna,
    input  logic [W-1:0] dzielnik,
    output logic          busy = 1'b0,
    output logic          done = 1'b0,
    output logic  [W-1:0] iloraz,
    output logic  [W-1:0] reszta,
    output logic          dziel_zero
);
    localparam CW = (W > 1) ? $clog2(W + 1) : 1;

    logic  [W-1:0]  q;                                   // dzielna przesuwana w lewo, w jej miejsce bity ilorazu
    logic  [W-1:0]  r;                                   // reszta częściowa
    logic  [W-1:0]  d;                                   // moduł dzielnika
    logic  [CW-1:0] licz;
    logic           zn_q, zn_r, zero;
    logic  [W-1:0]  dzielna_r;

    logic          ujemna_a;
    assign ujemna_a = (ZNAK != 0) && dzielna[W-1];
    logic          ujemny_b;
    assign ujemny_b = (ZNAK != 0) && dzielnik[W-1];
    logic [W-1:0]  mod_a;
    assign mod_a = ujemna_a ? -dzielna  : dzielna;
    logic [W-1:0]  mod_b;
    assign mod_b = ujemny_b ? -dzielnik : dzielnik;

    // krok: reszta przesunięta o bit dzielnej; odejmowanie próbne na W+1 bitach
    logic [W:0]    r_przes;
    assign r_przes = {r, q[W-1]};
    logic [W:0]    roznica;
    assign roznica = r_przes - {1'b0, d};
    logic          bit_q;
    assign bit_q = !roznica[W];              // brak pożyczki: reszta >= dzielnik
    /* verilator lint_off UNUSEDSIGNAL */
    logic [W:0]    r_nowa;
    assign r_nowa = bit_q ? roznica : r_przes; // odtworzenie reszty, gdy odejmowanie się nie udało
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0;
        end else if (!busy) begin
            if (start) begin
                q         <= mod_a;
                r         <= {W{1'b0}};
                d         <= mod_b;
                dzielna_r <= dzielna;
                zn_q      <= ujemna_a ^ ujemny_b;
                zn_r      <= ujemna_a;
                zero      <= (dzielnik == {W{1'b0}});
                licz      <= W[CW-1:0];
                busy      <= 1'b1;
            end
        end else if (licz != {CW{1'b0}}) begin
            q    <= {q[W-2:0], bit_q};
            r    <= r_nowa[W-1:0];
            licz <= licz - 1'b1;
        end else begin
            busy       <= 1'b0;
            done       <= 1'b1;
            dziel_zero <= zero;
            if (zero) begin
                iloraz <= {W{1'b1}};
                reszta <= dzielna_r;
            end else begin
                iloraz <= zn_q ? -q : q;
                reszta <= zn_r ? -r : r;
            end
        end
    end
endmodule

`default_nettype wire

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
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [W-1:0] dzielna,
    input  wire [W-1:0] dzielnik,
    output reg          busy = 1'b0,
    output reg          done = 1'b0,
    output reg  [W-1:0] iloraz,
    output reg  [W-1:0] reszta,
    output reg          dziel_zero
);
    localparam CW = (W > 1) ? $clog2(W + 1) : 1;

    reg  [W-1:0]  q;                                   // dzielna przesuwana w lewo, w jej miejsce bity ilorazu
    reg  [W-1:0]  r;                                   // reszta częściowa
    reg  [W-1:0]  d;                                   // moduł dzielnika
    reg  [CW-1:0] licz;
    reg           zn_q, zn_r, zero;
    reg  [W-1:0]  dzielna_r;

    wire          ujemna_a = (ZNAK != 0) && dzielna[W-1];
    wire          ujemny_b = (ZNAK != 0) && dzielnik[W-1];
    wire [W-1:0]  mod_a    = ujemna_a ? -dzielna  : dzielna;
    wire [W-1:0]  mod_b    = ujemny_b ? -dzielnik : dzielnik;

    // krok: reszta przesunięta o bit dzielnej; odejmowanie próbne na W+1 bitach
    wire [W:0]    r_przes  = {r, q[W-1]};
    wire [W:0]    roznica  = r_przes - {1'b0, d};
    wire          bit_q    = !roznica[W];              // brak pożyczki: reszta >= dzielnik
    /* verilator lint_off UNUSEDSIGNAL */
    wire [W:0]    r_nowa   = bit_q ? roznica : r_przes; // odtworzenie reszty, gdy odejmowanie się nie udało
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
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

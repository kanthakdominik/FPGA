// Dzielenie bez znaku w pełnym potoku (19.03): ten sam krok co w dziel_iter, ale każdy bit ilorazu
// liczy osobny stopień — W stopni, opóźnienie W taktów, nowy wynik w każdym takcie.
// Koszt: W odejmowań i rejestry dzielnika, reszty i ilorazu w każdym stopniu (ok. W² przerzutników).
// Dzielenie przez zero: iloraz = same jedynki, reszta = dzielna (wynika z algorytmu, bez dodatkowej logiki).
`default_nettype none

module dziel_potok #(
    parameter W = 16
) (
    input  wire         clk,
    input  wire         in_valid,
    input  wire [W-1:0] dzielna,
    input  wire [W-1:0] dzielnik,
    output wire         out_valid,
    output wire [W-1:0] iloraz,
    output wire [W-1:0] reszta
);
    // stan między stopniami: indeks 0 — wejście, indeks k — po k stopniach
    wire [W-1:0] q [0:W];
    wire [W-1:0] r [0:W];
    /* verilator lint_off UNUSEDSIGNAL */
    wire [W-1:0] d [0:W];                              // d[W] — dzielnik za ostatnim stopniem, nieużywany
    /* verilator lint_on UNUSEDSIGNAL */
    wire         v [0:W];

    assign q[0] = dzielna;
    assign r[0] = {W{1'b0}};
    assign d[0] = dzielnik;
    assign v[0] = in_valid;

    genvar k;
    generate
        for (k = 0; k < W; k = k + 1) begin : g_st
            /* verilator lint_off UNUSEDSIGNAL */
            wire [W:0] r_przes = {r[k], q[k][W-1]};
            /* verilator lint_on UNUSEDSIGNAL */
            wire [W:0] roznica = r_przes - {1'b0, d[k]};
            wire       bit_q   = !roznica[W];
            reg  [W-1:0] q_r, r_r, d_r;
            reg          v_r = 1'b0;
            always @(posedge clk) begin
                q_r <= {q[k][W-2:0], bit_q};
                r_r <= bit_q ? roznica[W-1:0] : r_przes[W-1:0];
                d_r <= d[k];
                v_r <= v[k];
            end
            assign q[k+1] = q_r;
            assign r[k+1] = r_r;
            assign d[k+1] = d_r;
            assign v[k+1] = v_r;
        end
    endgenerate

    assign iloraz    = q[W];
    assign reszta    = r[W];
    assign out_valid = v[W];
endmodule

`default_nettype wire

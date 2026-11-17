// Suma ośmiu liczb W-bitowych drzewem sumatorów (16.01). Rejestry wejściowe i wyjściowy zawsze;
// PIPE (0..2) dodaje rejestry potoku po 1. i 2. poziomie drzewa, RET (0..3) — dodatkowe rejestry
// na wyjściu (materiał dla retimingu). Opóźnienie: L = 2 + PIPE + RET taktów, jeden wynik na takt.
module sumator_drzewo #(
    parameter int W    = 16,
    parameter int PIPE = 0,
    parameter int RET  = 0
) (
    input  logic           clk,
    input  logic           rst,
    input  logic           in_valid,
    input  logic [8*W-1:0] x,
    output logic           out_valid,
    output logic [W+2:0]   y
);
    localparam int L = 2 + PIPE + RET;

    logic [W-1:0] x_r [8];
    always_ff @(posedge clk)
        for (int i = 0; i < 8; i++) x_r[i] <= x[i*W +: W];

    // poziom 1
    logic [W:0] s1 [4], s1_p [4];
    always_comb
        for (int k = 0; k < 4; k++) s1[k] = (W+1)'(x_r[2*k]) + (W+1)'(x_r[2*k+1]);
    if (PIPE >= 1) begin : g_p1
        always_ff @(posedge clk) s1_p <= s1;
    end else begin : g_b1
        assign s1_p = s1;
    end

    // poziom 2
    logic [W+1:0] s2 [2], s2_p [2];
    always_comb
        for (int k = 0; k < 2; k++) s2[k] = (W+2)'(s1_p[2*k]) + (W+2)'(s1_p[2*k+1]);
    if (PIPE >= 2) begin : g_p2
        always_ff @(posedge clk) s2_p <= s2;
    end else begin : g_b2
        assign s2_p = s2;
    end

    // poziom 3, rejestr wyjściowy i RET rejestrów dodatkowych
    logic [W+2:0] y_r;
    always_ff @(posedge clk) y_r <= (W+3)'(s2_p[0]) + (W+3)'(s2_p[1]);

    if (RET > 0) begin : g_ret
        logic [W+2:0] ret_r [RET];
        always_ff @(posedge clk) begin
            ret_r[0] <= y_r;
            for (int i = 1; i < RET; i++) ret_r[i] <= ret_r[i-1];
        end
        assign y = ret_r[RET-1];
    end else begin : g_r0
        assign y = y_r;
    end

    logic [L-1:0] v_r;
    always_ff @(posedge clk)
        if (rst) v_r <= '0;
        else     v_r <= {v_r[L-2:0], in_valid};
    assign out_valid = v_r[L-1];
endmodule

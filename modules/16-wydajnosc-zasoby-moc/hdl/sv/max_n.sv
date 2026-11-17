// Maksimum z 16 liczb W-bitowych (16.03). DRZEWO = 0: łańcuch 15 porównań (głębokość 15),
// DRZEWO = 1: drzewo porównań (głębokość 4). Rejestry na wejściu i wyjściu.
module max_n #(
    parameter int W      = 8,
    parameter bit DRZEWO = 1'b1
) (
    input  logic            clk,
    input  logic [16*W-1:0] x,
    output logic [W-1:0]    y
);
    logic [W-1:0] x_r [16];
    logic [W-1:0] wynik;

    always_ff @(posedge clk)
        for (int i = 0; i < 16; i++) x_r[i] <= x[i*W +: W];

    function automatic logic [W-1:0] wiekszy(logic [W-1:0] lewy, logic [W-1:0] prawy);
        return (lewy > prawy) ? lewy : prawy;
    endfunction

    if (DRZEWO) begin : g_drzewo
        logic [W-1:0] t [15];                  // t[0..7] poziom 1, t[8..11] poziom 2, t[12..13] poziom 3
        always_comb begin
            for (int k = 0; k < 8; k++) t[k]      = wiekszy(x_r[2*k], x_r[2*k+1]);
            for (int k = 0; k < 4; k++) t[8 + k]  = wiekszy(t[2*k], t[2*k+1]);
            for (int k = 0; k < 2; k++) t[12 + k] = wiekszy(t[8 + 2*k], t[8 + 2*k+1]);
            t[14] = wiekszy(t[12], t[13]);
        end
        assign wynik = t[14];
    end else begin : g_lancuch
        logic [W-1:0] m [16];
        always_comb begin
            m[0] = x_r[0];
            for (int k = 1; k < 16; k++) m[k] = wiekszy(x_r[k], m[k-1]);
        end
        assign wynik = m[15];
    end

    always_ff @(posedge clk) y <= wynik;
endmodule

// Suma ośmiu liczb W-bitowych drzewem sumatorów (16.01). Rejestry wejściowe i wyjściowy zawsze;
// PIPE (0..2) dodaje rejestry potoku po 1. i 2. poziomie drzewa, RET (0..3) — dodatkowe rejestry
// na wyjściu (materiał dla retimingu: narzędzie może je przesunąć do wnętrza drzewa).
// Opóźnienie: L = 2 + PIPE + RET taktów; przepustowość: jeden wynik na takt.
// Rejestry danych bez resetu (ścieżka danych), out_valid z resetem (sterowanie).
`default_nettype none

module sumator_drzewo #(
    parameter W    = 16,
    parameter PIPE = 0,
    parameter RET  = 0
) (
    input  wire           clk,
    input  wire           rst,
    input  wire           in_valid,
    input  wire [8*W-1:0] x,
    output wire           out_valid,
    output wire [W+2:0]   y
);
    localparam L = 2 + PIPE + RET;

    // rejestr wejściowy
    reg [8*W-1:0] x_r;
    always @(posedge clk) x_r <= x;

    // poziom 1: cztery sumy W+1 bitów
    wire [4*(W+1)-1:0] s1;
    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : g_s1
            assign s1[k*(W+1) +: W+1] = {1'b0, x_r[(2*k)*W +: W]} + {1'b0, x_r[(2*k+1)*W +: W]};
        end
    endgenerate
    wire [4*(W+1)-1:0] s1_p;
    generate
        if (PIPE >= 1) begin : g_p1
            reg [4*(W+1)-1:0] s1_r;
            always @(posedge clk) s1_r <= s1;
            assign s1_p = s1_r;
        end else begin : g_b1
            assign s1_p = s1;
        end
    endgenerate

    // poziom 2: dwie sumy W+2 bitów
    wire [2*(W+2)-1:0] s2;
    generate
        for (k = 0; k < 2; k = k + 1) begin : g_s2
            assign s2[k*(W+2) +: W+2] = {1'b0, s1_p[(2*k)*(W+1) +: W+1]} + {1'b0, s1_p[(2*k+1)*(W+1) +: W+1]};
        end
    endgenerate
    wire [2*(W+2)-1:0] s2_p;
    generate
        if (PIPE >= 2) begin : g_p2
            reg [2*(W+2)-1:0] s2_r;
            always @(posedge clk) s2_r <= s2;
            assign s2_p = s2_r;
        end else begin : g_b2
            assign s2_p = s2;
        end
    endgenerate

    // poziom 3 i rejestr wyjściowy
    wire [W+2:0] s3 = {1'b0, s2_p[0 +: W+2]} + {1'b0, s2_p[W+2 +: W+2]};
    reg  [W+2:0] y_r;
    always @(posedge clk) y_r <= s3;

    // RET dodatkowych rejestrów wyjściowych
    generate
        if (RET > 0) begin : g_ret
            reg [(W+3)*RET-1:0] ret_r;
            if (RET == 1) begin : g_r1
                always @(posedge clk) ret_r <= y_r;
            end else begin : g_rn
                always @(posedge clk) ret_r <= {ret_r[(W+3)*(RET-1)-1:0], y_r};
            end
            assign y = ret_r[(W+3)*RET-1 -: W+3];
        end else begin : g_r0
            assign y = y_r;
        end
    endgenerate

    // ważność wyniku: L taktów
    reg [L-1:0] v_r;
    always @(posedge clk)
        if (rst) v_r <= {L{1'b0}};
        else     v_r <= {v_r[L-2:0], in_valid};
    assign out_valid = v_r[L-1];
endmodule

`default_nettype wire

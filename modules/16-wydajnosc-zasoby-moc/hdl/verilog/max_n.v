// Maksimum z 16 liczb W-bitowych (16.03). DRZEWO = 0: łańcuch 15 porównań (głębokość 15),
// DRZEWO = 1: drzewo porównań (głębokość 4). Rejestry na wejściu i wyjściu.
`default_nettype none

module max_n #(
    parameter W      = 8,
    parameter DRZEWO = 1
) (
    input  wire            clk,
    input  wire [16*W-1:0] x,
    output reg  [W-1:0]    y
);
    reg [16*W-1:0] x_r;
    always @(posedge clk) x_r <= x;

    wire [W-1:0] wynik;
    genvar k;
    generate
        if (DRZEWO != 0) begin : g_drzewo
            // poziomy: 16 -> 8 -> 4 -> 2 -> 1; węzeł j poziomu l w t[...]
            wire [W-1:0] t1 [0:7];
            wire [W-1:0] t2 [0:3];
            wire [W-1:0] t3 [0:1];
            for (k = 0; k < 8; k = k + 1) begin : g_l1
                wire [W-1:0] p = x_r[(2*k)*W +: W];
                wire [W-1:0] q = x_r[(2*k+1)*W +: W];
                assign t1[k] = (p > q) ? p : q;
            end
            for (k = 0; k < 4; k = k + 1) begin : g_l2
                assign t2[k] = (t1[2*k] > t1[2*k+1]) ? t1[2*k] : t1[2*k+1];
            end
            for (k = 0; k < 2; k = k + 1) begin : g_l3
                assign t3[k] = (t2[2*k] > t2[2*k+1]) ? t2[2*k] : t2[2*k+1];
            end
            assign wynik = (t3[0] > t3[1]) ? t3[0] : t3[1];
        end else begin : g_lancuch
            wire [W-1:0] m [0:15];
            assign m[0] = x_r[0 +: W];
            for (k = 1; k < 16; k = k + 1) begin : g_l
                wire [W-1:0] p = x_r[k*W +: W];
                assign m[k] = (p > m[k-1]) ? p : m[k-1];
            end
            assign wynik = m[15];
        end
    endgenerate

    always @(posedge clk) y <= wynik;
endmodule

`default_nettype wire

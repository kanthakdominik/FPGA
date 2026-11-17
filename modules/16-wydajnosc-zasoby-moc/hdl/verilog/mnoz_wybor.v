// y = sel ? a*b : c*d (16.02). WSPOLNY = 0: dwie mnożarki i multiplekser wyników;
// WSPOLNY = 1: multipleksery argumentów i jedna mnożarka (ręczne współdzielenie zasobu).
// Funkcja identyczna; różni się liczba mnożarek i miejsce multipleksera na ścieżce.
`default_nettype none

module mnoz_wybor #(
    parameter W        = 16,
    parameter WSPOLNY  = 0
) (
    input  wire           clk,
    input  wire           sel,
    input  wire [W-1:0]   a,
    input  wire [W-1:0]   b,
    input  wire [W-1:0]   c,
    input  wire [W-1:0]   d,
    output reg  [2*W-1:0] y
);
    generate
        if (WSPOLNY != 0) begin : g_wsp
            wire [W-1:0] x1 = sel ? a : c;
            wire [W-1:0] x2 = sel ? b : d;
            always @(posedge clk) y <= {{W{1'b0}}, x1} * {{W{1'b0}}, x2};
        end else begin : g_dwie
            wire [2*W-1:0] p_ab = {{W{1'b0}}, a} * {{W{1'b0}}, b};
            wire [2*W-1:0] p_cd = {{W{1'b0}}, c} * {{W{1'b0}}, d};
            always @(posedge clk) y <= sel ? p_ab : p_cd;
        end
    endgenerate
endmodule

`default_nettype wire

// y = sel ? a*b : c*d (16.02). WSPOLNY = 0: dwie mnożarki i multiplekser wyników;
// WSPOLNY = 1: multipleksery argumentów i jedna mnożarka.
module mnoz_wybor #(
    parameter int W       = 16,
    parameter bit WSPOLNY = 1'b0
) (
    input  logic           clk,
    input  logic           sel,
    input  logic [W-1:0]   a,
    input  logic [W-1:0]   b,
    input  logic [W-1:0]   c,
    input  logic [W-1:0]   d,
    output logic [2*W-1:0] y
);
    if (WSPOLNY) begin : g_wsp
        logic [W-1:0] x1, x2;
        assign x1 = sel ? a : c;
        assign x2 = sel ? b : d;
        always_ff @(posedge clk) y <= (2*W)'(x1) * (2*W)'(x2);
    end else begin : g_dwie
        logic [2*W-1:0] p_ab, p_cd;
        assign p_ab = (2*W)'(a) * (2*W)'(b);
        assign p_cd = (2*W)'(c) * (2*W)'(d);
        always_ff @(posedge clk) y <= sel ? p_ab : p_cd;
    end
endmodule

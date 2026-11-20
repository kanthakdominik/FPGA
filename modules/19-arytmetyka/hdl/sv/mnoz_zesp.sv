// Mnożenie liczb zespolonych (ar + j·ai)(br + j·bi) ze znakiem, W bitów na składową (19.02).
//   TRZY = 0: cztery mnożenia — pr = ar·br - ai·bi, pi = ar·bi + ai·br,
//   TRZY = 1: trzy mnożenia (sztuczka Gaussa) kosztem trzech dodatkowych sumatorów:
//             k1 = br·(ar + ai), k2 = ar·(bi - br), k3 = ai·(br + bi); pr = k1 - k3, pi = k1 + k2.
// Obie wersje: potok 4 takty, wynik 2W+1 bitów (dokładny), w każdym takcie nowa para.
`default_nettype none

module mnoz_zesp #(
    parameter W    = 16,
    parameter TRZY = 1
) (
    input  logic           clk,
    input  logic           in_valid,
    input  logic [W-1:0]   ar,
    input  logic [W-1:0]   ai,
    input  logic [W-1:0]   br,
    input  logic [W-1:0]   bi,
    output logic            out_valid = 1'b0,
    output logic  [2*W:0]   pr,
    output logic  [2*W:0]   pi
);
    logic signed [W-1:0] ar1, ai1, br1, bi1;
    logic [2:0]          v = 3'b000;

    always_ff @(posedge clk) begin
        ar1 <= ar; ai1 <= ai; br1 <= br; bi1 <= bi;
        v   <= {v[1:0], in_valid};
        out_valid <= v[2];
    end

    generate
        if (TRZY == 0) begin : g_cztery
            logic signed [2*W-1:0] m1, m2, m3, m4;
            logic signed [2*W:0]   sr, si;
            /* verilator lint_off WIDTHEXPAND */
            always_ff @(posedge clk) begin
                m1 <= ar1 * br1;
                m2 <= ai1 * bi1;
                m3 <= ar1 * bi1;
                m4 <= ai1 * br1;
                sr <= m1 - m2;
                si <= m3 + m4;
                pr <= sr;
                pi <= si;
            end
            /* verilator lint_on WIDTHEXPAND */
        end else begin : g_trzy
            logic signed [W:0]     s1, s2, s3;            // sumy przed mnożeniem (W+1 bitów)
            logic signed [W-1:0]   ar2, ai2, br2;
            logic signed [2*W:0]   k1, k2, k3;
            /* verilator lint_off WIDTHEXPAND */
            /* verilator lint_off WIDTHTRUNC */
            always_ff @(posedge clk) begin
                s1  <= ar1 + ai1;
                s2  <= bi1 - br1;
                s3  <= br1 + bi1;
                ar2 <= ar1; ai2 <= ai1; br2 <= br1;
                k1  <= br2 * s1;
                k2  <= ar2 * s2;
                k3  <= ai2 * s3;
                pr  <= k1 - k3;                         // dokładnie ar·br - ai·bi, mieści się w 2W+1
                pi  <= k1 + k2;
            end
            /* verilator lint_on WIDTHTRUNC */
            /* verilator lint_on WIDTHEXPAND */
        end
    endgenerate
endmodule

`default_nettype wire

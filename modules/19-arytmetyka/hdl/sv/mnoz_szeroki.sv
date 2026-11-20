// Mnożenie ze znakiem 2H × 2H bitów z czterech mnożeń (H+1) × (H+1) (19.02) — tak narzędzie składa
// szerokie mnożenie z bloków 18 × 18. Przy H = 17: 34 × 34 -> 68 bitów z czterech bloków 18 × 18.
//   a = ah·2^H + al, al — H młodszych bitów bez znaku (rozszerzone zerem do H+1), ah — starsza część
//   ze znakiem; a·b = ah·bh·2^2H + (ah·bl + al·bh)·2^H + al·bl.
// Dlatego blok ma 18 bitów: 17 bitów bez znaku + bit znaku pozwala dzielić operandy na kawałki.
// Potok 3 takty: rejestry wejść, rejestry iloczynów częściowych, rejestr sumy.
`default_nettype none

module mnoz_szeroki #(
    parameter H = 17
) (
    input  logic           clk,
    input  logic           in_valid,
    input  logic [2*H-1:0] a,
    input  logic [2*H-1:0] b,
    output logic            out_valid = 1'b0,
    output logic  [4*H-1:0] p
);
    logic [2*H-1:0] a_r, b_r;
    logic           v1 = 1'b0, v2 = 1'b0;

    logic signed [H:0] al;
    assign al = {1'b0, a_r[H-1:0]};
    logic signed [H:0] ah;
    assign ah = {a_r[2*H-1], a_r[2*H-1:H]};
    logic signed [H:0] bl;
    assign bl = {1'b0, b_r[H-1:0]};
    logic signed [H:0] bh;
    assign bh = {b_r[2*H-1], b_r[2*H-1:H]};

    logic signed [2*H+1:0] pll, plh, phl, phh;            // iloczyny częściowe (H+1) × (H+1)

    // rozszerzenie znakiem iloczynu częściowego do szerokości wyniku
    function [4*H-1:0] rozsz(input [2*H+1:0] x);
        rozsz = {{(2*H-2){x[2*H+1]}}, x};
    endfunction

    always_ff @(posedge clk) begin
        a_r <= a;
        b_r <= b;
        v1  <= in_valid;
        pll <= al * bl;
        plh <= al * bh;
        phl <= ah * bl;
        phh <= ah * bh;
        v2  <= v1;
        p   <= (rozsz(phh) << (2 * H)) + (rozsz(plh) << H) + (rozsz(phl) << H) + rozsz(pll);
        out_valid <= v2;
    end
endmodule

`default_nettype wire

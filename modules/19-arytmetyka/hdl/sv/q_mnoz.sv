// Mnożenie liczb stałoprzecinkowych ze znakiem w formacie Q (19.01): a (WA bitów, FA ułamkowych) × b
// (WB, FB) -> p (WO, FO) z zaokrągleniem i nasyceniem przez q_zmien. Iloczyn pełny ma WA+WB bitów
// i FA+FB bitów ułamkowych — dopiero potem zmiana formatu. Potok: rejestr iloczynu, rejestr wyniku.
`default_nettype none

module q_mnoz #(
    parameter WA    = 16,
    parameter FA    = 15,
    parameter WB    = 16,
    parameter FB    = 15,
    parameter WO    = 16,
    parameter FO    = 15,
    parameter ZAOKR = 2,
    parameter NASYC = 1
) (
    input  logic          clk,
    input  logic          in_valid,
    input  logic [WA-1:0] a,
    input  logic [WB-1:0] b,
    output logic           out_valid = 1'b0,
    output logic  [WO-1:0] p,
    output logic           przepel
);
    logic  signed [WA+WB-1:0] iloczyn;
    logic                     v1 = 1'b0;
    logic        [WO-1:0]    p_q;
    logic                    przepel_q;

    q_zmien #(.WI(WA + WB), .FI(FA + FB), .WO(WO), .FO(FO), .ZAOKR(ZAOKR), .NASYC(NASYC))
        u_q (.din(iloczyn), .dout(p_q), .przepel(przepel_q));

    always_ff @(posedge clk) begin
        /* verilator lint_off WIDTHEXPAND */
        iloczyn   <= $signed(a) * $signed(b);       // pełny iloczyn ze znakiem, WA+WB bitów
        /* verilator lint_on WIDTHEXPAND */
        v1        <= in_valid;
        p         <= p_q;
        przepel   <= przepel_q;
        out_valid <= v1;
    end
endmodule

`default_nettype wire

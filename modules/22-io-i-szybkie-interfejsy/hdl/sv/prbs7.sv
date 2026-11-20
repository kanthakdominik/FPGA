// Generator PRBS7 (x^7 + x^6 + 1), N bitów na takt, bit najstarszy wychodzi pierwszy (22.02, 22.03).
// Ciąg ma okres 127 bitów i służy do testów łączy: odbiornik sprawdza go bez znajomości fazy (prbs7_spr).
`default_nettype none

module prbs7 #(
    parameter integer N = 2
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         en,
    output logic  [N-1:0] q
);
    logic [6:0] s;
    logic [6:0] t;
    logic [N-1:0] b;
    integer i;
    always_comb begin
        t = s;
        for (i = N - 1; i >= 0; i = i - 1) begin
            b[i] = t[6] ^ t[5];
            t    = {t[5:0], b[i]};
        end
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            s <= 7'h7F;
            q <= {N{1'b0}};
        end else if (en) begin
            s <= t;
            q <= b;
        end
    end
endmodule

`default_nettype wire

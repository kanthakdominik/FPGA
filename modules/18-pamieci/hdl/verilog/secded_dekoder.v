// Dekoder SECDED (18.06): syndrom = XOR numerów pozycji, na których słowo ma jedynkę (dla poprawnego
// słowa 0), parzystość ogólna = XOR wszystkich bitów.
//   syndrom = 0, parzystość 0 — brak błędu;
//   parzystość 1 — błąd pojedynczy na pozycji syndromu (0 = bit parzystości), poprawiany;
//   syndrom ≠ 0, parzystość 0 — błąd podwójny, wykryty, niepoprawialny.
`default_nettype none

module secded_dekoder #(
    parameter K = 32,
    parameter R = 6
) (
    input  wire [K+R:0] kod,
    output reg  [K-1:0] dane,
    output reg          pojedynczy,
    output reg          podwojny,
    output reg  [R-1:0] syndrom
);
    integer p, d;
    reg         ogolna;
    reg [K+R:0] popr;
    always @(*) begin
        syndrom = {R{1'b0}};
        for (p = 1; p <= K + R; p = p + 1)
            if (kod[p]) syndrom = syndrom ^ p[R-1:0];
        ogolna = ^kod;
        popr   = kod;
        pojedynczy = 1'b0;
        podwojny   = 1'b0;
        if (ogolna) begin
            if (syndrom <= K + R) begin
                popr[syndrom] = ~popr[syndrom];
                pojedynczy = 1'b1;
            end else begin
                podwojny = 1'b1;              // syndrom poza słowem: błąd wielokrotny
            end
        end else if (syndrom != {R{1'b0}}) begin
            podwojny = 1'b1;
        end
        dane = {K{1'b0}};
        d = 0;
        for (p = 1; p <= K + R; p = p + 1)
            if ((p & (p - 1)) != 0) begin
                dane[d] = popr[p];
                d = d + 1;
            end
    end
endmodule

`default_nettype wire

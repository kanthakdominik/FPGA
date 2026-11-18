// Dekoder SECDED (18.06): syndrom = XOR numerów pozycji z jedynką, parzystość = XOR wszystkich bitów.
// Parzystość 1 — błąd pojedynczy na pozycji syndromu (poprawiany); syndrom ≠ 0 przy parzystości 0 —
// błąd podwójny (wykryty).
module secded_dekoder #(
    parameter int K = 32,
    parameter int R = 6
) (
    input  logic [K+R:0] kod,
    output logic [K-1:0] dane,
    output logic         pojedynczy,
    output logic         podwojny,
    output logic [R-1:0] syndrom
);
    always_comb begin
        int d;
        logic         ogolna;
        logic [K+R:0] popr;
        syndrom = '0;
        for (int p = 1; p <= K + R; p++)
            if (kod[p]) syndrom ^= R'(p);
        ogolna     = ^kod;
        popr       = kod;
        pojedynczy = 1'b0;
        podwojny   = 1'b0;
        if (ogolna) begin
            if (int'(syndrom) <= K + R) begin
                popr[syndrom] = ~popr[syndrom];
                pojedynczy = 1'b1;
            end else begin
                podwojny = 1'b1;
            end
        end else if (syndrom != '0) begin
            podwojny = 1'b1;
        end
        dane = '0;
        d = 0;
        for (int p = 1; p <= K + R; p++)
            if ((p & (p - 1)) != 0) begin
                dane[d] = popr[p];
                d++;
            end
    end
endmodule

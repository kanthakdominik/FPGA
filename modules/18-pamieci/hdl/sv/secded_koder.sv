// Koder SECDED (18.06): rozszerzony kod Hamminga — bity kontrolne na pozycjach 2^j, parzystość ogólna
// na pozycji 0; K = 32, R = 6 -> 39 bitów. Poprawia błąd pojedynczy, wykrywa podwójny.
module secded_koder #(
    parameter int K = 32,
    parameter int R = 6
) (
    input  logic [K-1:0] dane,
    output logic [K+R:0] kod
);
    always_comb begin
        int d;
        logic par;
        kod = '0;
        d = 0;
        for (int p = 1; p <= K + R; p++)
            if ((p & (p - 1)) != 0) begin
                kod[p] = dane[d];
                d++;
            end
        for (int j = 0; j < R; j++) begin
            par = 1'b0;
            for (int p = 1; p <= K + R; p++)
                if (((p >> j) & 1) == 1) par ^= kod[p];
            kod[1 << j] = par;
        end
        kod[0] = ^kod[K+R:1];
    end
endmodule

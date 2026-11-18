// Koder SECDED (18.06): rozszerzony kod Hamminga dla K bitów danych — R bitów kontrolnych na pozycjach
// 1, 2, 4, …, 2^(R-1) i bit parzystości całego słowa na pozycji 0. K = 32, R = 6 -> słowo 39 bitów.
// Poprawia każdy pojedynczy błąd, wykrywa każdy podwójny (Single Error Correction, Double Error Detection).
`default_nettype none

module secded_koder #(
    parameter K = 32,
    parameter R = 6                          // 2^R > K + R
) (
    input  wire [K-1:0] dane,
    output reg  [K+R:0] kod
);
    integer p, d, j;
    reg par;
    always @(*) begin
        kod = {(K+R+1){1'b0}};
        d = 0;
        for (p = 1; p <= K + R; p = p + 1)
            if ((p & (p - 1)) != 0) begin    // pozycja nie jest potęgą dwójki — bit danych
                kod[p] = dane[d];
                d = d + 1;
            end
        for (j = 0; j < R; j = j + 1) begin  // bit kontrolny 2^j: parzystość pozycji z ustawionym bitem j
            par = 1'b0;
            for (p = 1; p <= K + R; p = p + 1)
                if (((p >> j) & 1) == 1) par = par ^ kod[p];
            kod[1 << j] = par;
        end
        kod[0] = ^kod[K+R:1];
    end
endmodule

`default_nettype wire

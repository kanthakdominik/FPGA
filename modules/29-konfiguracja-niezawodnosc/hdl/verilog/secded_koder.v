// Koder SECDED (39,32) — kod Hamminga z bitem parzystości całości (29.04). Bity słowa kodowego numerowane
// pozycjami 0..38: pozycje 1, 2, 4, 8, 16, 32 — bity kontrolne p_k (XOR pozycji z ustawionym bitem k numeru),
// pozostałe pozycje 3, 5, 6, 7, 9, … — kolejne bity danych, pozycja 0 — parzystość wszystkich pozostałych.
`default_nettype none

module secded_koder (
    input  wire [31:0] d,
    output wire [38:0] c
);
    function [38:0] koduj(input [31:0] dane);
        integer i, j, k;
        reg [38:0] w;
        reg p;
        begin
            w = 39'd0;
            j = 0;
            for (i = 1; i < 39; i = i + 1)
                if ((i & (i - 1)) != 0) begin
                    w[i] = dane[j];
                    j = j + 1;
                end
            for (k = 0; k < 6; k = k + 1) begin
                p = 1'b0;
                for (i = 1; i < 39; i = i + 1)
                    if (((i >> k) & 1) == 1 && i != (1 << k)) p = p ^ w[i];
                w[1 << k] = p;
            end
            w[0] = ^w[38:1];
            koduj = w;
        end
    endfunction

    assign c = koduj(d);
endmodule

`default_nettype wire

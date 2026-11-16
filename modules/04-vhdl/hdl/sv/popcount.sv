// Liczba jedynek w słowie — zmienna lokalna w always_comb (jak zmienna VHDL).
module popcount #(
    parameter int W = 8
) (
    input  logic [W-1:0]           d,
    output logic [$clog2(W+1)-1:0] count
);
    always_comb begin
        count = '0;
        foreach (d[i])                             // pętla po wszystkich indeksach wektora
            count += d[i];
    end
endmodule

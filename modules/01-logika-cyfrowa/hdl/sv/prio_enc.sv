// Enkoder priorytetowy: numer najstarszego ustawionego bitu wejścia; valid = 1, gdy jakikolwiek bit jest ustawiony.
module prio_enc #(
    parameter int N = 8
) (
    input  logic [N-1:0]         a,
    output logic [$clog2(N)-1:0] y,
    output logic                 valid
);
    always_comb begin
        y     = '0;
        valid = 1'b0;
        // pętla od najmłodszego bitu: ostatnie trafienie (najstarszy bit) wygrywa
        for (int i = 0; i < N; i++) begin
            if (a[i]) begin
                y     = i[$clog2(N)-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule

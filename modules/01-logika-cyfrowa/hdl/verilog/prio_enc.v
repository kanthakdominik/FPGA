// Enkoder priorytetowy: numer najstarszego ustawionego bitu wejścia; valid = 1, gdy jakikolwiek bit jest ustawiony.
`default_nettype none

module prio_enc #(
    parameter integer N = 8
) (
    input  wire [N-1:0]          a,
    output reg  [$clog2(N)-1:0]  y,
    output reg                   valid
);
    integer i;

    always @* begin
        y     = {$clog2(N){1'b0}};
        valid = 1'b0;
        // pętla od najmłodszego bitu: ostatnie trafienie (najstarszy bit) wygrywa
        for (i = 0; i < N; i = i + 1) begin
            if (a[i]) begin
                y     = i;
                valid = 1'b1;
            end
        end
    end
endmodule

`default_nettype wire

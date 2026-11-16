// Dekoder N na 2**N (kod 1 z n): ustawia jedynkę na wyjściu o numerze a.
module decoder #(
    parameter int N = 3
) (
    input  logic [N-1:0]      a,
    output logic [2**N-1:0]   y
);
    always_comb begin
        y    = '0;               // wartość domyślna: brak zatrzasku
        y[a] = 1'b1;
    end
endmodule

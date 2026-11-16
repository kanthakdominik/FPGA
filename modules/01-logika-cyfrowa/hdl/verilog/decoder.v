// Dekoder N na 2**N (kod 1 z n): ustawia jedynkę na wyjściu o numerze a.
`default_nettype none

module decoder #(
    parameter integer N = 3
) (
    input  wire [N-1:0]        a,
    output reg  [(1<<N)-1:0]   y
);
    always @* begin
        y    = {(1<<N){1'b0}};   // wartość domyślna: brak zatrzasku
        y[a] = 1'b1;
    end
endmodule

`default_nettype wire

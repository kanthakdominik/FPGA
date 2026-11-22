// Synchronizator poziomu: STAGES przerzutników w domenie docelowej (15.03).
// Wejście d pochodzi z innej domeny (albo z pinu) i może zmieniać się w dowolnej chwili; wyjście q jest
// bezpieczne w domenie clk po STAGES taktach. Dla wektora W > 1 każdy bit synchronizowany osobno —
// poprawne TYLKO, gdy w jednej chwili zmienia się co najwyżej jeden bit (kod Graya, 15.04).
// Atrybuty: ASYNC_REG (AMD: przerzutniki obok siebie, analiza MTBF), SYNCHRONIZER_IDENTIFICATION (Intel).
module sync_bit #(
    parameter int STAGES = 2,                  // co najmniej 2
    parameter int W      = 1
) (
    input  logic         clk,
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);
    (* ASYNC_REG = "TRUE", altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [STAGES-1:0][W-1:0] sync_r = '0;

    always_ff @(posedge clk)
        sync_r <= {sync_r[STAGES-2:0], d};

    assign q = sync_r[STAGES-1];
endmodule

// Synchronizator poziomu: STAGES przerzutników w domenie docelowej (15.03).
// Wejście d pochodzi z innej domeny (albo z pinu) i może zmieniać się w dowolnej chwili; wyjście q jest
// bezpieczne w domenie clk po STAGES taktach. Dla wektora W > 1 każdy bit synchronizowany osobno —
// poprawne TYLKO, gdy w jednej chwili zmienia się co najwyżej jeden bit (kod Graya, 15.04).
// Atrybuty: ASYNC_REG (AMD: przerzutniki obok siebie, analiza MTBF), SYNCHRONIZER_IDENTIFICATION (Intel).
`default_nettype none

module sync_bit #(
    parameter STAGES = 2,                      // co najmniej 2
    parameter W      = 1
) (
    input  wire         clk,
    input  wire [W-1:0] d,
    output wire [W-1:0] q
);
    // stopień k zajmuje bity [k*W +: W]; stopień 0 łapie sygnał asynchroniczny
    (* ASYNC_REG = "TRUE", altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [STAGES*W-1:0] sync_r = {(STAGES*W){1'b0}};

    always @(posedge clk)
        sync_r <= {sync_r[(STAGES-1)*W-1:0], d};

    assign q = sync_r[STAGES*W-1 -: W];
endmodule

`default_nettype wire

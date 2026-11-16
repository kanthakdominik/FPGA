// Operacje bitowe: potęga dwójki, najmłodsza jedynka, odwrócenie bitów, redukcje.
module bit_tricks #(
    parameter int W = 8
) (
    input  logic [W-1:0] x,
    output logic         is_pow2,
    output logic [W-1:0] lowest,
    output logic [W-1:0] rev,
    output logic         parity,
    output logic         all_ones
);
    assign is_pow2  = ($countones(x) == 1);        // funkcja systemowa SV — syntezowalna
    assign lowest   = x & (~x + 1'b1);
    assign parity   = ^x;
    assign all_ones = &x;
    assign rev      = {<<{x}};                     // operator strumieniowy: odwrócenie kolejności bitów
endmodule

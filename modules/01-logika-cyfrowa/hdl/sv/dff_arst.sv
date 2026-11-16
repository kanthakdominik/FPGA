// Przerzutnik D z resetem asynchronicznym.
module dff_arst (
    input  logic clk,
    input  logic arst,                   // asynchroniczny, aktywny wysoki
    input  logic d,
    output logic q
);
    always_ff @(posedge clk or posedge arst) begin
        if (arst)
            q <= 1'b0;                   // działa natychmiast, bez czekania na zegar
        else
            q <= d;
    end
endmodule

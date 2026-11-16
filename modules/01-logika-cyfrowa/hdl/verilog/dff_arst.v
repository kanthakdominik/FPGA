// Przerzutnik D z resetem asynchronicznym.
`default_nettype none

module dff_arst (
    input  wire clk,
    input  wire arst,                    // asynchroniczny, aktywny wysoki
    input  wire d,
    output reg  q
);
    always @(posedge clk or posedge arst) begin
        if (arst)
            q <= 1'b0;                   // działa natychmiast, bez czekania na zegar
        else
            q <= d;
    end
endmodule

`default_nettype wire

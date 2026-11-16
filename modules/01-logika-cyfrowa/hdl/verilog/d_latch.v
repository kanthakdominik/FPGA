// Zatrzask D: przezroczysty przy en = 1, pamięta przy en = 0.
// Celowy przykład — w kodzie FPGA zatrzaski są zwykle błędem (temat 07.03).
`default_nettype none

module d_latch (
    input  wire en,
    input  wire d,
    output reg  q
);
    always @* begin
        if (en)
            q <= d;                      // brak else: q pamięta — powstaje zatrzask
    end
endmodule

`default_nettype wire

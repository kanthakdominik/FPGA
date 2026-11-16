// Zatrzask D: przezroczysty przy en = 1, pamięta przy en = 0.
// Celowy przykład — w kodzie FPGA zatrzaski są zwykle błędem (temat 07.03).
// always_latch mówi narzędziom wprost: "tu ma być zatrzask" — inaczej niż przypadkowy zatrzask w always_comb.
module d_latch (
    input  logic en,
    input  logic d,
    output logic q
);
    always_latch begin
        if (en)
            q <= d;
    end
endmodule

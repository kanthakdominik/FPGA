// ROM z zawartością z pliku (18.02): $readmemh wczytuje plik szesnastkowy (jedna wartość w wierszu)
// w czasie elaboracji — w symulacji i w syntezie (Quartus, Vivado, Yosys). Odczyt synchroniczny,
// więc synteza używa bloku pamięci zamiast logiki. Plik generuje hdl/dane/gen_sinus.py.
`default_nettype none

module rom_sinus #(
    parameter W    = 8,
    parameter AW   = 8,
    parameter PLIK = "sinus.hex"
) (
    input  wire          clk,
    input  wire          en,
    input  wire [AW-1:0] addr,
    output reg  [W-1:0]  dout
);
    reg [W-1:0] rom [0:(1<<AW)-1];
    initial $readmemh(PLIK, rom);

    always @(posedge clk)
        if (en) dout <= rom[addr];
endmodule

`default_nettype wire

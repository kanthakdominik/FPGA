// ROM z zawartością z pliku (18.02): $readmemh w czasie elaboracji, odczyt synchroniczny.
module rom_sinus #(
    parameter int    W    = 8,
    parameter int    AW   = 8,
    parameter string PLIK = "sinus.hex"
) (
    input  logic          clk,
    input  logic          en,
    input  logic [AW-1:0] addr,
    output logic [W-1:0]  dout
);
    logic [W-1:0] rom [2**AW];
    initial $readmemh(PLIK, rom);

    always_ff @(posedge clk)
        if (en) dout <= rom[addr];
endmodule

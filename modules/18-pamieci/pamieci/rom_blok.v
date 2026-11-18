// ROM z rom_sinus z atrybutem wymuszającym blok pamięci (18.01, 18.02). Yosys mapuje małą ROM 256 × 8
// na LUT, bo to tańsze niż blok 18 Kb; atrybut rom_style = "block" (Quartus: romstyle = "M9K",
// Vivado: rom_style = "block") wymusza blok pamięci.
`default_nettype none

module rom_blok #(
    parameter W    = 8,
    parameter AW   = 8,
    parameter PLIK = "sinus.hex"
) (
    input  wire          clk,
    input  wire          en,
    input  wire [AW-1:0] addr,
    output reg  [W-1:0]  dout
);
    (* rom_style = "block", romstyle = "M9K" *)
    reg [W-1:0] rom [0:(1<<AW)-1];
    initial $readmemh(PLIK, rom);

    always @(posedge clk)
        if (en) dout <= rom[addr];
endmodule

`default_nettype wire

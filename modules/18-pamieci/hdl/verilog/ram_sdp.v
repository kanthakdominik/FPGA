// Pamięć dwuportowa prosta (18.01): port zapisu w domenie clk_w, port odczytu w domenie clk_r
// (zegary mogą być różne — pamięć jest wtedy też przejściem między domenami dla bloków danych).
// Odczyt synchroniczny; przy jednym zegarze i odczycie adresu zapisywanego w tym samym takcie
// symulacja daje starą zawartość (w MAX 10 zachowanie mieszanych portów ustala się parametrem bloku).
`default_nettype none

module ram_sdp #(
    parameter W  = 8,
    parameter AW = 8
) (
    input  wire          clk_w,
    input  wire          we,
    input  wire [AW-1:0] addr_w,
    input  wire [W-1:0]  din,
    input  wire          clk_r,
    input  wire          re,
    input  wire [AW-1:0] addr_r,
    output reg  [W-1:0]  dout
);
    reg [W-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk_w)
        if (we) mem[addr_w] <= din;

    always @(posedge clk_r)
        if (re) dout <= mem[addr_r];
endmodule

`default_nettype wire

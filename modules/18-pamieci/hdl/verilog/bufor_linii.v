// Bufor dwóch linii obrazu (18.04): dla strumienia pikseli w kolejności rastrowej (SZER pikseli w linii)
// wyprowadza kolumnę trzech pikseli o tej samej współrzędnej x: z bieżącej linii i z dwóch poprzednich —
// podstawa filtrów 3 × 3. Jedna pamięć SZER słów po 2·W bitów: odczyt adresu x w takcie piksela,
// zapis {linia−1, bieżący} pod ten sam adres w takcie następnym. Przed dwiema pierwszymi liniami
// pamięć zawiera zera.
`default_nettype none

module bufor_linii #(
    parameter W    = 8,
    parameter SZER = 16
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         in_valid,
    input  wire [W-1:0] piksel,
    output reg          out_valid,
    output wire [W-1:0] p0,                  // bieżąca linia
    output wire [W-1:0] p1,                  // linia poprzednia
    output wire [W-1:0] p2                   // dwie linie wcześniej
);
    localparam XW = (SZER > 1) ? $clog2(SZER) : 1;
    localparam integer  XMAX = SZER - 1;

    reg [2*W-1:0] mem [0:SZER-1];
    integer i;
    initial for (i = 0; i < SZER; i = i + 1) mem[i] = {(2*W){1'b0}};

    reg [XW-1:0]  x, x_d;
    reg [W-1:0]   piksel_d;
    reg [2*W-1:0] stare;                     // {linia−2, linia−1} spod adresu x

    always @(posedge clk) begin
        if (in_valid) stare <= mem[x];
        if (out_valid) mem[x_d] <= {stare[W-1:0], piksel_d};
    end

    always @(posedge clk)
        if (rst) begin
            x         <= {XW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                x_d      <= x;
                piksel_d <= piksel;
                x        <= (x == XMAX[XW-1:0]) ? {XW{1'b0}} : x + 1'b1;
            end
        end

    assign p0 = piksel_d;
    assign p1 = stare[W-1:0];
    assign p2 = stare[2*W-1:W];
endmodule

`default_nettype wire

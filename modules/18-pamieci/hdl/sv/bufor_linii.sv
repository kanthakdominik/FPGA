// Bufor dwóch linii obrazu (18.04): kolumna trzech pikseli (bieżąca linia i dwie poprzednie) dla każdego
// piksela strumienia rastrowego. Jedna pamięć SZER × 2W: odczyt adresu x w takcie piksela, zapis
// {linia−1, bieżący} pod ten sam adres w takcie następnym; przed dwiema pierwszymi liniami zera.
module bufor_linii #(
    parameter int W    = 8,
    parameter int SZER = 16
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         in_valid,
    input  logic [W-1:0] piksel,
    output logic         out_valid,
    output logic [W-1:0] p0,
    output logic [W-1:0] p1,
    output logic [W-1:0] p2
);
    localparam int XW = (SZER > 1) ? $clog2(SZER) : 1;

    logic [2*W-1:0] mem [SZER] = '{default: '0};
    logic [XW-1:0]  x, x_d;
    logic [W-1:0]   piksel_d;
    logic [2*W-1:0] stare;

    always_ff @(posedge clk) begin
        if (in_valid) stare <= mem[x];
        if (out_valid) mem[x_d] <= {stare[W-1:0], piksel_d};
    end

    always_ff @(posedge clk)
        if (rst) begin
            x         <= '0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                x_d      <= x;
                piksel_d <= piksel;
                x        <= (x == XW'(SZER - 1)) ? '0 : x + 1'b1;
            end
        end

    assign p0 = piksel_d;
    assign p1 = stare[W-1:0];
    assign p2 = stare[2*W-1:W];
endmodule

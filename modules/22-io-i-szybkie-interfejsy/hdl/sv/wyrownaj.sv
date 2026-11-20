// Wyrównanie granicy słowa (22.03): w fazie treningu nadajnik wysyła stałe słowo WZOR; dopóki odebrane
// słowo się nie zgadza, automat wydaje impuls bitslip i odczekuje 2 słowa (zmiana granicy dociera
// z opóźnieniem); po ILE słowach zgodnych z rzędu — wyrownane = 1.
`default_nettype none

module wyrownaj #(
    parameter integer          N    = 8,
    parameter [N-1:0]          WZOR = 8'h6B,
    parameter integer          ILE  = 8
) (
    input  logic         clk,
    input  logic         rst,
    input  logic [N-1:0] slowo,
    input  logic         wazne,
    output logic          bitslip,
    output logic          wyrownane,
    output logic  [7:0]   poslizgi
);
    /* verilator lint_off WIDTHTRUNC */
    localparam [7:0] OST = ILE - 1;
    /* verilator lint_on WIDTHTRUNC */
    logic [1:0] czekaj;
    logic [7:0] zgodne;

    always_ff @(posedge clk) begin
        bitslip <= 1'b0;
        if (rst) begin
            czekaj    <= 2'd0;
            zgodne    <= 8'd0;
            wyrownane <= 1'b0;
            poslizgi  <= 8'd0;
        end else if (wazne && !wyrownane) begin
            if (czekaj != 2'd0)
                czekaj <= czekaj - 1'b1;
            else if (slowo == WZOR) begin
                zgodne <= zgodne + 1'b1;
                if (zgodne == OST) wyrownane <= 1'b1;
            end else begin
                zgodne   <= 8'd0;
                bitslip  <= 1'b1;
                poslizgi <= poslizgi + 1'b1;
                czekaj   <= 2'd2;
            end
        end
    end
endmodule

`default_nettype wire

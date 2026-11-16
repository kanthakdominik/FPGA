// Licznik modulo MODULO z zezwoleniem i resetem synchronicznym (MODULO >= 2).
`default_nettype none

module counter_mod #(
    parameter integer MODULO = 10                  // liczba stanów: 0 .. MODULO - 1
) (
    input  wire                        clk,
    input  wire                        rst,        // synchroniczny, aktywny wysoki
    input  wire                        en,
    output reg  [$clog2(MODULO)-1:0]   count,
    output wire                        wrap        // 1, gdy w tym takcie licznik przejdzie z MODULO - 1 do 0
);
    initial count = 0;                             // wartość po konfiguracji (jak := 0 w VHDL)

    assign wrap = en && (count == MODULO - 1);

    always @(posedge clk) begin
        if (rst)
            count <= 0;
        else if (en)
            count <= wrap ? 0 : count + 1'b1;
    end
endmodule

`default_nettype wire

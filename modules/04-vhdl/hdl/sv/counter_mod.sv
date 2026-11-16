// Licznik modulo MODULO z zezwoleniem i resetem synchronicznym (MODULO >= 2).
module counter_mod #(
    parameter int MODULO = 10                      // liczba stanów: 0 .. MODULO - 1
) (
    input  logic                      clk,
    input  logic                      rst,         // synchroniczny, aktywny wysoki
    input  logic                      en,
    output logic [$clog2(MODULO)-1:0] count,
    output logic                      wrap         // 1, gdy w tym takcie licznik przejdzie z MODULO - 1 do 0
);
    assign wrap = en && (count == MODULO - 1);

    always_ff @(posedge clk) begin
        if (rst)
            count <= '0;
        else if (en)
            count <= wrap ? '0 : count + 1'b1;
    end
endmodule

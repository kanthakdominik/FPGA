// Rejestr W-bitowy z zezwoleniem zapisu (en) i resetem synchronicznym.
module register_en #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         rst,            // synchroniczny, aktywny wysoki
    input  logic         en,
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);
    always_ff @(posedge clk) begin
        if (rst)
            q <= '0;
        else if (en)
            q <= d;                      // en = 0: q pamięta poprzednią wartość
    end
endmodule

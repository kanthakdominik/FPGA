// Rejestr W-bitowy z zezwoleniem zapisu (en) i resetem synchronicznym.
`default_nettype none

module register_en #(
    parameter integer W = 8
) (
    input  wire         clk,
    input  wire         rst,             // synchroniczny, aktywny wysoki
    input  wire         en,
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= {W{1'b0}};
        else if (en)
            q <= d;                      // en = 0: q pamięta poprzednią wartość
    end
endmodule

`default_nettype wire

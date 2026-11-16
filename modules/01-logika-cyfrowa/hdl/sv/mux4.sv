// Multiplekser 4:1 dla słów W-bitowych.
module mux4 #(
    parameter int W = 8
) (
    input  logic [W-1:0] d0, d1, d2, d3,
    input  logic [1:0]   sel,
    output logic [W-1:0] y
);
    always_comb begin
        unique case (sel)
            2'd0: y = d0;
            2'd1: y = d1;
            2'd2: y = d2;
            2'd3: y = d3;
        endcase
    end
endmodule

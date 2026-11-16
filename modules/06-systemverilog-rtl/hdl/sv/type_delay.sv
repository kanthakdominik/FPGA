// Linia opóźniająca parametryzowana typem: działa dla wektorów, struktur i tablic spakowanych.
module type_delay #(
    parameter type T     = logic [7:0],
    parameter int  DEPTH = 2                       // co najmniej 1
) (
    input  logic clk,
    input  T     d,
    output T     q
);
    T stage [DEPTH];

    always_ff @(posedge clk) begin
        stage[0] <= d;
        for (int i = 1; i < DEPTH; i++)
            stage[i] <= stage[i-1];
    end

    assign q = stage[DEPTH-1];
endmodule

// Sumator liczb ze znakiem z nasyceniem: przy przepełnieniu wynik to największa albo najmniejsza liczba.
`default_nettype none

module sat_add #(
    parameter integer W = 8
) (
    input  wire signed [W-1:0] a, b,               // liczby U2
    output reg  signed [W-1:0] y,
    output reg                 sat                 // 1, gdy wynik został obcięty
);
    localparam signed [W-1:0] MAX_VAL = {1'b0, {(W-1){1'b1}}};
    localparam signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}};

    // wszystkie argumenty signed -> poszerzenie do W+1 bitów powiela bit znaku
    wire signed [W:0] sum = a + b;

    always @* begin
        if (sum[W] != sum[W-1]) begin              // wynik nie mieści się w W bitach
            sat = 1'b1;
            y   = sum[W] ? MIN_VAL : MAX_VAL;
        end else begin
            sat = 1'b0;
            y   = sum[W-1:0];
        end
    end
endmodule

`default_nettype wire

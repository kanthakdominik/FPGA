// Sumator liczb ze znakiem z nasyceniem: przy przepełnieniu wynik to największa albo najmniejsza liczba.
module sat_add #(
    parameter int W = 8
) (
    input  logic signed [W-1:0] a, b,              // liczby U2
    output logic signed [W-1:0] y,
    output logic                sat                // 1, gdy wynik został obcięty
);
    localparam logic signed [W-1:0] MAX_VAL = {1'b0, {(W-1){1'b1}}};
    localparam logic signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}};

    logic signed [W:0] sum;
    assign sum = a + b;                            // wszystkie signed: poszerzenie powiela bit znaku

    always_comb begin
        sat = (sum[W] != sum[W-1]);                // wynik nie mieści się w W bitach
        if (!sat)        y = sum[W-1:0];
        else if (sum[W]) y = MIN_VAL;
        else             y = MAX_VAL;
    end
endmodule

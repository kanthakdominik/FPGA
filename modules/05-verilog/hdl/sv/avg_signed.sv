// Średnia dwóch liczb ze znakiem zaokrąglona w dół: y = floor((a + b) / 2).
module avg_signed #(
    parameter int W = 8
) (
    input  logic signed [W-1:0] a, b,
    output logic signed [W-1:0] y
);
    logic signed [W:0] sum;

    assign sum = a + b;
    assign y   = W'(sum >>> 1);                    // przesunięcie arytmetyczne, rzutowanie na W bitów
endmodule

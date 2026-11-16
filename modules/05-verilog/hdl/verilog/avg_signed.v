// Średnia dwóch liczb ze znakiem zaokrąglona w dół: y = floor((a + b) / 2).
// Wynik zawsze mieści się w W bitach — przepełnienie nie jest możliwe.
`default_nettype none

module avg_signed #(
    parameter integer W = 8
) (
    input  wire signed [W-1:0] a, b,
    output wire signed [W-1:0] y
);
    wire signed [W:0] sum = a + b;                 // wszystko signed: poszerzenie powiela bit znaku
    wire signed [W:0] half = sum >>> 1;            // przesunięcie arytmetyczne: zaokrąglenie w dół
    assign y = half[W-1:0];
endmodule

`default_nettype wire

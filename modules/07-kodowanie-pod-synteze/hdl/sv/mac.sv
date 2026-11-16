// Mnożenie z akumulacją (MAC) liczb ze znakiem, potok 3-stopniowy:
// rejestry wejść -> rejestr iloczynu -> akumulator. first = 1 zaczyna nową sumę od tej próbki.
module mac #(
    parameter int W     = 9,                   // 9 bitów = połowa bloku mnożarki MAX 10
    parameter int ACC_W = 24
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    in_valid,
    input  logic                    first,
    input  logic signed [W-1:0]     a,
    input  logic signed [W-1:0]     b,
    output logic signed [ACC_W-1:0] acc,
    output logic                    acc_valid = 1'b0
);
    logic signed [W-1:0]   a_r, b_r;
    logic signed [2*W-1:0] p_r;
    logic                  v1 = 1'b0, v2 = 1'b0, f1, f2;

    always_ff @(posedge clk) begin
        a_r <= a;                              // rejestry danych bez resetu — mogą trafić do bloku mnożarki
        b_r <= b;
        f1  <= first;
        p_r <= (2*W)'(a_r) * (2*W)'(b_r);      // rozszerzenie ze znakiem (operandy signed) do 2W bitów
        f2  <= f1;
        if (v2)
            acc <= f2 ? ACC_W'(p_r) : acc + ACC_W'(p_r);
        if (rst) begin
            v1 <= 1'b0; v2 <= 1'b0; acc_valid <= 1'b0;
        end else begin
            v1 <= in_valid; v2 <= v1; acc_valid <= v2;
        end
    end
endmodule

// Mnożenie z akumulacją (MAC) liczb ze znakiem, potok 3-stopniowy:
// rejestry wejść -> rejestr iloczynu -> akumulator. first = 1 zaczyna nową sumę od tej próbki.
`default_nettype none

module mac #(
    parameter W     = 9,                       // 9 bitów = połowa bloku mnożarki MAX 10
    parameter ACC_W = 24
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire                    first,
    input  wire signed [W-1:0]     a,
    input  wire signed [W-1:0]     b,
    output reg  signed [ACC_W-1:0] acc,
    output reg                     acc_valid = 1'b0
);
    reg signed [W-1:0]     a_r, b_r;
    reg signed [2*W-1:0]   p_r;
    reg                    v1 = 1'b0, v2 = 1'b0, f1, f2;
    wire signed [ACC_W-1:0] p_ext = {{(ACC_W-2*W){p_r[2*W-1]}}, p_r};

    always @(posedge clk) begin
        a_r <= a;                              // rejestry danych bez resetu — mogą trafić do bloku mnożarki
        b_r <= b;
        f1  <= first;
        /* verilator lint_off WIDTHEXPAND */
        p_r <= a_r * b_r;                      // iloczyn ze znakiem na 2W bitach
        /* verilator lint_on WIDTHEXPAND */
        f2  <= f1;
        if (v2)
            acc <= f2 ? p_ext : acc + p_ext;
        if (rst) begin
            v1 <= 1'b0; v2 <= 1'b0; acc_valid <= 1'b0;
        end else begin
            v1 <= in_valid; v2 <= v1; acc_valid <= v2;
        end
    end
endmodule

`default_nettype wire

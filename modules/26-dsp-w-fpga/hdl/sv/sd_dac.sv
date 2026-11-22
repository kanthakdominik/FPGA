// Przetwornik sigma-delta pierwszego rzędu (26.03): 16-bitowa próbka ze znakiem -> strumień bitów, w którym
// gęstość jedynek = (x + 32768) / 65536. Za filtrem RC (np. 1 kΩ, 10 nF) na wyjściu cyfrowym daje napięcie
// proporcjonalne do próbki; szum kwantyzacji przesunięty do wysokich częstotliwości.
`default_nettype none

module sd_dac (
    input  logic               clk,
    input  logic               rst,
    input  logic signed [15:0] x,
    output logic                q
);
    logic [16:0] acc;
    always_ff @(posedge clk)
        if (rst) begin
            acc <= 17'd0; q <= 1'b0;
        end else begin
            acc <= {1'b0, acc[15:0]} + {1'b0, ~x[15], x[14:0]};    // przesunięcie o 2^15: kod z przesunięciem
            q   <= acc[16];
        end
endmodule

`default_nettype wire

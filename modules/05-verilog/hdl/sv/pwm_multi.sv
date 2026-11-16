// N kanałów PWM o rozdzielczości W bitów ze wspólnym licznikiem; wyjścia rejestrowane.
module pwm_multi #(
    parameter int N = 4,
    parameter int W = 8
) (
    input  logic                clk,
    input  logic                rst,
    input  logic [N-1:0][W-1:0] duty,              // tablica spakowana: duty[i] to kanał i
    output logic [N-1:0]        pwm
);
    logic [W-1:0] cnt = '0;

    always_ff @(posedge clk) begin
        if (rst) cnt <= '0;
        else     cnt <= cnt + 1'b1;                // zawija się samo na W bitach
    end

    for (genvar i = 0; i < N; i++) begin : g_ch
        always_ff @(posedge clk) begin
            if (rst) pwm[i] <= 1'b0;
            else     pwm[i] <= (cnt < duty[i]);
        end
    end
endmodule

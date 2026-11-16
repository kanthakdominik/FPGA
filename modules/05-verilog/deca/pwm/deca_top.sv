// Moduł nadrzędny DECA — SystemVerilog. Osiem diod z jasnością rosnącą wykładniczo:
// LED[i] ma wypełnienie (2**(i+1) - 1) / 256, od 1/256 (LED[0]) do 255/256 (LED[7]).
module deca_top (
    input  logic       MAX10_CLK1_50,
    output logic [7:0] LED                         // 0 = świeci
);
    localparam int N = 8, W = 8;

    logic [N-1:0][W-1:0] duty;
    logic [N-1:0]        pwm;

    always_comb
        for (int i = 0; i < N; i++)
            duty[i] = W'((1 << (i + 1)) - 1);

    pwm_multi #(.N(N), .W(W)) u_pwm (.clk(MAX10_CLK1_50), .rst(1'b0), .duty, .pwm);

    assign LED = ~pwm;
endmodule

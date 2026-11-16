// Moduł nadrzędny DECA — Verilog. Osiem diod z jasnością rosnącą wykładniczo:
// LED[i] ma wypełnienie (2**(i+1) - 1) / 256, od 1/256 (LED[0]) do 255/256 (LED[7]).
// PWM 8-bitowy przy 50 MHz ma częstotliwość ok. 195 kHz — oko widzi tylko średnią jasność.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    output wire [7:0] LED                          // 0 = świeci
);
    localparam integer N = 8, W = 8;

    wire [N*W-1:0] duty;
    wire [N-1:0]   pwm;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_duty
            localparam [W-1:0] D = (1 << (i + 1)) - 1;
            assign duty[i*W +: W] = D;
        end
    endgenerate

    pwm_multi #(.N(N), .W(W)) u_pwm (
        .clk(MAX10_CLK1_50), .rst(1'b0), .duty(duty), .pwm(pwm)
    );

    assign LED = ~pwm;                             // diody DECA świecą przy stanie niskim
endmodule

`default_nettype wire

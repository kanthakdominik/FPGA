// Testbench PWM: 3 kanały, W = 4 (okres 16 taktów); w każdym okresie liczba taktów w stanie 1 = duty.
`default_nettype none
`timescale 1ns / 1ps

module tb_pwm_multi;
    localparam integer N = 3, W = 4, P = 1 << W;

    reg            clk = 1'b0, rst = 1'b1;
    reg  [N*W-1:0] duty = {4'd15, 4'd5, 4'd0};   // kanał 2: 15, kanał 1: 5, kanał 0: 0
    wire [N-1:0]   pwm;

    always #5 clk = ~clk;

    pwm_multi #(.N(N), .W(W)) dut (.clk(clk), .rst(rst), .duty(duty), .pwm(pwm));

    integer errors = 0, k, ch, period;
    integer high [0:N-1];

    initial begin
        @(negedge clk);
        rst = 1'b0;
        @(negedge clk);                            // jeden takt na rejestr wyjściowy
        for (period = 0; period < 3; period = period + 1) begin
            for (ch = 0; ch < N; ch = ch + 1) high[ch] = 0;
            for (k = 0; k < P; k = k + 1) begin
                for (ch = 0; ch < N; ch = ch + 1) high[ch] = high[ch] + pwm[ch];
                @(negedge clk);
            end
            for (ch = 0; ch < N; ch = ch + 1)
                if (high[ch] != duty[ch*W +: W]) begin
                    $display("okres %0d, kanal %0d: %0d taktow w stanie 1", period, ch, high[ch]);
                    errors = errors + 1;
                end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

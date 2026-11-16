// Testbench PWM: 3 kanały, W = 4 (okres 16 taktów); w każdym okresie liczba taktów w stanie 1 = duty.
`timescale 1ns / 1ps

module tb_pwm_multi;
    localparam int N = 3, W = 4, P = 2**W;

    logic                clk = 1'b0, rst = 1'b1;
    logic [N-1:0][W-1:0] duty = {4'd15, 4'd5, 4'd0};    // duty[2] = 15, duty[1] = 5, duty[0] = 0
    logic [N-1:0]        pwm;

    always #5 clk = ~clk;

    pwm_multi #(.N(N), .W(W)) dut (.*);

    int errors = 0;
    int high [N];

    initial begin
        @(negedge clk);
        rst = 1'b0;
        @(negedge clk);
        for (int period = 0; period < 3; period++) begin
            high = '{default: 0};
            repeat (P) begin
                for (int ch = 0; ch < N; ch++) high[ch] += pwm[ch];
                @(negedge clk);
            end
            for (int ch = 0; ch < N; ch++)
                if (high[ch] != int'(duty[ch])) begin
                    $display("okres %0d, kanal %0d: %0d taktow w stanie 1", period, ch, high[ch]); errors++;
                end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

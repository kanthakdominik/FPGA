// Testbench bicie_serca: POLOKRES = 7, zegar 10 ns — zmiana stanu co 70 ns; reset zeruje wyjście.
`timescale 1ns / 1ps

module tb_bicie_serca;
    logic clk = 1'b0, rst = 1'b1, led;
    always #5 clk = ~clk;
    bicie_serca #(.POLOKRES(7)) dut (.clk, .rst, .led);

    realtime t_ost = 0;
    int zmian = 0, errors = 0;
    always @(led) if (!rst) begin
        if (zmian > 0 && ($realtime - t_ost) != 70.0) begin
            $display("%0t: polokres %0.1f ns", $time, $realtime - t_ost);
            errors++;
        end
        t_ost = $realtime;
        zmian++;
    end

    initial begin
        #23 rst = 1'b0;
        #2000;
        rst = 1'b1;
        #50;
        if (led !== 1'b0) begin $display("reset nie zeruje wyjscia"); errors++; end
        if (errors == 0 && zmian >= 25) $display("PASS");
        else $display("FAIL: %0d bledow, %0d zmian", errors, zmian);
        $finish;
    end
endmodule

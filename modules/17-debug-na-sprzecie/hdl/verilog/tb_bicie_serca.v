// Testbench bicie_serca: POLOKRES = 7 przy zegarze 10 ns — wyjście zmienia stan co 70 ns; reset
// zatrzymuje miganie i zeruje wyjście.
`timescale 1ns / 1ps
`default_nettype none

module tb_bicie_serca;
    reg clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;
    wire led;
    bicie_serca #(.POLOKRES(7)) dut (.clk(clk), .rst(rst), .led(led));

    realtime t_ost = 0;
    integer zmian = 0, errors = 0;
    always @(led) if (!rst) begin
        if (zmian > 0 && ($realtime - t_ost) != 70.0) begin
            $display("%0t: polokres %0.1f ns", $time, $realtime - t_ost);
            errors = errors + 1;
        end
        t_ost = $realtime;
        zmian = zmian + 1;
    end

    initial begin
        #23 rst = 1'b0;
        #2000;
        rst = 1'b1;
        #50;
        if (led !== 1'b0) begin $display("reset nie zeruje wyjscia"); errors = errors + 1; end
        if (errors == 0 && zmian >= 25) $display("PASS");
        else $display("FAIL: %0d bledow, %0d zmian", errors, zmian);
        $finish;
    end
endmodule

`default_nettype wire

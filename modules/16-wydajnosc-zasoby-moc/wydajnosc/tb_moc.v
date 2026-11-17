// Pobudzenie do szacowania aktywności (16.06): dwie netlisty bramkowe izolacja_operandow (ISO = 0 i 1)
// po syntezie Yosysem, ten sam strumień danych (ważne co czwarty takt, pomiędzy losowe śmieci).
// Zapis przebiegów wszystkich sieci do build/moc.vcd — moc.py liczy z niego przełączenia.
`timescale 1ns / 1ps
`default_nettype none

module tb_moc;
    reg clk = 1'b0, rst = 1'b1, vin = 1'b0;
    reg [15:0] a = 16'd0, b = 16'd0;
    wire v0, v1;
    wire [31:0] p0, p1;
    always #5 clk = ~clk;

    izo0 u0 (.clk(clk), .rst(rst), .in_valid(vin), .a(a), .b(b), .out_valid(v0), .p(p0));
    izo1 u1 (.clk(clk), .rst(rst), .in_valid(vin), .a(a), .b(b), .out_valid(v1), .p(p1));

    integer n;
    initial begin
        $dumpfile("build/moc.vcd");
        #23 rst = 1'b0;
        $dumpvars(0, u0);
        $dumpvars(0, u1);
        for (n = 1; n <= 2000; n = n + 1) begin
            @(negedge clk);
            vin = (n % 4 == 0);
            a = $random;
            b = $random;
        end
        $display("koniec: %0d taktow", n - 1);
        $finish;
    end
endmodule

`default_nettype wire

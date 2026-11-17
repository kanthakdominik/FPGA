// Testbench bramkowanie: 400 taktów z losowym en (rejestr taktowany clk). Sprawdzane:
// cnt_icg == cnt_ce w każdym takcie, cnt_and == cnt_ce + liczba okien en = 1 (dodatkowe zbocze
// zegara bramkowanego bramką AND na początku każdego okna).
`default_nettype none
`timescale 1ns / 1ps

module tb_bramkowanie;
    reg        clk = 1'b0, rst = 1'b1, en = 1'b0;
    wire [7:0] cnt_ce, cnt_and, cnt_icg;
    integer    errors = 0, n_okien = 0, k, seed = 15;
    reg  [7:0] oczek;

    always #5 clk = ~clk;

    bramkowanie dut (.clk(clk), .rst(rst), .en(en), .cnt_ce(cnt_ce), .cnt_and(cnt_and), .cnt_icg(cnt_icg));

    always @(posedge clk)
        if (rst) en <= 1'b0;
        else     en <= (($random(seed) & 3) == 0) ? ~en : en;
    always @(posedge en) if (!rst) n_okien = n_okien + 1;

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (k = 0; k < 400; k = k + 1) begin
            @(negedge clk);
            oczek = cnt_ce + n_okien;
            if (cnt_icg !== cnt_ce) begin
                $display("%0t: cnt_icg=%0d cnt_ce=%0d", $time, cnt_icg, cnt_ce); errors = errors + 1;
            end
            if (cnt_and !== oczek) begin
                $display("%0t: cnt_and=%0d, oczekiwano %0d", $time, cnt_and, oczek); errors = errors + 1;
            end
        end
        oczek = cnt_and - cnt_ce;
        $display("okien en=1: %0d, cnt_ce=%0d, cnt_and=%0d (o %0d za duzo), cnt_icg=%0d",
                 n_okien, cnt_ce, cnt_and, oczek, cnt_icg);
        if (n_okien < 10) begin $display("pokrycie: za malo okien"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

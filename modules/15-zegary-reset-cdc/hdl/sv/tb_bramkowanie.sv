// Testbench bramkowanie: 400 taktów z losowym en (rejestr taktowany clk). Sprawdzane:
// cnt_icg == cnt_ce w każdym takcie, cnt_and == cnt_ce + liczba okien en = 1 (dodatkowe zbocze
// zegara bramkowanego bramką AND na początku każdego okna).
`timescale 1ns / 1ps

module tb_bramkowanie;
    logic       clk = 1'b0, rst = 1'b1, en = 1'b0;
    logic [7:0] cnt_ce, cnt_and, cnt_icg;
    int         errors = 0, n_okien = 0;

    always #5 clk = ~clk;

    bramkowanie dut (.*);

    // en z przerzutnika — zmienia się tuż po narastającym zboczu, jak w prawdziwym układzie
    always @(posedge clk) begin
        if (rst) en <= 1'b0;
        else     en <= ($urandom_range(3) == 0) ? ~en : en;
    end
    always @(posedge en) if (!rst) n_okien++;

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (400) begin
            @(negedge clk);
            if (cnt_icg !== cnt_ce) begin
                $display("%0t: cnt_icg=%0d cnt_ce=%0d", $time, cnt_icg, cnt_ce); errors++;
            end
            if (cnt_and !== 8'(cnt_ce + n_okien)) begin
                $display("%0t: cnt_and=%0d, oczekiwano %0d", $time, cnt_and, 8'(cnt_ce + n_okien)); errors++;
            end
        end
        $display("okien en=1: %0d, cnt_ce=%0d, cnt_and=%0d (o %0d za duzo), cnt_icg=%0d",
                 n_okien, cnt_ce, cnt_and, 8'(cnt_and - cnt_ce), cnt_icg);
        if (n_okien < 10) begin $display("pokrycie: za malo okien"); errors++; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

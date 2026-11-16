// Testbench arbitra karuzelowego: losowe zgłoszenia porównane z modelem, potem sprawiedliwość przy pełnym obciążeniu.
`timescale 1ns / 1ps

module tb_rr_arbiter;
    logic       clk = 1'b0, rst = 1'b1;
    logic [3:0] req = '0, grant;
    logic [1:0] grant_idx;
    logic       grant_valid;

    always #5 clk = ~clk;

    rr_arbiter dut (.*);

    int errors = 0;

    initial begin
        int         last = 3;
        logic [3:0] e;
        logic [7:0] lfsr = 8'hC3;
        @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 200; k++) begin
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 8'hB8) : (lfsr >> 1);
            req  = (k >= 150) ? 4'b1111 : lfsr[3:0];
            #1;
            e = '0;                                      // model: pierwszy zgłaszający po last
            for (int s = 1; s <= 4; s++)
                if (e == '0 && req[(last + s) % 4]) e[(last + s) % 4] = 1'b1;
            if (grant != e || grant_valid != (e != '0) || (e != '0 && e[grant_idx] != 1'b1)) begin
                $display("takt %0d: req=%b grant=%b idx=%0d, oczekiwano %b", k, req, grant, grant_idx, e); errors++;
            end
            if (k >= 150 && int'(grant_idx) != (last + 1) % 4) begin
                $display("pelne obciazenie: brak rotacji w takcie %0d", k); errors++;
            end
            if (e != '0) last = grant_idx;
            @(negedge clk);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

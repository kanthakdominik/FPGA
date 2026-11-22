// Testbench zadania 5: najpierw wszystkie 4 zgłoszenia stale — przydziały muszą krążyć 0, 1, 2, 3, 0, ...; potem
// losowe zgłoszenia z modelem (ten sam algorytm) i sprawdzeniem, że przydział ma jedną jedynkę, trafia
// w zgłoszenie, a zgłoszenie trwające bez przerwy czeka najwyżej 3 takty.
`timescale 1ns / 1ps
`default_nettype none

module tb_rr_arbiter;
    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg  [3:0] req = 4'd0;
    wire [3:0] grant;
    always #5 clk = ~clk;

    rr_arbiter #(.N(4)) dut (.clk(clk), .rst(rst), .req(req), .grant(grant));

    integer   errors = 0, ptr = 0, i, j, k, seed = 5, max_wait = 0, n_grant = 0;
    integer   wait_cnt [0:3];
    reg [3:0] exp;
    reg [3:0] granted = 4'd0;              // przydział z ostatniego zbocza
    reg       found;

    initial for (j = 0; j < 4; j = j + 1) wait_cnt[j] = 0;

    always @(posedge clk)
        if (!rst) begin
            exp = 4'd0; found = 1'b0;
            for (k = 0; k < 4; k = k + 1)
                if (!found && req[(ptr + k) % 4]) begin found = 1'b1; exp[(ptr + k) % 4] = 1'b1; ptr = (ptr + k + 1) % 4; end
            if (grant !== exp) begin
                $display("%0t: req=%b grant=%b oczekiwano %b", $time, req, grant, exp); errors = errors + 1;
            end
            if ((grant & ~req) != 4'd0) begin $display("%0t: przydzial bez zgloszenia", $time); errors = errors + 1; end
            if (grant != 4'd0) n_grant = n_grant + 1;
            granted = grant;
            for (j = 0; j < 4; j = j + 1) begin
                if (req[j] && !grant[j]) wait_cnt[j] = wait_cnt[j] + 1;
                else                     wait_cnt[j] = 0;
                if (wait_cnt[j] > max_wait) max_wait = wait_cnt[j];
            end
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        req = 4'b1111;
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            if (grant != (4'b0001 << (i % 4))) begin
                $display("rotacja: takt %0d grant=%b", i, grant); errors = errors + 1;
            end
        end
        for (i = 0; i < 1000; i = i + 1) begin
            @(negedge clk);
            // zgłoszenie trwa do przydziału (jak w prawdziwym układzie), nowe pojawiają się losowo
            req = (req & ~granted) | ($random(seed) & 4'hF);
        end
        @(negedge clk) req = 4'd0;
        @(negedge clk);
        $display("przydzialow %0d, najdluzsze oczekiwanie %0d taktow", n_grant, max_wait);
        if (max_wait > 3) begin $display("zaglodzenie"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire

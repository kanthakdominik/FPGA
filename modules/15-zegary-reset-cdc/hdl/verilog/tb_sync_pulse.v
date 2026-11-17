// Testbench sync_pulse i sync_bit: dwa kierunki — szybki 100 MHz -> wolny 36,6 MHz i odwrotnie.
// Impulsy podawane losowo, gdy busy = 0. Sprawdzane: liczba impulsów odebranych = wysłanych,
// impuls docelowy trwa 1 takt, poziom przechodzi przez sync_bit w 3 taktach docelowych.
`default_nettype none
`timescale 1ns / 1ps

module tb_sync_pulse;
    reg clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1;
    always #5     clk_f = ~clk_f;
    always #13.65 clk_s = ~clk_s;

    reg  p1 = 1'b0, p2 = 1'b0, lvl = 1'b0, stop = 1'b0;
    wire b1, q1, b2, q2, lvl_s;
    sync_pulse u1 (.clk_src(clk_f), .rst_src(rst), .src_pulse(p1), .busy(b1),
                   .clk_dst(clk_s), .rst_dst(rst), .dst_pulse(q1));
    sync_pulse u2 (.clk_src(clk_s), .rst_src(rst), .src_pulse(p2), .busy(b2),
                   .clk_dst(clk_f), .rst_dst(rst), .dst_pulse(q2));
    sync_bit #(.STAGES(2)) u3 (.clk(clk_s), .d(lvl), .q(lvl_s));

    integer errors = 0, wys1 = 0, odb1 = 0, wys2 = 0, odb2 = 0, k, seed = 3;
    reg q1_d = 1'b0, q2_d = 1'b0;
    always @(posedge clk_f) if (!rst && p1 && !b1) wys1 = wys1 + 1;
    always @(posedge clk_s) if (!rst && q1) odb1 = odb1 + 1;
    always @(posedge clk_s) if (!rst && p2 && !b2) wys2 = wys2 + 1;
    always @(posedge clk_f) if (!rst && q2) odb2 = odb2 + 1;
    always @(posedge clk_s) begin
        if (q1 && q1_d) begin $display("q1 dluzszy niz takt"); errors = errors + 1; end
        q1_d <= q1;
    end
    always @(posedge clk_f) begin
        if (q2 && q2_d) begin $display("q2 dluzszy niz takt"); errors = errors + 1; end
        q2_d <= q2;
    end

    always @(negedge clk_f) p1 <= !rst && !stop && !b1 && (($random(seed) & 3) == 0);
    always @(negedge clk_s) p2 <= !rst && !stop && !b2 && (($random(seed) & 1) == 0);

    initial begin
        @(negedge rst);
        for (k = 0; k < 40; k = k + 1) begin
            repeat (5 + ($unsigned($random(seed)) % 16)) @(negedge clk_f);
            lvl = ~lvl;
            repeat (3) @(posedge clk_s);
            #1;
            if (lvl_s !== lvl) begin $display("%0t: poziom nie dotarl w 3 taktach", $time); errors = errors + 1; end
        end
    end

    initial begin
        #100 rst = 1'b0;
        #40000 stop = 1'b1;                    // koniec: brak nowych impulsów, czas na dotarcie ostatnich
        #500;
        $display("szybki->wolny: wyslano %0d, odebrano %0d; wolny->szybki: wyslano %0d, odebrano %0d",
                 wys1, odb1, wys2, odb2);
        if (wys1 != odb1 || wys2 != odb2) errors = errors + 1;
        if (wys1 < 100 || wys2 < 100) begin $display("pokrycie: za malo impulsow"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

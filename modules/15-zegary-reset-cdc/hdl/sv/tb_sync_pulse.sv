// Testbench sync_pulse i sync_bit: dwa kierunki — szybki 100 MHz -> wolny 36,6 MHz i odwrotnie.
// Impulsy podawane losowo, gdy busy = 0. Sprawdzane: liczba impulsów odebranych = wysłanych,
// impuls docelowy trwa 1 takt, opóźnienie impulsu i poziomu ograniczone (STAGES + 2 takty docelowe).
`timescale 1ns / 1ps

module tb_sync_pulse;
    logic clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1;
    always #5     clk_f = ~clk_f;              // 100 MHz
    always #13.65 clk_s = ~clk_s;              // 36,6 MHz — bez wspólnej wielokrotności z clk_f

    // kierunek 1: szybki -> wolny, kierunek 2: wolny -> szybki
    logic p1 = 1'b0, b1, q1, p2 = 1'b0, b2, q2;
    sync_pulse u1 (.clk_src(clk_f), .rst_src(rst), .src_pulse(p1), .busy(b1),
                   .clk_dst(clk_s), .rst_dst(rst), .dst_pulse(q1));
    sync_pulse u2 (.clk_src(clk_s), .rst_src(rst), .src_pulse(p2), .busy(b2),
                   .clk_dst(clk_f), .rst_dst(rst), .dst_pulse(q2));

    // poziom: sync_bit w kierunku szybki -> wolny
    logic lvl = 1'b0, lvl_s;
    sync_bit #(.STAGES(2)) u3 (.clk(clk_s), .d(lvl), .q(lvl_s));

    int errors = 0, wys1 = 0, odb1 = 0, wys2 = 0, odb2 = 0;
    always @(posedge clk_f) if (!rst && p1 && !b1) wys1++;
    always @(posedge clk_s) if (!rst && q1) odb1++;
    always @(posedge clk_s) if (!rst && p2 && !b2) wys2++;
    always @(posedge clk_f) if (!rst && q2) odb2++;

    // impuls docelowy 1 takt
    logic q1_d = 1'b0, q2_d = 1'b0;
    always @(posedge clk_s) begin if (q1 && q1_d) begin $display("q1 dluzszy niz takt"); errors++; end q1_d <= q1; end
    always @(posedge clk_f) begin if (q2 && q2_d) begin $display("q2 dluzszy niz takt"); errors++; end q2_d <= q2; end

    // źródła impulsów
    always @(negedge clk_f) p1 <= !rst && !b1 && ($urandom_range(3) == 0);
    always @(negedge clk_s) p2 <= !rst && !b2 && ($urandom_range(1) == 0);

    // poziom: zmiana co jakiś czas, sprawdzenie, że po 3 taktach clk_s wyjście ją pokazuje
    initial begin
        @(negedge rst);
        repeat (40) begin
            repeat ($urandom_range(20, 5)) @(negedge clk_f);
            lvl = ~lvl;
            repeat (3) @(posedge clk_s);
            #1;
            if (lvl_s !== lvl) begin $display("%0t: poziom nie dotarl w 3 taktach", $time); errors++; end
        end
    end

    initial begin
        #100 rst = 1'b0;
        #40000;
        force p1 = 1'b0;                       // koniec: brak nowych impulsów, czas na dotarcie ostatnich
        force p2 = 1'b0;
        #500;
        $display("szybki->wolny: wyslano %0d, odebrano %0d; wolny->szybki: wyslano %0d, odebrano %0d",
                 wys1, odb1, wys2, odb2);
        if (wys1 != odb1 || wys2 != odb2) errors++;
        if (wys1 < 100 || wys2 < 100) begin $display("pokrycie: za malo impulsow"); errors++; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

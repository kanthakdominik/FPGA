// Testbench pomiar_czestotliwosci: odniesienie 50 MHz, okno 2500 taktów; zegary mierzone 37,3 MHz
// (oczekiwane ok. 1865) i 100 MHz (5000). Pięć wyników każdego miernika w granicach ±1.
`timescale 1ns / 1ps

module tb_pomiar_czestotliwosci;
    localparam int BRAMKA = 2500;
    logic clk_ref = 1'b0, clk_a = 1'b0, clk_b = 1'b0, rst = 1'b1;
    always #10 clk_ref = ~clk_ref;
    initial begin #3.3 forever #13.405 clk_a = ~clk_a; end
    initial begin #1.7 forever #5      clk_b = ~clk_b; end

    logic [23:0] wa, wb;
    logic        va, vb;
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(BRAMKA)) u_a (.clk_ref, .rst, .clk_mier(clk_a), .wynik(wa), .wynik_valid(va));
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(BRAMKA)) u_b (.clk_ref, .rst, .clk_mier(clk_b), .wynik(wb), .wynik_valid(vb));

    real oa = 1.0e9 / 26.81 * BRAMKA / 50.0e6;
    real ob = 100.0e6 * BRAMKA / 50.0e6;
    int errors = 0, na = 0, nb = 0;

    always @(posedge clk_ref) begin
        if (va) begin
            na++;
            $display("37,3 MHz: %0d (teoria %0.1f)", wa, oa);
            if (real'(wa) < oa - 1.0 || real'(wa) > oa + 1.0) errors++;
        end
        if (vb) begin
            nb++;
            $display("100 MHz: %0d (teoria %0.1f)", wb, ob);
            if (real'(wb) < ob - 1.0 || real'(wb) > ob + 1.0) errors++;
        end
    end

    initial begin
        #95 rst = 1'b0;
        wait (na >= 5 && nb >= 5);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #1000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

// Testbench rst_sekwencer: clk_a 100 MHz, clk_b 58,8 MHz, 30 impulsów arst_n w losowych chwilach.
// Sprawdzane: ustawienie resetu w obu domenach natychmiast (bez czekania na zegar), zdjęcie rst_a
// dokładnie na STAGES-tym zboczu clk_a po zwolnieniu arst_n, zdjęcie rst_b tylko na zboczu clk_b
// i nie wcześniej niż rst_a, liczba taktów clk_b od rst_a do rst_b w granicach STAGES…STAGES+1.
`timescale 1ns / 1ps

module tb_rst_sekwencer;
    localparam int STAGES = 2;
    logic clk_a = 1'b0, clk_b = 1'b0, arst_n = 1'b0, rst_a, rst_b;
    always #5    clk_a = ~clk_a;
    always #8.5  clk_b = ~clk_b;

    rst_sekwencer #(.STAGES(STAGES)) dut (.*);

    int errors = 0, n_a = 0, n_b = 0;
    realtime t_rel, t_a;

    // licznik zboczy po zwolnieniu
    always @(posedge clk_a) if (arst_n) n_a++;
    always @(posedge clk_b) if (arst_n && !rst_a) n_b++;

    always @(negedge rst_a) begin
        t_a = $realtime;
        if (n_a != STAGES) begin $display("%0t: rst_a zdjety po %0d zboczach", $time, n_a); errors++; end
        if (!clk_a) begin $display("%0t: rst_a zdjety poza zboczem clk_a", $time); errors++; end
    end
    always @(negedge rst_b) begin
        if (rst_a) begin $display("%0t: rst_b przed rst_a", $time); errors++; end
        if (!clk_b) begin $display("%0t: rst_b zdjety poza zboczem clk_b", $time); errors++; end
        if (n_b < STAGES || n_b > STAGES + 1) begin $display("%0t: rst_b po %0d taktach clk_b", $time, n_b); errors++; end
    end

    initial begin
        for (int k = 0; k < 30; k++) begin
            #($urandom_range(3000, 200) * 0.1);
            arst_n = 1'b0;
            #0.5;
            if (rst_a !== 1'b1 || rst_b !== 1'b1) begin $display("%0t: reset nie ustawiony natychmiast", $time); errors++; end
            #($urandom_range(500, 50) * 0.1 + 0.05);   // nigdy w chwili zbocza
            n_a = 0;
            n_b = 0;
            arst_n = 1'b1;
            #200;
            if (rst_a || rst_b) begin $display("%0t: reset nie zdjety", $time); errors++; end
        end
        $display("impulsow resetu: 30");
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

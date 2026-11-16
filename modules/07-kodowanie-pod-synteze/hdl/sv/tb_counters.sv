// Testbench tick_gen (DIV = 5 i 7) i bcd_counter (3 cyfry): okres impulsów, wartość licznika
// porównana z liczbą całkowitą modulo 1000, przeniesienie przy przejściu 999 -> 000.
`timescale 1ns / 1ps

module tb_counters;
    logic                clk = 1'b0, rst = 1'b1, en = 1'b0;
    logic                tick5, tick7, carry;
    logic [2:0][3:0]     bcd;

    always #5 clk = ~clk;

    tick_gen    #(.DIV(5))    u_t5  (.clk, .rst, .tick(tick5));
    tick_gen    #(.DIV(7))    u_t7  (.clk, .rst, .tick(tick7));
    bcd_counter #(.DIGITS(3)) u_bcd (.clk, .rst, .en, .bcd, .carry);

    int errors = 0, value = 0, carries = 0;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 1; n <= 1500; n++) begin
            @(negedge clk);                    // po n-tym zboczu od zdjęcia resetu
            if (en) value = (value + 1) % 1000;
            if (tick5 != (n % 5 == 0) || tick7 != (n % 7 == 0)) begin
                $display("takt %0d: tick5=%b tick7=%b", n, tick5, tick7); errors++;
            end
            if (bcd[2] != 4'(value / 100) || bcd[1] != 4'(value / 10 % 10) || bcd[0] != 4'(value % 10)) begin
                $display("takt %0d: bcd=%h, oczekiwano %0d", n, bcd, value); errors++;
            end
            en = ($urandom_range(3) != 0);     // zezwolenie w 3/4 taktów
            #1;
            if (carry != (en && value == 999)) begin
                $display("takt %0d: carry=%b przy %0d", n, carry, value); errors++;
            end
            if (carry) carries++;
        end

        if (carries == 0) begin
            $display("test nie osiagnal przepelnienia licznika"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

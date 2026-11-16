// Testbench tick_gen (DIV = 5 i 7) i bcd_counter (3 cyfry): okres impulsów, wartość licznika
// porównana z liczbą całkowitą modulo 1000, przeniesienie przy przejściu 999 -> 000.
`default_nettype none
`timescale 1ns / 1ps

module tb_counters;
    reg         clk = 1'b0, rst = 1'b1, en = 1'b0;
    wire        tick5, tick7, carry;
    wire [11:0] bcd;

    always #5 clk = ~clk;

    tick_gen    #(.DIV(5))    u_t5  (.clk(clk), .rst(rst), .tick(tick5));
    tick_gen    #(.DIV(7))    u_t7  (.clk(clk), .rst(rst), .tick(tick7));
    bcd_counter #(.DIGITS(3)) u_bcd (.clk(clk), .rst(rst), .en(en), .bcd(bcd), .carry(carry));

    integer errors = 0, n, value = 0, carries = 0, seed = 11;
    reg [11:0] e_bcd;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 1; n <= 1500; n = n + 1) begin
            @(negedge clk);                    // po n-tym zboczu od zdjęcia resetu
            if (en) value = (value + 1) % 1000;
            if (tick5 !== (n % 5 == 0) || tick7 !== (n % 7 == 0)) begin
                $display("takt %0d: tick5=%b tick7=%b", n, tick5, tick7); errors = errors + 1;
            end
            e_bcd[11:8] = value / 100;         // przypisanie obcina do 4 bitów
            e_bcd[7:4]  = value / 10 % 10;
            e_bcd[3:0]  = value % 10;
            if (bcd !== e_bcd) begin
                $display("takt %0d: bcd=%h, oczekiwano %0d", n, bcd, value); errors = errors + 1;
            end
            en = (($random(seed) & 3) != 0);   // zezwolenie w 3/4 taktów
            #1;
            if (carry !== (en && value == 999)) begin
                $display("takt %0d: carry=%b przy %0d", n, carry, value); errors = errors + 1;
            end
            if (carry) carries = carries + 1;
        end

        if (carries == 0) begin
            $display("test nie osiagnal przepelnienia licznika"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

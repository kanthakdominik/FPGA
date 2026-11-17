// Testbench pomiar_czestotliwosci: zegar odniesienia 50 MHz, okno 2500 taktów (50 µs), dwa zegary
// mierzone: 37,3 MHz (okres 26,81 ns, oczekiwane ok. 1865) i 100 MHz (oczekiwane 5000), z fazą
// niezależną od zegara odniesienia. Sprawdzane: pięć kolejnych wyników każdego miernika w granicach ±1
// od wartości teoretycznej; pierwszy wynik po resecie pominięty.
`timescale 1ns / 1ps
`default_nettype none

module tb_pomiar_czestotliwosci;
    localparam BRAMKA = 2500;
    reg clk_ref = 1'b0, clk_a = 1'b0, clk_b = 1'b0, rst = 1'b1;
    always #10    clk_ref = ~clk_ref;
    initial begin #3.3 forever #13.405 clk_a = ~clk_a; end
    initial begin #1.7 forever #5      clk_b = ~clk_b; end

    wire [23:0] wa, wb;
    wire        va, vb;
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(BRAMKA)) u_a (.clk_ref(clk_ref), .rst(rst), .clk_mier(clk_a), .wynik(wa), .wynik_valid(va));
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(BRAMKA)) u_b (.clk_ref(clk_ref), .rst(rst), .clk_mier(clk_b), .wynik(wb), .wynik_valid(vb));

    // oczekiwane: f_mier * BRAMKA / f_ref
    real oa = 1.0e9 / 26.81 * BRAMKA / 50.0e6;
    real ob = 100.0e6 * BRAMKA / 50.0e6;
    integer errors = 0, na = 0, nb = 0;

    always @(posedge clk_ref) begin
        if (va) begin
            na = na + 1;
            $display("37,3 MHz: %0d (teoria %0.1f)", wa, oa);
            if (wa < oa - 1.0 || wa > oa + 1.0) errors = errors + 1;
        end
        if (vb) begin
            nb = nb + 1;
            $display("100 MHz: %0d (teoria %0.1f)", wb, ob);
            if (wb < ob - 1.0 || wb > ob + 1.0) errors = errors + 1;
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

`default_nettype wire

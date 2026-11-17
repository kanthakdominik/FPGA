// Testbench rozgalezienie: N = 64, NDUP = 1 i 8. Wyjście = wejście przesunięte o N pozycji
// (przesunięcia tylko w taktach z zezwoleniem opóźnionym przez en_r); obie wersje identyczne.
`timescale 1ns / 1ps

module tb_rozgalezienie;
    localparam int N = 64;
    logic clk = 1'b0, en = 1'b0, d = 1'b0, q1, q8;
    always #5 clk = ~clk;

    rozgalezienie #(.N(N), .NDUP(1)) u1 (.clk, .en, .d, .q(q1));
    rozgalezienie #(.N(N), .NDUP(8)) u8 (.clk, .en, .d, .q(q8));

    logic [N-1:0] model = '0;
    logic         en_d = 1'b0;
    int n = 0, errors = 0, przes = 0;
    always @(posedge clk) begin
        en_d <= en;
        if (en_d) begin
            model <= {model[N-2:0], d};
            przes++;
        end
    end

    always @(negedge clk) begin
        if (q1 !== model[N-1] || q8 !== model[N-1]) begin
            $display("%0t: q1=%b q8=%b, oczekiwano %b", $time, q1, q8, model[N-1]);
            errors++;
        end
        n++;
        en = ($urandom_range(2) != 0);
        d  = 1'($urandom);
    end

    initial begin
        wait (n == 2000);
        $display("przesuniec: %0d", przes);
        if (errors == 0 && przes > 3 * N) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #100000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

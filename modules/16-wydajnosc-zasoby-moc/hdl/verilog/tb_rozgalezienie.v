// Testbench rozgalezienie: N = 64, warianty NDUP = 1 i 8. Sprawdzane: wyjście = wejście opóźnione o
// N przesunięć (licząc tylko takty z zezwoleniem, które dotarło przez en_r) i obie wersje identyczne.
`timescale 1ns / 1ps
`default_nettype none

module tb_rozgalezienie;
    localparam N = 64;
    reg clk = 1'b0, en = 1'b0, d = 1'b0;
    always #5 clk = ~clk;

    wire q1, q8;
    rozgalezienie #(.N(N), .NDUP(1)) u1 (.clk(clk), .en(en), .d(d), .q(q1));
    rozgalezienie #(.N(N), .NDUP(8)) u8 (.clk(clk), .en(en), .d(d), .q(q8));

    // model: rejestr przesuwny z zezwoleniem opóźnionym o takt
    reg [N-1:0] model = {N{1'b0}};
    reg         en_d = 1'b0;
    integer n = 0, errors = 0, przes = 0;
    always @(posedge clk) begin
        en_d <= en;
        if (en_d) begin
            model <= {model[N-2:0], d};
            przes = przes + 1;
        end
    end

    always @(negedge clk) begin
        if (q1 !== model[N-1] || q8 !== model[N-1]) begin
            $display("%0t: q1=%b q8=%b, oczekiwano %b", $time, q1, q8, model[N-1]);
            errors = errors + 1;
        end
        n = n + 1;
        en = ($random % 3 != 0);
        d  = $random;
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

`default_nettype wire

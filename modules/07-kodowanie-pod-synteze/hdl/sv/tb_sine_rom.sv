// Testbench sine_rom: każdy adres porównany z wartością liczoną funkcją $sin, sprawdzenie opóźnienia
// odczytu (1 takt) i monotoniczności ćwiartki.
`timescale 1ns / 1ps

module tb_sine_rom;
    localparam real PI = 3.14159265358979323846;

    logic       clk = 1'b0;
    logic [5:0] addr = '0;
    logic [7:0] data;

    always #5 clk = ~clk;

    sine_rom dut (.*);

    int errors = 0;

    initial begin
        logic [7:0] prev;
        prev = '0;
        @(negedge clk);
        for (int i = 0; i < 64; i++) begin
            int e;
            addr = 6'(i);
            #1;
            if (i > 0 && data != prev) begin   // przed zboczem wyjście trzyma poprzednią wartość
                $display("adres %0d: wyjscie zmienilo sie bez zbocza", i); errors++;
            end
            @(negedge clk);
            e = int'($floor(255.0 * $sin(PI / 2.0 * (real'(i) + 0.5) / 64.0) + 0.5));
            if (int'(data) != e) begin
                $display("adres %0d: data=%0d, oczekiwano %0d", i, data, e); errors++;
            end
            if (data < prev) begin
                $display("adres %0d: tablica nie jest niemalejaca", i); errors++;
            end
            prev = data;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

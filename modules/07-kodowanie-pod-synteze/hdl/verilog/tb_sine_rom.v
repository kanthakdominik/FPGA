// Testbench sine_rom: każdy adres porównany z wartością liczoną funkcją $sin, sprawdzenie opóźnienia
// odczytu (1 takt) i monotoniczności ćwiartki.
`default_nettype none
`timescale 1ns / 1ps

module tb_sine_rom;
    localparam real PI = 3.14159265358979323846;

    reg        clk = 1'b0;
    reg  [5:0] addr = 6'd0;
    wire [7:0] data;

    always #5 clk = ~clk;

    sine_rom dut (.clk(clk), .addr(addr), .data(data));

    integer errors = 0, i, e;
    reg [7:0] prev;

    initial begin
        @(negedge clk);
        prev = 8'd0;
        for (i = 0; i < 64; i = i + 1) begin
            addr = i;
            #1;
            if (i > 0 && data !== prev) begin            // przed zboczem wyjście trzyma poprzednią wartość
                $display("adres %0d: wyjscie zmienilo sie bez zbocza", i); errors = errors + 1;
            end
            @(negedge clk);
            e = $rtoi(255.0 * $sin(PI / 2.0 * (i + 0.5) / 64.0) + 0.5);
            if (data !== e) begin
                $display("adres %0d: data=%0d, oczekiwano %0d", i, data, e); errors = errors + 1;
            end
            if (data < prev) begin
                $display("adres %0d: tablica nie jest niemalejaca", i); errors = errors + 1;
            end
            prev = data;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

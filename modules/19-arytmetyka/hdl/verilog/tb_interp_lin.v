// Testbench interp_lin (19.06): wszystkie 65 536 wejść strumieniem, porównanie z sin(πx/2)·2^16
// (nasycone do 65535); tolerancja 4 LSB (model w gen_aproks.py: 3,79 LSB). Wypisuje największy
// i średni błąd oraz sprawdza opóźnienie 3 takty.
`timescale 1ns / 1ps
`default_nettype none

module tb_interp_lin;
    localparam real PI = 3.14159265358979323846;
    localparam real TOL = 4.0;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg         in_valid = 1'b0;
    reg  [15:0] x = 16'd0;
    wire        out_valid;
    wire [15:0] y;
    interp_lin dut (.clk(clk), .in_valid(in_valid), .x(x), .out_valid(out_valid), .y(y));

    integer i, k = 0, errors = 0, takt = 0;
    integer t_wej [0:65535];
    real    w, d, m = 0.0, suma = 0.0;

    always @(posedge clk) begin
        takt <= takt + 1;
        if (out_valid) begin
            w = $sin(PI * k / 131072.0) * 65536.0;
            if (w > 65535.0) w = 65535.0;
            d = y - w;
            if (d < 0.0) d = -d;
            if (d > m) m = d;
            suma = suma + d;
            if (d > TOL || takt - t_wej[k] != 3) begin
                if (errors < 10) $display("x=%0d: y=%0d, oczekiwano %f", k, y, w);
                errors = errors + 1;
            end
            k = k + 1;
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        for (i = 0; i < 65536; i = i + 1) begin
            @(negedge clk);
            x = i[15:0]; in_valid = 1'b1; t_wej[i] = takt;
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (5) @(negedge clk);
        $display("wynikow %0d, najwiekszy blad %f LSB, sredni %f LSB", k, m, suma / k);
        if (k != 65536) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

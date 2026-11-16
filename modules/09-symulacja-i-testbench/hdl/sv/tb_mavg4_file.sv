// Testbench mavg4 sterowany wektorami z pliku mavg4_wektory.txt (generator: ../dane/gen_mavg4.py).
// Wiersz: rst in_valid x exp_out_valid exp_y — wejścia przed zboczem, oczekiwane wyjścia po zboczu.
// Plik jest kopiowany do katalogu roboczego symulacji (tools/run_hdl_tests.py, sim/Makefile).
`timescale 1ns / 1ps

module tb_mavg4_file;
    logic              clk = 1'b0, rst = 1'b1, in_valid = 1'b0, out_valid;
    logic signed [7:0] x = '0, y;

    always #5 clk = ~clk;

    mavg4 dut (.*);

    int    fd, line_no = 0, vectors = 0, errors = 0;
    int    v_rst, v_valid, v_x, e_valid, e_y;
    string line;

    initial begin
        fd = $fopen("mavg4_wektory.txt", "r");
        if (fd == 0) begin
            $display("FAIL: brak pliku mavg4_wektory.txt w katalogu roboczym");
            $finish;
        end
        @(negedge clk);
        while ($fgets(line, fd) != 0) begin
            line_no++;
            // komentarze i puste wiersze dają mniej niż 5 pól
            if ($sscanf(line, "%d %d %d %d %d", v_rst, v_valid, v_x, e_valid, e_y) == 5) begin
                rst      = 1'(v_rst);
                in_valid = 1'(v_valid);
                x        = 8'(v_x);
                @(negedge clk);
                vectors++;
                if (out_valid !== 1'(e_valid) || int'(y) != e_y) begin
                    $display("wiersz %0d: out_valid=%b y=%0d, oczekiwano %0d %0d", line_no, out_valid, y, e_valid, e_y);
                    errors++;
                end
            end
        end
        $fclose(fd);

        $display("wektorow: %0d, bledow: %0d", vectors, errors);
        if (vectors < 400) begin
            $display("za malo wektorow — plik niepelny?"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

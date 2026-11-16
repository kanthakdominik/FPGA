// Testbench mavg4 sterowany wektorami z pliku mavg4_wektory.txt (generator: ../dane/gen_mavg4.py).
// Wiersz: rst in_valid x exp_out_valid exp_y — wejścia przed zboczem, oczekiwane wyjścia po zboczu.
// Plik jest kopiowany do katalogu roboczego symulacji (tools/run_hdl_tests.py, sim/Makefile).
`default_nettype none
`timescale 1ns / 1ps

module tb_mavg4_file;
    reg               clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    reg  signed [7:0] x = 8'sd0;
    wire              out_valid;
    wire signed [7:0] y;

    always #5 clk = ~clk;

    mavg4 dut (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(out_valid), .y(y));

    integer fd, n_fields, line_no = 0, vectors = 0, errors = 0;
    integer v_rst, v_valid, v_x, e_valid, e_y;
    reg [8*256-1:0] line;

    initial begin
        fd = $fopen("mavg4_wektory.txt", "r");
        if (fd == 0) begin
            $display("FAIL: brak pliku mavg4_wektory.txt w katalogu roboczym");
            $finish;
        end
        @(negedge clk);
        while (!$feof(fd)) begin
            line = 0;
            if ($fgets(line, fd) != 0) begin
                line_no  = line_no + 1;
                n_fields = $sscanf(line, "%d %d %d %d %d", v_rst, v_valid, v_x, e_valid, e_y);
                if (n_fields == 5) begin       // komentarze i puste wiersze dają mniej pól
                    rst      = v_rst;
                    in_valid = v_valid;
                    x        = v_x;
                    @(negedge clk);
                    vectors = vectors + 1;
                    if (out_valid !== e_valid[0] || y !== e_y[7:0]) begin
                        $display("wiersz %0d: out_valid=%b y=%0d, oczekiwano %0d %0d", line_no, out_valid, y, e_valid, e_y);
                        errors = errors + 1;
                    end
                end
            end
        end
        $fclose(fd);

        $display("wektorow: %0d, bledow: %0d", vectors, errors);
        if (vectors < 400) begin
            $display("za malo wektorow — plik niepelny?"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

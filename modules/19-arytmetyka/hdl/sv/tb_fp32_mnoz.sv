// Testbench (SystemVerilog) fp32_mnoz (19.05): wektory z hdl/dane/fp32_mnoz.hex (generator gen_fp32.py — model
// całkowitoliczbowy sprawdzony względem IEEE 754 w Pythonie): wszystkie pary wartości specjalnych
// (zera, nieskończoności, NaN, zdenormalizowane, skrajne), losowe z całego zakresu, remisy przy
// zaokrąglaniu, granice nadmiaru i niedomiaru. Dane w każdym takcie, opóźnienie 2 takty.
`timescale 1ns / 1ps
`default_nettype none

module tb_fp32_mnoz;
    localparam NMAX = 8192;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic         in_valid = 1'b0;
    logic  [31:0] a = 32'd0, b = 32'd0;
    logic        out_valid, nadmiar, niedomiar;
    logic [31:0] p;
    fp32_mnoz dut (.clk(clk), .in_valid(in_valid), .a(a), .b(b), .out_valid(out_valid), .p(p),
                   .nadmiar(nadmiar), .niedomiar(niedomiar));

    logic  [31:0] wa [0:NMAX-1];
    logic  [31:0] wb [0:NMAX-1];
    logic  [31:0] wp [0:NMAX-1];
    logic  [3:0]  wf [0:NMAX-1];
    int     f, r, n = 0, i, k = 0, errors = 0, takt = 0, n_nan = 0, n_inf = 0, n_zero = 0;
    int     t_wej [0:NMAX-1];

    always @(posedge clk) begin
        takt <= takt + 1;
        if (out_valid) begin
            if (p !== wp[k] || {nadmiar, niedomiar} !== wf[k][1:0] || takt - t_wej[k] != 2) begin
                if (errors < 10)
                    $display("%h * %h = %h (flagi %b%b), oczekiwano %h (%b)", wa[k], wb[k], p, nadmiar, niedomiar,
                             wp[k], wf[k][1:0]);
                errors = errors + 1;
            end
            if (p == 32'h7FC00000) n_nan = n_nan + 1;
            if (p[30:0] == 31'h7F800000) n_inf = n_inf + 1;
            if (p[30:0] == 31'd0) n_zero = n_zero + 1;
            k = k + 1;
        end
    end

    initial begin
        f = $fopen("fp32_mnoz.hex", "r");
        if (f == 0) begin
            $display("FAIL: brak pliku fp32_mnoz.hex");
            $finish;
        end
        r = 4;
        while (r == 4 && n < NMAX) begin
            r = $fscanf(f, "%h %h %h %h\n", wa[n], wb[n], wp[n], wf[n]);
            if (r == 4) n = n + 1;
        end
        $fclose(f);
        repeat (2) @(negedge clk);
        for (i = 0; i < n; i = i + 1) begin
            @(negedge clk);
            a = wa[i]; b = wb[i]; in_valid = 1'b1; t_wej[i] = takt;
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (4) @(negedge clk);
        $display("wektorow %0d, wynikow %0d: NaN %0d, nieskonczonosci %0d, zer %0d", n, k, n_nan, n_inf, n_zero);
        if (k != n || n < 3000) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

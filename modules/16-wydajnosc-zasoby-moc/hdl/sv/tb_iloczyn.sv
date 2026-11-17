// Testbench iloczyn_rown i iloczyn_szer: te same losowe wektory. Równoległa — wynik po 2 taktach dla
// każdych danych; szeregowa — dane przy ready = 1, wynik z done. Sprawdzane: wyniki zgodne z modelem,
// przy ciągłym starcie szeregowa daje wynik co 4 takty.
`timescale 1ns / 1ps

module tb_iloczyn;
    localparam int N = 400;
    logic clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;

    logic [31:0] a = '0, b = '0;
    logic        vin = 1'b0, start = 1'b0, vout, ready, done;
    logic [17:0] y_rown, y_szer;
    iloczyn_rown u_r (.clk, .rst, .in_valid(vin), .a, .b, .out_valid(vout), .y(y_rown));
    iloczyn_szer u_s (.clk, .rst, .start, .a, .b, .ready, .done, .y(y_szer));

    function automatic logic [17:0] model(logic [31:0] fa, logic [31:0] fb);
        logic [17:0] s = '0;
        for (int k = 0; k < 4; k++) s += 18'(fa[8*k +: 8]) * 18'(fb[8*k +: 8]);
        return s;
    endfunction

    logic [17:0] q_r [$], q_s [$];
    int errors = 0, takt = 0, t_done = 0, odst = 0, odst_ok = 0, n_r = 0, n_s = 0;

    always @(posedge clk) if (!rst) begin
        takt <= takt + 1;
        if (vin) q_r.push_back(model(a, b));
        if (start && ready) q_s.push_back(model(a, b));
    end

    always @(negedge clk) begin
        if (!rst) begin
            if (vout) begin
                if (q_r.size() == 0 || y_rown !== q_r[0]) begin
                    $display("%0t: rownolegly y=%0d", $time, y_rown); errors++;
                end
                if (q_r.size() > 0) void'(q_r.pop_front());
                n_r++;
            end
            if (done) begin
                if (q_s.size() == 0 || y_szer !== q_s[0]) begin
                    $display("%0t: szeregowy y=%0d", $time, y_szer); errors++;
                end
                if (q_s.size() > 0) void'(q_s.pop_front());
                if (n_s > 0) begin
                    odst++;
                    if (takt - t_done == 4) odst_ok++;
                end
                t_done = takt;
                n_s++;
            end
        end
        a = ($urandom_range(5) == 0) ? '1 : $urandom;
        b = ($urandom_range(5) == 0) ? '1 : $urandom;
        vin   = ($urandom_range(2) != 0);
        start = (n_s >= N / 2) ? 1'b1 : ($urandom_range(2) == 0);
    end

    initial begin
        #23 rst = 1'b0;
        wait (n_s >= N);
        @(negedge clk);
        $display("rownolegly: %0d wynikow, szeregowy: %0d wynikow; odstep 4 takty: %0d z %0d", n_r, n_s, odst_ok, odst);
        if (errors == 0 && n_r > N && odst_ok >= N / 2 - 2) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #200000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

// Testbench samosprawdzający mavg4: losowe pobudzenia, model referencyjny, tablica wyników (scoreboard)
// i sprawdzenie pokrycia przypadków. Model liczy średnią na liczbach rzeczywistych z $floor —
// inaczej niż układ (odrzucenie dwóch bitów), więc ten sam błąd nie powtórzy się po obu stronach.
`timescale 1ns / 1ps

module tb_mavg4;
    logic              clk = 1'b0, rst = 1'b1, in_valid = 1'b0, out_valid;
    logic signed [7:0] x = '0, y;

    always #5 clk = ~clk;

    mavg4 dut (.*);

`ifdef FALE
    // przebiegi tylko na żądanie: verilator … --trace-fst -DFALE (09.04)
    initial begin
        $dumpfile("tb_mavg4.fst");
        $dumpvars(0, tb_mavg4);
    end
`endif

    // --- model referencyjny
    int m1 = 0, m2 = 0, m3 = 0, m_y = 0;
    bit m_valid = 0;
    int checked = 0, errors = 0, cov_floor = 0, cov_min = 0, cov_max = 0, cov_hold = 0;

    function automatic void model_edge();      // stan modelu po zboczu
        if (rst) begin
            m1 = 0; m2 = 0; m3 = 0; m_y = 0; m_valid = 0;
        end else begin
            m_valid = in_valid;
            if (in_valid) begin
                int s = int'(x) + m1 + m2 + m3;
                m_y = int'($floor(real'(s) / 4.0));
                if (s < 0 && s % 4 != 0) cov_floor++;
                m3 = m2; m2 = m1; m1 = int'(x);
            end
        end
    endfunction

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            rst      = (n == 1500);            // jeden reset w trakcie pracy
            in_valid = ($urandom_range(3) != 0);
            x        = ($urandom_range(7) == 0) ? ($urandom_range(1) ? 8'sd127 : 8'h80) : 8'($urandom);
            @(negedge clk);
            model_edge();
            checked++;
            if (out_valid !== m_valid || int'(y) != m_y) begin
                $display("takt %0d: out_valid=%b y=%0d, model %0d %0d", n, out_valid, y, m_valid, m_y);
                errors++;
            end
            if (m_valid && m_y == -128) cov_min++;
            if (m_valid && m_y == 127)  cov_max++;
            if (!m_valid && !rst)       cov_hold++;
        end

        $display("sprawdzone takty: %0d, bledy: %0d", checked, errors);
        $display("pokrycie: zaokraglenie ujemnych %0d, y = -128: %0d, y = 127: %0d, wstrzymanie: %0d",
                 cov_floor, cov_min, cov_max, cov_hold);
        if (cov_floor == 0 || cov_min == 0 || cov_max == 0 || cov_hold == 0) begin
            $display("niepelne pokrycie przypadkow"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

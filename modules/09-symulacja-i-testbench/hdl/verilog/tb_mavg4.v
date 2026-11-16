// Testbench samosprawdzający mavg4: losowe pobudzenia, model referencyjny, tablica wyników (scoreboard)
// i sprawdzenie pokrycia przypadków. Model liczy średnią na liczbach rzeczywistych z $floor —
// inaczej niż układ (przesunięcie arytmetyczne), więc ten sam błąd nie powtórzy się po obu stronach.
`default_nettype none
`timescale 1ns / 1ps

module tb_mavg4;
    reg               clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    reg  signed [7:0] x = 8'sd0;
    wire              out_valid;
    wire signed [7:0] y;

    always #5 clk = ~clk;

    mavg4 dut (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(out_valid), .y(y));

    // przebiegi tylko na żądanie: vvp … +fale (09.04); bez tego testy w CI nie zapisują plików
    initial
        if ($test$plusargs("fale")) begin
            $dumpfile("tb_mavg4.vcd");
            $dumpvars(0, tb_mavg4);
        end

    // --- tablica wyników i pokrycie
    integer checked = 0, errors = 0, cov_floor = 0, cov_min = 0, cov_max = 0, cov_hold = 0, n, seed = 71;
    integer burst = 0;                         // pozostała długość serii wartości skrajnych
    reg signed [7:0] burst_x;

    // --- model referencyjny
    integer m1 = 0, m2 = 0, m3 = 0, m_y = 0, m_valid = 0;
    task model_edge;                           // stan modelu po zboczu
        integer s;
        begin
            if (rst) begin
                m1 = 0; m2 = 0; m3 = 0; m_y = 0; m_valid = 0;
            end else begin
                m_valid = in_valid;
                if (in_valid) begin
                    s   = x + m1 + m2 + m3;
                    m_y = $rtoi($floor(s / 4.0));
                    if (s < 0 && s % 4 != 0) cov_floor = cov_floor + 1;
                    m3 = m2; m2 = m1; m1 = x;
                end
            end
        end
    endtask


    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 3000; n = n + 1) begin
            rst      = (n == 1500);            // jeden reset w trakcie pracy
            if (burst == 0 && ($random(seed) & 63) == 0) begin   // czasem seria 4..6 jednakowych wartości skrajnych —
                burst   = 4 + (($random(seed) & 32'h7fffffff) % 3);  // bez niej średnia nigdy nie osiąga -128 ani 127
                burst_x = (($random(seed) & 1) != 0) ? 8'h7F : 8'h80;
            end
            if (burst > 0) begin
                in_valid = 1'b1; x = burst_x; burst = burst - 1;
            end else begin
                in_valid = (($random(seed) & 3) != 0);
                x        = (($random(seed) & 7) == 0) ? ((($random(seed) & 1) != 0) ? 8'h7F : 8'h80) : $random(seed);
            end
            @(negedge clk);
            model_edge;
            checked = checked + 1;
            if (out_valid !== m_valid[0] || y !== m_y[7:0]) begin
                $display("takt %0d: out_valid=%b y=%0d, model %0d %0d", n, out_valid, y, m_valid, m_y);
                errors = errors + 1;
            end
            if (m_valid && m_y == -128) cov_min = cov_min + 1;
            if (m_valid && m_y == 127)  cov_max = cov_max + 1;
            if (!m_valid && !rst)       cov_hold = cov_hold + 1;
        end

        $display("sprawdzone takty: %0d, bledy: %0d", checked, errors);
        $display("pokrycie: zaokraglenie ujemnych %0d, y = -128: %0d, y = 127: %0d, wstrzymanie: %0d",
                 cov_floor, cov_min, cov_max, cov_hold);
        if (cov_floor == 0 || cov_min == 0 || cov_max == 0 || cov_hold == 0) begin
            $display("niepelne pokrycie przypadkow"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

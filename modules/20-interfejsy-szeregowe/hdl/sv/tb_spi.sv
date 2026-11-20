// Testbench (SystemVerilog) SPI (20.02): spi_master <-> spi_slave dla czterech trybów (CPOL, CPHA) i dwóch szybkości
// (DIV = 4 i 7: SCLK = f_clk/8 i f_clk/14). W każdym trybie 5 transakcji po 3 słowa z CS trzymanym
// między słowami i 5 transakcji jednosłowowych; dane losowe w obie strony.
// Niezależny monitor protokołu próbkuje MOSI i MISO na zboczach wynikających z trybu (CPHA = 0 — wiodące,
// CPHA = 1 — końcowe) — sprawdza więc obie strony względem definicji trybu, a nie tylko względem siebie.
// Sprawdzane też: SCLK w spoczynku = CPOL przy nieaktywnym CS, 2N zboczy na słowo.
`timescale 1ns / 1ps
`default_nettype none

module tb_spi;
    localparam N = 8, NS = 40;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    logic cpol = 1'b0, cpha = 1'b0;
    int errors = 0, m, i, w, j;

    genvar g;
    generate
        for (g = 0; g < 2; g = g + 1) begin : g_div
            localparam DIV = (g == 0) ? 4 : 7;
            logic          start = 1'b0, dalej = 1'b0;
            logic  [N-1:0] tx_m = 0, tx_s = 0;
            logic [N-1:0] rx_m, rx_s;
            logic         zajety, gotowe, sclk, mosi, miso, miso_oe, cs_n, pobrany, rx_wazne;
            spi_master #(.N(N), .DIV(DIV)) u_m (.clk(clk), .rst(rst), .cpol(cpol), .cpha(cpha), .start(start),
                .dalej(dalej), .tx_dane(tx_m), .rx_dane(rx_m), .zajety(zajety), .gotowe(gotowe), .sclk(sclk),
                .mosi(mosi), .miso(miso_oe ? miso : 1'bx), .cs_n(cs_n));
            spi_slave #(.N(N)) u_s (.clk(clk), .rst(rst), .cpol(cpol), .cpha(cpha), .sclk(sclk), .mosi(mosi),
                .miso(miso), .miso_oe(miso_oe), .cs_n(cs_n), .tx_dane(tx_s), .tx_pobrany(pobrany),
                .rx_dane(rx_s), .rx_wazne(rx_wazne));

            logic  [N-1:0] slowa_m [0:NS-1];               // słowa mastera i slave'a w bieżącym trybie
            logic  [N-1:0] slowa_s [0:NS-1];
            int      n_rm = 0, n_rs = 0, n_pob = 0, n_mon = 0, zbocza = 0, bl = 0;
            logic  [N-1:0] mon_mosi, mon_miso;
            int      mon_bit = 0;

            // slave: kolejne słowo po każdym pobraniu
            always @(posedge clk) if (pobrany) begin
                n_pob = n_pob + 1;
                tx_s <= slowa_s[n_pob];
            end
            // odebrane słowa
            always @(posedge clk) begin
                if (gotowe) begin
                    if (rx_m !== slowa_s[n_rm]) bl = bl + 1;
                    n_rm = n_rm + 1;
                end
                if (rx_wazne) begin
                    if (rx_s !== slowa_m[n_rs]) bl = bl + 1;
                    n_rs = n_rs + 1;
                end
            end
            // monitor protokołu
            always @(sclk) if (!cs_n) begin
                zbocza = zbocza + 1;
                if ((sclk != cpol) ^ cpha) begin          // zbocze próbkujące tego trybu
                    mon_mosi = {mon_mosi[N-2:0], mosi};
                    mon_miso = {mon_miso[N-2:0], miso};
                    mon_bit  = mon_bit + 1;
                    if (mon_bit == N) begin
                        if (mon_mosi !== slowa_m[n_mon] || mon_miso !== slowa_s[n_mon]) bl = bl + 1;
                        n_mon   = n_mon + 1;
                        mon_bit = 0;
                    end
                end
            end
            // SCLK w spoczynku musi mieć poziom CPOL przy każdej zmianie CS
            always @(cs_n) if (!rst && sclk !== cpol) bl = bl + 1;
        end
    endgenerate

    // jedna transakcja na obu parach: ile słów, CS trzymane między nimi
    task transakcja(input int ile);
        int q;
        begin
            for (q = 0; q < ile; q = q + 1) begin
                @(negedge clk);
                g_div[0].tx_m = g_div[0].slowa_m[w]; g_div[1].tx_m = g_div[1].slowa_m[w];
                g_div[0].dalej = (q != ile - 1);    g_div[1].dalej = (q != ile - 1);
                g_div[0].start = 1'b1;              g_div[1].start = 1'b1;
                @(negedge clk);
                g_div[0].start = 1'b0;              g_div[1].start = 1'b0;
                wait (!g_div[0].zajety && !g_div[1].zajety);
                w = w + 1;
            end
            repeat (20) @(negedge clk);
        end
    endtask

    initial begin
        for (m = 0; m < 4; m = m + 1) begin
            rst = 1'b1;                                    // nowy tryb: kolejka slave'a i master od zera
            {cpol, cpha} = m[1:0];
            for (j = 0; j < NS; j = j + 1) begin
                g_div[0].slowa_m[j] = $random; g_div[0].slowa_s[j] = $random;
                g_div[1].slowa_m[j] = $random; g_div[1].slowa_s[j] = $random;
            end
            g_div[0].n_rm = 0; g_div[0].n_rs = 0; g_div[0].n_pob = 0; g_div[0].n_mon = 0; g_div[0].zbocza = 0;
            g_div[1].n_rm = 0; g_div[1].n_rs = 0; g_div[1].n_pob = 0; g_div[1].n_mon = 0; g_div[1].zbocza = 0;
            g_div[0].tx_s = g_div[0].slowa_s[0];
            g_div[1].tx_s = g_div[1].slowa_s[0];
            repeat (20) @(negedge clk);                    // nowy poziom spoczynku SCLK po zmianie trybu
            rst = 1'b0;
            repeat (5) @(negedge clk);
            w = 0;
            for (i = 0; i < 5; i = i + 1) transakcja(3);
            for (i = 0; i < 5; i = i + 1) transakcja(1);
            if (g_div[0].n_rm != 20 || g_div[0].n_rs != 20 || g_div[0].n_mon != 20 || g_div[0].zbocza != 20 * 2 * N ||
                g_div[1].n_rm != 20 || g_div[1].n_rs != 20 || g_div[1].n_mon != 20 || g_div[1].zbocza != 20 * 2 * N) begin
                $display("tryb %0d: slow master %0d/%0d, slave %0d/%0d, monitor %0d/%0d, zboczy %0d/%0d", m,
                         g_div[0].n_rm, g_div[1].n_rm, g_div[0].n_rs, g_div[1].n_rs, g_div[0].n_mon, g_div[1].n_mon,
                         g_div[0].zbocza, g_div[1].zbocza);
                errors = errors + 1;
            end
            $display("tryb %0d (CPOL=%0d CPHA=%0d): 20 slow w obie strony, DIV 4 i 7, bledow %0d / %0d", m, cpol, cpha,
                     g_div[0].bl, g_div[1].bl);
        end
        errors = errors + g_div[0].bl + g_div[1].bl;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

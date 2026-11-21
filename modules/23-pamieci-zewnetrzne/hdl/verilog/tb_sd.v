// Testbench 23.05: sd_spi z behawioralnym modelem karty SD w trybie SPI. Model: sprawdza CRC7 każdego
// rozkazu, odpowiada R1 po jednym bajcie NCR, CMD8 (echo 0x1AA), ACMD41 zajęta przez 3 pierwsze próby,
// CMD58 (OCR z bitem CCS), CMD16, CMD17 (dwa bajty oczekiwania, token 0xFE, 512 B, CRC16). Kontroluje też
// ≥ 74 takty SCLK z CS = 1 przed CMD0 i SCLK ≤ 400 kHz do końca inicjalizacji.
// Przebiegi: karta SDHC (adres = numer bloku) i SDSC (adres w bajtach, CMD16), odczyt bloków 5 i 1000.
`timescale 1ns / 1ps
`default_nettype none

module tb_sd;
    reg clk = 1'b0;
    always #10 clk = ~clk;                        // 50 MHz
    reg rst = 1'b1;
    integer errors = 0;

    reg         odczyt = 1'b0;
    reg  [31:0] blok = 0;
    wire        gotowy, sdhc, blad, dane_wazne, koniec, crc_ok, sclk, mosi, cs_n;
    wire [3:0]  kod_bledu;
    wire [7:0]  dane;
    reg         miso = 1'b1;
    sd_spi #(.DIV_WOLNY(63), .DIV_SZYBKI(2)) dut (.clk(clk), .rst(rst), .odczyt(odczyt), .blok(blok),
        .gotowy(gotowy), .sdhc(sdhc), .blad(blad), .kod_bledu(kod_bledu), .dane(dane), .dane_wazne(dane_wazne),
        .koniec(koniec), .crc_ok(crc_ok), .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(miso));

    // ================= model karty
    reg         m_hc = 1'b1;                       // 1: SDHC (CCS = 1)
    reg  [7:0]  q [0:1023];
    integer     qh = 0, qt = 0;
    reg  [7:0]  rx_sr, tx_sr = 8'hFF;
    integer     nb = 0, n_cmd = 0, acmd41 = 0, zle_crc = 0, takty_przed = 0, za_szybko = 0;
    reg  [47:0] cmd;
    reg         app = 1'b0, gotowa = 1'b0, pierwszy = 1'b1;
    real        t_ost = 0.0;

    function [6:0] crc7(input [39:0] d);
        integer i;
        reg fb;
        begin
            crc7 = 7'd0;
            for (i = 39; i >= 0; i = i - 1) begin
                fb   = d[i] ^ crc7[6];
                crc7 = {crc7[5:0], 1'b0} ^ (fb ? 7'h09 : 7'h00);
            end
        end
    endfunction
    function [15:0] crc16(input [15:0] c, input [7:0] d);
        integer i;
        reg fb;
        begin
            crc16 = c;
            for (i = 7; i >= 0; i = i - 1) begin
                fb    = d[i] ^ crc16[15];
                crc16 = {crc16[14:0], 1'b0} ^ (fb ? 16'h1021 : 16'h0000);
            end
        end
    endfunction
    function [7:0] wzor(input [31:0] b, input integer i);
        wzor = (b * 7 + i * 13 + (i >> 8)) & 8'hFF;
    endfunction

    task wstaw(input [7:0] b);
        begin q[qt % 1024] = b; qt = qt + 1; end
    endtask

    task wykonaj;
        reg [5:0]  nr;
        reg [31:0] arg, bl;
        reg [15:0] c;
        integer    i;
        begin
            nr  = cmd[45:40];
            arg = cmd[39:8];
            if (cmd[7:1] != crc7(cmd[47:8])) zle_crc = zle_crc + 1;
            if (pierwszy && nr == 6'd0) pierwszy = 1'b0;
            wstaw(8'hFF);                                                // NCR
            if (app && nr == 6'd41) begin
                acmd41 = acmd41 + 1;
                if (acmd41 > 3) gotowa = 1'b1;
                wstaw(gotowa ? 8'h00 : 8'h01);
            end else case (nr)
                6'd0:  begin gotowa = 1'b0; acmd41 = 0; wstaw(8'h01); end
                6'd8:  begin wstaw(8'h01); wstaw(8'h00); wstaw(8'h00); wstaw({4'd0, arg[11:8]}); wstaw(arg[7:0]); end
                6'd55: wstaw(gotowa ? 8'h00 : 8'h01);
                6'd58: begin wstaw(gotowa ? 8'h00 : 8'h01); wstaw({1'b1, m_hc, 6'd0}); wstaw(8'hFF);
                             wstaw(8'h80); wstaw(8'h00); end
                6'd16: wstaw(arg == 512 ? 8'h00 : 8'h40);
                6'd17: begin
                    bl = m_hc ? arg : arg / 512;
                    if (!m_hc && arg % 512 != 0) wstaw(8'h40);              // błąd adresu
                    else begin
                        wstaw(8'h00); wstaw(8'hFF); wstaw(8'hFF); wstaw(8'hFE);
                        c = 16'd0;
                        for (i = 0; i < 512; i = i + 1) begin wstaw(wzor(bl, i)); c = crc16(c, wzor(bl, i)); end
                        wstaw(c[15:8]); wstaw(c[7:0]);
                    end
                end
                default: wstaw(8'h04);                                     // nielegalny rozkaz
            endcase
            app = (nr == 6'd55);
            n_cmd = n_cmd + 1;
        end
    endtask

    always @(negedge cs_n) begin nb = 0; tx_sr = 8'hFF; miso = 1'b1; end
    always @(posedge cs_n) begin qh = qt; miso = 1'b1; end
    always @(posedge sclk) begin
        if (!gotowa || pierwszy) begin                                   // SCLK ≤ 400 kHz w inicjalizacji
            if (t_ost > 0.0 && $realtime - t_ost < 2490.0) za_szybko = za_szybko + 1;
            t_ost = $realtime;
        end
        if (cs_n && pierwszy) takty_przed = takty_przed + 1;
        if (!cs_n) begin
            rx_sr = {rx_sr[6:0], mosi};
            nb = nb + 1;
            if (nb == 8) begin
                nb = 0;
                if (cmd[47:46] == 2'b01 || rx_sr[7:6] == 2'b01 || cmd != 48'd0) begin
                    cmd = {cmd[39:0], rx_sr};
                    if (cmd[47:46] == 2'b01) begin wykonaj; cmd = 48'd0; end
                end
            end
        end
    end
    always @(negedge sclk) if (!cs_n) begin
        if (nb == 0) begin
            tx_sr = (qh != qt) ? q[qh % 1024] : 8'hFF;
            if (qh != qt) qh = qh + 1;
        end else
            tx_sr = {tx_sr[6:0], 1'b1};
        miso = tx_sr[7];
    end

    // ================= odbiór bloku
    reg [7:0] buf_odcz [0:511];
    integer   n_b = 0;
    always @(posedge clk) if (dane_wazne) begin buf_odcz[n_b % 512] = dane; n_b = n_b + 1; end

    task czytaj(input [31:0] b);
        integer i, z;
        begin
            n_b = 0;
            @(negedge clk); blok = b; odczyt = 1'b1;
            @(negedge clk) odczyt = 1'b0;
            wait (koniec || blad);
            z = 0;
            for (i = 0; i < 512; i = i + 1) if (buf_odcz[i] !== wzor(b, i)) z = z + 1;
            $display("  blok %0d: %0d bajtow, bledow %0d, CRC16 %s", b, n_b, z, crc_ok ? "zgodne" : "NIEZGODNE");
            if (z != 0 || n_b != 512 || !crc_ok || blad) errors = errors + 1;
            @(negedge clk);
        end
    endtask

    integer typ;
    real    t0;
    initial begin
        for (typ = 0; typ < 2; typ = typ + 1) begin
            m_hc = (typ == 0);
            rst = 1'b1; pierwszy = 1'b1; gotowa = 1'b0; takty_przed = 0; za_szybko = 0; zle_crc = 0; n_cmd = 0;
            t_ost = 0.0; cmd = 48'd0; app = 1'b0;
            repeat (5) @(negedge clk);
            rst = 1'b0;
            t0 = $realtime;
            wait (gotowy || blad);
            $display("karta %s: inicjalizacja %0.2f ms, %0d rozkazow, ACMD41 %0d razy, sdhc = %b, blad %b (kod %0d)",
                     m_hc ? "SDHC" : "SDSC", ($realtime - t0) / 1.0e6, n_cmd, acmd41, sdhc, blad, kod_bledu);
            $display("  taktow SCLK z CS = 1 przed CMD0: %0d, za szybkich taktow w inicjalizacji: %0d, zlych CRC7: %0d",
                     takty_przed, za_szybko, zle_crc);
            if (blad || sdhc != m_hc || takty_przed < 74 || za_szybko != 0 || zle_crc != 0) errors = errors + 1;
            czytaj(5);
            czytaj(1000);
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

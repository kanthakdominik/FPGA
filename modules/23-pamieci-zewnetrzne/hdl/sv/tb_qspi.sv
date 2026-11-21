// Testbench (SystemVerilog) 23.03: qspi_master z behawioralnym modelem pamięci SPI NOR flash (64 KiB, ID C2 20 19):
// rozkazy 0x9F (ID), 0x05 (status: WIP, WEL), 0x06 (WREN), 0x03 (READ), 0x0B (FAST READ, 8 cykli pustych),
// 0x6B (QUAD OUTPUT READ 1-1-4, 8 cykli pustych), 0x02 (PAGE PROGRAM, zawijanie w stronie 256 B,
// programowanie tylko zeruje bity, 20 µs), 0x20 (SECTOR ERASE 4 KiB, 50 µs). Model sprawdza konflikt
// sterowania liniami. Testy: ID, odczyty 1-1-1 i 1-1-4 zgodne z zawartością, programowanie strony z czekaniem
// na WIP, zapis bez WREN ignorowany, kasowanie sektora, przepustowość odczytu 1-1-1 i 1-1-4.
`timescale 1ns / 1ps
`default_nettype none

module tb_qspi;
    logic clk = 1'b0;
    always #5 clk = ~clk;                         // 100 MHz, DIV = 2 -> SCLK 25 MHz
    logic rst = 1'b1;
    int errors = 0, seed = 5;

    logic        start = 0, z_adresem = 0, zapis = 0, quad = 0;
    logic [7:0]  rozkaz = 0;
    logic [23:0] adres = 0;
    logic [3:0]  puste = 0;
    logic [8:0]  dlugosc = 0;
    logic [7:0]  wdane = 0;
    logic       wpobierz, rwazne, gotowy, sclk, cs_n;
    logic [7:0] rdane;
    logic [3:0] m_o, m_oe;
    logic  [3:0] f_o = 4'h0, f_oe = 4'h0;
    logic [3:0] linia;
    assign linia = (m_oe & m_o) | (f_oe & f_o) | (~m_oe & ~f_oe);   // podciąganie

    qspi_master #(.DIV(2)) dut (.clk(clk), .rst(rst), .start(start), .rozkaz(rozkaz), .adres(adres),
        .z_adresem(z_adresem), .puste(puste), .dlugosc(dlugosc), .zapis(zapis), .quad(quad), .wdane(wdane),
        .wpobierz(wpobierz), .rdane(rdane), .rwazne(rwazne), .gotowy(gotowy), .sclk(sclk), .cs_n(cs_n),
        .dq_o(m_o), .dq_oe(m_oe), .dq_i(linia));

    // ================= model pamięci flash
    logic  [7:0]  mem [0:65535];
    logic  [7:0]  strona [0:255];
    logic  [255:0] w_stronie;
    logic  [7:0]  f_roz, f_bajt;
    logic  [23:0] f_adr;
    int     f_nb, f_np, k;
    logic         wel = 1'b0, wip = 1'b0;
    int     czas_wip = 0;
    always @(posedge wip) begin #(czas_wip) wip = 1'b0; end      // czas programowania / kasowania
    int     konflikty = 0;
    always @(*) if (|(m_oe & f_oe)) konflikty = konflikty + 1;

    function z_adr(input [7:0] r);
        z_adr = (r == 8'h03 || r == 8'h0B || r == 8'h6B || r == 8'h02 || r == 8'h20);
    endfunction
    function int pocz_danych(input [7:0] r);                       // cykl, od którego płyną dane
        case (r)
            8'h03, 8'h02: pocz_danych = 32;
            8'h0B, 8'h6B: pocz_danych = 40;
            default:      pocz_danych = 8;
        endcase
    endfunction

    always @(negedge cs_n) begin
        f_nb = 0; f_np = 0; f_roz = 0; w_stronie = 0;
    end
    always @(posedge sclk) if (!cs_n) begin
        if (f_nb < 8) f_roz = {f_roz[6:0], linia[0]};
        else if (f_nb < 32 && z_adr(f_roz)) f_adr = {f_adr[22:0], linia[0]};
        else if (f_roz == 8'h02 && !wip) begin                           // dane strony z DQ0
            f_bajt = {f_bajt[6:0], linia[0]};
            if ((f_nb - 32) % 8 == 7) begin
                strona[(f_adr[7:0] + f_np) & 8'hFF] = f_bajt;
                w_stronie[(f_adr[7:0] + f_np) & 8'hFF] = 1'b1;
                f_np = f_np + 1;
            end
        end
        f_nb = f_nb + 1;
    end
    always @(negedge sclk) if (!cs_n) begin                               // wystawienie danych
        if (f_nb >= pocz_danych(f_roz)) begin
            k = f_nb - pocz_danych(f_roz);
            case (f_roz)
                8'h9F: begin
                    f_bajt = (k / 8 == 0) ? 8'hC2 : (k / 8 == 1) ? 8'h20 : 8'h19;
                    f_o = {2'b00, f_bajt[7 - k % 8], 1'b0}; f_oe = 4'b0010;
                end
                8'h05: begin
                    f_bajt = {6'd0, wel, wip};
                    f_o = {2'b00, f_bajt[7 - k % 8], 1'b0}; f_oe = 4'b0010;
                end
                8'h03, 8'h0B: begin
                    f_bajt = mem[(f_adr + k / 8) & 24'hFFFF];
                    f_o = {2'b00, f_bajt[7 - k % 8], 1'b0}; f_oe = 4'b0010;
                end
                8'h6B: begin
                    f_bajt = mem[(f_adr + k / 2) & 24'hFFFF];
                    f_o = (k % 2 == 0) ? f_bajt[7:4] : f_bajt[3:0]; f_oe = 4'b1111;
                end
                default: f_oe = 4'b0000;
            endcase
        end
    end
    always @(posedge cs_n) begin
        f_oe = 4'b0000;
        if (f_roz == 8'h06 && f_nb == 8) wel = 1'b1;
        if (f_roz == 8'h02 && wel && !wip && f_nb >= 40) begin
            czas_wip = 20000; wel = 1'b0; wip = 1'b1;
            for (k = 0; k < 256; k = k + 1)
                if (w_stronie[k]) mem[{f_adr[15:8], 8'd0} + k] = mem[{f_adr[15:8], 8'd0} + k] & strona[k];
        end
        if (f_roz == 8'h20 && wel && !wip && f_nb == 32) begin
            czas_wip = 50000; wel = 1'b0; wip = 1'b1;
            for (k = 0; k < 4096; k = k + 1) mem[{f_adr[15:12], 12'd0} + k] = 8'hFF;
        end
    end

    // ================= sterowanie
    logic [7:0] bufor [0:255];
    logic [7:0] odczyt [0:255];
    int   n_odcz, n_zap;
    always @(posedge clk) if (rwazne) begin odczyt[n_odcz] = rdane; n_odcz = n_odcz + 1; end
    always @(posedge clk) if (wpobierz) begin n_zap = n_zap + 1; wdane = bufor[n_zap & 255]; end

    int t0, t_tr;
    task transakcja(input [7:0] r, input [23:0] a, input za, input [3:0] p, input [8:0] dl, input zp, input q);
        begin
            n_odcz = 0; n_zap = 0; wdane = bufor[0];
            @(negedge clk);
            rozkaz = r; adres = a; z_adresem = za; puste = p; dlugosc = dl; zapis = zp; quad = q; start = 1'b1;
            t0 = $time;
            @(negedge clk) start = 1'b0;
            wait (gotowy);
            t_tr = ($time - t0) / 10;
            @(negedge clk);
        end
    endtask

    task czekaj_wip;
        int n;
        begin
            n = 0;
            transakcja(8'h05, 0, 0, 0, 1, 0, 0);
            while (odczyt[0][0]) begin
                n = n + 1;
                transakcja(8'h05, 0, 0, 0, 1, 0, 0);
            end
        end
    endtask

    task sprawdz(input [23:0] a, input int dl, input [8*24-1:0] nazwa);
        int i, z;
        begin
            z = 0;
            for (i = 0; i < dl; i = i + 1) if (odczyt[i] !== mem[a + i]) z = z + 1;
            if (z != 0 || n_odcz != dl) begin
                $display("%0s: %0d bledow, odebrano %0d", nazwa, z, n_odcz);
                errors = errors + 1;
            end
        end
    endtask

    int i, t_111, t_114;
    initial begin
        for (i = 0; i < 65536; i = i + 1) mem[i] = (i * 37 + (i >> 8)) & 8'hFF;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        // identyfikator
        transakcja(8'h9F, 0, 0, 0, 3, 0, 0);
        $display("JEDEC ID: %h %h %h", odczyt[0], odczyt[1], odczyt[2]);
        if (odczyt[0] != 8'hC2 || odczyt[1] != 8'h20 || odczyt[2] != 8'h19) errors = errors + 1;
        // odczyty
        transakcja(8'h03, 24'h001234, 1, 0, 256, 0, 0);  sprawdz(24'h001234, 256, "READ 0x03");
        t_111 = t_tr;
        transakcja(8'h0B, 24'h00ABCD, 1, 8, 100, 0, 0);  sprawdz(24'h00ABCD, 100, "FAST READ 0x0B");
        transakcja(8'h6B, 24'h001234, 1, 8, 256, 0, 1);  sprawdz(24'h001234, 256, "QUAD OUTPUT READ 0x6B");
        t_114 = t_tr;
        $display("odczyt 256 B: 1-1-1 %0d taktow (%0d cykli SCLK), 1-1-4 %0d taktow", t_111, t_111 / 4, t_114);
        if (t_114 * 3 > t_111) errors = errors + 1;                     // 1-1-4 ma być ok. 3-4 razy szybszy
        // kasowanie sektora 0x003000 i programowanie strony
        transakcja(8'h06, 0, 0, 0, 0, 0, 0);
        transakcja(8'h20, 24'h003000, 1, 0, 0, 0, 0);
        czekaj_wip;
        transakcja(8'h03, 24'h003000, 1, 0, 256, 0, 0);
        for (i = 0; i < 256; i = i + 1) if (odczyt[i] != 8'hFF) errors = errors + 1;
        for (i = 0; i < 256; i = i + 1) bufor[i] = $random(seed);
        transakcja(8'h02, 24'h003100, 1, 0, 256, 1, 0);              // bez WREN: ignorowane
        transakcja(8'h03, 24'h003100, 1, 0, 4, 0, 0);
        if (odczyt[0] != 8'hFF) begin $display("zapis bez WREN zmienil pamiec"); errors = errors + 1; end
        transakcja(8'h06, 0, 0, 0, 0, 0, 0);
        transakcja(8'h05, 0, 0, 0, 1, 0, 0);
        if (odczyt[0] != 8'h02) begin $display("WEL po WREN: %h", odczyt[0]); errors = errors + 1; end
        transakcja(8'h02, 24'h003100, 1, 0, 256, 1, 0);
        czekaj_wip;
        transakcja(8'h6B, 24'h003100, 1, 8, 256, 0, 1);
        for (i = 0; i < 256; i = i + 1) if (odczyt[i] !== bufor[i]) errors = errors + 1;
        $display("kasowanie sektora, programowanie strony 256 B z WREN i WIP, odczyt 1-1-4: bledow %0d", errors);
        if (konflikty != 0) begin $display("konflikty na liniach DQ: %0d", konflikty); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

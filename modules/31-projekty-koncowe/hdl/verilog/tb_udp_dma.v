// Testbench projektu 4 (31.04): udp_dma jak w systemie Nios V — procesor (zadania zapisu/odczytu rejestrów),
// pamięć z losowym waitrequest i losowym opóźnieniem odczytu (kolejność zachowana), zegar nadawania MII
// niezależny od zegara systemu. Ramki odbiera mii_rx; sprawdzane są CRC, długość, pola Ethernet/IPv4/UDP,
// suma kontrolna nagłówka IP i każdy bajt danych względem pamięci.
`timescale 1ns / 1ps
`default_nettype none

module tb_udp_dma;
    reg clk = 1'b0;
    reg tclk = 1'b0;
    always #10 clk = ~clk;                       // 50 MHz system
    always #20.3 tclk = ~tclk;                   // ok. 24,6 MHz nadawanie MII
    reg rst = 1'b1;
    integer errors = 0;

    localparam [47:0] MAC_FPGA = 48'h02_00_00_00_00_01, MAC_PC = 48'h00_1B_21_3C_4D_5E;
    localparam [31:0] IP_FPGA  = {8'd192, 8'd168, 8'd1, 8'd200}, IP_PC = {8'd192, 8'd168, 8'd1, 8'd100};

    reg  [3:0]  s_address = 4'd0;
    reg         s_read = 1'b0;
    reg         s_write = 1'b0;
    reg  [31:0] s_writedata = 32'd0;
    wire [31:0] s_readdata, m_address;
    wire        irq, m_read;
    reg         m_waitrequest = 1'b1;
    reg  [31:0] m_readdata = 32'd0;
    reg         m_readdatavalid = 1'b0;
    wire [3:0]  txd;
    wire        tx_en;

    udp_dma dut (.clk(clk), .rst(rst), .s_address(s_address), .s_read(s_read), .s_write(s_write),
        .s_writedata(s_writedata), .s_readdata(s_readdata), .irq(irq), .m_address(m_address), .m_read(m_read),
        .m_waitrequest(m_waitrequest), .m_readdata(m_readdata), .m_readdatavalid(m_readdatavalid),
        .tx_clk(tclk), .tx_rst(rst), .txd(txd), .tx_en(tx_en));

    // ---- pamięć 8 KB z losowym waitrequest i opóźnieniem 1..6 taktów
    reg [7:0] mem [0:8191];
    integer i;
    initial for (i = 0; i < 8192; i = i + 1) mem[i] = (i * 7 + 3) & 8'hFF;
    reg [31:0] los = 32'h1234_5678;
    reg [31:0] q_adr [0:31];
    integer    q_t [0:31];
    integer    q_gl = 0;
    integer    q_og = 0;
    integer    takt = 0;
    integer    t_ost = 0;
    integer    t_nowy;
    integer    odczytow = 0;
    always @(posedge clk) begin
        takt <= takt + 1;
        los  <= {los[30:0], los[31] ^ los[21] ^ los[1] ^ los[0]};
        m_waitrequest <= los[3] & los[7];             // ok. 25 % taktów wstrzymanych
        if (m_read && !m_waitrequest) begin
            t_nowy = takt + 1 + (los[10:8] % 6);
            if (t_nowy < t_ost) t_nowy = t_ost;
            t_ost = t_nowy;
            q_adr[q_og % 32] = m_address;
            q_t[q_og % 32] = t_nowy;
            q_og = q_og + 1;
            odczytow = odczytow + 1;
        end
        m_readdatavalid <= 1'b0;
        if (q_gl != q_og && q_t[q_gl % 32] <= takt) begin
            m_readdata <= {mem[q_adr[q_gl % 32] + 3], mem[q_adr[q_gl % 32] + 2], mem[q_adr[q_gl % 32] + 1],
                           mem[q_adr[q_gl % 32]]};
            m_readdatavalid <= 1'b1;
            q_gl = q_gl + 1;
        end
    end

    // ---- „procesor”
    task zapisz(input [3:0] a, input [31:0] d);
        begin
            @(negedge clk); s_address = a; s_writedata = d; s_write = 1'b1;
            @(negedge clk); s_write = 1'b0;
        end
    endtask
    reg [31:0] odczyt;
    task czytaj(input [3:0] a);
        begin
            @(negedge clk); s_address = a; s_read = 1'b1;
            @(negedge clk); s_read = 1'b0; odczyt = s_readdata;
        end
    endtask

    // ---- odbiornik
    wire [7:0]  r_dane;
    wire        r_wazne, r_koniec, r_crc_ok, r_blad;
    wire [10:0] r_dl;
    mii_rx u_rx (.clk(tclk), .rst(rst), .rxd(txd), .rx_dv(tx_en), .rx_er(1'b0), .m_dane(r_dane), .m_wazne(r_wazne),
                 .koniec(r_koniec), .crc_ok(r_crc_ok), .dlugosc(r_dl), .blad(r_blad));
    reg [7:0] ramka [0:2047];
    integer   nb = 0;
    integer   ramek = 0;
    integer   crc_zle = 0;
    integer   dl_ost = 0;
    always @(posedge tclk) begin
        if (r_wazne) begin ramka[nb] = r_dane; nb = nb + 1; end
        if (r_koniec) begin
            ramek = ramek + 1;
            if (!r_crc_ok || r_blad) crc_zle = crc_zle + 1;
            dl_ost = r_dl;
            nb = 0;
        end
    end

    function [15:0] s16(input integer k);
        s16 = {ramka[k], ramka[k + 1]};
    endfunction

    task sprawdz_ramke(input integer adres, input integer dl);
        integer k, bl_danych, oczek_dl;
        reg [31:0] suma;
        begin
            oczek_dl = (14 + 20 + 8 + dl < 60) ? 60 : 14 + 20 + 8 + dl;
            if (dl_ost != oczek_dl) begin
                $display("FAIL: dlugosc ramki %0d, oczekiwana %0d", dl_ost, oczek_dl); errors = errors + 1;
            end
            if ({s16(0), s16(2), s16(4)} != MAC_PC || {s16(6), s16(8), s16(10)} != MAC_FPGA || s16(12) != 16'h0800) begin
                $display("FAIL: naglowek Ethernet"); errors = errors + 1;
            end
            suma = 0;
            for (k = 14; k < 34; k = k + 2) suma = suma + s16(k);
            suma = (suma & 32'hFFFF) + (suma >> 16);
            if (ramka[14] != 8'h45 || s16(16) != 20 + 8 + dl || ramka[23] != 8'h11 ||
                {s16(26), s16(28)} != IP_FPGA || {s16(30), s16(32)} != IP_PC || suma[15:0] != 16'hFFFF) begin
                $display("FAIL: naglowek IPv4 (suma %h)", suma); errors = errors + 1;
            end
            if (s16(34) != 16'd5005 || s16(36) != 16'd5006 || s16(38) != 8 + dl) begin
                $display("FAIL: naglowek UDP"); errors = errors + 1;
            end
            bl_danych = 0;
            for (k = 0; k < dl; k = k + 1) if (ramka[42 + k] != mem[adres + k]) bl_danych = bl_danych + 1;
            if (bl_danych != 0) begin $display("FAIL: %0d bajtow danych niezgodnych", bl_danych); errors = errors + 1; end
            $display("ramka %0d: %0d B (dane %0d B spod 0x%0h), CRC %0s, naglowki i dane %0s", ramek, dl_ost, dl,
                     adres, (crc_zle == 0) ? "OK" : "ZLE", (bl_danych == 0) ? "zgodne" : "NIEZGODNE");
        end
    endtask

    task wyslij_pakiet(input integer adres, input integer dl, input integer dwa_starty);
        integer t, r0;
        begin
            r0 = ramek;
            zapisz(4'd2, adres);
            zapisz(4'd3, dl);
            zapisz(4'd0, 32'd3);                          // START, PRZ
            if (dwa_starty) zapisz(4'd0, 32'd3);          // ignorowany: blok zajęty
            t = 0;
            while (!irq && t < 200_000) begin @(posedge clk); t = t + 1; end
            if (!irq) begin $display("FAIL: brak przerwania"); errors = errors + 1; end
            czytaj(4'd1);
            if (odczyt[1:0] != 2'b10) begin $display("FAIL: STATUS = %b", odczyt[1:0]); errors = errors + 1; end
            zapisz(4'd1, 32'd2);                          // W1C KONIEC
            @(negedge clk);
            if (irq) begin $display("FAIL: przerwanie po kasowaniu"); errors = errors + 1; end
            t = 0;
            while (ramek == r0 && t < 100_000) begin @(posedge tclk); t = t + 1; end
            repeat (4) @(posedge tclk);
            sprawdz_ramke(adres, dl);
        end
    endtask

    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        zapisz(4'd4, IP_FPGA);
        zapisz(4'd5, IP_PC);
        zapisz(4'd6, {16'd5005, 16'd5006});
        zapisz(4'd7, MAC_FPGA[47:32]);
        zapisz(4'd8, MAC_FPGA[31:0]);
        zapisz(4'd9, MAC_PC[47:32]);
        zapisz(4'd10, MAC_PC[31:0]);
        czytaj(4'd6);
        if (odczyt != {16'd5005, 16'd5006}) begin $display("FAIL: odczyt rejestru PORTY"); errors = errors + 1; end
        wyslij_pakiet(32'h100, 1001, 0);
        wyslij_pakiet(32'h1000, 18, 0);
        wyslij_pakiet(32'h400, 1472, 1);
        czytaj(4'd11);
        $display("PAKIETY = %0d, ramek odebranych %0d, z bledem CRC %0d, odczytow pamieci %0d", odczyt, ramek,
                 crc_zle, odczytow);
        if (odczyt != 3 || ramek != 3 || crc_zle != 0 || odczytow != 251 + 5 + 368) begin
            $display("FAIL: liczniki"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

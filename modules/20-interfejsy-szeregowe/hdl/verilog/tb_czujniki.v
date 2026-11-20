// Testbench sterowników czujników płytki DECA (20.05) z modelami behawioralnymi czujników:
//   LIS2DH12 — slave SPI w trybie 3: rejestry, bit odczytu i autoinkrementacji, WHO_AM_I = 0x33;
//              sprawdzane: zapis CTRL_REG1 = 0x57 i CTRL_REG4 = 0x88, SCLK w spoczynku wysoki przy CS,
//              odczyt X, Y, Z (dwa różne zestawy wartości),
//   LM71     — 16 bitów wystawianych po zboczu opadającym SC; +25,0625 °C i −10,5 °C,
//   HDC1000  — slave I²C 0x40: zapis konfiguracji, wyzwolenie pomiaru zapisem wskaźnika 0x00,
//              NACK na adres w czasie pomiaru (sterownik ponawia), odczyt 4 bajtów.
`timescale 1ns / 1ps
`default_nettype none

module tb_czujniki;
    reg clk = 1'b0;
    always #10 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;

    // ================= LIS2DH12
    wire        a_sclk, a_mosi, a_cs_n, a_nowe, a_id_ok;
    reg         a_miso = 1'b0;
    wire [15:0] ax, ay, az;
    wire [7:0]  a_who;
    akcel_lis2dh12 #(.DIV(4), .CZEKAJ(100), .OKRES(3000)) u_akc (.clk(clk), .rst(rst), .sclk(a_sclk),
        .mosi(a_mosi), .miso(a_miso), .cs_n(a_cs_n), .x(ax), .y(ay), .z(az), .nowe(a_nowe), .who_am_i(a_who),
        .id_ok(a_id_ok));

    reg [7:0] lis [0:63];
    integer   l_nb = 0, l_nbit = 0;
    reg       l_czyt = 1'b0, l_ms = 1'b0;
    reg [5:0] l_adr = 6'd0;
    reg [7:0] l_bajt = 8'd0, l_wyj = 8'd0;
    always @(negedge a_cs_n) begin
        l_nb = 0; l_nbit = 0;
        if (a_sclk !== 1'b1) begin $display("LIS2DH12: SCLK niski przy CS (tryb 3 wymaga wysokiego)"); errors = errors + 1; end
    end
    always @(negedge a_sclk) if (!a_cs_n && l_nb > 0 && l_czyt) begin    // wystawienie bitu (zbocze wiodące)
        if (l_nbit == 0) l_wyj = lis[l_adr];
        a_miso = l_wyj[7 - l_nbit];
    end
    always @(posedge a_sclk) if (!a_cs_n) begin                           // próbkowanie MOSI
        l_bajt = {l_bajt[6:0], a_mosi};
        l_nbit = l_nbit + 1;
        if (l_nbit == 8) begin
            l_nbit = 0;
            if (l_nb == 0) begin l_czyt = l_bajt[7]; l_ms = l_bajt[6]; l_adr = l_bajt[5:0]; end
            else begin
                if (!l_czyt) lis[l_adr] = l_bajt;
                if (l_ms) l_adr = l_adr + 1;
            end
            l_nb = l_nb + 1;
        end
    end
    task ustaw_xyz(input [15:0] x, input [15:0] y, input [15:0] z);
        begin
            lis[6'h28] = x[7:0]; lis[6'h29] = x[15:8];
            lis[6'h2A] = y[7:0]; lis[6'h2B] = y[15:8];
            lis[6'h2C] = z[7:0]; lis[6'h2D] = z[15:8];
        end
    endtask

    // ================= LM71
    wire        t_sc, t_cs_n, t_nowe;
    wire [13:0] t_temp;
    wire [8:0]  t_c;
    reg  [15:0] lm_wart = 16'h0000, lm_sr = 16'h0000;
    temp_lm71 #(.DIV(5), .OKRES(2000)) u_lm (.clk(clk), .rst(rst), .sc(t_sc), .sio(lm_sr[15]), .cs_n(t_cs_n),
        .temp(t_temp), .temp_c(t_c), .nowe(t_nowe));
    always @(negedge t_cs_n) lm_sr = lm_wart;
    always @(negedge t_sc) if (!t_cs_n) lm_sr = {lm_sr[14:0], 1'b1};
    function [15:0] lm71_kod(input integer setne_c);   // temperatura w 1/100 °C -> słowo LM71
        integer k;
        begin
            k = (setne_c * 32) / 100;
            lm71_kod = {k[13:0], 2'b11};
        end
    endfunction

    // ================= HDC1000
    wire        h_scl_oe, h_sda_oe, h_nowe;
    wire [15:0] h_temp, h_wilg;
    wire [8:0]  h_c;
    wire [6:0]  h_proc;
    wire [7:0]  h_nacki;
    reg         m_sda_oe = 1'b0;
    wire        scl = !h_scl_oe;
    wire        sda = !(h_sda_oe || m_sda_oe);
    hdc1000 #(.ADR(7'h40), .DIV(10), .CZEKAJ(5000), .OKRES(20000)) u_hdc (.clk(clk), .rst(rst), .scl_i(scl),
        .scl_oe(h_scl_oe), .sda_i(sda), .sda_oe(h_sda_oe), .temp_sur(h_temp), .wilg_sur(h_wilg), .temp_c(h_c),
        .wilg_proc(h_proc), .nowe(h_nowe), .nacki(h_nacki));

    reg  [15:0] h_konf = 16'h0000, h_t = 16'h6667, h_rh = 16'h8000;
    reg  [7:0]  h_ptr = 8'h00, h_bajt = 8'h00;
    reg  [31:0] h_wyj = 32'd0;
    integer     h_tryb = 0, h_n = 0, h_nd = 0, h_odcz = 0;
    reg         h_rw = 1'b0, h_mack = 1'b0, h_gotowy = 1'b0;
    realtime    h_t_pomiar = 0.0;
    always @(negedge sda) if (scl) begin h_tryb = 1; h_n = 0; end
    always @(posedge sda) if (scl) begin
        if (h_tryb == 2 && h_nd == 1 && h_ptr == 8'h00) begin             // sam wskaźnik 0x00: wyzwolenie pomiaru
            h_gotowy   = 1'b0;
            h_t_pomiar = $realtime;
        end
        h_tryb = 0; m_sda_oe = 1'b0;
    end
    always @(posedge scl) begin
        if (h_tryb == 1 || h_tryb == 2) begin
            if (h_n < 8) h_bajt = {h_bajt[6:0], sda};
            h_n = h_n + 1;
        end else if (h_tryb == 3) begin
            if (h_n == 8) h_mack = sda;
            h_n = h_n + 1;
        end
    end
    always @(negedge scl) begin
        if (!h_gotowy && $realtime - h_t_pomiar > 200_000.0) h_gotowy = 1'b1;   // pomiar trwa 200 µs
        if ((h_tryb == 1 || h_tryb == 2) && h_n == 8) begin
            if (h_tryb == 1) begin
                if (h_bajt[7:1] == 7'h40 && (!h_bajt[0] || h_gotowy)) begin m_sda_oe = 1'b1; h_rw = h_bajt[0]; end
                else h_tryb = 0;                                            // NACK (inny adres albo pomiar trwa)
            end else begin
                if (h_nd == 0) h_ptr = h_bajt;
                else if (h_ptr == 8'h02) h_konf = (h_nd == 1) ? {h_bajt, h_konf[7:0]} : {h_konf[15:8], h_bajt};
                h_nd = h_nd + 1;
                m_sda_oe = 1'b1;
            end
        end else if (h_n == 9 && h_tryb != 0) begin
            m_sda_oe = 1'b0;
            h_n = 0;
            if (h_tryb == 1) begin
                if (h_rw) begin
                    h_tryb = 3; h_wyj = {h_t, h_rh}; h_odcz = h_odcz + 1;
                    m_sda_oe = !h_wyj[31];
                end else begin h_tryb = 2; h_nd = 0; end
            end else if (h_tryb == 3) begin
                if (!h_mack) begin h_wyj = {h_wyj[23:0], 8'h00}; m_sda_oe = !h_wyj[31]; end
                else h_tryb = 0;
            end
        end else if (h_tryb == 3 && h_n >= 1 && h_n <= 7) begin
            m_sda_oe = !h_wyj[31 - h_n];
        end else if (h_tryb == 3 && h_n == 8) begin
            m_sda_oe = 1'b0;
        end
    end

    // ================= przebieg
    integer n_a = 0, n_t = 0, n_h = 0;
    always @(posedge clk) begin
        if (a_nowe) n_a = n_a + 1;
        if (t_nowe) n_t = n_t + 1;
        if (h_nowe) n_h = n_h + 1;
    end

    initial begin
        lis[6'h0F] = 8'h33;
        lis[6'h20] = 8'h07;
        lis[6'h23] = 8'h00;
        ustaw_xyz(16'h1230, 16'hFED0, 16'h4000);
        lm_wart = lm71_kod(2506);                              // 25,06 °C -> 801 = 25,03125 °C
        repeat (5) @(negedge clk);
        rst = 1'b0;

        fork
            begin                                                  // LIS2DH12
                wait (n_a == 1);
                @(negedge clk);
                if (a_who != 8'h33 || !a_id_ok) begin $display("WHO_AM_I = %h", a_who); errors = errors + 1; end
                if (lis[6'h20] != 8'h57 || lis[6'h23] != 8'h88) begin
                    $display("LIS2DH12: CTRL_REG1 = %h, CTRL_REG4 = %h", lis[6'h20], lis[6'h23]); errors = errors + 1;
                end
                if (ax != 16'h1230 || ay != 16'hFED0 || az != 16'h4000) begin
                    $display("LIS2DH12: x=%h y=%h z=%h", ax, ay, az); errors = errors + 1;
                end
                ustaw_xyz(16'h8000, 16'h7FF0, 16'h0010);
                wait (n_a == 2);
                @(negedge clk);
                if (ax != 16'h8000 || ay != 16'h7FF0 || az != 16'h0010) begin
                    $display("LIS2DH12 (2): x=%h y=%h z=%h", ax, ay, az); errors = errors + 1;
                end
            end
            begin                                                  // LM71
                wait (n_t == 1);
                @(negedge clk);
                if ($signed(t_c) != 25) begin $display("LM71: %0d C", $signed(t_c)); errors = errors + 1; end
                lm_wart = lm71_kod(-1050);                         // −10,5 °C
                wait (n_t == 2);
                @(negedge clk);
                if ($signed(t_c) != -11 || $signed(t_temp) != -336) begin
                    $display("LM71 (2): %0d C, surowe %0d", $signed(t_c), $signed(t_temp)); errors = errors + 1;
                end
            end
            begin                                                  // HDC1000
                wait (n_h == 1);
                @(negedge clk);
                $display("HDC1000: konfiguracja %h, temperatura %0d C, wilgotnosc %0d %%, NACK %0d, odczytow %0d",
                         h_konf, $signed(h_c), h_proc, h_nacki, h_odcz);
                if (h_konf != 16'h1000 || h_temp != 16'h6667 || h_wilg != 16'h8000 || $signed(h_c) != 26 ||
                    h_proc != 50 || h_nacki == 0) errors = errors + 1;
                h_t = 16'h0000; h_rh = 16'hFFFF;                     // −40 °C, 99 %
                wait (n_h == 2);
                @(negedge clk);
                if ($signed(h_c) != -40 || h_proc != 99) begin
                    $display("HDC1000 (2): %0d C, %0d %%", $signed(h_c), h_proc); errors = errors + 1;
                end
            end
        join
        $display("LIS2DH12: WHO_AM_I %h, odczyty XYZ %0d; LM71: %0d C; HDC1000: %0d C, %0d %%", a_who, n_a,
                 $signed(t_c), $signed(h_c), h_proc);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

// DECA — HDMI (moduł 24, 24.01–24.03): obraz 640×480 przy ok. 60 Hz przez nadajnik ADV7513.
// Zegar piksela 25 MHz z PLL (50 MHz · 1/2; 640×480 nominalnie 25,175 MHz — monitory akceptują 59,5 Hz).
// ADV7513 konfigurowany przez I2C po resecie i co 1 s (adv7513_konfig); HDMI_TX_CLK z rejestru DDR jako zegar
// odwrócony — zbocze narastające w środku bitu danych.
// Obraz: SW[0] = 0 — pasy barw, 1 — gradient; SW[1] = 1 — nakładki: odcinki z rogów do sprite'a (bitmapa
// 160×120 rysowana algorytmem Bresenhama w wygaszaniu pionowym), tekst (40×30 znaków 16×16) i sprite 16×16
// odbijający się od krawędzi. KEY[0] — reset, KEY[1] — ponowna konfiguracja ADV7513.
// Diody (0 = świeci): LED[0] konfiguracja zakończona, LED[1] błąd I2C (NACK), LED[2] konfiguracja w toku,
// LED[7:3] — licznik ramek (miganie). Ograniczenia: hdmi.sdc.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  logic        MAX10_CLK1_50,
    input  logic [1:0]  KEY,
    input  logic [1:0]  SW,
    output logic [7:0]  LED,
    output logic  [23:0] HDMI_TX_D,
    output logic        HDMI_TX_CLK,
    output logic         HDMI_TX_DE,
    output logic         HDMI_TX_HS,
    output logic         HDMI_TX_VS,
    input  logic        HDMI_TX_INT,
    inout  wire         HDMI_I2C_SCL,
    inout  wire         HDMI_I2C_SDA,
    inout  wire         HDMI_MCLK,
    inout  wire         HDMI_LRCLK,
    inout  wire         HDMI_SCLK,
    inout  wire  [3:0]  HDMI_I2S
);
    // ---- zegar piksela
    logic clk, locked;
`ifdef DECA_SYMULACJA
    assign clk    = MAX10_CLK1_50;
    assign locked = 1'b1;
    assign HDMI_TX_CLK = ~clk;
`else
    logic [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"),
        .lpm_type               ("altpll"),
        .operation_mode         ("NORMAL"),
        .pll_type               ("AUTO"),
        .inclk0_input_frequency (20000),
        .clk0_multiply_by       (1),
        .clk0_divide_by         (2),
        .clk0_duty_cycle        (50),
        .clk0_phase_shift       ("0"),
        .compensate_clock       ("CLK0"),
        .width_clock            (5)
    ) u_pll (.inclk({1'b0, MAX10_CLK1_50}), .areset(1'b0), .clk(pll_clk), .locked(locked));
    assign clk = pll_clk[0];
    // zegar dla ADV7513: rejestr DDR z 0 na zboczu narastającym i 1 na opadającym = zegar odwrócony
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_zeg (
        .datain_h(1'b0), .datain_l(1'b1), .outclock(clk), .dataout(HDMI_TX_CLK));
`endif
    assign HDMI_MCLK = 1'bz;
    assign HDMI_LRCLK = 1'bz;
    assign HDMI_SCLK = 1'bz;
    assign HDMI_I2S = 4'bzzzz;

    // ---- reset
    logic [1:0] rs = 2'b00;
    always_ff @(posedge clk or negedge KEY[0])
        if (!KEY[0]) rs <= 2'b00;
        else         rs <= {rs[0], locked};
    logic rst;
    assign rst = ~rs[1];
    logic [1:0] s_sw = 2'b00, s_k1 = 2'b11;
    logic       k1_d = 1'b1;
    always_ff @(posedge clk) begin s_sw <= SW; s_k1 <= {s_k1[0], KEY[1]}; k1_d <= s_k1[1]; end

    // ---- taktowanie
    logic        hs, vs, de, nowa_ramka;
    logic [11:0] x, y;
    takt_wideo u_takt (.clk(clk), .rst(rst), .hs(hs), .vs(vs), .de(de), .x(x), .y(y), .nowa_ramka(nowa_ramka));

    // ---- konfiguracja ADV7513
    logic scl_o, sda_o, zajety, gotowe, blad;
    adv7513_konfig #(.F_CLK(25000000), .F_I2C(100000), .OKRES(25000000)) u_adv (
        .clk(clk), .rst(rst), .start(k1_d && !s_k1[1]), .zajety(zajety), .gotowe(gotowe), .blad(blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(HDMI_I2C_SDA));
    assign HDMI_I2C_SCL = scl_o ? 1'bz : 1'b0;
    assign HDMI_I2C_SDA = sda_o ? 1'bz : 1'b0;

    // ---- tekst: zapis napisów po resecie
    localparam [8*26-1:0] T1 = "MODUL 24 - WIDEO I GRAFIKA";
    localparam [8*26-1:0] T2 = "DECA  HDMI  640X480  60 HZ";
    localparam [8*26-1:0] T3 = "SW0: TLO     SW1: NAKLADKI";
    logic  [6:0]  ti = 7'd0;
    logic         t_we = 1'b0;
    logic  [10:0] t_adr = 11'd0;
    logic  [7:0]  t_kod = 8'd0;
    always_ff @(posedge clk) begin
        t_we <= 1'b0;
        if (rst) ti <= 7'd0;
        else if (ti < 7'd78) begin
            t_we <= 1'b1;
            if (ti < 7'd26)      begin t_adr <= 11'd82  + ti;          t_kod <= T1[8 * (25 - ti) +: 8]; end
            else if (ti < 7'd52) begin t_adr <= 11'd162 + ti - 7'd26;  t_kod <= T2[8 * (51 - ti) +: 8]; end
            else                 begin t_adr <= 11'd1122 + ti - 7'd52; t_kod <= T3[8 * (77 - ti) +: 8]; end
            ti <= ti + 1'b1;
        end
    end
    logic piks_t;
    znaki #(.KOL(40), .WIER(30), .SK(1)) u_zn (.clk(clk), .we(t_we), .wadr(t_adr), .wkod(t_kod), .x(x), .y(y),
                                               .piks(piks_t));

    // ---- sprite: odbijanie od krawędzi, krok co ramkę
    logic  [11:0] sx = 12'd100, sy = 12'd60;
    logic         lewo = 1'b0, gora = 1'b0;
    logic  [4:0]  nr_ramki = 5'd0;
    always_ff @(posedge clk)
        if (nowa_ramka) begin
            nr_ramki <= nr_ramki + 1'b1;
            sx <= lewo ? sx - 12'd2 : sx + 12'd2;
            sy <= gora ? sy - 12'd1 : sy + 12'd1;
            if (!lewo && sx >= 12'd620) lewo <= 1'b1;
            if (lewo && sx <= 12'd2)    lewo <= 1'b0;
            if (!gora && sy >= 12'd462) gora <= 1'b1;
            if (gora && sy <= 12'd1)    gora <= 1'b0;
        end
    logic       sp_w;
    logic [1:0] sp_k;
    sprite16 u_sp (.clk(clk), .x(x), .y(y), .sx(sx), .sy(sy), .widoczny(sp_w), .kolor(sp_k));

    // ---- bitmapa 160×120 z odcinkami: czyszczenie i rysowanie w wygaszaniu pionowym
    logic         bm [0:19199];
    logic  [14:0] bw_adr = 15'd0;
    logic         bw_we = 1'b0, bw_d = 1'b0;
    always_ff @(posedge clk) if (bw_we) bm[bw_adr] <= bw_d;
    logic [14:0] br_adr;
    assign br_adr = {y[9:2], 7'd0} + {2'd0, y[9:2], 5'd0} + {5'd0, x[11:2]};   // (y/4)·160 + x/4
    logic         bm_q = 1'b0;
    always_ff @(posedge clk) bm_q <= bm[br_adr < 15'd19200 ? br_adr : 15'd0];

    localparam [1:0] R_CZEKA = 2'd0, R_CZYSC = 2'd1, R_LINIA = 2'd2, R_RYSUJ = 2'd3;
    logic  [1:0]  rs_st = R_CZEKA;
    logic  [1:0]  nr_l = 2'd0;
    logic         l_start = 1'b0;
    logic  [11:0] l_x0 = 12'd0, l_y0 = 12'd0, l_x1 = 12'd0, l_y1 = 12'd0;
    logic        l_got, l_pw, l_kon;
    logic [11:0] l_px, l_py;
    linia_bres u_lin (.clk(clk), .rst(rst), .start(l_start), .x0(l_x0), .y0(l_y0), .x1(l_x1), .y1(l_y1),
                      .dalej(1'b1), .gotowy(l_got), .px(l_px), .py(l_py), .pwazny(l_pw), .koniec(l_kon));
    logic [14:0] pkt_adr;
    assign pkt_adr = {l_py[7:0], 7'd0} + {2'd0, l_py[7:0], 5'd0} + {3'd0, l_px};
    always_ff @(posedge clk) begin
        l_start <= 1'b0;
        bw_we   <= 1'b0;
        if (rst) rs_st <= R_CZEKA;
        else case (rs_st)
            R_CZEKA: if (x == 12'd0 && y == 12'd480) begin rs_st <= R_CZYSC; bw_adr <= 15'd0; end
            R_CZYSC: begin
                bw_we <= 1'b1; bw_d <= 1'b0;
                if (bw_we) bw_adr <= bw_adr + 1'b1;
                if (bw_adr == 15'd19199) begin rs_st <= R_LINIA; nr_l <= 2'd0; bw_we <= 1'b0; end
            end
            R_LINIA: if (l_got && !l_start) begin                   // odcinek z rogu nr_l do środka sprite'a
                l_x0 <= nr_l[0] ? 12'd159 : 12'd0;
                l_y0 <= nr_l[1] ? 12'd119 : 12'd0;
                l_x1 <= (sx + 12'd8) >> 2;
                l_y1 <= (sy + 12'd8) >> 2;
                l_start <= 1'b1;
                rs_st <= R_RYSUJ;
            end
            default: begin                                          // punkty odcinka do bitmapy
                if (l_pw) begin bw_we <= 1'b1; bw_d <= 1'b1; bw_adr <= pkt_adr; end
                if (l_pw && l_kon) begin
                    nr_l  <= nr_l + 1'b1;
                    rs_st <= (nr_l == 2'd3) ? R_CZEKA : R_LINIA;
                end
            end
        endcase
    end

    // ---- tło (stopień 0) i wyrównanie do opóźnienia tekstu (2 takty)
    logic [2:0]  pas;
    assign pas = (x < 12'd80) ? 3'd0 : (x < 12'd160) ? 3'd1 : (x < 12'd240) ? 3'd2 : (x < 12'd320) ? 3'd3 :
                      (x < 12'd400) ? 3'd4 : (x < 12'd480) ? 3'd5 : (x < 12'd560) ? 3'd6 : 3'd7;
    logic  [23:0] tlo;
    always_comb begin
        if (s_sw[0]) tlo = {x[9:2], y[8:1], 8'h80};
        else case (pas)                                              // 8 pasów po 80 pikseli
            3'd0: tlo = 24'hFFFFFF;  3'd1: tlo = 24'hFFFF00;  3'd2: tlo = 24'h00FFFF;  3'd3: tlo = 24'h00FF00;
            3'd4: tlo = 24'hFF00FF;  3'd5: tlo = 24'hFF0000;  3'd6: tlo = 24'h0000FF;  default: tlo = 24'h000000;
        endcase
    end
    logic [23:0] tlo1, tlo2;
    logic [2:0]  syn1, syn2;
    logic        sp_w2, bm2;
    logic [1:0]  sp_k2;
    always_ff @(posedge clk) begin
        tlo1 <= tlo;  tlo2 <= tlo1;
        syn1 <= {de, hs, vs};  syn2 <= syn1;
        sp_w2 <= sp_w; sp_k2 <= sp_k;
        bm2 <= bm_q;
    end

    // ---- składanie (stopień 2) i rejestry wyjściowe
    logic [23:0] kolor;
    always_comb begin
        kolor = tlo2;
        if (s_sw[1]) begin
            if (bm2)    kolor = 24'hFF4040;
            if (piks_t) kolor = 24'hFFFFFF;
            if (sp_w2)  kolor = (sp_k2 == 2'd1) ? 24'h000080 : (sp_k2 == 2'd2) ? 24'hFFD000 : 24'h000000;
        end
        if (!syn2[2]) kolor = 24'h000000;
    end
    always_ff @(posedge clk) begin
        HDMI_TX_D  <= kolor;
        HDMI_TX_DE <= syn2[2];
        HDMI_TX_HS <= syn2[1];
        HDMI_TX_VS <= syn2[0];
    end

    assign LED = ~{nr_ramki, zajety, blad, gotowe};
endmodule

`default_nettype wire

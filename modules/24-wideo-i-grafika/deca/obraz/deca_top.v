// DECA — bufor ramki i filtr 3×3 (moduł 24, 24.04 i 24.06): obraz 320×240 w 16 odcieniach szarości (4 bity na
// piksel), dwie ramki w pamięci na chipie (bloki M9K, 2 × 9600 słów 32-bitowych) za portem Avalon-MM z burstami,
// wyświetlany z powiększeniem 2× (640×480) przez bufor_ramki i filtr3x3, wyjście przez ADV7513.
// Pamięć na chipie zastępuje tu DDR3: bufor_ramki widzi tylko port Avalon-MM, więc w miejsce tego modelu można
// podłączyć kontroler DDR3 z 23.02 (rozdz. „Na płytce DECA” w 24.04).
// Generator (zegar 50 MHz) rysuje do ramki niewyświetlanej: ukośne pasy przesuwające się co ramkę i koło
// odbijające się od krawędzi, potem zgłasza zamianę (przelacz) i czeka na jej wykonanie (podwójne buforowanie).
// SW[0] = 1 — rysowanie w ramce wyświetlanej, bez zamiany: widać rozdarcie obrazu (tearing).
// Filtr: SW[1] i KEY[1] (wciśnięty = 1): 00 — bez zmian, 01 — rozmycie, 10 — Sobel, 11 — krawędzie.
// Diody (0 = świeci): LED[0] ADV7513 skonfigurowany, LED[1] błąd I2C, LED[2] ramka aktywna, LED[3] niedobór
// danych (brak), LED[7:4] — licznik narysowanych ramek. Ograniczenia: obraz.sdc.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  wire        MAX10_CLK1_50,
    input  wire [1:0]  KEY,
    input  wire [1:0]  SW,
    output wire [7:0]  LED,
    output reg  [23:0] HDMI_TX_D,
    output wire        HDMI_TX_CLK,
    output reg         HDMI_TX_DE,
    output reg         HDMI_TX_HS,
    output reg         HDMI_TX_VS,
    input  wire        HDMI_TX_INT,
    inout  wire        HDMI_I2C_SCL,
    inout  wire        HDMI_I2C_SDA,
    inout  wire        HDMI_MCLK,
    inout  wire        HDMI_LRCLK,
    inout  wire        HDMI_SCLK,
    inout  wire [3:0]  HDMI_I2S
);
    wire clk_m = MAX10_CLK1_50;                 // domena pamięci i generatora: 50 MHz
    wire clk, locked;                           // domena piksela: 25 MHz
`ifdef DECA_SYMULACJA
    reg  dz = 1'b0;
    always @(posedge MAX10_CLK1_50) dz <= ~dz;
    assign clk    = dz;
    assign locked = 1'b1;
    assign HDMI_TX_CLK = ~clk;
`else
    wire [4:0] pll_clk;
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
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_zeg (
        .datain_h(1'b0), .datain_l(1'b1), .outclock(clk), .dataout(HDMI_TX_CLK));
`endif
    assign HDMI_MCLK = 1'bz;
    assign HDMI_LRCLK = 1'bz;
    assign HDMI_SCLK = 1'bz;
    assign HDMI_I2S = 4'bzzzz;

    // ---- resety w obu domenach
    reg [1:0] rs_p = 2'b00, rs_m = 2'b00;
    always @(posedge clk or negedge KEY[0])   if (!KEY[0]) rs_p <= 2'b00; else rs_p <= {rs_p[0], locked};
    always @(posedge clk_m or negedge KEY[0]) if (!KEY[0]) rs_m <= 2'b00; else rs_m <= {rs_m[0], locked};
    wire rst_p = ~rs_p[1];
    wire rst_m = ~rs_m[1];
    reg [1:0] sw_m = 2'b00, sw_p = 2'b00, k1_p = 2'b11;
    always @(posedge clk_m) sw_m <= SW;
    always @(posedge clk)   begin sw_p <= SW; k1_p <= {k1_p[0], KEY[1]}; end

    // ---- pamięć ramek: port A — odczyt burstami (Avalon-MM), port B — zapis generatora
    reg  [31:0] pam [0:19199];
    wire [15:0] m_adr;
    wire        m_read;
    wire [4:0]  m_burstcount;
    reg         s_akt = 1'b0, m_rvalid = 1'b0;
    reg  [15:0] s_adr = 16'd0;
    reg  [4:0]  s_ile = 5'd0;
    reg  [31:0] m_rdata = 32'd0;
    wire        m_wait = s_akt;                 // zajęty podczas wysyłania burstu
    always @(posedge clk_m) begin
        m_rvalid <= 1'b0;
        if (!s_akt) begin
            if (m_read) begin s_akt <= 1'b1; s_adr <= m_adr; s_ile <= m_burstcount; end
        end else begin
            m_rdata  <= pam[s_adr];
            m_rvalid <= 1'b1;
            s_adr    <= s_adr + 1'b1;
            s_ile    <= s_ile - 1'b1;
            if (s_ile == 5'd1) s_akt <= 1'b0;
        end
    end
    reg         g_we = 1'b0;
    reg  [15:0] g_adr = 16'd0;
    reg  [31:0] g_dane = 32'd0;
    always @(posedge clk_m) if (g_we) pam[g_adr] <= g_dane;

    // ---- bufor ramki
    wire        hs, vs, de, nowa_ramka;
    wire [11:0] x, y;
    takt_wideo u_takt (.clk(clk), .rst(rst_p), .hs(hs), .vs(vs), .de(de), .x(x), .y(y), .nowa_ramka(nowa_ramka));
    reg         przelacz = 1'b0;
    wire        aktywny, oczekuje, brak;
    wire        b_de, b_hs, b_vs;
    wire [3:0]  b_piks;
    bufor_ramki #(.SZER(320), .WYS(240), .SK(1), .BURST(8), .AW(16), .BAZA0(0), .BAZA1(9600)) u_bufor (
        .clk_m(clk_m), .rst_m(rst_m), .przelacz(przelacz), .aktywny(aktywny), .oczekuje(oczekuje), .brak(brak),
        .m_adr(m_adr), .m_read(m_read), .m_burstcount(m_burstcount), .m_wait(m_wait), .m_rvalid(m_rvalid),
        .m_rdata(m_rdata),
        .clk_p(clk), .rst_p(rst_p), .de(de), .hs(hs), .vs(vs), .x(x), .y(y),
        .o_de(b_de), .o_hs(b_hs), .o_vs(b_vs), .o_piks(b_piks));

    // ---- generator obrazu (domena pamięci): piksel na takt, słowo co 8 pikseli
    localparam [1:0] G_RYSUJ = 2'd0, G_ZAMIANA = 2'd1, G_CZEKAJ = 2'd2;
    reg  [1:0]  g_st = G_RYSUJ;
    reg  [8:0]  gx = 9'd0;
    reg  [7:0]  gy = 8'd0;
    reg  [7:0]  faza = 8'd0;
    reg  [8:0]  kx = 9'd160;
    reg  [7:0]  ky = 8'd120;
    reg         k_lewo = 1'b0, k_gora = 1'b0;
    reg  [31:0] slowo = 32'd0;
    reg  [15:0] w_adr = 16'd0;
    reg  [19:0] pauza = 20'd0;
    reg  [3:0]  narysowane = 4'd0;
    wire signed [9:0]  dx = $signed({1'b0, gx}) - $signed({1'b0, kx});
    wire signed [9:0]  dy = $signed({2'b00, gy}) - $signed({2'b00, ky});
    wire        [19:0] r2 = dx * dx + dy * dy;
    wire        [8:0]  pas = {1'b0, gx[7:0]} + {1'b0, gy} + {1'b0, faza};
    wire        [3:0]  g_piks = (gx == 9'd0 || gx == 9'd319 || gy == 8'd0 || gy == 8'd239) ? 4'd12 :
                                (r2 < 20'd1600) ? 4'd15 : pas[4] ? 4'd6 : 4'd2;
    always @(posedge clk_m) begin
        g_we     <= 1'b0;
        przelacz <= 1'b0;
        if (rst_m) begin
            g_st <= G_RYSUJ; gx <= 9'd0; gy <= 8'd0; w_adr <= 16'd9600;  // pierwsza ramka: do bufora 1
        end else case (g_st)
            G_RYSUJ: begin
                slowo <= {g_piks, slowo[31:4]};                           // piksel 0 słowa w bitach 3..0
                if (gx[2:0] == 3'd7) begin
                    g_we   <= 1'b1;
                    g_adr  <= w_adr;
                    g_dane <= {g_piks, slowo[31:4]};
                    w_adr  <= w_adr + 1'b1;
                end
                if (gx == 9'd319) begin
                    gx <= 9'd0;
                    if (gy == 8'd239) begin gy <= 8'd0; g_st <= G_ZAMIANA; end
                    else gy <= gy + 1'b1;
                end else gx <= gx + 1'b1;
            end
            G_ZAMIANA: begin
                if (!sw_m[0]) przelacz <= 1'b1;
                pauza <= 20'd833000;                                      // ok. 1 ramka przy 50 MHz
                g_st  <= G_CZEKAJ;
            end
            default: begin
                if (pauza != 20'd0) pauza <= pauza - 1'b1;
                if (sw_m[0] ? (pauza == 20'd0) : (!oczekuje && !przelacz)) begin
                    // następna klatka animacji; cel: ramka niewyświetlana (albo wyświetlana przy SW[0] = 1)
                    w_adr <= (aktywny ^ !sw_m[0]) ? 16'd9600 : 16'd0;
                    faza  <= faza + 1'b1;
                    narysowane <= narysowane + 1'b1;
                    kx <= k_lewo ? kx - 9'd3 : kx + 9'd3;
                    ky <= k_gora ? ky - 8'd2 : ky + 8'd2;
                    if (!k_lewo && kx >= 9'd276) k_lewo <= 1'b1;
                    if (k_lewo && kx <= 9'd44)   k_lewo <= 1'b0;
                    if (!k_gora && ky >= 8'd196) k_gora <= 1'b1;
                    if (k_gora && ky <= 8'd44)   k_gora <= 1'b0;
                    g_st <= G_RYSUJ;
                end
            end
        endcase
    end

    // ---- filtr 3×3 i wyjście
    wire       f_de, f_hs, f_vs;
    wire [7:0] f_piks;
    filtr3x3 #(.L(800), .PROG(96)) u_filtr (.clk(clk), .tryb({sw_p[1], ~k1_p[1]}), .de(b_de), .hs(b_hs),
                                            .vs(b_vs), .piks({b_piks, b_piks}), .o_de(f_de), .o_hs(f_hs),
                                            .o_vs(f_vs), .o_piks(f_piks));
    always @(posedge clk) begin
        HDMI_TX_D  <= f_de ? {f_piks, f_piks, f_piks} : 24'd0;
        HDMI_TX_DE <= f_de;
        HDMI_TX_HS <= f_hs;
        HDMI_TX_VS <= f_vs;
    end

    // ---- ADV7513
    wire scl_o, sda_o, zajety, gotowe, blad;
    adv7513_konfig #(.F_CLK(25000000), .F_I2C(100000), .OKRES(25000000)) u_adv (
        .clk(clk), .rst(rst_p), .start(1'b0), .zajety(zajety), .gotowe(gotowe), .blad(blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(HDMI_I2C_SDA));
    assign HDMI_I2C_SCL = scl_o ? 1'bz : 1'b0;
    assign HDMI_I2C_SDA = sda_o ? 1'bz : 1'b0;

    assign LED = ~{narysowane, brak, aktywny, blad, gotowe};
endmodule

`default_nettype wire

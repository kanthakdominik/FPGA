// Wyjście bufora ramki (24.04): obraz SZER × WYS, 4 bity na piksel (8 pikseli w słowie 32-bitowym, piksel i
// w bitach 4i+3..4i), dwie ramki w pamięci (BAZA0, BAZA1), wyświetlanie z powiększeniem 2^SK.
//  - domena pamięci (clk_m): czytnik_linii ładuje linie obrazu do dwóch buforów linii (linia n -> bufor n mod 2)
//    z wyprzedzeniem jednej linii; przelacz zamienia ramki na końcu wyświetlanej ramki (podwójne buforowanie);
//  - domena piksela (clk_p): odczyt bufora linii według (x, y) z generatora taktowania; zdarzenia „linia
//    zwolniona” i „koniec ramki” przechodzą do domeny pamięci jako zmiany bitów przełączanych (toggle) przez
//    synchronizatory 3-przerzutnikowe. Opóźnienie wyjść względem wejść: 2 takty clk_p.
// Pierwsza ramka po resecie jest czarna (nic nie było załadowane). brak = linia nie zdążyła się załadować.
`default_nettype none

module bufor_ramki #(
    parameter integer SZER  = 320,
    parameter integer WYS   = 240,
    parameter integer SK    = 1,
    parameter integer BURST = 8,
    parameter integer AW    = 16,
    parameter integer BAZA0 = 0,
    parameter integer BAZA1 = 9600
) (
    // domena pamięci
    input  wire          clk_m,
    input  wire          rst_m,
    input  wire          przelacz,
    output reg           aktywny,               // ramka wyświetlana (0: BAZA0, 1: BAZA1)
    output reg           oczekuje,              // zamiana zgłoszona, jeszcze niewykonana
    output reg           brak,
    output wire [AW-1:0] m_adr,
    output wire          m_read,
    output wire [4:0]    m_burstcount,
    input  wire          m_wait,
    input  wire          m_rvalid,
    input  wire [31:0]   m_rdata,
    // domena piksela
    input  wire          clk_p,
    input  wire          rst_p,
    input  wire          de,
    input  wire          hs,
    input  wire          vs,
    input  wire [11:0]   x,
    input  wire [11:0]   y,
    output reg           o_de,
    output reg           o_hs,
    output reg           o_vs,
    output reg  [3:0]    o_piks
);
    localparam integer SLOW = SZER / 8;
    localparam integer LW   = (2 * SLOW > 1) ? $clog2(2 * SLOW) : 1;
    /* verilator lint_off WIDTHTRUNC */
    localparam [11:0]   OST_Y = (WYS << SK) - 1;
    localparam [11:0]   MASKA = (1 << SK) - 1;
    localparam [10:0]   WYSW  = WYS;
    localparam [AW-1:0] SLA   = SLOW;
    localparam [AW-1:0] B0    = BAZA0;
    localparam [AW-1:0] B1    = BAZA1;
    localparam [LW-1:0] SLL   = SLOW;
    /* verilator lint_on WIDTHTRUNC */

    // ---------------------------------------------------------------- bufor linii (zapis clk_m, odczyt clk_p)
    reg  [31:0]   lram [0:2*SLOW-1];
    wire          lw_we;
    wire [LW-1:0] lw_adr;
    wire [31:0]   lw_dane;
    always @(posedge clk_m)
        if (lw_we) lram[lw_adr] <= lw_dane;

    // ---------------------------------------------------------------- domena piksela
    reg         de_d = 1'b0;
    reg  [11:0] y_d = 12'd0;
    reg         t_zw = 1'b0, t_kr = 1'b0, ok = 1'b0;
    wire [11:0] sx  = x >> SK;
    wire        sy0 = y[SK];                                  // parzystość linii obrazu -> bufor
    /* verilator lint_off WIDTHTRUNC */
    /* verilator lint_off WIDTHEXPAND */
    wire [LW-1:0] r_adr = (sy0 ? SLL : {LW{1'b0}}) + sx[11:3];
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */
    reg  [31:0] q;
    reg  [2:0]  nib;
    reg         de1, hs1, vs1;

    always @(posedge clk_p) begin
        if (rst_p) begin
            de_d <= 1'b0; y_d <= 12'd0; t_zw <= 1'b0; t_kr <= 1'b0; ok <= 1'b0;
        end else begin
            de_d <= de;
            y_d  <= y;
            if (de_d && !de) begin                                   // koniec linii aktywnej
                if (y_d == OST_Y) begin
                    t_kr <= ~t_kr;
                    ok   <= 1'b1;
                end else if ((y_d & MASKA) == MASKA) begin
                    t_zw <= ~t_zw;                                   // ostatnie powtórzenie linii obrazu
                end
            end
        end
    end

    always @(posedge clk_p) begin
        q      <= lram[r_adr];
        nib    <= sx[2:0];
        de1    <= de;
        hs1    <= hs;
        vs1    <= vs;
        o_de   <= de1;
        o_hs   <= hs1;
        o_vs   <= vs1;
        o_piks <= (de1 && ok) ? q[{nib, 2'b00} +: 4] : 4'd0;
    end

    // ---------------------------------------------------------------- domena pamięci
    reg  [2:0]    s_zw = 3'd0, s_kr = 3'd0;     // synchronizatory (bit 2 — poprzednia wartość)
    wire          e_zw = s_zw[2] ^ s_zw[1];
    wire          e_kr = s_kr[2] ^ s_kr[1];
    reg  [10:0]   nast, zal, k;
    reg           ramka_m;                     // była już ramka z ładowaniem (pierwsza po resecie — nie)
    reg  [2:0]    do_zal;
    reg  [AW-1:0] baza, adr_l;
    reg           cz_start, bufor_l;
    wire          cz_zajety, cz_gotowe;

    always @(posedge clk_m) begin
        s_zw <= {s_zw[1:0], t_zw};
        s_kr <= {s_kr[1:0], t_kr};
        if (rst_m) begin
            aktywny <= 1'b0; oczekuje <= 1'b0; brak <= 1'b0;
            nast <= 11'd0; zal <= 11'd0; k <= 11'd0; do_zal <= 3'd0; ramka_m <= 1'b0;
            baza <= B0; adr_l <= B0; cz_start <= 1'b0; bufor_l <= 1'b0;
        end else begin
            cz_start <= 1'b0;
            if (przelacz) oczekuje <= 1'b1;
            if (cz_gotowe) zal <= zal + 1'b1;
            if (e_kr) begin                                          // koniec ramki: zamiana i nowa ramka
                if (oczekuje || przelacz) begin
                    aktywny  <= ~aktywny;
                    oczekuje <= 1'b0;
                    baza     <= aktywny ? B0 : B1;
                end else begin
                    baza     <= aktywny ? B1 : B0;
                end
                nast <= 11'd0; zal <= 11'd0; k <= 11'd0; do_zal <= 3'd2; ramka_m <= 1'b1;
            end else begin
                if (e_zw) begin                                      // zaczyna się linia k + 1
                    k <= k + 1'b1;
                    if (ramka_m && zal + (cz_gotowe ? 11'd1 : 11'd0) < k + 11'd2) brak <= 1'b1;
                end
                if (!cz_zajety && !cz_start && do_zal != 3'd0 && nast != WYSW) begin
                    cz_start <= 1'b1;
                    adr_l    <= baza;
                    bufor_l  <= nast[0];
                    baza     <= baza + SLA;
                    nast     <= nast + 1'b1;
                    do_zal   <= do_zal - 1'b1 + (e_zw ? 3'd1 : 3'd0);
                end else if (e_zw) begin
                    do_zal   <= do_zal + 1'b1;
                end
            end
        end
    end

    czytnik_linii #(.SLOW(SLOW), .BURST(BURST), .AW(AW), .LW(LW)) u_cz (
        .clk(clk_m), .rst(rst_m), .start(cz_start), .adr(adr_l), .bufor(bufor_l),
        .zajety(cz_zajety), .gotowe(cz_gotowe),
        .m_adr(m_adr), .m_read(m_read), .m_burstcount(m_burstcount), .m_wait(m_wait),
        .m_rvalid(m_rvalid), .m_rdata(m_rdata),
        .lw_we(lw_we), .lw_adr(lw_adr), .lw_dane(lw_dane));
endmodule

`default_nettype wire

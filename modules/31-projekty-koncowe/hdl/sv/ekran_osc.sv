// Obraz oscyloskopu (31.02), domena zegara piksela. Pole przebiegu 2^AW × 256 pikseli w (X0, Y0):
//   siatka co 64 × 32 piksele, ramka wokół pola, poziom wyzwalania (linia pozioma), znacznik chwili wyzwolenia
//   (linia pionowa w kolumnie PRZED) i przebieg — w każdej kolumnie odcinek pionowy od poprzedniej do bieżącej
//   próbki, więc strome zbocza są ciągłe.
// Na początku ramki, jeśli akwizycja przekazała nowy zrzut (przełącznik gotowy_t), obraz przechodzi na jego bank
// i potwierdza (potw_t). Odczyt pamięci z wyprzedzeniem jednej kolumny (pamięć ma 1 takt opóźnienia);
// wyjście RGB i synchronizacje są rejestrowane — opóźnienie 1 takt względem takt_wideo.
`default_nettype none

module ekran_osc #(
    parameter integer AW    = 9,
    parameter integer PRZED = 64,
    parameter integer X0    = 64,
    parameter integer Y0    = 112
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          hs_we,
    input  logic          vs_we,
    input  logic          de_we,
    input  logic [11:0]   x,
    input  logic [11:0]   y,
    input  logic          nowa_ramka,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [11:0]   poziom,                 // linia rysowana z 8 najstarszych bitów
    /* verilator lint_on UNUSEDSIGNAL */
    // zrzut z domeny akwizycji (stabilne, gdy przełącznik się zmienił)
    input  logic          gotowy_t,
    input  logic          bank_gotowy,
    input  logic [AW-1:0] poczatek,
    output logic           potw_t = 1'b0,
    // pamięć
    output logic [AW:0]   ram_adr,
    input  logic [7:0]    ram_dane,
    // obraz
    output logic  [23:0]   rgb = 24'd0,
    output logic           hs = 1'b1,
    output logic           vs = 1'b1,
    output logic           de = 1'b0,
    output logic  [15:0]   nr_zrzutu = 16'd0
);
    localparam integer N = 1 << AW;
    localparam [23:0] C_TLO = 24'h000000, C_SIATKA = 24'h404040, C_RAMKA = 24'h808080,
                      C_POZIOM = 24'hFF8000, C_WYZW = 24'h0060FF, C_SLAD = 24'h00FF00;
    /* verilator lint_off WIDTHTRUNC */
    localparam [11:0] X0_W = X0, Y0_W = Y0, XK_W = X0 + N, YK_W = Y0 + 256, PRZED_W = PRZED;
    /* verilator lint_on WIDTHTRUNC */

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_got = 2'b00;
    always_ff @(posedge clk) s_got <= {s_got[0], gotowy_t};

    logic          bank = 1'b0;
    logic [AW-1:0] start = {AW{1'b0}};
    always_ff @(posedge clk)
        if (rst) begin
            potw_t <= 1'b0; nr_zrzutu <= 16'd0;
        end else if (nowa_ramka && s_got[1] != potw_t) begin
            bank      <= bank_gotowy;
            start     <= poczatek;
            potw_t    <= s_got[1];
            nr_zrzutu <= nr_zrzutu + 16'd1;
        end

    // odczyt z wyprzedzeniem: w takcie piksela x pamięć oddaje próbkę kolumny x - X0
    /* verilator lint_off UNUSEDSIGNAL */
    logic [11:0] kol_nast;
    assign kol_nast = x - X0_W + 12'd1;
    /* verilator lint_on UNUSEDSIGNAL */
    assign ram_adr = {bank, start + kol_nast[AW-1:0]};
    logic [7:0] poprz = 8'd0;
    always_ff @(posedge clk) poprz <= ram_dane;

    logic        w_polu;
    assign w_polu = (x >= X0_W) && (x < XK_W) && (y >= Y0_W) && (y < YK_W);
    logic [11:0] dx;
    assign dx = x - X0_W;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [11:0] dy;
    assign dy = y - Y0_W;                                  // w polu wystarcza 8 bitów
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_off WIDTHEXPAND */
    logic [7:0]  w_biez;
    assign w_biez = 8'd255 - ram_dane;                    // wiersz próbki w polu (0 = góra)
    logic [7:0]  w_poprz;
    assign w_poprz = (dx == 12'd0) ? w_biez : 8'd255 - poprz;
    /* verilator lint_on WIDTHEXPAND */
    logic [7:0]  w_min;
    assign w_min = (w_biez < w_poprz) ? w_biez : w_poprz;
    logic [7:0]  w_max;
    assign w_max = (w_biez < w_poprz) ? w_poprz : w_biez;
    logic [7:0]  w_poz;
    assign w_poz = 8'd255 - poziom[11:4];
    logic        slad;
    assign slad = w_polu && dy[7:0] >= w_min && dy[7:0] <= w_max;
    logic        lin_poz;
    assign lin_poz = w_polu && dy[7:0] == w_poz;
    logic        lin_wyzw;
    assign lin_wyzw = w_polu && dx == PRZED_W;
    logic        siatka;
    assign siatka = w_polu && (dx[5:0] == 6'd0 || dy[4:0] == 5'd0);
    logic        ramka;
    assign ramka = ((x == X0_W - 12'd1 || x == XK_W) && y >= Y0_W - 12'd1 && y <= YK_W) ||
                        ((y == Y0_W - 12'd1 || y == YK_W) && x >= X0_W - 12'd1 && x <= XK_W);

    always_ff @(posedge clk) begin
        hs <= hs_we;
        vs <= vs_we;
        de <= de_we;
        if (!de_we)        rgb <= C_TLO;
        else if (slad)     rgb <= C_SLAD;
        else if (lin_poz)  rgb <= C_POZIOM;
        else if (lin_wyzw) rgb <= C_WYZW;
        else if (ramka)    rgb <= C_RAMKA;
        else if (siatka)   rgb <= C_SIATKA;
        else               rgb <= C_TLO;
    end
endmodule

`default_nettype wire

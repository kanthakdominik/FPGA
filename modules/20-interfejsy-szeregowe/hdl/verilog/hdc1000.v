// Odczyt czujnika wilgotności i temperatury HDC1000 przez I²C (20.05), z użyciem i2c_master.
//   konfiguracja: rejestr 0x02 = 0x1000 (pomiar temperatury i wilgotności jednym wyzwoleniem, 14 bitów),
//   pętla: zapis wskaźnika 0x00 (wyzwala pomiar), odczekanie CZEKAJ (przetwarzanie ok. 13 ms),
//   odczyt 4 bajtów (temperatura MSB, LSB, wilgotność MSB, LSB; ostatni z NACK), co OKRES taktów.
// Czujnik odpowiada NACK na adres, dopóki pomiar trwa — wtedy STOP, odczekanie i ponowienie odczytu.
// Przeliczenie: T = surowe·165/2^16 − 40 °C, RH = surowe·100/2^16 % (całe jednostki, w dół).
`default_nettype none

module hdc1000 #(
    parameter [6:0] ADR    = 7'h40,
    parameter       DIV    = 125,                  // SCL 100 kHz przy 50 MHz
    parameter       CZEKAJ = 1_000_000,            // 20 ms
    parameter       OKRES  = 25_000_000            // 0,5 s
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        scl_i,
    output wire        scl_oe,
    input  wire        sda_i,
    output wire        sda_oe,
    output reg  [15:0] temp_sur = 16'd0,
    output reg  [15:0] wilg_sur = 16'd0,
    output wire [8:0]  temp_c,                       // U2, °C
    output wire [6:0]  wilg_proc,                    // %
    output reg         nowe = 1'b0,
    output reg  [7:0]  nacki = 8'd0                  // liczba odpowiedzi NACK (także „pomiar trwa”)
);
    localparam K_START = 3'd1, K_STOP = 3'd2, K_ZAPIS = 3'd3, K_ODCZYT = 3'd4;

    reg  [2:0] rozkaz = 3'd0;
    reg        wykonaj = 1'b0, nack_wy = 1'b0;
    reg  [7:0] wdane = 8'd0;
    wire [7:0] rdane;
    wire       gotowy, wykonane, nack_we;
    /* verilator lint_off PINCONNECTEMPTY */
    i2c_master #(.DIV(DIV)) u_i2c (.clk(clk), .rst(rst), .rozkaz(rozkaz), .wykonaj(wykonaj), .wdane(wdane),
        .nack_wy(nack_wy), .gotowy(gotowy), .wykonane(wykonane), .rdane(rdane), .nack_we(nack_we), .utrata(),
        .scl_i(scl_i), .scl_oe(scl_oe), .sda_i(sda_i), .sda_oe(sda_oe));
    /* verilator lint_on PINCONNECTEMPTY */

    // sekwencje rozkazów: {rozkaz, dane, nack_wy}
    localparam S_KONF = 2'd0, S_WYZW = 2'd1, S_CZEKA = 2'd2, S_ODCZ = 2'd3;
    function [11:0] krok(input [1:0] s, input [2:0] k);
        case (s)
            S_KONF: case (k)
                3'd0: krok = {K_START, 8'h00, 1'b0};
                3'd1: krok = {K_ZAPIS, ADR, 1'b0, 1'b0};
                3'd2: krok = {K_ZAPIS, 8'h02, 1'b0};          // wskaźnik: rejestr konfiguracji
                3'd3: krok = {K_ZAPIS, 8'h10, 1'b0};          // MODE = 1
                3'd4: krok = {K_ZAPIS, 8'h00, 1'b0};
                default: krok = {K_STOP, 8'h00, 1'b0};
            endcase
            S_WYZW: case (k)
                3'd0: krok = {K_START, 8'h00, 1'b0};
                3'd1: krok = {K_ZAPIS, ADR, 1'b0, 1'b0};
                3'd2: krok = {K_ZAPIS, 8'h00, 1'b0};          // wskaźnik 0x00: wyzwolenie pomiaru
                default: krok = {K_STOP, 8'h00, 1'b0};
            endcase
            default: case (k)                                 // S_ODCZ
                3'd0: krok = {K_START, 8'h00, 1'b0};
                3'd1: krok = {K_ZAPIS, ADR, 1'b1, 1'b0};
                3'd2, 3'd3, 3'd4: krok = {K_ODCZYT, 8'h00, 1'b0};
                3'd5: krok = {K_ODCZYT, 8'h00, 1'b1};         // ostatni bajt: NACK
                default: krok = {K_STOP, 8'h00, 1'b0};
            endcase
        endcase
    endfunction
    reg [1:0]  stan = S_KONF;
    wire [2:0] ost = (stan == S_KONF) ? 3'd5 : (stan == S_WYZW) ? 3'd3 : 3'd6;   // indeks rozkazu STOP
    reg [2:0]  k = 3'd0;
    reg        w_toku = 1'b0, przerwij = 1'b0;
    reg [31:0] licz = 32'd0, czekaj_do = 32'd0;
    reg [1:0]  nast = S_WYZW;                        // stan po odczekaniu
    reg [31:0] bajty = 32'd0;

    wire [11:0] r = krok(stan, k);

    always @(posedge clk) begin
        wykonaj <= 1'b0;
        nowe    <= 1'b0;
        if (rst) begin
            stan   <= S_KONF;
            k      <= 3'd0;
            w_toku <= 1'b0;
            licz   <= 32'd0;
            nacki  <= 8'd0;
        end else if (stan == S_CZEKA) begin
            if (licz >= czekaj_do) begin
                licz <= 32'd0;
                stan <= nast;
                k    <= 3'd0;
            end else
                licz <= licz + 1'b1;
        end else if (!w_toku) begin
            if (gotowy) begin
                rozkaz  <= przerwij ? K_STOP : r[11:9];
                wdane   <= r[8:1];
                nack_wy <= r[0];
                wykonaj <= 1'b1;
                w_toku  <= 1'b1;
            end
        end else if (wykonane) begin
            w_toku <= 1'b0;
            if (rozkaz == K_ODCZYT) bajty <= {bajty[23:0], rdane};
            if (rozkaz == K_ZAPIS && nack_we) begin          // brak potwierdzenia: STOP i ponowienie
                przerwij <= 1'b1;
                if (nacki != 8'hFF) nacki <= nacki + 1'b1;
            end else if (przerwij || k == ost) begin           // koniec sekwencji
                przerwij  <= 1'b0;
                stan      <= S_CZEKA;
                licz      <= 32'd0;
                if (przerwij) begin                           // ponów tę samą sekwencję po krótkiej przerwie
                    czekaj_do <= CZEKAJ / 4;
                    nast      <= stan;
                end else if (stan == S_KONF) begin
                    czekaj_do <= 32'd0;
                    nast      <= S_WYZW;
                end else if (stan == S_WYZW) begin
                    czekaj_do <= CZEKAJ;
                    nast      <= S_ODCZ;
                end else begin
                    temp_sur  <= bajty[31:16];
                    wilg_sur  <= bajty[15:0];
                    nowe      <= 1'b1;
                    czekaj_do <= OKRES;
                    nast      <= S_WYZW;
                end
            end else
                k <= k + 1'b1;
        end
    end

    // przeliczenie na jednostki
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off UNUSEDSIGNAL */
    wire [23:0] t165 = temp_sur * 8'd165;
    wire [22:0] w100 = wilg_sur * 7'd100;
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_on WIDTHEXPAND */
    assign temp_c    = {1'b0, t165[23:16]} - 9'd40;
    assign wilg_proc = w100[22:16];
endmodule

`default_nettype wire

// SPI master (20.02): słowa N-bitowe od najstarszego bitu, tryb CPOL/CPHA wybierany w czasie pracy,
// SCLK = f_clk / (2·DIV). Każda faza (CS -> pierwsze zbocze, pół okresu SCLK, ostatnie zbocze -> CS)
// trwa DIV taktów.
//   CPOL — poziom SCLK w spoczynku; CPHA = 0 — próbkowanie na zboczu wiodącym (dane wystawione przed
//   pierwszym zboczem), CPHA = 1 — wystawienie na wiodącym, próbkowanie na końcowym.
// start przy zajety = 0 wysyła tx_dane; dalej = 1 zostawia CS aktywne po słowie (transakcja wielosłowowa:
// kolejny start bez podnoszenia CS), dalej = 0 kończy transakcję. gotowe — takt po odebraniu słowa.
`default_nettype none

module spi_master #(
    parameter N   = 8,
    parameter DIV = 4
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         cpol,
    input  logic         cpha,
    input  logic         start,
    input  logic         dalej,
    input  logic [N-1:0] tx_dane,
    output logic  [N-1:0] rx_dane,
    output logic         zajety,
    output logic          gotowe = 1'b0,
    output logic          sclk = 1'b0,
    output logic         mosi,
    input  logic         miso,
    output logic          cs_n = 1'b1
);
    localparam CW = $clog2(DIV + 1);
    localparam EW = $clog2(2 * N + 1);
    localparam [CW-1:0] DIV_1  = DIV - 1;
    localparam [EW-1:0] ZBOCZA = 2 * N;

    localparam S_SPOCZ = 3'd0, S_CS = 3'd1, S_ZBOCZA = 3'd2, S_KONIEC = 3'd3, S_CZEKA = 3'd4, S_CS_WYS = 3'd5;
    logic [2:0]    stan = S_SPOCZ;
    logic [CW-1:0] t;
    logic [EW-1:0] k;                                       // numer zbocza w słowie, 1…2N
    logic [N-1:0]  sr_tx, sr_rx;
    logic          trzymaj;

    assign mosi   = sr_tx[N-1];
    assign zajety = (stan != S_SPOCZ) && (stan != S_CZEKA);

    logic wiodace;
    assign wiodace = !k[0];                                  // następne zbocze (k+1) nieparzyste = wiodące

    always_ff @(posedge clk) begin
        gotowe <= 1'b0;
        if (rst) begin
            stan <= S_SPOCZ;
            cs_n <= 1'b1;
            sclk <= cpol;
        end else case (stan)
            S_SPOCZ, S_CZEKA: begin                        // S_CZEKA: CS aktywne, czekamy na kolejne słowo
                sclk <= cpol;
                if (start) begin
                    sr_tx   <= tx_dane;
                    trzymaj <= dalej;
                    k       <= {EW{1'b0}};
                    t       <= DIV_1;
                    cs_n    <= 1'b0;
                    stan    <= (stan == S_SPOCZ) ? S_CS : S_ZBOCZA;
                end
            end
            S_CS:                                          // czas od CS do pierwszego zbocza
                if (t == 0) begin
                    t    <= DIV_1;
                    stan <= S_ZBOCZA;
                end else t <= t - 1'b1;
            S_ZBOCZA:
                if (t == 0) begin
                    t    <= DIV_1;
                    k    <= k + 1'b1;
                    sclk <= ~sclk;
                    // próbkowanie: CPHA = 0 na zboczach wiodących, CPHA = 1 na końcowych
                    if (wiodace ^ cpha)
                        sr_rx <= {sr_rx[N-2:0], miso};
                    // wystawienie kolejnego bitu: CPHA = 0 na końcowych (poza ostatnim), CPHA = 1 na wiodących (poza pierwszym)
                    else if (k != 0 && k != ZBOCZA - 1)
                        sr_tx <= {sr_tx[N-2:0], 1'b0};
                    if (k == ZBOCZA - 1) stan <= S_KONIEC;
                end else t <= t - 1'b1;
            S_KONIEC:                                      // czas od ostatniego zbocza do końca słowa
                if (t == 0) begin
                    rx_dane <= sr_rx;
                    gotowe  <= 1'b1;
                    t       <= DIV_1;
                    if (trzymaj) stan <= S_CZEKA;
                    else begin
                        cs_n <= 1'b1;
                        stan <= S_CS_WYS;
                    end
                end else t <= t - 1'b1;
            default:                                       // S_CS_WYS: minimalny czas CS nieaktywnego
                if (t == 0) stan <= S_SPOCZ;
                else t <= t - 1'b1;
        endcase
    end
endmodule

`default_nettype wire

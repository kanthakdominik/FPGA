// Sterownik akcelerometru LIS2DH12 przez SPI (20.05), tryb 3 (CPOL = 1, CPHA = 1), MSB pierwszy.
// Pierwszy bajt transakcji: bit 7 — odczyt (1) / zapis (0), bit 6 — autoinkrementacja adresu (MS),
// bity 5:0 — adres rejestru. Sekwencja:
//   1. odczekanie CZEKAJ taktów (rozruch czujnika, 5 ms),
//   2. odczyt WHO_AM_I (0x0F) — oczekiwane 0x33 (flaga id_ok),
//   3. CTRL_REG1 (0x20) = 0x57: 100 Hz, tryb normalny, osie X, Y, Z,
//   4. CTRL_REG4 (0x23) = 0x88: BDU (spójne bajty L/H), HR (12 bitów), zakres ±2 g,
//   5. co OKRES taktów odczyt 6 bajtów od OUT_X_L (0x28) jedną transakcją z autoinkrementacją.
// Wyniki: 16 bitów ze znakiem, wyrównane do lewej (12 bitów znaczących w trybie HR, ~1 mg/LSB po >>> 4).
`default_nettype none

module akcel_lis2dh12 #(
    parameter DIV    = 13,                          // SCLK = 50 MHz / 26 ≈ 1,9 MHz
    parameter CZEKAJ = 250_000,                     // 5 ms przy 50 MHz
    parameter OKRES  = 2_500_000                    // 50 ms przy 50 MHz
) (
    input  logic        clk,
    input  logic        rst,
    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs_n,
    output logic  [15:0] x = 16'd0,
    output logic  [15:0] y = 16'd0,
    output logic  [15:0] z = 16'd0,
    output logic         nowe = 1'b0,
    output logic  [7:0]  who_am_i = 8'd0,
    output logic        id_ok
);
    assign id_ok = (who_am_i == 8'h33);

    // ---- SPI
    logic        start = 1'b0, dalej = 1'b0;
    logic  [7:0] tx = 8'd0;
    logic [7:0] rx;
    logic       zajety, gotowe;
    spi_master #(.N(8), .DIV(DIV)) u_spi (.clk(clk), .rst(rst), .cpol(1'b1), .cpha(1'b1), .start(start),
        .dalej(dalej), .tx_dane(tx), .rx_dane(rx), .zajety(zajety), .gotowe(gotowe), .sclk(sclk), .mosi(mosi),
        .miso(miso), .cs_n(cs_n));

    // ---- kolejne transakcje: lista bajtów zależna od etapu
    localparam E_ROZRUCH = 3'd0, E_ID = 3'd1, E_CTRL1 = 3'd2, E_CTRL4 = 3'd3, E_CZEKA = 3'd4, E_XYZ = 3'd5;
    logic [2:0]  etap = E_ROZRUCH;
    logic [2:0]  nb;                                   // numer bajtu w transakcji
    logic        w_toku = 1'b0;
    logic [31:0] licz = 32'd0;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [47:0] dane;                                 // bajty danych, ostatni odebrany na górze
    /* verilator lint_on UNUSEDSIGNAL */
    logic [47:0] pelne;
    assign pelne = {rx, dane[47:8]};            // po 6 bajtach: ZH ZL YH YL XH XL (od góry)

    logic [2:0] dlugosc;
    assign dlugosc = (etap == E_XYZ) ? 3'd7 : 3'd2;
    // bajt nb transakcji danego etapu
    function [7:0] bajt(input [2:0] e, input [2:0] n);
        case (e)
            E_ID:    bajt = (n == 0) ? 8'h8F : 8'h00;          // odczyt 0x0F
            E_CTRL1: bajt = (n == 0) ? 8'h20 : 8'h57;
            E_CTRL4: bajt = (n == 0) ? 8'h23 : 8'h88;
            default: bajt = (n == 0) ? 8'hE8 : 8'h00;          // odczyt, MS, 0x28
        endcase
    endfunction

    always_ff @(posedge clk) begin
        start <= 1'b0;
        nowe  <= 1'b0;
        if (rst) begin
            etap   <= E_ROZRUCH;
            licz   <= 32'd0;
            w_toku <= 1'b0;
        end else if (etap == E_ROZRUCH || etap == E_CZEKA) begin
            if (licz == ((etap == E_ROZRUCH) ? CZEKAJ : OKRES)) begin
                licz <= 32'd0;
                etap <= (etap == E_ROZRUCH) ? E_ID : E_XYZ;
            end else
                licz <= licz + 1'b1;
        end else if (!w_toku) begin                          // pierwszy bajt transakcji
            if (!zajety) begin
                tx     <= bajt(etap, 3'd0);
                dalej  <= 1'b1;
                start  <= 1'b1;
                nb     <= 3'd0;
                w_toku <= 1'b1;
            end
        end else if (gotowe) begin
            if (nb != 0) dane <= {rx, dane[47:8]};          // bajty danych od najmłodszego
            if (nb == dlugosc - 3'd1) begin                  // koniec transakcji
                w_toku <= 1'b0;
                case (etap)
                    E_ID:    begin who_am_i <= rx; etap <= E_CTRL1; end
                    E_CTRL1: etap <= E_CTRL4;
                    E_CTRL4: etap <= E_CZEKA;
                    default: begin
                        x    <= pelne[15:0];
                        y    <= pelne[31:16];
                        z    <= pelne[47:32];
                        nowe <= 1'b1;
                        etap <= E_CZEKA;
                    end
                endcase
            end else begin
                tx    <= bajt(etap, nb + 3'd1);
                dalej <= (nb + 3'd1 != dlugosc - 3'd1);       // ostatni bajt zwalnia CS
                start <= 1'b1;
                nb    <= nb + 3'd1;
            end
        end
    end
endmodule

`default_nettype wire

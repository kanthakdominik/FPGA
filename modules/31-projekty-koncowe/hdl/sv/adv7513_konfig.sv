// Konfiguracja nadajnika HDMI ADV7513 przez I2C (24.02): zapis tablicy rejestrów po resecie, na żądanie (start)
// i cyklicznie co OKRES taktów (po odłączeniu i podłączeniu monitora ADV7513 wraca do stanu wyłączenia, więc
// konfigurację trzeba powtórzyć). Każdy wpis: START, adres 0x72 (7 bitów 0x39 + zapis), rejestr, wartość, STOP.
// Brak potwierdzenia (NACK) przerywa serię i ustawia blad (do następnej udanej serii).
// Linie I2C z otwartym drenem: scl_o / sda_o = 0 — ściągnij do masy, 1 — zwolnij (podciąga rezystor).
// Wartości rejestrów: ADV7513 Programming Guide (rejestry stałe 0x98–0xF9, format wejścia 24-bit RGB 4:4:4
// z osobną synchronizacją, tryb HDMI); por. 24.02.
`default_nettype none

module adv7513_konfig #(
    parameter integer F_CLK  = 25000000,
    parameter integer F_I2C  = 100000,
    parameter integer OKRES  = 25000000,        // takty między seriami (0 — tylko po resecie i na start)
    parameter [6:0]   ADRES  = 7'h39
) (
    input  logic clk,
    input  logic rst,
    input  logic start,
    output logic  zajety,
    output logic  gotowe,                         // ostatnia seria zakończona bez błędu
    output logic  blad,
    output logic  scl_o,
    output logic  sda_o,
    input  logic sda_i
);
    localparam integer N  = 17;
    localparam integer DZ = F_CLK / (4 * F_I2C);    // takty na ćwierć okresu SCL
    /* verilator lint_off WIDTHTRUNC */
    localparam [4:0]  OST = N - 1;
    localparam [15:0] DZ1 = DZ - 1;
    /* verilator lint_on WIDTHTRUNC */

    function [15:0] tab(input [4:0] i);             // {rejestr, wartość}
        case (i)
            5'd0:    tab = 16'h41_10;               // zasilanie włączone
            5'd1:    tab = 16'h98_03;               // rejestry stałe (wymagane wartości)
            5'd2:    tab = 16'h9A_E0;
            5'd3:    tab = 16'h9C_30;
            5'd4:    tab = 16'h9D_61;
            5'd5:    tab = 16'hA2_A4;
            5'd6:    tab = 16'hA3_A4;
            5'd7:    tab = 16'hE0_D0;
            5'd8:    tab = 16'hF9_00;
            5'd9:    tab = 16'h15_00;               // wejście: 24 bity RGB 4:4:4, osobne HS/VS/DE
            5'd10:   tab = 16'h16_30;               // wyjście 4:4:4, 8 bitów na składową
            5'd11:   tab = 16'h17_00;               // polaryzacje synchronizacji z wejścia, proporcje 4:3
            5'd12:   tab = 16'h18_46;               // konwersja przestrzeni barw wyłączona (bit 7 = 0)
            5'd13:   tab = 16'hAF_16;               // tryb HDMI, bez HDCP
            5'd14:   tab = 16'hBA_60;               // opóźnienie zegara wejściowego: brak
            5'd15:   tab = 16'hD6_C0;               // HPD traktowane jako zawsze aktywne
            default: tab = 16'h96_F6;               // kasowanie flag przerwań
        endcase
    endfunction

    localparam [2:0] S_BEZCZ = 3'd0, S_START = 3'd1, S_BIT = 3'd2, S_STOP = 3'd3, S_PRZERWA = 3'd4;

    logic  [2:0]  stan;
    logic  [1:0]  faza;
    logic  [15:0] lt;
    logic  [4:0]  idx;
    logic  [4:0]  b;                               // numer bitu ramki 26..0
    logic  [26:0] ramka;
    logic  [31:0] lo;
    logic         nack, start_w;
    logic        tik;
    assign tik = (lt == 16'd0);
    logic [15:0] wpis;
    assign wpis = tab(idx);
    logic        ack_poz;
    assign ack_poz = (b == 5'd18) || (b == 5'd9) || (b == 5'd0);

    always_ff @(posedge clk) begin
        if (rst) begin
            stan    <= S_BEZCZ;
            faza    <= 2'd0;
            lt      <= 16'd0;
            idx     <= 5'd0;
            b       <= 5'd0;
            ramka   <= 27'd0;
            lo      <= 32'd0;
            nack    <= 1'b0;
            start_w <= 1'b1;                     // seria po resecie
            zajety  <= 1'b0;
            gotowe  <= 1'b0;
            blad    <= 1'b0;
            scl_o   <= 1'b1;
            sda_o   <= 1'b1;
        end else begin
            if (start) start_w <= 1'b1;
            if (OKRES > 0 && stan == S_BEZCZ) begin
                /* verilator lint_off WIDTHEXPAND */
                if (lo >= OKRES - 1) begin lo <= 32'd0; start_w <= 1'b1; end
                /* verilator lint_on WIDTHEXPAND */
                else lo <= lo + 1'b1;
            end
            lt <= tik ? DZ1 : lt - 1'b1;
            if (tik) begin
                faza <= faza + 1'b1;
                case (stan)
                    S_BEZCZ: begin
                        faza <= 2'd0;
                        if (start_w) begin
                            start_w <= 1'b0;
                            zajety  <= 1'b1;
                            idx     <= 5'd0;
                            nack    <= 1'b0;
                            stan    <= S_START;
                        end
                    end
                    S_START:                                     // SDA opada przy SCL = 1
                        case (faza)
                            2'd0: begin
                                sda_o <= 1'b1; scl_o <= 1'b1;
                                ramka <= {ADRES, 1'b0, 1'b1, wpis[15:8], 1'b1, wpis[7:0], 1'b1};
                            end
                            2'd1: sda_o <= 1'b0;
                            2'd2: ;                                  // t_HD;STA ≥ 4 µs: dwie ćwiartki
                            default: begin scl_o <= 1'b0; b <= 5'd26; stan <= S_BIT; end
                        endcase
                    S_BIT:
                        case (faza)
                            2'd0: sda_o <= ramka[b];                 // zmiana danych przy SCL = 0
                            2'd1: scl_o <= 1'b1;
                            2'd2: if (ack_poz && sda_i) nack <= 1'b1; // potwierdzenie: odbiornik ściąga SDA
                            default: begin
                                scl_o <= 1'b0;
                                if (b == 5'd0) stan <= S_STOP;
                                else b <= b - 1'b1;
                            end
                        endcase
                    S_STOP:                                      // SDA rośnie przy SCL = 1
                        case (faza)
                            2'd0: sda_o <= 1'b0;
                            2'd1: scl_o <= 1'b1;
                            2'd2: ;                                  // t_SU;STO ≥ 4 µs
                            default: begin sda_o <= 1'b1; stan <= S_PRZERWA; end
                        endcase
                    default:                                     // czas wolnej magistrali przed kolejnym START
                        if (faza == 2'd3) begin
                            if (nack || idx == OST) begin
                                zajety <= 1'b0;
                                gotowe <= !nack;
                                blad   <= nack;
                                stan   <= S_BEZCZ;
                            end else begin
                                idx  <= idx + 1'b1;
                                stan <= S_START;
                            end
                        end
                endcase
            end
        end
    end
endmodule

`default_nettype wire

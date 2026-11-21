// Kontroler karty SD w trybie SPI (23.05): inicjalizacja i odczyt bloku 512 B.
//   Inicjalizacja (SCLK ≤ 400 kHz): ≥ 74 takty z CS = 1, CMD0 (R1 = 0x01), CMD8 0x1AA (karta v2, echo 0x1AA),
//   CMD55 + ACMD41 z HCS aż R1 = 0x00, CMD58 (OCR: bit CCS = karta SDHC/SDXC), dla SDSC CMD16 512.
//   Odczyt: CMD17 (adres = numer bloku dla SDHC, numer·512 dla SDSC), token 0xFE, 512 bajtów, CRC16
//   sprawdzany (crc_ok). CRC7 liczone dla każdego rozkazu. Tryb SPI 0, MSB pierwszy.
`default_nettype none

module sd_spi #(
    parameter integer DIV_WOLNY  = 63,             // 50 MHz / 126 ≈ 397 kHz
    parameter integer DIV_SZYBKI = 2,              // 50 MHz / 4 = 12,5 MHz
    parameter integer PROBY      = 2000            // ACMD41 i oczekiwanie na token
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        odczyt,                     // impuls: czytaj blok
    input  wire [31:0] blok,
    output reg         gotowy,                     // zainicjalizowana i bezczynna
    output reg         sdhc,
    output reg         blad,
    output reg  [3:0]  kod_bledu,
    output reg  [7:0]  dane,
    output reg         dane_wazne,
    output reg         koniec,                     // impuls po bloku
    output reg         crc_ok,
    output reg         sclk,
    output reg         mosi,
    output reg         cs_n,
    input  wire        miso
);
    // ---- silnik bajtowy
    reg        b_start, b_done, szybko;
    /* verilator lint_off UNUSEDSIGNAL */  // b_sr[7] wysuwany na zewnątrz
    reg [7:0]  b_tx, b_rx, b_sr;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [3:0]  b_n;
    reg [6:0]  b_t;
    reg        b_akt;
    wire [6:0] b_div = szybko ? DIV_SZYBKI[6:0] - 1'b1 : DIV_WOLNY[6:0] - 1'b1;

    always @(posedge clk) begin
        b_done <= 1'b0;
        if (rst) begin
            b_akt <= 1'b0;
            sclk  <= 1'b0;
            mosi  <= 1'b1;
        end else if (!b_akt) begin
            if (b_start) begin
                b_akt <= 1'b1;
                b_sr  <= b_tx;
                mosi  <= b_tx[7];
                b_n   <= 4'd0;
                b_t   <= b_div;
            end
        end else if (b_t != 0)
            b_t <= b_t - 1'b1;
        else begin
            b_t  <= b_div;
            sclk <= !sclk;
            if (!sclk)                                          // narastające: próbka MISO
                b_rx <= {b_rx[6:0], miso};
            else begin                                          // opadające: następny bit
                b_n  <= b_n + 1'b1;
                b_sr <= {b_sr[6:0], 1'b1};
                mosi <= b_sr[6];
                if (b_n == 4'd7) begin
                    b_akt  <= 1'b0;
                    b_done <= 1'b1;
                    mosi   <= 1'b1;
                end
            end
        end
    end

    // ---- CRC (zmienne lokalne funkcji i zadań przypisywane blokująco — celowo)
    /* verilator lint_off BLKSEQ */
    function [6:0] crc7(input [39:0] d);
        integer i;
        reg fb;
        begin
            crc7 = 7'd0;
            for (i = 39; i >= 0; i = i - 1) begin
                fb   = d[i] ^ crc7[6];
                crc7 = {crc7[5:0], 1'b0} ^ (fb ? 7'h09 : 7'h00);
            end
        end
    endfunction
    function [15:0] crc16(input [15:0] c, input [7:0] d);
        integer i;
        reg fb;
        begin
            crc16 = c;
            for (i = 7; i >= 0; i = i - 1) begin
                fb    = d[i] ^ crc16[15];
                crc16 = {crc16[14:0], 1'b0} ^ (fb ? 16'h1021 : 16'h0000);
            end
        end
    endfunction

    // ---- sekwencer rozkazów
    localparam [3:0] P_ROZRUCH = 4'd0, P_WYSLIJ = 4'd1, P_R1 = 4'd2, P_EXT = 4'd3, P_PRZERWA = 4'd4,
                     P_GOTOWY = 4'd5, P_TOKEN = 4'd6, P_DANE = 4'd7, P_CRC = 4'd8, P_BLAD = 4'd9;
    localparam [2:0] K_CMD0 = 3'd0, K_CMD8 = 3'd1, K_CMD55 = 3'd2, K_ACMD41 = 3'd3, K_CMD58 = 3'd4,
                     K_CMD16 = 3'd5, K_CMD17 = 3'd6;

    reg  [3:0]  p;
    reg  [2:0]  krok;
    reg  [47:0] ramka;
    reg  [3:0]  idx;
    reg  [7:0]  r1;
    /* verilator lint_off UNUSEDSIGNAL */  // ext[29:24] (OCR) nieużywane
    reg  [31:0] ext;
    /* verilator lint_on UNUSEDSIGNAL */
    reg  [10:0] licz;
    /* verilator lint_off UNUSEDSIGNAL */  // crc_odeb[7:0] zbędne — porównanie przy ostatnim bajcie
    reg  [15:0] proby, crc_obl, crc_odeb;
    /* verilator lint_on UNUSEDSIGNAL */
    reg         czeka;                              // bajt w drodze

    function [5:0] nr(input [2:0] k);
        case (k)
            K_CMD0:   nr = 6'd0;
            K_CMD8:   nr = 6'd8;
            K_CMD55:  nr = 6'd55;
            K_ACMD41: nr = 6'd41;
            K_CMD58:  nr = 6'd58;
            K_CMD16:  nr = 6'd16;
            default:  nr = 6'd17;
        endcase
    endfunction
    function [31:0] argument(input [2:0] k, input [31:0] b, input hc);
        case (k)
            K_CMD8:   argument = 32'h0000_01AA;
            K_ACMD41: argument = 32'h4000_0000;           // HCS: host obsługuje SDHC
            K_CMD16:  argument = 32'd512;
            K_CMD17:  argument = hc ? b : {b[22:0], 9'd0};
            default:  argument = 32'd0;
        endcase
    endfunction

    task rozkaz(input [2:0] k);
        reg [39:0] ra;
        begin
            ra    = {2'b01, nr(k), argument(k, blok, sdhc)};
            ramka <= {ra, crc7(ra), 1'b1};
            krok  <= k;
            idx   <= 4'd0;
            p     <= P_WYSLIJ;
        end
    endtask

    /* verilator lint_on BLKSEQ */
    task bajt(input [7:0] b);
        begin
            b_tx    <= b;
            b_start <= 1'b1;
            czeka   <= 1'b1;
        end
    endtask

    task blad_ust(input [3:0] kod);
        begin
            blad      <= 1'b1;
            kod_bledu <= kod;
            cs_n      <= 1'b1;
            p         <= P_BLAD;
        end
    endtask

    always @(posedge clk) begin
        b_start    <= 1'b0;
        dane_wazne <= 1'b0;
        koniec     <= 1'b0;
        if (rst) begin
            p         <= P_ROZRUCH;
            cs_n      <= 1'b1;
            szybko    <= 1'b0;
            gotowy    <= 1'b0;
            sdhc      <= 1'b0;
            blad      <= 1'b0;
            kod_bledu <= 4'd0;
            crc_ok    <= 1'b0;
            czeka     <= 1'b0;
            licz      <= 11'd0;
            proby     <= 16'd0;
        end else if (czeka) begin
            if (b_done) czeka <= 1'b0;
        end else case (p)
            P_ROZRUCH:                                       // 10 bajtów 0xFF z CS = 1: 80 taktów SCLK
                if (licz == 11'd10) begin
                    licz <= 11'd0;
                    rozkaz(K_CMD0);
                end else begin
                    licz <= licz + 1'b1;
                    bajt(8'hFF);
                end
            P_WYSLIJ: begin
                cs_n <= 1'b0;
                if (idx == 4'd6) begin
                    idx  <= 4'd0;
                    licz <= 11'd0;
                    p    <= P_R1;
                    bajt(8'hFF);
                end else begin
                    idx <= idx + 1'b1;
                    bajt(ramka[47 - idx*8 -: 8]);
                end
            end
            P_R1:                                           // odpowiedź: pierwszy bajt z bitem 7 = 0
                if (!b_rx[7]) begin
                    r1   <= b_rx;
                    idx  <= 4'd0;
                    if (krok == K_CMD8 || krok == K_CMD58) begin
                        p <= P_EXT;
                        bajt(8'hFF);
                    end else if (krok == K_CMD17) begin
                        if (b_rx != 8'h00) blad_ust(4'd7);
                        else begin
                            licz <= 11'd0;
                            p    <= P_TOKEN;
                            bajt(8'hFF);
                        end
                    end else begin
                        p <= P_PRZERWA;
                        cs_n <= 1'b1;
                        bajt(8'hFF);
                    end
                end else if (licz == 11'd9)
                    blad_ust(4'd1);                       // brak odpowiedzi
                else begin
                    licz <= licz + 1'b1;
                    bajt(8'hFF);
                end
            P_EXT: begin                                   // 4 bajty R7 / R3
                ext <= {ext[23:0], b_rx};
                if (idx == 4'd3) begin
                    p    <= P_PRZERWA;
                    cs_n <= 1'b1;
                    bajt(8'hFF);
                end else begin
                    idx <= idx + 1'b1;
                    bajt(8'hFF);
                end
            end
            P_PRZERWA:                                     // CS = 1 i jeden bajt; decyzja o następnym kroku
                case (krok)
                    K_CMD0:   if (r1 == 8'h01) rozkaz(K_CMD8);
                              else if (proby == 16'd10) blad_ust(4'd2);
                              else begin proby <= proby + 1'b1; rozkaz(K_CMD0); end
                    K_CMD8:   if (r1 == 8'h01 && ext[11:0] == 12'h1AA) begin proby <= 16'd0; rozkaz(K_CMD55); end
                              else blad_ust(4'd3);          // karta v1 albo zła odpowiedź
                    K_CMD55:  if (r1 == 8'h01 || r1 == 8'h00) rozkaz(K_ACMD41);
                              else blad_ust(4'd4);
                    K_ACMD41: if (r1 == 8'h00) rozkaz(K_CMD58);
                              else if (r1 == 8'h01 && proby != PROBY[15:0]) begin
                                  proby <= proby + 1'b1;
                                  rozkaz(K_CMD55);
                              end else blad_ust(4'd5);
                    K_CMD58:  if (r1 == 8'h00 && ext[31]) begin
                                  sdhc <= ext[30];
                                  if (ext[30]) begin szybko <= 1'b1; gotowy <= 1'b1; p <= P_GOTOWY; end
                                  else rozkaz(K_CMD16);
                              end else blad_ust(4'd6);
                    K_CMD16:  if (r1 == 8'h00) begin szybko <= 1'b1; gotowy <= 1'b1; p <= P_GOTOWY; end
                              else blad_ust(4'd6);
                    default: begin                         // po odczycie bloku
                        gotowy <= 1'b1;
                        koniec <= 1'b1;
                        p      <= P_GOTOWY;
                    end
                endcase
            P_GOTOWY:
                if (odczyt) begin
                    gotowy <= 1'b0;
                    crc_ok <= 1'b0;
                    rozkaz(K_CMD17);
                end
            P_TOKEN:                                       // 0xFE — początek danych
                if (b_rx == 8'hFE) begin
                    licz    <= 11'd0;
                    crc_obl <= 16'd0;
                    p       <= P_DANE;
                    bajt(8'hFF);
                end else if (b_rx != 8'hFF || licz == PROBY[10:0])
                    blad_ust(4'd8);
                else begin
                    licz <= licz + 1'b1;
                    bajt(8'hFF);
                end
            P_DANE: begin
                dane       <= b_rx;
                dane_wazne <= 1'b1;
                crc_obl    <= crc16(crc_obl, b_rx);
                licz       <= licz + 1'b1;
                if (licz == 11'd511) begin
                    idx <= 4'd0;
                    p   <= P_CRC;
                end
                bajt(8'hFF);
            end
            P_CRC:
                if (idx == 4'd0) begin
                    crc_odeb[15:8] <= b_rx;
                    idx <= 4'd1;
                    bajt(8'hFF);
                end else begin
                    crc_ok <= ({crc_odeb[15:8], b_rx} == crc_obl);
                    cs_n   <= 1'b1;
                    p      <= P_PRZERWA;
                    bajt(8'hFF);
                end
            default: ;                                     // P_BLAD: czeka na reset
        endcase
    end
endmodule

`default_nettype wire

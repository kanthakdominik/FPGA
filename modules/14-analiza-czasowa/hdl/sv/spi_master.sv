// Nadajnik-odbiornik SPI w trybie 0 (CPOL = 0, CPHA = 0), 8 bitów, najstarszy bit pierwszy (14.06).
// Zegar SPI sclk powstaje w rejestrze sclk_r z zegara clk: pół okresu = DIV taktów, f_sclk = f_clk / (2·DIV).
// MOSI zmienia się przy opadającym zboczu sclk, MISO jest próbkowane przy narastającym — oba sygnały
// są wyrównane do zegara przesyłanego razem z danymi (interfejs źródłowo-synchroniczny dla wyjść).
// Ograniczenia: zegar generowany na sclk_r i na porcie, opóźnienia wyjść i wejścia względem niego
// oraz ścieżki wielotaktowe (DIV taktów clk między zmianą danych a zboczem próbkującym) — 14.06.
module spi_master #(
    parameter int DIV = 2                  // pół okresu sclk w taktach clk, >= 2
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,              // ignorowane, gdy busy
    input  logic [7:0] tx,
    output logic       busy,
    output logic       done,               // 1 takt po zakończeniu bajtu
    output logic [7:0] rx,
    output logic       sclk,
    output logic       mosi,
    output logic       cs_n,
    input  logic       miso
);
    localparam int CW = $clog2(DIV);
    localparam logic [CW-1:0] LAST = CW'(DIV - 1);

    logic          sclk_r;
    logic [CW-1:0] cnt;
    logic [2:0]    nbit;
    logic [6:0]    sh_tx;                  // bity jeszcze do wysłania (najstarszy idzie od razu na MOSI)
    logic [7:0]    sh_rx;

    always_ff @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy   <= 1'b0;
            sclk_r <= 1'b0;
            cs_n   <= 1'b1;
            mosi   <= 1'b0;
        end else if (!busy) begin
            if (start) begin
                busy  <= 1'b1;
                cs_n  <= 1'b0;
                sh_tx <= tx[6:0];
                mosi  <= tx[7];            // pierwszy bit przed pierwszym narastającym zboczem
                cnt   <= '0;
                nbit  <= '0;
            end
        end else if (cnt != LAST) begin
            cnt <= cnt + 1'b1;
        end else begin
            cnt <= '0;
            if (!sclk_r) begin             // zbocze narastające: próbkowanie MISO
                sclk_r <= 1'b1;
                sh_rx  <= {sh_rx[6:0], miso};
            end else begin                 // zbocze opadające: następny bit MOSI albo koniec
                sclk_r <= 1'b0;
                if (nbit == 3'd7) begin
                    busy <= 1'b0;
                    cs_n <= 1'b1;
                    done <= 1'b1;
                    rx   <= sh_rx;
                end else begin
                    nbit  <= nbit + 1'b1;
                    sh_tx <= {sh_tx[5:0], 1'b0};
                    mosi  <= sh_tx[6];
                end
            end
        end
    end

    assign sclk = sclk_r;
endmodule

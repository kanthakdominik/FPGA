// Nadajnik-odbiornik SPI w trybie 0 (CPOL = 0, CPHA = 0), 8 bitów, najstarszy bit pierwszy (14.06).
// Zegar SPI sclk powstaje w rejestrze sclk_r z zegara clk: pół okresu = DIV taktów, f_sclk = f_clk / (2·DIV).
// MOSI zmienia się przy opadającym zboczu sclk, MISO jest próbkowane przy narastającym — oba sygnały
// są wyrównane do zegara przesyłanego razem z danymi (interfejs źródłowo-synchroniczny dla wyjść).
// Ograniczenia: zegar generowany na sclk_r i na porcie, opóźnienia wyjść i wejścia względem niego
// oraz ścieżki wielotaktowe (DIV taktów clk między zmianą danych a zboczem próbkującym) — 14.06.
`default_nettype none

module spi_master #(
    parameter DIV = 2                      // pół okresu sclk w taktach clk, >= 2
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,               // ignorowane, gdy busy
    input  wire [7:0] tx,
    output reg        busy,
    output reg        done,                // 1 takt po zakończeniu bajtu
    output reg  [7:0] rx,
    output wire       sclk,
    output reg        mosi,
    output reg        cs_n,
    input  wire       miso
);
    localparam CW = $clog2(DIV);
    /* verilator lint_off WIDTHTRUNC */        // stała mieści się w CW bitach z definicji CW
    localparam [CW-1:0] LAST = DIV - 1;
    /* verilator lint_on WIDTHTRUNC */
    localparam [CW-1:0] ONE  = 1;

    reg          sclk_r;
    reg [CW-1:0] cnt;
    reg [2:0]    nbit;
    reg [6:0]    sh_tx;                    // bity jeszcze do wysłania (najstarszy idzie od razu na MOSI)
    reg [7:0]    sh_rx;

    always @(posedge clk) begin
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
                cnt   <= {CW{1'b0}};
                nbit  <= 3'd0;
            end
        end else if (cnt != LAST) begin
            cnt <= cnt + ONE;
        end else begin
            cnt <= {CW{1'b0}};
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
                    nbit  <= nbit + 3'd1;
                    sh_tx <= {sh_tx[5:0], 1'b0};
                    mosi  <= sh_tx[6];
                end
            end
        end
    end

    assign sclk = sclk_r;
endmodule

`default_nettype wire

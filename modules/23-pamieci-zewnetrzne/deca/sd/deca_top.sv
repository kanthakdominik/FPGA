// Moduł nadrzędny DECA — Verilog. Karta microSD w trybie SPI (23.05), tylko odczyt: po resecie inicjalizacja
// i odczyt bloku 0 (MBR albo sektor rozruchowy), sprawdzenie sygnatury 0x55 0xAA na końcu bloku; KEY[1] — odczyt
// ponownie. Gniazdo DECA ma translator poziomów: kierunki ustawiane pinami SD_CMD_DIR, SD_D0_DIR, SD_D123_DIR
// (1 — od FPGA do karty), SD_SEL wybiera napięcie po stronie karty (wartość jak w przykładach Terasic, README).
// Linie w trybie SPI: SD_CLK — SCLK, SD_CMD — MOSI, SD_DAT[3] — CS, SD_DAT[0] — MISO.
// Diody (świecą jedynki): LED[7] sygnatura 0x55AA, LED[6] CRC16 bloku zgodne, LED[5] inicjalizacja zakończona,
// LED[4] karta SDHC/SDXC, LED[3:0] kod błędu (0 — brak). KEY[0] — reset.
`default_nettype none

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,
    input  logic [1:0] SW,
    output logic [7:0] LED,                     // 0 = świeci
    output logic       SD_CLK,
    inout  wire        SD_CMD,
    inout  wire  [3:0] SD_DAT,
    output logic       SD_CMD_DIR,
    output logic       SD_D0_DIR,
    output logic       SD_D123_DIR,
    output logic       SD_SEL
);
    logic clk;
    assign clk = MAX10_CLK1_50;
    logic [1:0] rs = 2'b00;
    always_ff @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    logic rst;
    assign rst = !rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_k = 2'b11;
    logic       k_pop = 1'b1;
    always_ff @(posedge clk) begin
        s_k   <= {s_k[0], KEY[1]};
        k_pop <= s_k[1];
    end
    logic nacisk;
    assign nacisk = k_pop && !s_k[1];

    logic        odczyt = 1'b0;
    logic       gotowy, sdhc, blad, dane_wazne, koniec, crc_ok, sclk, mosi, cs_n;
    logic [3:0] kod_bledu;
    logic [7:0] dane;
    sd_spi #(.DIV_WOLNY(63), .DIV_SZYBKI(4)) u_sd (.clk(clk), .rst(rst), .odczyt(odczyt), .blok(32'd0),
        .gotowy(gotowy), .sdhc(sdhc), .blad(blad), .kod_bledu(kod_bledu), .dane(dane), .dane_wazne(dane_wazne),
        .koniec(koniec), .crc_ok(crc_ok), .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(SD_DAT[0]));

    assign SD_CLK      = sclk;
    assign SD_CMD      = mosi;
    assign SD_DAT[3]   = cs_n;
    assign SD_DAT[2:1] = 2'b11;
    assign SD_DAT[0]   = 1'bz;
    assign SD_CMD_DIR  = 1'b1;                 // FPGA -> karta
    assign SD_D123_DIR = 1'b1;
    assign SD_D0_DIR   = 1'b0;                 // karta -> FPGA
    assign SD_SEL      = 1'b0;

    // odczyt bloku 0 po inicjalizacji i po KEY[1]; sygnatura w bajtach 510 i 511
    logic [9:0] n = 10'd0;
    logic [7:0] b510 = 8'h00, b511 = 8'h00;
    logic       chce = 1'b1, gotowe_ok = 1'b0;
    always_ff @(posedge clk) begin
        odczyt <= 1'b0;
        if (rst) begin
            chce <= 1'b1;
        end else begin
            if (nacisk) chce <= 1'b1;
            if (chce && gotowy) begin
                chce   <= 1'b0;
                odczyt <= 1'b1;
                n      <= 10'd0;
            end
            if (dane_wazne) begin
                n <= n + 1'b1;
                if (n == 10'd510) b510 <= dane;
                if (n == 10'd511) b511 <= dane;
            end
            if (gotowy) gotowe_ok <= 1'b1;
        end
    end

    assign LED = ~{(b510 == 8'h55 && b511 == 8'hAA), crc_ok, gotowe_ok, sdhc, kod_bledu};
    /* verilator lint_off UNUSEDSIGNAL */
    logic _nieuzywane;
    assign _nieuzywane = &{SW, koniec, blad};
    /* verilator lint_on UNUSEDSIGNAL */
endmodule

`default_nettype wire

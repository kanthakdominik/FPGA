// Rdzeń mapy rejestrów niezależny od magistrali (21.02): adaptery AXI4-Lite, Avalon-MM i Wishbone
// zamieniają swoje transakcje na zapis (zap, adres słowa, dane, maska bajtów) i odczyt (adres -> dane).
//   0x00 ID      RO  stała ID
//   0x04 STER    RW  32 bity (wyjście ster), zapis z maską bajtów
//   0x08 STAN    RO  wejście stan
//   0x0C PRZER   W1C 8 bitów: ustawiane impulsami zdarz, kasowane zapisem jedynek
//   0x10 MASKA   RW  8 bitów; irq = |(PRZER & MASKA)
//   0x14 SKRYTKA RW  32 bity (rejestr próbny)
//   pozostałe adresy: błąd (odpowiedź SLVERR / err)
`default_nettype none

module rejestry_rdzen #(
    parameter [31:0] ID = 32'h2102_0001
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        zap,
    input  logic [3:0]  zap_adr,
    input  logic [31:0] zap_dane,
    input  logic [3:0]  zap_str,
    output logic        zap_blad,
    input  logic [3:0]  odc_adr,
    output logic  [31:0] odc_dane,
    output logic        odc_blad,
    output logic  [31:0] ster,
    input  logic [31:0] stan,
    input  logic [7:0]  zdarz,
    output logic        irq
);
    logic [7:0]  przer, maska;
    logic [31:0] skrytka;
    logic [31:0] m;
    assign m = {{8{zap_str[3]}}, {8{zap_str[2]}}, {8{zap_str[1]}}, {8{zap_str[0]}}};

    assign zap_blad = zap_adr > 4'd5;
    assign odc_blad = odc_adr > 4'd5;
    assign irq      = |(przer & maska);

    always_comb begin
        case (odc_adr)
            4'd0:    odc_dane = ID;
            4'd1:    odc_dane = ster;
            4'd2:    odc_dane = stan;
            4'd3:    odc_dane = {24'd0, przer};
            4'd4:    odc_dane = {24'd0, maska};
            4'd5:    odc_dane = skrytka;
            default: odc_dane = 32'd0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            ster    <= 32'd0;
            przer   <= 8'd0;
            maska   <= 8'd0;
            skrytka <= 32'd0;
        end else begin
            // zdarzenie w tym samym takcie co kasowanie wygrywa (nie gubi się)
            przer <= (przer & ~((zap && zap_adr == 4'd3 && zap_str[0]) ? zap_dane[7:0] : 8'd0)) | zdarz;
            if (zap) begin
                case (zap_adr)
                    4'd1: ster    <= (ster & ~m) | (zap_dane & m);
                    4'd4: if (zap_str[0]) maska <= zap_dane[7:0];
                    4'd5: skrytka <= (skrytka & ~m) | (zap_dane & m);
                    default: ;
                endcase
            end
        end
    end
endmodule

`default_nettype wire

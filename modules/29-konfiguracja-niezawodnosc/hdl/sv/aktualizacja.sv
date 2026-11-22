// Sterownik przełączenia obrazu w MAX 10 (29.02): master Avalon-MM dla rdzenia Dual Configuration Intel FPGA IP.
//   start (impuls) + obraz (0/1) + obraz_ok (np. CRC nowego obrazu zgodne):
//     1. zapis pod offset 1: bit 0 = 1 (config_sel_overwrite — pomiń pin CONFIG_SEL), bit 1 = obraz,
//     2. odczekanie CZAS taktów — rdzeń jest zajęty (busy) najwyżej 531 taktów po zapisie, a zapisy w tym czasie
//        ignoruje (zamiast odpytywania busy pod offsetem 3, które zależy od opóźnienia odczytu interfejsu),
//     3. zapis pod offset 0: bit 0 = 1 — rekonfiguracja z wybranego obrazu.
//   obraz_ok = 0 -> odmowa, nic nie jest zapisywane. pies (impuls) — zapis offset 0, bit 1: wyzerowanie
//   licznika nadzorującego (user watchdog), jeśli jest włączony w rdzeniu.
`default_nettype none

module aktualizacja #(
    parameter integer CZAS = 600
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic        obraz,
    input  logic        obraz_ok,
    input  logic        pies,
    output logic  [2:0]  av_address,
    output logic         av_write,
    output logic  [31:0] av_writedata,
    output logic        av_read,
    output logic        zajety,
    output logic         odmowa,
    output logic         wyzwolono
);
    localparam [1:0] S_BEZCZ = 2'd0, S_CZEKAJ = 2'd1, S_KONIEC = 2'd2;
    logic [1:0] stan;
    localparam integer LW = $clog2(CZAS + 1);
    logic [LW-1:0] licz;
    /* verilator lint_off WIDTHTRUNC */
    localparam [LW-1:0] CZAS_W = CZAS;
    /* verilator lint_on WIDTHTRUNC */

    assign av_read = 1'b0;
    assign zajety  = stan != S_BEZCZ;

    always_ff @(posedge clk) begin
        av_write  <= 1'b0;
        odmowa    <= 1'b0;
        wyzwolono <= 1'b0;
        if (rst) begin
            stan <= S_BEZCZ; licz <= {LW{1'b0}}; av_address <= 3'd0; av_writedata <= 32'd0;
        end else case (stan)
            S_BEZCZ:
                if (start && !obraz_ok) begin
                    odmowa <= 1'b1;
                end else if (start) begin
                    av_address   <= 3'd1;
                    av_writedata <= {30'd0, obraz, 1'b1};
                    av_write     <= 1'b1;
                    licz         <= CZAS_W;
                    stan         <= S_CZEKAJ;
                end else if (pies) begin
                    av_address   <= 3'd0;
                    av_writedata <= 32'd2;
                    av_write     <= 1'b1;
                end
            S_CZEKAJ:
                if (licz == {LW{1'b0}}) begin
                    av_address   <= 3'd0;
                    av_writedata <= 32'd1;
                    av_write     <= 1'b1;
                    wyzwolono    <= 1'b1;
                    stan         <= S_KONIEC;
                end else
                    licz <= licz - 1'b1;
            default: ;                                     // układ się rekonfiguruje
        endcase
    end
endmodule

`default_nettype wire

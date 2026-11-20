// Nadajnik UART (20.01): ramka start (0), 8 bitów danych od najmłodszego, opcjonalna parzystość,
// STOP bitów stopu (1). Takt bitowy z akumulatora fazy: średni okres dokładnie CLK_HZ/BAUD taktów
// (bez błędu zaokrąglenia dzielnika), akumulator zerowany na początku ramki.
//   PARZ: 0 — brak, 1 — nieparzysta (odd), 2 — parzysta (even).
// Interfejs: start przy gotowy = 1 pobiera bajt; gotowy = 0 do końca ostatniego bitu stopu.
`default_nettype none

module uart_tx #(
    parameter CLK_HZ = 50_000_000,
    parameter BAUD   = 115_200,
    parameter PARZ   = 0,
    parameter STOP   = 1
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] dane,
    output logic       gotowy,
    output logic        tx = 1'b1
);
    localparam NB = 1 + 8 + ((PARZ != 0) ? 1 : 0) + STOP;    // bity ramki
    localparam CW = $clog2(NB + 1);
    localparam [CW-1:0] OSTATNI = NB - 1;
    localparam [32:0]   KROK    = BAUD;
    localparam [32:0]   OKRES   = CLK_HZ;

    // ramka: bit 0 — start, potem dane, parzystość, bity stopu (same jedynki)
    /* verilator lint_off UNUSEDSIGNAL */
    logic          parz;
    assign parz = (^dane) ^ (PARZ == 1);       // nieparzysta: dopełnienie do nieparzystej liczby jedynek
    /* verilator lint_on UNUSEDSIGNAL */
    logic [NB-1:0] ramka;
    generate
        if (PARZ != 0) begin : g_parz
            assign ramka = {{STOP{1'b1}}, parz, dane, 1'b0};
        end else begin : g_bez
            assign ramka = {{STOP{1'b1}}, dane, 1'b0};
        end
    endgenerate

    /* verilator lint_off UNUSEDSIGNAL */
    logic  [NB-1:0] sr;                                    // bit 0 (start) wysyłany wprost
    /* verilator lint_on UNUSEDSIGNAL */
    logic  [CW-1:0] licz;
    logic           zajety = 1'b0;
    logic  [31:0]   acc;
    logic [32:0]   suma;
    assign suma = {1'b0, acc} + KROK;
    logic          tick;
    assign tick = (suma >= OKRES);

    assign gotowy = !zajety;

    always_ff @(posedge clk) begin
        if (rst) begin
            zajety <= 1'b0;
            tx     <= 1'b1;
        end else if (!zajety) begin
            if (start) begin
                sr     <= ramka;
                tx     <= 1'b0;                              // bit startu
                licz   <= {CW{1'b0}};
                acc    <= 32'd0;
                zajety <= 1'b1;
            end
        end else begin
            acc <= tick ? suma[31:0] - OKRES[31:0] : suma[31:0];
            if (tick) begin
                if (licz == OSTATNI) begin                    // koniec ostatniego bitu stopu
                    zajety <= 1'b0;
                    tx     <= 1'b1;
                end else begin
                    sr   <= {1'b1, sr[NB-1:1]};
                    tx   <= sr[1];
                    licz <= licz + 1'b1;
                end
            end
        end
    end
endmodule

`default_nettype wire

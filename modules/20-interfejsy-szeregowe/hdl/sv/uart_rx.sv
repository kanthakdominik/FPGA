// Odbiornik UART z nadpróbkowaniem (20.01): wejście przez synchronizator, próbkowanie OVS razy na bit
// (takt z akumulatora fazy), wykrycie zbocza startu, decyzja większościowa z trzech próbek w środku
// każdego bitu. Fałszywy start (zakłócenie krótsze niż pół bitu) jest odrzucany. Po środku bitu stopu
// odbiornik od razu czeka na kolejny start — to daje zapas na różnicę częstotliwości nadajnika.
//   PARZ: 0 — brak, 1 — nieparzysta, 2 — parzysta. Wyjście: wazne przez jeden takt z bajtem i flagami.
`default_nettype none

module uart_rx #(
    parameter CLK_HZ = 50_000_000,
    parameter BAUD   = 115_200,
    parameter PARZ   = 0,
    parameter OVS    = 16
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    output logic  [7:0] dane,
    output logic        wazne = 1'b0,
    output logic        blad_ramki = 1'b0,
    output logic        blad_parz = 1'b0
);
    localparam NDANE = 8 + ((PARZ != 0) ? 1 : 0);        // bity po starcie: dane i parzystość
    localparam FW    = $clog2(OVS);
    /* verilator lint_off WIDTHTRUNC */
    localparam [FW-1:0] SRODEK  = OVS / 2;
    localparam [FW-1:0] KONIEC  = OVS - 1;
    /* verilator lint_on WIDTHTRUNC */
    localparam [3:0]    OST_BIT = NDANE - 1;
    localparam [32:0]   KROK    = OVS * BAUD;
    localparam [32:0]   OKRES   = CLK_HZ;

    // synchronizator (stan spoczynku linii: 1)
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] syn = 2'b11;
    always_ff @(posedge clk) syn <= {syn[0], rx};
    logic rx_s;
    assign rx_s = syn[1];

    // takt nadpróbkowania: OVS·BAUD na sekundę
    logic  [31:0] acc = 32'd0;
    logic [32:0] suma;
    assign suma = {1'b0, acc} + KROK;
    logic        tick;
    assign tick = (suma >= OKRES);
    always_ff @(posedge clk) acc <= tick ? suma[31:0] - OKRES[31:0] : suma[31:0];

    localparam S_CZEKA = 2'd0, S_START = 2'd1, S_BITY = 2'd2, S_STOP = 2'd3;
    logic [1:0]       stan = S_CZEKA;
    logic [FW-1:0]    faza = {FW{1'b0}};
    logic [3:0]       nbit = 4'd0;
    logic [2:0]       probki = 3'b111;
    logic [NDANE-1:0] sr;
    logic            wiekszosc;
    assign wiekszosc = (probki[0] & probki[1]) | (probki[0] & probki[2]) | (probki[1] & probki[2]);

    always_ff @(posedge clk) begin
        wazne <= 1'b0;
        if (rst) begin
            stan <= S_CZEKA;
        end else if (tick) begin
            faza <= (faza == KONIEC) ? {FW{1'b0}} : faza + 1'b1;
            // trzy próbki wokół środka bitu
            if (faza == SRODEK - 1 || faza == SRODEK || faza == SRODEK + 1)
                probki <= {probki[1:0], rx_s};
            case (stan)
                S_CZEKA:
                    if (!rx_s) begin                         // pierwsza niska próbka: początek bitu startu
                        stan <= S_START;
                        faza <= 1;
                    end
                S_START:
                    if (faza == SRODEK + 2) begin            // trzy próbki zebrane (ostatnia w poprzednim tick)
                        if (wiekszosc) stan <= S_CZEKA;      // zakłócenie — to nie był start
                    end else if (faza == KONIEC) begin
                        stan <= S_BITY;
                        nbit <= 4'd0;
                    end
                S_BITY:
                    if (faza == SRODEK + 2) begin
                        sr   <= {wiekszosc, sr[NDANE-1:1]};  // od najmłodszego bitu
                    end else if (faza == KONIEC) begin
                        if (nbit == OST_BIT) stan <= S_STOP;
                        nbit <= nbit + 1'b1;
                    end
                default:                                      // S_STOP: decyzja w środku bitu stopu
                    if (faza == SRODEK + 2) begin
                        dane       <= sr[7:0];
                        wazne      <= 1'b1;
                        blad_ramki <= !wiekszosc;
                        blad_parz  <= (PARZ != 0) && ((^sr) ^ (PARZ == 1));
                        stan       <= S_CZEKA;               // gotów na następny start już teraz
                    end
            endcase
        end
    end
endmodule

`default_nettype wire

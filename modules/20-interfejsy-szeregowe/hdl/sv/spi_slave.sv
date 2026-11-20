// SPI slave z nadpróbkowaniem (20.02): SCLK, MOSI i CS_N przechodzą przez synchronizatory do domeny clk,
// zbocza SCLK wykrywane w logice — cały układ w jednej domenie zegarowej. Wymaga f_clk >= ok. 10·f_SCLK
// (opóźnienie synchronizatora i rejestru wyjścia MISO musi zmieścić się w pół okresu SCLK).
// Tryb CPOL/CPHA jak w spi_master. Nadawanie działa jak kolejka: tx_dane jest pobierane (impuls tx_pobrany —
// można wystawić kolejne słowo) przy opadnięciu CS, jeśli nic nie czeka, i zaraz po każdym słowie — slave nie
// wie, czy master będzie czytał dalej, więc słowo pobrane na zapas czeka do następnej transakcji.
// rx_wazne — impuls z odebranym słowem.
`default_nettype none

module spi_slave #(
    parameter N = 8
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         cpol,
    input  logic         cpha,
    input  logic         sclk,
    input  logic         mosi,
    output logic         miso,
    output logic         miso_oe,                      // 1 — slave steruje MISO (CS aktywne)
    input  logic         cs_n,
    input  logic [N-1:0] tx_dane,
    output logic          tx_pobrany = 1'b0,
    output logic  [N-1:0] rx_dane,
    output logic          rx_wazne = 1'b0
);
    localparam CW = $clog2(N + 1);
    localparam [CW-1:0] NN = N;

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_sclk = 2'b00, s_mosi = 2'b00, s_cs = 2'b11;
    logic       sclk_d = 1'b0, cs_d = 1'b1;
    always_ff @(posedge clk) begin
        s_sclk <= {s_sclk[0], sclk};
        s_mosi <= {s_mosi[0], mosi};
        s_cs   <= {s_cs[0], cs_n};
        sclk_d <= s_sclk[1];
        cs_d   <= s_cs[1];
    end
    logic aktywny;
    assign aktywny = !s_cs[1];
    logic cs_spad;
    assign cs_spad = cs_d && !s_cs[1];
    logic zbocze;
    assign zbocze = (s_sclk[1] != sclk_d) && aktywny;
    logic wiodace;
    assign wiodace = zbocze && (sclk_d == cpol);           // odejście od poziomu spoczynku
    logic koncowe;
    assign koncowe = zbocze && (sclk_d != cpol);

    logic [N-1:0]  sr_tx;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [N-1:0]  sr_rx;                                // najstarszy bit wychodzi wprost do rx_dane
    /* verilator lint_on UNUSEDSIGNAL */
    logic [CW-1:0] licz;                                   // próbki w bieżącym słowie
    logic          pierwsze;                               // przed pierwszym zboczem wystawiającym w słowie

    assign miso    = sr_tx[N-1];
    assign miso_oe = aktywny;

    logic probkuj;
    assign probkuj = cpha ? koncowe : wiodace;
    logic wystaw;
    assign wystaw = cpha ? wiodace : koncowe;

    logic czeka = 1'b0;                                     // w sr_tx jest słowo jeszcze nienadawane

    always_ff @(posedge clk) begin
        rx_wazne   <= 1'b0;
        tx_pobrany <= 1'b0;
        if (rst) begin
            czeka <= 1'b0;
            licz  <= {CW{1'b0}};
        end else if (!aktywny) begin
            licz <= {CW{1'b0}};
        end else if (cs_spad) begin
            if (!czeka) begin
                sr_tx      <= tx_dane;
                tx_pobrany <= 1'b1;
                czeka      <= 1'b1;
            end
            licz     <= {CW{1'b0}};
            pierwsze <= 1'b1;
        end else begin
            if (probkuj) begin
                sr_rx <= {sr_rx[N-2:0], s_mosi[1]};
                if (licz == 0) czeka <= 1'b0;             // słowo w drodze
                if (licz == NN - 1) begin
                    rx_dane  <= {sr_rx[N-2:0], s_mosi[1]};
                    rx_wazne <= 1'b1;
                    licz     <= {CW{1'b0}};
                    if (cpha) begin                       // CPHA = 1: następne słowo od razu (wystawi je zbocze wiodące)
                        sr_tx      <= tx_dane;
                        tx_pobrany <= 1'b1;
                        czeka      <= 1'b1;
                        pierwsze   <= 1'b1;
                    end
                end else
                    licz <= licz + 1'b1;
            end
            if (wystaw) begin
                if (!cpha && licz == 0 && !pierwsze) begin   // CPHA = 0: końcowe zbocze po ostatnim bicie — nowe słowo
                    sr_tx      <= tx_dane;
                    tx_pobrany <= 1'b1;
                    czeka      <= 1'b1;
                end else if (cpha && pierwsze)
                    pierwsze <= 1'b0;                     // pierwszy bit słowa już wystawiony
                else
                    sr_tx <= {sr_tx[N-2:0], 1'b0};
                if (!cpha) pierwsze <= 1'b0;
            end
        end
    end
endmodule

`default_nettype wire

// Czytnik linii obrazu (24.04): master Avalon-MM z odczytami burstowymi. Po impulsie start czyta SLOW słów
// 32-bitowych od adresu adr (burstami po maks. BURST słów, kolejne rozkazy bez czekania na dane) i zapisuje je
// do bufora linii pod adresy bufor·SLOW + i. zajety = 1 do odebrania ostatniego słowa; gotowe — impuls na końcu.
`default_nettype none

module czytnik_linii #(
    parameter integer SLOW  = 40,               // słów na linię
    parameter integer BURST = 8,                // maks. długość burstu (≤ 16)
    parameter integer AW    = 16,               // szerokość adresu słowa (≥ 11)
    parameter integer LW    = 7                 // szerokość adresu bufora linii (2·SLOW słów)
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          start,
    input  logic [AW-1:0] adr,
    input  logic          bufor,
    output logic           zajety,
    output logic           gotowe,
    // Avalon-MM
    output logic  [AW-1:0] m_adr,
    output logic           m_read,
    output logic  [4:0]    m_burstcount,
    input  logic          m_wait,
    input  logic          m_rvalid,
    input  logic [31:0]   m_rdata,
    // zapis do bufora linii
    output logic           lw_we,
    output logic  [LW-1:0] lw_adr,
    output logic  [31:0]   lw_dane
);
    /* verilator lint_off WIDTHTRUNC */
    localparam [10:0]   SL  = SLOW;
    localparam [10:0]   BU  = BURST;
    localparam [LW-1:0] SLL = SLOW;
    /* verilator lint_on WIDTHTRUNC */

    logic  [10:0]   wyd, odb;                     // słowa zamówione, odebrane
    logic  [AW-1:0] nast_adr;
    logic  [LW-1:0] baza_b;
    logic [10:0]   reszta;
    assign reszta = SL - wyd;
    logic [10:0]   dl;
    assign dl = (reszta > BU) ? BU : reszta;

    always_ff @(posedge clk) begin
        if (rst) begin
            zajety <= 1'b0;
            gotowe <= 1'b0;
            m_read <= 1'b0;
            m_adr  <= {AW{1'b0}};
            m_burstcount <= 5'd0;
            lw_we  <= 1'b0;
            lw_adr <= {LW{1'b0}};
            lw_dane <= 32'd0;
            wyd <= 11'd0; odb <= 11'd0; nast_adr <= {AW{1'b0}}; baza_b <= {LW{1'b0}};
        end else begin
            gotowe <= 1'b0;
            lw_we  <= 1'b0;
            if (!zajety) begin
                if (start) begin
                    zajety   <= 1'b1;
                    wyd      <= 11'd0;
                    odb      <= 11'd0;
                    nast_adr <= adr;
                    baza_b   <= bufor ? SLL : {LW{1'b0}};
                end
            end else begin
                // rozkazy: następny burst, gdy poprzedni przyjęty (albo brak rozkazu)
                if (!m_read || !m_wait) begin            // brak rozkazu albo właśnie przyjęty
                    m_read <= 1'b0;
                    if (wyd != SL) begin
                        m_read       <= 1'b1;
                        m_adr        <= nast_adr;
                        m_burstcount <= dl[4:0];
                        nast_adr     <= nast_adr + {{(AW-11){1'b0}}, dl};
                        wyd          <= wyd + dl;
                    end
                end
                // dane
                if (m_rvalid) begin
                    lw_we   <= 1'b1;
                    lw_adr  <= baza_b + odb[LW-1:0];
                    lw_dane <= m_rdata;
                    odb     <= odb + 1'b1;
                    if (odb == SL - 1'b1) begin
                        zajety <= 1'b0;
                        gotowe <= 1'b1;
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire

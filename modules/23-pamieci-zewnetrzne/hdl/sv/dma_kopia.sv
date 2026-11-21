// Silnik DMA kopiujący n słów spod adresu zrodlo pod cel (23.04), master Avalon-MM z odczytami potokowymi:
// do GL odczytów w toku i słów w kolejce wewnętrznej łącznie (nie zamawia więcej, niż zmieści). Rozkaz jest
// trzymany do przyjęcia (waitrequest), decyzja o następnym — w takcie przyjęcia (transfery jeden za drugim).
// Zapis ma pierwszeństwo, gdy kolejka jest pełna albo odczyty się skończyły; inaczej odczyt.
`default_nettype none

module dma_kopia #(
    parameter integer AW = 12,
    parameter integer GL = 8
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          start,
    input  logic [AW-1:0] zrodlo,
    input  logic [AW-1:0] cel,
    input  logic [AW-1:0] n,
    output logic           zajety,
    output logic           gotowe,
    // master
    output logic  [AW-1:0] m_adr,
    output logic           m_read,
    output logic           m_write,
    output logic  [31:0]   m_wdata,
    input  logic          m_wait,
    input  logic          m_rvalid,
    input  logic [31:0]   m_rdata
);
    localparam integer KW = $clog2(GL);
    /* verilator lint_off WIDTHTRUNC */
    localparam [KW:0] GLW = GL;
    /* verilator lint_on WIDTHTRUNC */

    logic  [31:0]   kol [0:GL-1];
    logic  [KW-1:0] wz, wo;
    logic  [KW:0]   wlocie, ile;                     // odczyty w toku, słowa w kolejce
    logic  [AW-1:0] r_zr, r_cel, r_n, ri, wi;

    logic  [KW:0]   wl, il, il_dost;
    logic  [AW-1:0] nri, nwi;
    logic  [KW-1:0] nwo;
    logic           przyj;

    // wartości następne liczone blokująco w tym samym bloku (zmienne pomocnicze) — celowo
    /* verilator lint_off BLKSEQ */
    always_ff @(posedge clk) begin
        gotowe <= 1'b0;
        if (rst) begin
            zajety  <= 1'b0;
            m_read  <= 1'b0;
            m_write <= 1'b0;
            wz      <= {KW{1'b0}};
            wo      <= {KW{1'b0}};
            wlocie  <= {(KW+1){1'b0}};
            ile     <= {(KW+1){1'b0}};
        end else if (!zajety) begin
            if (start) begin
                zajety <= 1'b1;
                r_zr   <= zrodlo;
                r_cel  <= cel;
                r_n    <= n;
                ri     <= {AW{1'b0}};
                wi     <= {AW{1'b0}};
            end
        end else begin
            wl = wlocie; il = ile; nri = ri; nwi = wi; nwo = wo;
            il_dost = ile;                              // słowa już zapisane w kolejce (bez dzisiejszego)
            if (m_rvalid) begin
                kol[wz] <= m_rdata;
                wz      <= wz + 1'b1;
                wl      = wl - 1'b1;
                il      = il + 1'b1;
            end
            przyj = (m_read || m_write) && !m_wait;
            if (przyj && m_read) begin
                nri = nri + 1'b1;
                wl  = wl + 1'b1;
            end
            if (przyj && m_write) begin
                nwi     = nwi + 1'b1;
                il      = il - 1'b1;
                il_dost = il_dost - 1'b1;
                nwo     = nwo + 1'b1;
            end
            if (!(m_read || m_write) || przyj) begin    // można wystawić nowy rozkaz
                m_read  <= 1'b0;
                m_write <= 1'b0;
                if (il_dost != 0 && (nri == r_n || wl + il >= GLW)) begin
                    m_write <= 1'b1;
                    m_adr   <= r_cel + nwi;
                    m_wdata <= kol[nwo];
                end else if (nri != r_n && wl + il < GLW) begin
                    m_read <= 1'b1;
                    m_adr  <= r_zr + nri;
                end else if (il_dost != 0) begin
                    m_write <= 1'b1;
                    m_adr   <= r_cel + nwi;
                    m_wdata <= kol[nwo];
                end
            end
            wlocie <= wl;
            ile    <= il;
            ri     <= nri;
            wi     <= nwi;
            wo     <= nwo;
            if (nwi == r_n) begin
                zajety  <= 1'b0;
                gotowe  <= 1'b1;
                m_read  <= 1'b0;
                m_write <= 1'b0;
            end
        end
    end
    /* verilator lint_on BLKSEQ */
endmodule

`default_nettype wire

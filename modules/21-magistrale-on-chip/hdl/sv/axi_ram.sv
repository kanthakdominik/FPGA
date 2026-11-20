// Pamięć RAM ze slave'em AXI4 (21.03): bursty FIXED, INCR i WRAP, maska bajtów WSTRB, identyfikatory
// odsyłane w BID/RID. Kanał zapisu i odczytu działają niezależnie, w każdym jedna transakcja naraz.
// Adresy bajtowe (AW bitów), dane 32 bity; odczyt synchroniczny z pamięci (blok RAM), jedno słowo na takt.
`default_nettype none

module axi_ram #(
    parameter integer AW  = 12,                    // 4 KiB
    parameter integer IDW = 4
) (
    input  logic           clk,
    input  logic           rst,
    // adres zapisu
    input  logic [IDW-1:0] s_awid,
    input  logic [AW-1:0]  s_awaddr,
    input  logic [7:0]     s_awlen,
    input  logic [2:0]     s_awsize,
    input  logic [1:0]     s_awburst,
    input  logic           s_awvalid,
    output logic           s_awready,
    // dane zapisu
    input  logic [31:0]    s_wdata,
    input  logic [3:0]     s_wstrb,
    input  logic           s_wlast,
    input  logic           s_wvalid,
    output logic           s_wready,
    // odpowiedź zapisu
    output logic  [IDW-1:0] s_bid,
    output logic [1:0]     s_bresp,
    output logic            s_bvalid,
    input  logic           s_bready,
    // adres odczytu
    input  logic [IDW-1:0] s_arid,
    input  logic [AW-1:0]  s_araddr,
    input  logic [7:0]     s_arlen,
    input  logic [2:0]     s_arsize,
    input  logic [1:0]     s_arburst,
    input  logic           s_arvalid,
    output logic           s_arready,
    // dane odczytu
    output logic  [IDW-1:0] s_rid,
    output logic  [31:0]    s_rdata,
    output logic [1:0]     s_rresp,
    output logic            s_rlast,
    output logic            s_rvalid,
    input  logic           s_rready
);
    localparam [1:0] FIXED = 2'b00, WRAP = 2'b10;

    logic [31:0] mem [0:(1 << (AW - 2)) - 1];

    // adres następnego taktu burstu (bajtowy)
    function [AW-1:0] nast(input [AW-1:0] a, input [1:0] typ, input [2:0] size, input [7:0] len);
        logic [AW-1:0] krok, rozm, n;
        begin
            krok = {{(AW-1){1'b0}}, 1'b1} << size;
            n    = a + krok;
            rozm = krok * ({{(AW-8){1'b0}}, len} + 1'b1);        // rozmiar okna WRAP w bajtach
            if (typ == FIXED)
                nast = a;
            else if (typ == WRAP && (n & (rozm - 1'b1)) == {AW{1'b0}})
                nast = n - rozm;                                  // przekroczona granica okna: zawinięcie
            else
                nast = n;
        end
    endfunction

    // ---- zapis
    logic           w_akt;
    logic [AW-1:0]  w_adr;
    logic [7:0]     w_len;
    logic [2:0]     w_size;
    logic [1:0]     w_typ;
    logic [IDW-1:0] w_id;

    logic [AW-1:0] w_nast;
    assign w_nast = nast(w_adr, w_typ, w_size, w_len);
    assign s_awready = !w_akt && !s_bvalid;
    assign s_wready  = w_akt;
    assign s_bresp   = 2'b00;
    assign s_rresp   = 2'b00;

    integer b;
    always_ff @(posedge clk) begin
        if (s_wvalid && s_wready)
            for (b = 0; b < 4; b = b + 1)
                if (s_wstrb[b]) mem[w_adr[AW-1:2]][b*8 +: 8] <= s_wdata[b*8 +: 8];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            w_akt    <= 1'b0;
            s_bvalid <= 1'b0;
        end else begin
            if (s_awvalid && s_awready) begin
                w_akt  <= 1'b1;
                w_adr  <= s_awaddr;
                w_len  <= s_awlen;
                w_size <= s_awsize;
                w_typ  <= s_awburst;
                w_id   <= s_awid;
            end
            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
            if (s_wvalid && s_wready) begin
                w_adr <= w_nast;
                if (s_wlast) begin
                    w_akt    <= 1'b0;
                    s_bvalid <= 1'b1;
                    s_bid    <= w_id;
                end
            end
        end
    end

    // ---- odczyt
    logic           r_akt;
    logic [AW-1:0]  r_adr;
    logic [7:0]     r_len, r_zost;
    logic [2:0]     r_size;
    logic [1:0]     r_typ;
    logic [IDW-1:0] r_id;

    logic [AW-1:0] r_nast;
    assign r_nast = nast(r_adr, r_typ, r_size, r_len);
    assign s_arready = !r_akt;

    always_ff @(posedge clk) begin
        if (rst) begin
            r_akt    <= 1'b0;
            s_rvalid <= 1'b0;
        end else begin
            if (s_arvalid && s_arready) begin
                r_akt  <= 1'b1;
                r_adr  <= s_araddr;
                r_len  <= s_arlen;
                r_zost <= s_arlen;
                r_size <= s_arsize;
                r_typ  <= s_arburst;
                r_id   <= s_arid;
            end
            if (r_akt && (!s_rvalid || s_rready)) begin          // kolejne słowo, gdy poprzednie odebrane
                s_rdata  <= mem[r_adr[AW-1:2]];
                s_rvalid <= 1'b1;
                s_rid    <= r_id;
                s_rlast  <= (r_zost == 8'd0);
                r_adr    <= r_nast;
                if (r_zost == 8'd0) r_akt <= 1'b0;
                r_zost   <= r_zost - 1'b1;
            end else if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;
        end
    end
endmodule

`default_nettype wire

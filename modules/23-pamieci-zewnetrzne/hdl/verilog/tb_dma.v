// Testbench 23.04: arbiter_rr z trzema masterami — dwa silniki dma_kopia i „procesor” (losowe zapisy
// i odczyty we własnym obszarze) — do modelu pamięci Avalon-MM (4096 słów, odczyt po 2 taktach w potoku,
// losowy waitrequest 20 %). Sprawdzane: obie kopie zgodne ze źródłem, każdy odczyt procesora zgodny
// z modelem, liczba transferów każdego mastera w czasie rywalizacji (sprawiedliwość), przepustowość
// pojedynczego DMA bez rywalizacji.
`timescale 1ns / 1ps
`default_nettype none

module tb_dma;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0, seed = 9;
    integer p_wait = 20;

    // ---- pamięć (slave)
    wire [11:0] s_adr;
    wire        s_read, s_write;
    wire [31:0] s_wdata;
    reg         s_wait = 1'b0;
    reg  [1:0]  rv = 2'b00;
    reg  [31:0] rd0, rd1;
    reg  [31:0] pam [0:4095];
    wire        s_rvalid = rv[1];
    wire [31:0] s_rdata = rd1;
    always @(posedge clk) begin
        s_wait <= (($random(seed) & 32'h7fffffff) % 100) < p_wait;
        if (s_write && !s_wait) pam[s_adr] <= s_wdata;
        rv  <= {rv[0], s_read && !s_wait};
        rd0 <= pam[s_adr];
        rd1 <= rd0;
    end

    // ---- mastery
    wire [3*12-1:0] m_adr;
    wire [2:0]      m_read, m_write, m_wait, m_rvalid;
    wire [3*32-1:0] m_wdata;
    wire [31:0]     m_rdata;
    arbiter_rr #(.N(3), .AW(12), .KOL(8)) u_arb (.clk(clk), .rst(rst), .m_adr(m_adr), .m_read(m_read),
        .m_write(m_write), .m_wdata(m_wdata), .m_wait(m_wait), .m_rvalid(m_rvalid), .m_rdata(m_rdata),
        .s_adr(s_adr), .s_read(s_read), .s_write(s_write), .s_wdata(s_wdata), .s_wait(s_wait),
        .s_rvalid(s_rvalid), .s_rdata(s_rdata));

    reg  [1:0]  start = 2'b00;
    reg  [11:0] zr0 = 0, cel0 = 0, n0 = 0, zr1 = 0, cel1 = 0, n1 = 0;
    wire [1:0]  zajety, gotowe;
    dma_kopia #(.AW(12), .GL(8)) u_dma0 (.clk(clk), .rst(rst), .start(start[0]), .zrodlo(zr0), .cel(cel0), .n(n0),
        .zajety(zajety[0]), .gotowe(gotowe[0]), .m_adr(m_adr[11:0]), .m_read(m_read[0]), .m_write(m_write[0]),
        .m_wdata(m_wdata[31:0]), .m_wait(m_wait[0]), .m_rvalid(m_rvalid[0]), .m_rdata(m_rdata));
    dma_kopia #(.AW(12), .GL(8)) u_dma1 (.clk(clk), .rst(rst), .start(start[1]), .zrodlo(zr1), .cel(cel1), .n(n1),
        .zajety(zajety[1]), .gotowe(gotowe[1]), .m_adr(m_adr[23:12]), .m_read(m_read[1]), .m_write(m_write[1]),
        .m_wdata(m_wdata[63:32]), .m_wait(m_wait[1]), .m_rvalid(m_rvalid[1]), .m_rdata(m_rdata));

    // ---- „procesor”: losowe zapisy i odczyty w obszarze 3584-4095, rozkaz trzymany do przyjęcia
    reg  [11:0] c_adr = 0;
    reg         c_read = 0, c_write = 0, c_akt = 0;
    reg  [31:0] c_wdata = 0;
    reg  [31:0] c_model [0:511];
    reg  [31:0] c_ocz [0:63];
    integer     c_wz = 0, c_wo = 0, c_bl = 0, c_n = 0, a_nowy;
    reg  [31:0] d_nowe;
    assign m_adr[35:24]   = c_adr;
    assign m_read[2]      = c_read;
    assign m_write[2]     = c_write;
    assign m_wdata[95:64] = c_wdata;
    always @(posedge clk) begin
        if (m_rvalid[2]) begin
            if (m_rdata !== c_ocz[c_wo % 64]) c_bl = c_bl + 1;
            c_wo = c_wo + 1;
        end
        if ((c_read || c_write) && !m_wait[2]) begin
            c_n = c_n + 1;
            if (c_read) begin c_ocz[c_wz % 64] = c_model[c_adr - 12'd3584]; c_wz = c_wz + 1; end
            c_read  <= 1'b0;
            c_write <= 1'b0;
        end
        if (c_akt && (!(c_read || c_write) || !m_wait[2]) && (($random(seed) & 32'h7fffffff) % 100) < 70) begin
            a_nowy = ($random(seed) & 32'h7fffffff) % 512;           // nieblokująco: bez wyścigu z układem
            c_adr <= 12'd3584 + a_nowy[11:0];
            if ($random(seed) & 1) begin
                d_nowe = $random(seed);
                c_model[a_nowy] = d_nowe;
                c_wdata <= d_nowe;
                c_write <= 1'b1;
            end else
                c_read <= 1'b1;
        end
    end

    // liczniki transferów w czasie rywalizacji
    integer licz [0:2];
    reg     mierz = 1'b0;
    integer j;
    always @(posedge clk) if (mierz)
        for (j = 0; j < 3; j = j + 1) if ((m_read[j] || m_write[j]) && !m_wait[j]) licz[j] = licz[j] + 1;

    integer i, t0, t1;
    initial begin
        for (i = 0; i < 4096; i = i + 1) pam[i] = $random(seed);
        for (i = 3584; i < 4096; i = i + 1) c_model[i - 3584] = pam[i];
        for (j = 0; j < 3; j = j + 1) licz[j] = 0;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        // 1. pojedynczy DMA bez rywalizacji i bez waitrequest: 256 słów
        p_wait = 0;
        @(negedge clk);
        zr0 = 0; cel0 = 1024; n0 = 256; start = 2'b01;
        @(negedge clk) start = 2'b00;
        t0 = $time;
        wait (gotowe[0]);
        t1 = $time;
        for (i = 0; i < 256; i = i + 1) if (pam[1024 + i] !== pam[i]) errors = errors + 1;
        $display("DMA sam: 256 slow w %0d taktach (%0d transferow: odczyt + zapis na slowo)", (t1 - t0) / 10, 512);
        // 2. rywalizacja: dwa DMA i procesor, waitrequest 20 %
        p_wait = 20;
        @(negedge clk);
        zr0 = 256; cel0 = 1536; n0 = 300; zr1 = 2048; cel1 = 2560; n1 = 300; start = 2'b11;
        c_akt = 1'b1; mierz = 1'b1;
        @(negedge clk) start = 2'b00;
        wait (gotowe[0] || gotowe[1]);
        mierz = 1'b0;
        $display("rywalizacja (do konca pierwszego DMA): transfery DMA0 %0d, DMA1 %0d, procesor %0d", licz[0], licz[1],
                 licz[2]);
        if (licz[0] < 2 * licz[1] / 3 || licz[1] < 2 * licz[0] / 3) errors = errors + 1;
        wait (!zajety[0] && !zajety[1]);
        c_akt = 1'b0;
        repeat (20) @(negedge clk);
        for (i = 0; i < 300; i = i + 1) begin
            if (pam[1536 + i] !== pam[256 + i]) errors = errors + 1;
            if (pam[2560 + i] !== pam[2048 + i]) errors = errors + 1;
        end
        $display("kopie 2 x 300 slow: bledow %0d; procesor: %0d transferow, %0d odczytow, bledow odczytu %0d",
                 errors, c_n, c_wo, c_bl);
        if (c_bl != 0 || c_wo < 50) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

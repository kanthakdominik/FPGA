// Testbench (SystemVerilog) 21.03: axi_ram (AXI4) i avmm_burst_ram (Avalon-MM) z modelem pamięci.
//   AXI4: wypełnienie całej pamięci burstami INCR po 16, potem 300 losowych transakcji zapis + odczyt:
//   FIXED (1–4 takty), INCR (1–16), WRAP (2, 4, 8, 16), losowe WSTRB, ID, przerwy w WVALID, losowe
//   BREADY i RREADY; adresy kolejnych taktów liczone w modelu wprost ze wzorów specyfikacji.
//   Przepustowość: odczyt INCR 16 przy RREADY = 1.
//   Avalon-MM: wypełnienie, potem 200 losowych burstów zapisu (z przerwami między taktami) i odczytu.
`timescale 1ns / 1ps
`default_nettype none

module tb_burst;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0, seed = 21;
    function int los(input int zakres);
        los = ($random(seed) & 32'h7fff_ffff) % zakres;
    endfunction

    localparam [1:0] FIXED = 2'b00, INCR = 2'b01, WRAP = 2'b10;

    // ================= AXI4
    logic  [3:0]  awid = 0, arid = 0;
    logic  [11:0] awaddr = 0, araddr = 0;
    logic  [7:0]  awlen = 0, arlen = 0;
    logic  [1:0]  awburst = 0, arburst = 0;
    logic         awvalid = 0, wvalid = 0, wlast = 0, bready = 0, arvalid = 0, rready = 0;
    logic  [31:0] wdata = 0;
    logic  [3:0]  wstrb = 0;
    logic        awready, wready, bvalid, arready, rvalid, rlast;
    logic [3:0]  bid, rid;
    logic [1:0]  bresp, rresp;
    logic [31:0] rdata;
    axi_ram #(.AW(12), .IDW(4)) u_axi (.clk(clk), .rst(rst),
        .s_awid(awid), .s_awaddr(awaddr), .s_awlen(awlen), .s_awsize(3'd2), .s_awburst(awburst),
        .s_awvalid(awvalid), .s_awready(awready),
        .s_wdata(wdata), .s_wstrb(wstrb), .s_wlast(wlast), .s_wvalid(wvalid), .s_wready(wready),
        .s_bid(bid), .s_bresp(bresp), .s_bvalid(bvalid), .s_bready(bready),
        .s_arid(arid), .s_araddr(araddr), .s_arlen(arlen), .s_arsize(3'd2), .s_arburst(arburst),
        .s_arvalid(arvalid), .s_arready(arready),
        .s_rid(rid), .s_rdata(rdata), .s_rresp(rresp), .s_rlast(rlast), .s_rvalid(rvalid), .s_rready(rready));

    logic [7:0] model [0:4095];
    int   pr_r = 100;                       // prawdopodobieństwo RREADY

    // adres taktu k ze wzorów specyfikacji (rozmiar 4 bajty)
    function int adres(input int start, input [1:0] typ, input int len, input int k);
        int rozm, dol;
        begin
            if (typ == FIXED) adres = start;
            else if (typ == INCR) adres = start + 4 * k;
            else begin
                rozm  = 4 * (len + 1);
                dol   = start - (start % rozm);
                adres = dol + ((start - dol + 4 * k) % rozm);
            end
        end
    endfunction

    task axi_zapis(input int start, input [1:0] typ, input int len, input [3:0] id, input int pelne);
        int k, b, a;
        logic [31:0] d;
        logic [3:0]  s;
        begin
            fork
                begin
                    repeat (los(3)) @(negedge clk);
                    awaddr = start; awburst = typ; awlen = len; awid = id; awvalid = 1'b1;
                    @(posedge clk); while (!awready) @(posedge clk);
                    @(negedge clk) awvalid = 1'b0;
                end
                begin
                    for (k = 0; k <= len; k = k + 1) begin
                        repeat (los(2)) @(negedge clk);
                        d = $random(seed);
                        s = pelne ? 4'hF : los(16);
                        wdata = d; wstrb = s; wlast = (k == len); wvalid = 1'b1;
                        @(posedge clk); while (!wready) @(posedge clk);
                        a = adres(start, typ, len, k);
                        for (b = 0; b < 4; b = b + 1) if (s[b]) model[a + b] = d[b*8 +: 8];
                        @(negedge clk) wvalid = 1'b0;
                    end
                end
            join
            repeat (los(3)) @(negedge clk);
            bready = 1'b1;
            @(posedge clk); while (!bvalid) @(posedge clk);
            if (bid !== id || bresp !== 2'b00) begin
                $display("AXI: BID %h, oczekiwano %h", bid, id); errors = errors + 1;
            end
            @(negedge clk) bready = 1'b0;
        end
    endtask

    int t_ar, t_last;
    task axi_odczyt(input int start, input [1:0] typ, input int len, input [3:0] id);
        int k, a;
        begin
            repeat (los(3)) @(negedge clk);
            araddr = start; arburst = typ; arlen = len; arid = id; arvalid = 1'b1;
            @(posedge clk); while (!arready) @(posedge clk);
            t_ar = $time;
            @(negedge clk) arvalid = 1'b0;
            k = 0;
            while (k <= len) begin
                rready = (los(100) < pr_r);
                @(posedge clk);
                if (rvalid && rready) begin
                    a = adres(start, typ, len, k);
                    if (rdata !== {model[a + 3], model[a + 2], model[a + 1], model[a]} || rid !== id
                        || rlast !== (k == len)) begin
                        if (errors < 10) $display("AXI odczyt typ %0d len %0d takt %0d adres %0d: %h, oczekiwano %h",
                            typ, len, k, a, rdata, {model[a + 3], model[a + 2], model[a + 1], model[a]});
                        errors = errors + 1;
                    end
                    k = k + 1;
                    t_last = $time;
                end
                @(negedge clk);
            end
            rready = 1'b0;
        end
    endtask

    // ================= Avalon-MM z burstami
    logic  [9:0]  address = 0;
    logic         read = 0, write = 0;
    logic  [31:0] writedata = 0;
    logic  [3:0]  byteenable = 0;
    logic  [4:0]  burstcount = 0;
    logic        waitrequest, readdatavalid;
    logic [31:0] readdata;
    avmm_burst_ram #(.AW(10), .BW(5)) u_avmm (.clk(clk), .rst(rst), .address(address), .read(read),
        .write(write), .writedata(writedata), .byteenable(byteenable), .burstcount(burstcount),
        .waitrequest(waitrequest), .readdata(readdata), .readdatavalid(readdatavalid));
    logic [31:0] mmodel [0:1023];

    task av_zapis(input int a, input int n, input int przerwy);
        int k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                if (przerwy) repeat (los(2)) @(negedge clk);
                address = a; burstcount = n; writedata = $random(seed); byteenable = 4'hF; write = 1'b1;
                @(posedge clk); while (waitrequest) @(posedge clk);
                mmodel[a + k] = writedata;
                @(negedge clk) write = 1'b0;
            end
        end
    endtask

    task av_odczyt(input int a, input int n);
        int k;
        begin
            @(negedge clk);
            address = a; burstcount = n; read = 1'b1;
            @(posedge clk); while (waitrequest) @(posedge clk);
            @(negedge clk) read = 1'b0;
            k = 0;
            while (k < n) begin
                @(posedge clk);
                if (readdatavalid) begin
                    if (readdata !== mmodel[a + k]) begin
                        if (errors < 10) $display("Avalon: burst %0d slow od %0d, slowo %0d = %h, oczekiwano %h", n, a, k,
                                                  readdata, mmodel[a + k]);
                        errors = errors + 1;
                    end
                    k = k + 1;
                end
            end
            @(negedge clk);                             // następna operacja zaczyna się od zbocza opadającego
        end
    endtask

    int i, st, len, n_fix, n_incr, n_wrap;
    logic [1:0] typ;
    initial begin
        n_fix = 0; n_incr = 0; n_wrap = 0;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 64; i = i + 1) axi_zapis(i * 64, INCR, 15, i[3:0], 1);
        pr_r = 100;
        axi_odczyt(256, INCR, 15, 4'h3);
        $display("AXI: odczyt INCR 16 slow przy RREADY = 1: %0d taktow od przyjecia AR do RLAST", (t_last - t_ar) / 10);
        if ((t_last - t_ar) / 10 > 17) errors = errors + 1;
        pr_r = 60;
        for (i = 0; i < 300; i = i + 1) begin
            typ = los(3);
            case (typ)
                FIXED: begin len = los(4);              st = 4 * los(1024); n_fix = n_fix + 1; end
                INCR:  begin len = los(16);             st = 4 * los(1024 - len); n_incr = n_incr + 1; end
                default: begin len = (2 << los(4)) - 1; st = 4 * los(1024); n_wrap = n_wrap + 1; end
            endcase
            axi_zapis(st, typ, len, los(16), 0);
            axi_odczyt(st, typ, len, los(16));
        end
        $display("AXI4: 300 transakcji zapis + odczyt (FIXED %0d, INCR %0d, WRAP %0d), bledow %0d", n_fix, n_incr, n_wrap,
                 errors);
        // Avalon-MM
        for (i = 0; i < 64; i = i + 1) av_zapis(i * 16, 16, 0);
        for (i = 0; i < 200; i = i + 1) begin
            len = 1 + los(16);
            st  = los(1024 - len);
            av_zapis(st, len, 1);
            len = 1 + los(16);
            st  = los(1024 - len);
            av_odczyt(st, len);
        end
        $display("Avalon-MM: 200 burstow zapisu i odczytu (1-16 slow), bledow lacznie %0d", errors);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

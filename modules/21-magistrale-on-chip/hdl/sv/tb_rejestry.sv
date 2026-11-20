// Testbench (SystemVerilog) 21.02: ta sama mapa rejestrów przez AXI4-Lite (axil_rejestry) i Avalon-MM (avmm_rejestry).
// Master AXI4-Lite podaje AW i W z losowymi, niezależnymi opóźnieniami (także W przed AW) i z losowym
// opóźnieniem BREADY/RREADY. Sprawdzane: ID, zapis z maską bajtów, rejestr tylko do odczytu, W1C
// z równoczesnym zdarzeniem, przerwanie z maską, SLVERR pod adresem spoza mapy, 100 losowych zapisów
// i odczytów rejestru SKRYTKA z modelem.
`timescale 1ns / 1ps
`default_nettype none

module tb_rejestry;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0, seed = 11;
    function int los(input int zakres);
        los = ($random(seed) & 32'h7fff_ffff) % zakres;
    endfunction

    // ---- AXI4-Lite
    logic  [5:0]  awaddr = 0, araddr = 0;
    logic         awvalid = 0, wvalid = 0, bready = 0, arvalid = 0, rready = 0;
    logic  [31:0] wdata = 0;
    logic  [3:0]  wstrb = 0;
    logic        awready, wready, bvalid, arready, rvalid;
    logic [1:0]  bresp, rresp;
    logic [31:0] rdata;
    logic [31:0] ster_a;
    logic        irq_a;
    logic  [31:0] stan_a = 0;
    logic  [7:0]  zdarz_a = 0;
    axil_rejestry u_axil (.clk(clk), .rst(rst),
        .s_awaddr(awaddr), .s_awvalid(awvalid), .s_awready(awready),
        .s_wdata(wdata), .s_wstrb(wstrb), .s_wvalid(wvalid), .s_wready(wready),
        .s_bresp(bresp), .s_bvalid(bvalid), .s_bready(bready),
        .s_araddr(araddr), .s_arvalid(arvalid), .s_arready(arready),
        .s_rdata(rdata), .s_rresp(rresp), .s_rvalid(rvalid), .s_rready(rready),
        .ster(ster_a), .stan(stan_a), .zdarz(zdarz_a), .irq(irq_a));

    // ---- Avalon-MM
    logic  [3:0]  address = 0;
    logic         read = 0, write = 0;
    logic  [31:0] writedata = 0;
    logic  [3:0]  byteenable = 0;
    logic [31:0] readdata;
    logic [1:0]  response;
    logic [31:0] ster_m;
    logic        irq_m;
    logic  [31:0] stan_m = 0;
    logic  [7:0]  zdarz_m = 0;
    avmm_rejestry u_avmm (.clk(clk), .rst(rst), .address(address), .read(read), .write(write),
        .writedata(writedata), .byteenable(byteenable), .readdata(readdata), .response(response),
        .ster(ster_m), .stan(stan_m), .zdarz(zdarz_m), .irq(irq_m));

    int szyna;                                  // 0 — AXI4-Lite, 1 — Avalon-MM
    logic [31:0] dane;
    logic [1:0]  odp;

    task zapis(input [5:0] a, input [31:0] d, input [3:0] s);
        begin
            if (szyna == 0) begin
                fork
                    begin
                        repeat (los(4)) @(negedge clk);
                        awaddr = a; awvalid = 1'b1;
                        @(posedge clk); while (!awready) @(posedge clk);
                        @(negedge clk) awvalid = 1'b0;
                    end
                    begin
                        repeat (los(4)) @(negedge clk);
                        wdata = d; wstrb = s; wvalid = 1'b1;
                        @(posedge clk); while (!wready) @(posedge clk);
                        @(negedge clk) wvalid = 1'b0;
                    end
                join
                repeat (los(3)) @(negedge clk);
                bready = 1'b1;
                @(posedge clk); while (!bvalid) @(posedge clk);
                odp = bresp;
                @(negedge clk) bready = 1'b0;
            end else begin
                @(negedge clk);
                address = a[5:2]; writedata = d; byteenable = s; write = 1'b1;
                @(negedge clk) write = 1'b0;
                odp = 2'b00;                            // Avalon-MM: zapis bez odpowiedzi
            end
        end
    endtask

    task odczyt(input [5:0] a);
        begin
            if (szyna == 0) begin
                repeat (los(4)) @(negedge clk);
                araddr = a; arvalid = 1'b1;
                @(posedge clk); while (!arready) @(posedge clk);
                @(negedge clk) arvalid = 1'b0;
                repeat (los(3)) @(negedge clk);
                rready = 1'b1;
                @(posedge clk); while (!rvalid) @(posedge clk);
                dane = rdata; odp = rresp;
                @(negedge clk) rready = 1'b0;
            end else begin
                @(negedge clk);
                address = a[5:2]; read = 1'b1;
                @(negedge clk) read = 1'b0;            // readLatency = 1: dane po zboczu za rozkazem
                dane = readdata; odp = response;
            end
        end
    endtask

    task oczekuj(input [5:0] a, input [31:0] d, input [1:0] o);
        begin
            odczyt(a);
            if (dane !== d || odp !== o) begin
                $display("szyna %0d: odczyt 0x%h = %h (odp %b), oczekiwano %h (%b)", szyna, a, dane, odp, d, o);
                errors = errors + 1;
            end
        end
    endtask

    task zdarzenie(input [7:0] z);
        begin
            @(negedge clk);
            if (szyna == 0) zdarz_a = z; else zdarz_m = z;
            @(negedge clk);
            zdarz_a = 0; zdarz_m = 0;
        end
    endtask

    int i;
    logic [31:0] model, x;
    logic [3:0]  s;
    logic [31:0] ster;
    assign ster = szyna == 0 ? ster_a : ster_m;
    logic        irq;
    assign irq = szyna == 0 ? irq_a : irq_m;
    initial begin
        repeat (5) @(negedge clk);
        rst = 1'b0;
        for (szyna = 0; szyna < 2; szyna = szyna + 1) begin
            oczekuj(6'h00, 32'h2102_0001, 2'b00);                  // ID
            zapis(6'h04, 32'h1234_5678, 4'b1111);
            oczekuj(6'h04, 32'h1234_5678, 2'b00);
            zapis(6'h04, 32'hAABB_CCDD, 4'b0101);                  // tylko bajty 0 i 2
            oczekuj(6'h04, 32'h12BB_56DD, 2'b00);
            if (ster !== 32'h12BB_56DD) errors = errors + 1;
            zapis(6'h00, 32'hFFFF_FFFF, 4'b1111);                  // ID tylko do odczytu
            oczekuj(6'h00, 32'h2102_0001, 2'b00);
            if (szyna == 0) stan_a = 32'hCAFE_F00D; else stan_m = 32'hCAFE_F00D;
            oczekuj(6'h08, 32'hCAFE_F00D, 2'b00);
            // przerwania
            zdarzenie(8'h05);
            oczekuj(6'h0C, 32'h0000_0005, 2'b00);
            if (irq !== 1'b0) errors = errors + 1;
            zapis(6'h10, 32'h0000_0004, 4'b0001);                  // maska bitu 2
            @(negedge clk);
            if (irq !== 1'b1) begin $display("szyna %0d: brak irq", szyna); errors = errors + 1; end
            zapis(6'h0C, 32'h0000_0004, 4'b0001);                  // W1C bitu 2
            oczekuj(6'h0C, 32'h0000_0001, 2'b00);
            @(negedge clk);
            if (irq !== 1'b0) errors = errors + 1;
            // adres spoza mapy
            oczekuj(6'h20, 32'h0000_0000, 2'b10);
            zapis(6'h3C, 32'h1, 4'b1111);
            if (odp !== (szyna == 0 ? 2'b10 : 2'b00)) begin
                $display("szyna %0d: zapis poza mapa, odp %b", szyna, odp); errors = errors + 1;
            end
            // losowe zapisy z maską i odczyty
            model = 0;
            zapis(6'h14, 32'h0, 4'b1111);
            for (i = 0; i < 100; i = i + 1) begin
                x = $random(seed);
                s = los(16);
                zapis(6'h14, x, s);
                model = (model & ~{{8{s[3]}}, {8{s[2]}}, {8{s[1]}}, {8{s[0]}}})
                        | (x & {{8{s[3]}}, {8{s[2]}}, {8{s[1]}}, {8{s[0]}}});
                oczekuj(6'h14, model, 2'b00);
            end
            $display("szyna %s: ID, maska bajtow, RO, W1C, irq, SLVERR, 100 zapisow losowych - bledow do tej pory %0d",
                     szyna == 0 ? "AXI4-Lite" : "Avalon-MM", errors);
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

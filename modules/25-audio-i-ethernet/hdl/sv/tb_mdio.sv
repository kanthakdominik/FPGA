// Testbench (SystemVerilog) 25.03: mdio z modelem PHY (adres 1; rejestry: 0 — sterowanie, 1 — stan, 2/3 — identyfikator).
// Model sprawdza preambułę (32 jedynki), ST, kod operacji, adres; przy odczycie wystawia TA = 0 i dane po
// narastającym MDC poprzedniego bitu (opóźnienie 100 ns). Przebiegi: odczyt rejestrów 2, 3 i 1, zapis 0x3100
// do rejestru 0 i odczyt zwrotny, odczyt pod nieistniejącym adresem PHY (linia w spoczynku -> 0xFFFF).
`timescale 1ns / 1ps
`default_nettype none

module tb_mdio;
    logic clk = 1'b0;
    always #10 clk = ~clk;                        // 50 MHz
    logic rst = 1'b1;
    int errors = 0;

    logic         start = 1'b0, zapis = 1'b0;
    logic  [4:0]  phy = 5'd1, rej = 5'd0;
    logic  [15:0] wdane = 0;
    logic [15:0] rdane;
    logic        gotowe, zajety, mdc, mdio_o, mdio_oe;
    logic         p_o = 1'b1, p_oe = 1'b0;          // PHY
    logic        linia;
    assign linia = mdio_oe ? mdio_o : (p_oe ? p_o : 1'b1);   // podciąganie do 1
    mdio #(.DIV(10)) dut (.clk(clk), .rst(rst), .start(start), .zapis(zapis), .phy(phy), .rej(rej), .wdane(wdane),
                          .rdane(rdane), .gotowe(gotowe), .zajety(zajety), .mdc(mdc), .mdio_o(mdio_o),
                          .mdio_oe(mdio_oe), .mdio_i(linia));

    // ---- model PHY
    logic  [15:0] r [0:31];
    int     nb = 0, jedynki = 0, bl_ramki = 0;
    logic  [13:0] nagl = 0;                          // ST, OP, PHYAD, REGAD
    logic  [15:0] d = 0;
    logic         czyt = 1'b0, nasz = 1'b0;
    realtime    t_pop = 0, min_okres = 1.0e9;
    always @(posedge mdc) begin
        if (t_pop > 0 && $realtime - t_pop < min_okres) min_okres = $realtime - t_pop;
        t_pop = $realtime;
        if (nb == 0) begin                                         // preambuła: liczenie jedynek
            if (linia) jedynki = jedynki + 1;
            else if (jedynki >= 32) begin nb = 1; nagl = 14'd0; end // bit 0 pola ST (= 0)
            else jedynki = 0;
        end else begin
            nb = nb + 1;
            if (nb <= 14) nagl = {nagl[12:0], linia};
            if (nb == 14) begin
                if (nagl[13:12] != 2'b01) bl_ramki = bl_ramki + 1;  // ST = 01 (bit 0 już przyjęty)
                czyt = (nagl[11:10] == 2'b10);
                nasz = (nagl[9:5] == 5'd1);
            end
            if (nb == 15 && czyt && nasz) begin d = r[nagl[4:0]]; #100 begin p_oe = 1'b1; p_o = 1'b0; end end
            if (nb >= 16 && nb <= 31 && czyt && nasz) begin #100 p_o = d[31 - nb]; end
            if (nb >= 17 && nb <= 32 && !czyt) d = {d[14:0], linia};
            if (nb == 32) begin
                if (!czyt && nasz) r[nagl[4:0]] = d;
                #100 p_oe = 1'b0;
                nb = 0; jedynki = 0;
            end
        end
    end

    task op(input z, input [4:0] p, input [4:0] rr, input [15:0] w);
        begin
            @(negedge clk) begin start = 1'b1; zapis = z; phy = p; rej = rr; wdane = w; end
            @(negedge clk) start = 1'b0;
            @(posedge gotowe); #1;
        end
    endtask

    int i;
    initial begin
        for (i = 0; i < 32; i = i + 1) r[i] = 16'h0000;
        r[1] = 16'h7849; r[2] = 16'h2000; r[3] = 16'h5CE1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        op(0, 5'd1, 5'd2, 0); $display("odczyt rejestru 2: %h", rdane); if (rdane !== 16'h2000) errors = errors + 1;
        op(0, 5'd1, 5'd3, 0); $display("odczyt rejestru 3: %h", rdane); if (rdane !== 16'h5CE1) errors = errors + 1;
        op(0, 5'd1, 5'd1, 0); $display("odczyt rejestru 1: %h", rdane); if (rdane !== 16'h7849) errors = errors + 1;
        op(1, 5'd1, 5'd0, 16'h3100);
        op(0, 5'd1, 5'd0, 0); $display("zapis 3100 do rejestru 0, odczyt: %h", rdane); if (rdane !== 16'h3100) errors = errors + 1;
        op(0, 5'd7, 5'd2, 0); $display("odczyt pod adresem PHY 7 (brak): %h", rdane); if (rdane !== 16'hFFFF) errors = errors + 1;
        $display("MDC: okres min %.0f ns (%.2f MHz), bledne naglowki %0d", min_okres, 1.0e3 / min_okres, bl_ramki);
        if (bl_ramki != 0 || min_okres < 400.0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

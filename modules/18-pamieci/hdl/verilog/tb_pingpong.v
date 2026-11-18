// Testbench pingpong: nadawca zapisuje bloki po 16 słów (słowo = numer bloku · 256 + indeks), z losowymi
// przerwami; odbiorca czeka losowo, czyta blok w odwrotnej kolejności (dostęp swobodny) i go zwalnia.
// Sprawdzane: każdy blok odczytany w całości, bez pominięć i powtórzeń; nadawca bywa wstrzymywany
// (wr_ready = 0), bo odbiorca jest wolniejszy.
`timescale 1ns / 1ps
`default_nettype none

module tb_pingpong;
    localparam W = 16, AW = 4, NB = 40;
    reg clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;
    reg           wr_en = 1'b0, zwolnij = 1'b0;
    reg  [W-1:0]  din = 0;
    reg  [AW-1:0] rd_addr = 0;
    wire          wr_ready, gotowy;
    wire [W-1:0]  dout;
    pingpong #(.W(W), .AW(AW)) dut (.clk(clk), .rst(rst), .wr_en(wr_en), .din(din), .wr_ready(wr_ready),
        .rd_gotowy(gotowy), .rd_addr(rd_addr), .dout(dout), .rd_zwolnij(zwolnij));

    integer blok_w = 0, slowo_w = 0, blok_r = 0, i, errors = 0, wstrzymania = 0;

    // nadawca: licznik przyjętych słów na zboczu, nowe słowo na opadającym zboczu
    always @(posedge clk) if (!rst) begin
        if (wr_en && wr_ready) begin
            slowo_w = slowo_w + 1;
            if (slowo_w == (1 << AW)) begin slowo_w = 0; blok_w = blok_w + 1; end
        end
        if (wr_en && !wr_ready) wstrzymania = wstrzymania + 1;
    end
    always @(negedge clk) if (!rst) begin
        wr_en = (blok_w < NB) && ($urandom % 4 != 0);
        din   = blok_w * 256 + slowo_w;
    end

    // odbiorca
    initial begin
        #23 rst = 1'b0;
        while (blok_r < NB) begin
            @(negedge clk);
            if (gotowy) begin
                repeat ($urandom % 40) @(negedge clk);   // odbiorca zajęty czymś innym
                for (i = (1 << AW) - 1; i >= 0; i = i - 1) begin
                    rd_addr = i;
                    @(negedge clk);
                    if (dout !== blok_r * 256 + i) begin
                        $display("%0t: blok %0d slowo %0d: %h", $time, blok_r, i, dout);
                        errors = errors + 1;
                    end
                end
                zwolnij = 1'b1;
                @(negedge clk) zwolnij = 1'b0;
                blok_r = blok_r + 1;
            end
        end
        $display("blokow odczytanych: %0d, takty wstrzymania nadawcy: %0d", blok_r, wstrzymania);
        if (errors == 0 && wstrzymania > 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #2000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire

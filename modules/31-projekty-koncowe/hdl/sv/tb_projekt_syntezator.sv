// Testbench (SystemVerilog) projektu 3 (31.03): bajty MIDI wysyłane szeregowo (500 000 b/s w symulacji), próbki obserwowane
// na wyjściu syntezatora i dekodowane z linii I2S. Krótka obwiednia: atak 8 próbek, opadanie 32, wybrzmiewanie 8.
`timescale 1ns / 1ps
`default_nettype none

module tb_projekt_syntezator;
    localparam int BIT = 25;
    localparam real    FS = 12_500_000.0 / 256.0;
    logic clk = 1'b0;
    always #40 clk = ~clk;
    logic rst = 1'b1;
    logic rx = 1'b1;
    logic bclk, wclk, dout, nowa, blad_ramki;
    logic signed [23:0] probka;
    logic [3:0] aktywne;
    int errors = 0;

    projekt_syntezator #(.CLK_HZ(12_500_000), .BAUD(500_000), .A_KROK(17'd8192), .D_KROK(17'd1024),
        .S_POZ(17'd32768), .R_KROK(17'd4096)) dut (.clk(clk), .rst(rst), .rx(rx), .bclk(bclk), .wclk(wclk),
        .dout(dout), .probka(probka), .nowa(nowa), .aktywne(aktywne), .blad_ramki(blad_ramki));

    task wyslij(input [7:0] b);
        int i;
        begin
            rx = 1'b0; repeat (BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin rx = b[i]; repeat (BIT) @(posedge clk); end
            rx = 1'b1; repeat (BIT) @(posedge clk);
        end
    endtask

    task probki(input int n);
        int i;
        for (i = 0; i < n; i = i + 1) @(posedge nowa);
    endtask

    task oczekuj_glosy(input [3:0] wzor, input [8*32-1:0] co);
        if (aktywne !== wzor) begin
            $display("FAIL: %0s: aktywne glosy %b, oczekiwane %b", co, aktywne, wzor); errors = errors + 1;
        end else
            $display("%0s: aktywne glosy %b", co, aktywne);
    endtask

    // pomiar częstotliwości (przejścia przez zero w górę) i wartości szczytowych na n próbkach
    real    f_zm;
    int p_max, p_min;
    task mierz(input int n);
        int i, nprz, t_pierw, t_ost;
        logic signed [23:0] poprz;
        begin
            nprz = 0; t_pierw = 0; t_ost = 0; p_max = -(1 << 23); p_min = (1 << 23); poprz = probka;
            for (i = 0; i < n; i = i + 1) begin
                @(posedge nowa); #1;
                if (poprz < 0 && probka >= 0) begin
                    if (nprz == 0) t_pierw = i;
                    t_ost = i;
                    nprz = nprz + 1;
                end
                if (probka > p_max) p_max = probka;
                if (probka < p_min) p_min = probka;
                poprz = probka;
            end
            f_zm = (nprz > 1) ? (nprz - 1) * FS / (t_ost - t_pierw) : 0.0;
        end
    endtask

    task sprawdz_f(input real f_ocz, input [8*32-1:0] co);
        if (f_zm < f_ocz * 0.998 || f_zm > f_ocz * 1.002) begin
            $display("FAIL: %0s: %0.2f Hz, oczekiwane %0.2f Hz", co, f_zm, f_ocz); errors = errors + 1;
        end else
            $display("%0s: %0.2f Hz (oczekiwane %0.2f Hz), szczyt %0d / %0d", co, f_zm, f_ocz, p_max, p_min);
    endtask

    // dekoder I2S: słowo lewego kanału porównywane z dwiema ostatnimi próbkami syntezatora
    logic signed [23:0] p_ost = 24'sd0;
    logic signed [23:0] p_przed = 24'sd0;
    always @(posedge nowa) begin p_przed <= p_ost; p_ost <= probka; end
    logic        wclk_d = 1'b1;
    int    kb = 0;
    logic [23:0] slowo = 24'd0;
    int    i2s_zgodne = 0;
    int    i2s_zle = 0;
    always @(posedge bclk) begin
        if (wclk_d && !wclk) kb = 0; else kb = kb + 1;
        wclk_d <= wclk;
        if (!wclk && kb >= 1 && kb <= 24) slowo = {slowo[22:0], dout};
        if (!wclk && kb == 24) begin
            if (slowo == p_ost || slowo == p_przed) i2s_zgodne = i2s_zgodne + 1;
            else i2s_zle = i2s_zle + 1;
        end
    end

    initial begin
        repeat (10) @(posedge clk);
        rst = 1'b0;
        probki(4);
        // 1. prostokąt, nuta 93 (1760 Hz), prędkość 127
        wyslij(8'hC0); wyslij(8'h00);
        wyslij(8'h90); wyslij(8'd93); wyslij(8'd127);
        probki(60);
        oczekuj_glosy(4'b0001, "Note On 93");
        mierz(2048);
        sprawdz_f(440.0 * 4.0, "prostokat, nuta 93");
        // podtrzymanie 0,5, prędkość 127: amp = 32 512, szczyt (32 767 * amp) >> 16, << 6
        if (p_max != 1040320 || p_min != -1040384) begin
            $display("FAIL: szczyt %0d / %0d, oczekiwane 1040320 / -1040384", p_max, p_min); errors = errors + 1;
        end
        // 2. running status i bajt czasu rzeczywistego w środku komunikatu
        wyslij(8'd97); wyslij(8'd100);
        wyslij(8'd81); wyslij(8'hF8); wyslij(8'd64);
        probki(10);
        oczekuj_glosy(4'b0111, "running status + F8");
        // 3. Note Off jako Note On z prędkością 0, potem 8n
        wyslij(8'd93); wyslij(8'd0);
        probki(30);
        oczekuj_glosy(4'b0110, "93 vel 0 (Note Off)");
        wyslij(8'h80); wyslij(8'd97); wyslij(8'd64);
        probki(30);
        oczekuj_glosy(4'b0100, "80 97 (Note Off)");
        // 4. pięć nut na cztery głosy: piąta zabiera najstarszy przydzielony głos
        wyslij(8'h90); wyslij(8'd60); wyslij(8'd127); wyslij(8'd62); wyslij(8'd127);
        wyslij(8'd64); wyslij(8'd127); wyslij(8'd65); wyslij(8'd127);
        probki(10);
        oczekuj_glosy(4'b1111, "4 nuty + glos 81");
        wyslij(8'h80); wyslij(8'd60); wyslij(8'd0);
        probki(30);
        oczekuj_glosy(4'b1111, "Note Off zabranej nuty 60");
        wyslij(8'hB0); wyslij(8'd123); wyslij(8'd0);
        probki(30);
        oczekuj_glosy(4'b0000, "CC 123 (wszystkie wyl.)");
        // 5. sinus, nuta 69 (440 Hz)
        wyslij(8'hC0); wyslij(8'h03);
        wyslij(8'h90); wyslij(8'd69); wyslij(8'd127);
        probki(60);
        mierz(4096);
        sprawdz_f(440.0, "sinus, nuta 69");
        if (p_max < 1030000 || p_max > 1040320) begin
            $display("FAIL: szczyt sinusa %0d", p_max); errors = errors + 1;
        end
        $display("I2S: slow lewego kanalu zgodnych z probkami %0d, niezgodnych %0d", i2s_zgodne, i2s_zle);
        if (i2s_zgodne < 5000 || i2s_zle != 0) begin $display("FAIL: dane I2S"); errors = errors + 1; end
        if (blad_ramki) begin $display("FAIL: blad ramki UART"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

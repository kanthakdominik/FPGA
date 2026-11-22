// Testbench (SystemVerilog) 27.03: pwm_avl przez zadania (task) mastera Avalon-MM — zapis, odczyt z opóźnieniem 1 takt.
// Sprawdza: wartości po resecie, zapis i odczyt rejestrów, wypełnienie (liczba taktów stanu wysokiego w okresie),
// zmianę wypełnienia dopiero od następnego okresu, flagę KONIEC z kasowaniem zapisem 1, maskowanie przerwania,
// skrajne wypełnienia 0 i ≥ OKRES.
`timescale 1ns / 1ps
`default_nettype none

module tb_pwm;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [1:0]  address = 2'd0;
    logic         read = 1'b0, write = 1'b0;
    logic  [31:0] writedata = 32'd0;
    logic [31:0] readdata;
    logic        irq, pwm;
    pwm_avl dut (.clk(clk), .rst(rst), .address(address), .read(read), .write(write), .writedata(writedata),
        .readdata(readdata), .irq(irq), .pwm(pwm));

    task av_zapis(input [1:0] a, input [31:0] d);
        begin
            @(negedge clk) begin address = a; writedata = d; write = 1'b1; end
            @(negedge clk) write = 1'b0;
        end
    endtask

    task av_odczyt(input [1:0] a, output [31:0] d);
        begin
            @(negedge clk) begin address = a; read = 1'b1; end
            @(negedge clk) begin read = 1'b0; d = readdata; end      // readLatency = 1
        end
    endtask

    task sprawdz(input [1:0] a, input [31:0] oczek, input [8*12-1:0] nazwa);
        logic [31:0] d;
        begin
            av_odczyt(a, d);
            if (d !== oczek) begin
                $display("FAIL: %0s = 0x%08h, oczekiwane 0x%08h", nazwa, d, oczek);
                errors = errors + 1;
            end
        end
    endtask

    // liczba taktów stanu wysokiego w kolejnych n taktach
    int wysokie;
    task zmierz(input int n);
        int k;
        begin
            wysokie = 0;
            for (k = 0; k < n; k = k + 1) begin
                @(negedge clk);
                if (pwm) wysokie = wysokie + 1;
            end
        end
    endtask

    // początek okresu = narastające zbocze wyjścia (przy 0 < WYPELN)
    task czekaj_na_zbocze;
        begin
            @(posedge pwm);
            @(negedge clk);
        end
    endtask

    logic [31:0] d;
    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        sprawdz(2'd0, 32'd0, "STER");
        sprawdz(2'd1, 32'd0, "OKRES");
        sprawdz(2'd3, 32'd0, "STATUS");
        av_zapis(2'd1, 32'd10);
        av_zapis(2'd2, 32'd3);
        sprawdz(2'd1, 32'd10, "OKRES");
        sprawdz(2'd2, 32'd3, "WYPELN");
        if (pwm !== 1'b0) begin $display("FAIL: PWM aktywne przed wlaczeniem"); errors = errors + 1; end

        av_zapis(2'd0, 32'd1);                                   // włącz, bez przerwań
        zmierz(100);                                             // dowolne 100 taktów = 10 pełnych okresów
        $display("OKRES = 10, WYPELN = 3: %0d taktow stanu wysokiego na 100 (oczekiwane 30)", wysokie);
        if (wysokie != 30) errors = errors + 1;
        av_odczyt(2'd3, d);
        if (d[0] !== 1'b1) begin $display("FAIL: brak flagi KONIEC"); errors = errors + 1; end
        if (irq !== 1'b0) begin $display("FAIL: irq mimo PRZ = 0"); errors = errors + 1; end
        av_zapis(2'd0, 32'd3);                                   // zezwolenie na przerwanie
        if (irq !== 1'b1) begin $display("FAIL: brak irq przy KONIEC i PRZ"); errors = errors + 1; end
        av_zapis(2'd0, 32'd2);                                   // PWM wyłączone — flaga już się nie ustawi
        if (irq !== 1'b1) begin $display("FAIL: irq zniknelo bez kasowania"); errors = errors + 1; end
        av_zapis(2'd3, 32'd1);                                   // W1C
        if (irq !== 1'b0) begin $display("FAIL: irq po skasowaniu"); errors = errors + 1; end
        sprawdz(2'd3, 32'd0, "STATUS");
        $display("flaga KONIEC, przerwanie i kasowanie zapisem 1: sprawdzone");

        // zmiana wypełnienia w środku okresu działa od następnego okresu
        av_zapis(2'd0, 32'd1);
        czekaj_na_zbocze;
        repeat (4) @(negedge clk);                               // licznik ok. 5-6: wyjście już niskie
        av_zapis(2'd2, 32'd9);
        wysokie = 0;
        while (!pwm) begin @(negedge clk); wysokie = wysokie + 1; end
        $display("zmiana WYPELN 3 -> 9 w srodku okresu: do konca okresu wyjscie niskie przez %0d taktow", wysokie);
        if (wysokie < 3) errors = errors + 1;                   // natychmiastowa zmiana dałaby 1
        zmierz(10);
        $display("nastepny okres: %0d taktow wysokich na 10 (oczekiwane 9)", wysokie);
        if (wysokie != 9) errors = errors + 1;
        sprawdz(2'd2, 32'd9, "WYPELN");

        av_zapis(2'd2, 32'd0);                                   // 0% i 100%
        repeat (12) @(negedge clk);
        zmierz(30);
        $display("WYPELN = 0: %0d taktow wysokich na 30", wysokie);
        if (wysokie != 0) errors = errors + 1;
        av_zapis(2'd2, 32'd50);
        repeat (12) @(negedge clk);
        zmierz(30);
        $display("WYPELN = 50 > OKRES: %0d taktow wysokich na 30", wysokie);
        if (wysokie != 30) errors = errors + 1;

        av_zapis(2'd0, 32'd0);                                   // wyłącz
        repeat (2) @(negedge clk);
        if (pwm !== 1'b0) begin $display("FAIL: PWM po wylaczeniu"); errors = errors + 1; end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

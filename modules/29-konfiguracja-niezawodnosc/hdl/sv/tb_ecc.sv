// Testbench (SystemVerilog) 29.04: SECDED (39,32) i pamięć z czyszczeniem.
//  A. koder + dekoder: 200 losowych słów, każde bez błędu, z każdym z 39 błędów pojedynczych (poprawione)
//     i z każdym z 741 błędów podwójnych (wykryte, bez fałszywej korekty).
//  B. pamiec_ecc (64 słowa): błędy pojedyncze w 20 słowach i podwójne w 3; odczyt przed czyszczeniem —
//     dane poprawione w locie; jedno przejście czyszczenia - 20 zapisów zwrotnych, 3 błędy podwójne wykryte;
//     potem odczyty bez flag. Zapis użytkownika w trakcie czyszczenia tego samego adresu ma pierwszeństwo.
`timescale 1ns / 1ps
`default_nettype none

module tb_ecc;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    // ---------------------------------------------------------------- A
    logic  [31:0] d;
    logic  [38:0] blad;
    logic [38:0] c;
    logic [31:0] dd;
    logic        pop, podw;
    secded_koder   u_k (.d(d), .c(c));
    secded_dekoder u_d (.c(c ^ blad), .d(dd), .poprawiony(pop), .podwojny(podw));

    logic [31:0] s = 32'd29;
    function [31:0] lcg(input [31:0] x);
        lcg = x * 32'd1664525 + 32'd1013904223;
    endfunction

    int n;
    int i;
    int j;
    int a_czyste = 0;
    int a_poj = 0;
    int a_podw = 0;
    int a_bl = 0;

    // ---------------------------------------------------------------- B
    logic         we = 1'b0;
    logic         rd = 1'b0;
    logic         czysc_en = 1'b0;
    logic         wstrzyk = 1'b0;
    logic  [5:0]  adr = 6'd0;
    logic  [5:0]  wstrzyk_adr = 6'd0;
    logic  [31:0] wdane = 32'd0;
    logic  [38:0] wstrzyk_maska = 39'd0;
    logic [31:0] rdane;
    logic        r_pop, r_podw, r_wazne;
    logic [5:0]  czysc_adr;
    logic [15:0] skorygowane, podwojne;
    pamiec_ecc #(.SLOWA(64)) u_p (.clk(clk), .rst(rst), .we(we), .rd(rd), .adr(adr), .wdane(wdane),
        .rdane(rdane), .r_poprawiony(r_pop), .r_podwojny(r_podw), .r_wazne(r_wazne), .czysc_en(czysc_en),
        .czysc_adr(czysc_adr), .skorygowane(skorygowane), .podwojne(podwojne), .wstrzyk(wstrzyk),
        .wstrzyk_adr(wstrzyk_adr), .wstrzyk_maska(wstrzyk_maska));

    logic [31:0] wzor [0:63];

    task zapisz(input [5:0] a, input [31:0] v);
        begin
            @(negedge clk) begin we = 1'b1; adr = a; wdane = v; end
            @(negedge clk) we = 1'b0;
            wzor[a] = v;
        end
    endtask

    task psuj(input [5:0] a, input [38:0] m);
        begin
            @(negedge clk) begin wstrzyk = 1'b1; wstrzyk_adr = a; wstrzyk_maska = m; end
            @(negedge clk) wstrzyk = 1'b0;
        end
    endtask

    logic [31:0] od;
    logic        op, opd;
    task czytaj(input [5:0] a);
        begin
            @(negedge clk) begin rd = 1'b1; adr = a; end
            @(negedge clk) begin rd = 1'b0; od = rdane; op = r_pop; opd = r_podw; end
        end
    endtask

    int b_flagi = 0;
    int b_dane = 0;
    initial begin
        blad = 39'd0;
        for (n = 0; n < 200; n = n + 1) begin
            s = lcg(s); d = s;
            blad = 39'd0; #1;
            if (dd !== d || pop || podw) a_bl = a_bl + 1; else a_czyste = a_czyste + 1;
            for (i = 0; i < 39; i = i + 1) begin
                blad = 39'd1 << i; #1;
                if (dd !== d || !pop || podw) a_bl = a_bl + 1; else a_poj = a_poj + 1;
            end
            for (i = 0; i < 39; i = i + 1)
                for (j = i + 1; j < 39; j = j + 1) begin
                    blad = (39'd1 << i) | (39'd1 << j); #1;
                    if (!podw || pop) a_bl = a_bl + 1; else a_podw = a_podw + 1;
                end
        end
        $display("A: slow 200 - bez bledu %0d, bledy pojedyncze poprawione %0d/7800, podwojne wykryte %0d/148200, niezgodnosci %0d",
                 a_czyste, a_poj, a_podw, a_bl);
        if (a_bl != 0 || a_poj != 7800 || a_podw != 148200) errors = errors + 1;

        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 64; i = i + 1) begin s = lcg(s); zapisz(i[5:0], s); end
        for (i = 0; i < 20; i = i + 1) psuj(i[5:0], 39'd1 << (i % 39));
        for (i = 40; i < 43; i = i + 1) psuj(i[5:0], (39'd1 << (i % 39)) | (39'd1 << ((i + 7) % 39)));
        czytaj(6'd5);
        if (od !== wzor[5] || !op || opd) begin $display("FAIL: odczyt slowa z bledem pojedynczym"); errors = errors + 1; end
        czytaj(6'd41);
        if (!opd) begin $display("FAIL: brak flagi bledu podwojnego"); errors = errors + 1; end

        @(negedge clk) czysc_en = 1'b1;                 // dokładnie jedno przejście: 64 adresy
        repeat (64) @(negedge clk);
        czysc_en = 1'b0;
        repeat (3) @(negedge clk);
        $display("B: jedno przejscie czyszczenia - zapisow zwrotnych %0d (oczekiwane 20), bledow podwojnych %0d (oczekiwane 3)",
                 skorygowane, podwojne);
        if (skorygowane != 16'd20 || podwojne != 16'd3) errors = errors + 1;
        for (i = 0; i < 64; i = i + 1) begin
            czytaj(i[5:0]);
            if (i >= 40 && i < 43) begin
                if (!opd) b_flagi = b_flagi + 1;
            end else begin
                if (op || opd) b_flagi = b_flagi + 1;
                if (od !== wzor[i]) b_dane = b_dane + 1;
            end
        end
        $display("B: po czyszczeniu - slow z flagami nieoczekiwanymi %0d, z blednymi danymi %0d", b_flagi, b_dane);
        if (b_flagi != 0 || b_dane != 0) errors = errors + 1;

        // zapis użytkownika w takcie odczytu czyszczenia (adres 30) i w takcie zapisu zwrotnego (adres 31)
        psuj(6'd30, 39'd1 << 3);
        psuj(6'd31, 39'd1 << 9);
        @(negedge clk) czysc_en = 1'b1;
        while (czysc_adr != 6'd30) @(negedge clk);
        we = 1'b1; adr = 6'd30; wdane = 32'hA5A5_0030; wzor[30] = 32'hA5A5_0030;   // ten sam takt co odczyt 30
        @(negedge clk) begin adr = 6'd31; wdane = 32'hA5A5_0031; wzor[31] = 32'hA5A5_0031; end // takt zapisu zwrotnego 30 / odczytu 31
        @(negedge clk) we = 1'b0;
        repeat (70) @(negedge clk);
        czysc_en = 1'b0;
        repeat (3) @(negedge clk);
        czytaj(6'd30);
        if (od !== 32'hA5A5_0030 || op || opd) begin $display("FAIL: czyszczenie nadpisalo zapis uzytkownika (30)"); errors = errors + 1; end
        czytaj(6'd31);
        if (od !== 32'hA5A5_0031 || op || opd) begin $display("FAIL: czyszczenie nadpisalo zapis uzytkownika (31)"); errors = errors + 1; end
        $display("B: zapisy uzytkownika w trakcie czyszczenia zachowane: adres 30 = 0x%08h, 31 = 0x%08h", wzor[30], wzor[31]);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

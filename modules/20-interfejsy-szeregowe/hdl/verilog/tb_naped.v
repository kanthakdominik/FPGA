// Testbench 20.04: pwm_mostek, serwo i enkoder.
//   pwm_mostek (OKRES = 100, MARTWY = 5): dla wypełnień 0, 1, 3, 10, 50, 99, 100 — czasy włączenia wyjść
//   górnego i dolnego w okresie (2·wyp − MARTWY i 2·(OKRES − wyp) − MARTWY, ucięte w zerze), nigdy oba
//   naraz, przerwa między nimi >= MARTWY; zmiana wypełnienia w środku okresu działa od następnego okresu.
//   serwo (zegar 1 MHz): pozycje 0, 128, 255 -> impulsy 1000, 1502, 2000 µs, okres 20 000 µs.
//   enkoder (FILTR = 8): 300 kroków w przód i 120 w tył z drganiami styków krótszymi od filtra,
//   pozycja i kierunek; 5 skoków niedozwolonych (zmiana A i B naraz) -> bledy = 5.
`timescale 1ns / 1ps
`default_nettype none

module tb_naped;
    reg clk = 1'b0, zatrzymaj = 1'b0;
    always begin                                           // zegar 50 MHz zatrzymywany na czas testu serwa
        if (zatrzymaj) wait (!zatrzymaj);
        #10 clk = ~clk;
    end
    reg rst = 1'b1;
    integer errors = 0, i, k;

    // ---------------- PWM
    localparam OKRES = 100, MARTWY = 5;
    reg  [9:0] wyp = 10'd0;
    wire       gora, dol, poczatek;
    pwm_mostek #(.W(10), .OKRES(OKRES), .MARTWY(MARTWY)) u_pwm (.clk(clk), .rst(rst), .wyp(wyp), .gora(gora),
        .dol(dol), .poczatek(poczatek));
    integer n_g = 0, n_d = 0, przerwa = 0, min_przerwa = 1000, okresy = 0, wg [0:15], wd [0:15];
    always @(posedge clk) if (!rst) begin
        if (gora && dol) begin $display("oba wyjscia wlaczone!"); errors = errors + 1; end
        if (!gora && !dol) przerwa = przerwa + 1;
        else begin
            if (przerwa > 0 && przerwa < min_przerwa) min_przerwa = przerwa;
            przerwa = 0;
        end
        if (gora) n_g = n_g + 1;
        if (dol)  n_d = n_d + 1;
        if (poczatek) begin
            if (okresy < 16) begin wg[okresy] = n_g; wd[okresy] = n_d; end
            okresy = okresy + 1;
            n_g = 0; n_d = 0;
        end
    end

    // czas włączenia wyjścia w okresie; bez przełączeń (0 % i 100 %) nie ma czasu martwego
    function integer oczek_g(input integer w);
        if (w == 0)          oczek_g = 0;
        else if (w == OKRES) oczek_g = 2 * OKRES;
        else                 oczek_g = (2 * w - MARTWY > 0) ? 2 * w - MARTWY : 0;
    endfunction

    // ---------------- serwo (osobny zegar 1 MHz)
    reg clk1 = 1'b0;
    always #500 clk1 = ~clk1;
    reg  [7:0] poz = 8'd0;
    wire       imp;
    serwo #(.CLK_HZ(1_000_000)) u_serwo (.clk(clk1), .rst(rst), .pozycja(poz), .impuls(imp));
    realtime t_nar, t_poprz = 0.0;
    real     szer [0:5], okr [0:5];
    integer  n_imp = 0;
    always @(posedge imp) begin
        if (n_imp > 0 && n_imp <= 6) okr[n_imp - 1] = $realtime - t_poprz;
        t_poprz = $realtime;
        t_nar = $realtime;
    end
    always @(negedge imp) begin
        if (n_imp < 6) szer[n_imp] = $realtime - t_nar;
        n_imp = n_imp + 1;
    end

    // ---------------- enkoder
    reg        ea = 1'b0, eb = 1'b0;
    wire [15:0] pozycja;
    wire        kierunek;
    wire [7:0]  bledy;
    enkoder #(.W(16), .FILTR(8)) u_enk (.clk(clk), .rst(rst), .a(ea), .b(eb), .pozycja(pozycja),
        .kierunek(kierunek), .bledy(bledy));
    reg [1:0] faza_e = 2'd0;                               // indeks w sekwencji Graya
    function [1:0] gray(input [1:0] f);
        case (f) 2'd0: gray = 2'b00; 2'd1: gray = 2'b10; 2'd2: gray = 2'b11; default: gray = 2'b01; endcase
    endfunction
    // jeden krok z drganiami: zmieniany sygnał przełącza się kilka razy po 60 ns (3 takty < FILTR)
    task krok(input integer w_przod);
        reg [1:0] nowy, stary;
        integer q;
        begin
            stary = gray(faza_e);
            faza_e = w_przod ? faza_e + 1 : faza_e - 1;
            nowy = gray(faza_e);
            for (q = 0; q < 3; q = q + 1) begin
                {ea, eb} = nowy; #60;
                {ea, eb} = stary; #60;
            end
            {ea, eb} = nowy;
            #(400 + ($random & 255));
        end
    endtask

    initial begin
        repeat (5) @(negedge clk);
        rst = 1'b0;
        // PWM: kolejne wypełnienia, po 3 okresy każde
        for (k = 0; k < 7; k = k + 1) begin
            case (k) 0: wyp = 0; 1: wyp = 1; 2: wyp = 3; 3: wyp = 10; 4: wyp = 50; 5: wyp = 99; default: wyp = 100; endcase
            okresy = 0;
            wait (okresy == 4);
            // okres nr 0 — niepełny, ze starym wypełnieniem; nr 1 zaczyna się od połowy impulsu górnego, którego
            // czas martwy wypadł jeszcze przy starym wypełnieniu; nr 2 — w pełni ustalony
            if (wg[2] != oczek_g(wyp) || wd[2] != oczek_g(OKRES - wyp)) begin
                $display("PWM wyp=%0d: gora %0d (oczekiwano %0d), dol %0d (oczekiwano %0d)", wyp, wg[2], oczek_g(wyp),
                         wd[2], oczek_g(OKRES - wyp));
                errors = errors + 1;
            end
        end
        // zmiana wypełnienia w połowie okresu: okres bieżący bez zmian
        wyp = 30;
        okresy = 0;
        wait (okresy == 1);
        repeat (OKRES) @(negedge clk);
        wyp = 70;
        wait (okresy == 3);
        if (wg[1] != oczek_g(30) || wg[2] != oczek_g(70)) begin
            $display("PWM: zmiana w trakcie okresu: %0d, %0d", wg[1], wg[2]); errors = errors + 1;
        end
        $display("PWM: najkrotsza przerwa miedzy wyjsciami %0d taktow (MARTWY = %0d)", min_przerwa, MARTWY);
        if (min_przerwa < MARTWY) errors = errors + 1;

        // serwo (zegar 50 MHz zatrzymany — niepotrzebny przez 80 ms symulacji)
        zatrzymaj = 1'b1;
        poz = 8'd0;   #20_000_000;
        poz = 8'd128; #20_000_000;
        poz = 8'd255; #40_000_000;
        zatrzymaj = 1'b0;
        // impuls nr 1 zaczyna się tuż przed zmianą pozycji (pozycja pobierana na początku okresu)
        $display("serwo: impulsy %0.0f, %0.0f, %0.0f us; okres %0.0f us", szer[1] / 1000, szer[2] / 1000,
                 szer[3] / 1000, okr[1] / 1000);
        if (szer[1] != 1_000_000.0 || szer[2] != 1_502_000.0 || szer[3] != 2_000_000.0 || okr[1] != 20_000_000.0)
            errors = errors + 1;

        // enkoder
        for (i = 0; i < 300; i = i + 1) krok(1);
        #2000;
        if (pozycja != 16'd300 || !kierunek) begin $display("enkoder: %0d po 300 w przod", $signed(pozycja)); errors = errors + 1; end
        for (i = 0; i < 120; i = i + 1) krok(0);
        #2000;
        if (pozycja != 16'd180 || kierunek) begin $display("enkoder: %0d po 120 w tyl", $signed(pozycja)); errors = errors + 1; end
        for (i = 0; i < 5; i = i + 1) begin                  // skok o dwie fazy: A i B naraz
            faza_e = faza_e + 2;
            {ea, eb} = gray(faza_e);
            #1000;
        end
        $display("enkoder: pozycja %0d, bledy %0d", $signed(pozycja), bledy);
        if (bledy != 8'd5 || pozycja != 16'd180) errors = errors + 1;

        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

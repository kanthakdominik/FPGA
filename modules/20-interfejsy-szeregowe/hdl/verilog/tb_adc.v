// Testbench 20.06: adc_sekwencer z modelem rdzenia „ADC Control Core Only” (przyjęcie rozkazu impulsem
// command_ready, odpowiedź po czasie przetwarzania KONW taktów, bez przeciwciśnienia), adc_srednia
// i tsd_temperatura.
//   sekwencer: kanały 1, 3, 17 na zmianę; każda odpowiedź trafia do właściwego pola wyników,
//              kolejność kanałów w rozkazach zgodna z listą, 300 konwersji,
//   srednia:   K = 6 na kanale 1 (próbki 1000 + szum ±7) — wynik 1000…1003,
//   tsd:       punkty z tabeli UG (3798 -> −40, 3677 -> 25, 3595 -> 60, 3431 -> 125, 3690 -> 20),
//              kody spoza tabeli i monotoniczność dla wszystkich kodów 3300…3999.
`timescale 1ns / 1ps
`default_nettype none

module tb_adc;
    localparam KONW = 20;
    reg clk = 1'b0;
    always #10 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0, i;

    wire        c_valid, c_sop, c_eop, nowy;
    wire [4:0]  c_kanal, kanal;
    wire [11:0] dane;
    wire [35:0] wyniki;
    reg         c_ready = 1'b0, r_valid = 1'b0;
    reg  [4:0]  r_kanal = 5'd0;
    reg  [11:0] r_dane = 12'd0;
    adc_sekwencer #(.LICZBA(3), .KANALY({5'd17, 5'd3, 5'd1})) dut (.clk(clk), .rst(rst), .wlacz(1'b1),
        .command_valid(c_valid), .command_channel(c_kanal), .command_startofpacket(c_sop),
        .command_endofpacket(c_eop), .command_ready(c_ready), .response_valid(r_valid),
        .response_channel(r_kanal), .response_data(r_dane), .wyniki(wyniki), .nowy(nowy), .kanal(kanal),
        .dane(dane));

    // model rdzenia: przyjmuje rozkaz (ready przez takt), po KONW taktach odpowiedź, potem kolejny rozkaz
    integer   t = 0, n_konw = 0, szum;
    reg       zajety = 1'b0;
    reg [4:0] kan_konw = 5'd0;
    function [11:0] probka(input [4:0] k, input integer n);
        case (k)
            5'd1:    probka = 12'd1000 + (n % 8);          // „szum” 0…7
            5'd3:    probka = 12'd2500;
            default: probka = 12'd3677;                    // termodioda: 25 °C
        endcase
    endfunction
    always @(posedge clk) begin
        c_ready <= 1'b0;
        r_valid <= 1'b0;
        if (!rst) begin
            if (!zajety && c_valid && !c_ready) begin
                c_ready  <= 1'b1;                          // przyjęcie w tym takcie (valid && ready)
                kan_konw <= c_kanal;
                zajety   <= 1'b1;
                t        <= KONW;
            end else if (zajety) begin
                if (t == 0) begin
                    r_valid <= 1'b1;
                    r_kanal <= kan_konw;
                    r_dane  <= probka(kan_konw, n_konw);
                    n_konw  <= n_konw + 1;
                    zajety  <= 1'b0;
                end else
                    t <= t - 1;
            end
        end
    end

    // sprawdzanie kolejności rozkazów i wyników
    integer   n_rozk = 0, n_odp = 0;
    reg [4:0] lista [0:2];
    initial begin lista[0] = 5'd1; lista[1] = 5'd3; lista[2] = 5'd17; end
    always @(posedge clk) begin
        if (c_valid && c_ready) begin
            if (c_kanal !== lista[n_rozk % 3]) begin
                if (errors < 10) $display("rozkaz %0d: kanal %0d, oczekiwano %0d", n_rozk, c_kanal, lista[n_rozk % 3]);
                errors = errors + 1;
            end
            n_rozk = n_rozk + 1;
        end
        if (nowy) n_odp = n_odp + 1;
    end

    // średnia z kanału 1
    wire        s_wazne;
    wire [11:0] srednia;
    adc_srednia #(.W(12), .K(6)) u_sr (.clk(clk), .rst(rst), .wazne(nowy && kanal == 5'd1), .dane(dane),
        .wyj_wazne(s_wazne), .srednia(srednia));
    integer n_sr = 0;
    always @(posedge clk) if (s_wazne) begin
        n_sr = n_sr + 1;
        if (srednia < 12'd1000 || srednia > 12'd1007) begin $display("srednia %0d", srednia); errors = errors + 1; end
    end

    // termodioda
    reg  [11:0] kod = 12'd0;
    wire [7:0]  tc;
    tsd_temperatura u_tsd (.clk(clk), .kod(kod), .temp_c(tc));
    task sprawdz_tsd(input [11:0] k, input integer oczek);
        begin
            @(negedge clk) kod = k;
            @(negedge clk);
            if ($signed(tc) != oczek) begin $display("TSD kod %0d: %0d C, oczekiwano %0d", k, $signed(tc), oczek); errors = errors + 1; end
        end
    endtask

    integer poprz;
    initial begin
        repeat (5) @(negedge clk);
        rst = 1'b0;
        wait (n_odp == 300);
        @(negedge clk);
        $display("sekwencer: %0d rozkazow, %0d odpowiedzi; wyniki: kanal 1 = %0d, kanal 3 = %0d, kanal 17 = %0d; srednich %0d",
                 n_rozk, n_odp, wyniki[11:0], wyniki[23:12], wyniki[35:24], n_sr);
        if (wyniki[11:0] < 12'd1000 || wyniki[11:0] > 12'd1007 || wyniki[23:12] != 12'd2500 ||
            wyniki[35:24] != 12'd3677 || n_sr < 1) errors = errors + 1;

        sprawdz_tsd(12'd3798, -40);
        sprawdz_tsd(12'd3677, 25);
        sprawdz_tsd(12'd3595, 60);
        sprawdz_tsd(12'd3431, 125);
        sprawdz_tsd(12'd3690, 20);                    // między 19 °C (3695) a 20 °C (3688): bliżej 3688
        sprawdz_tsd(12'd3200, 125);
        sprawdz_tsd(12'd4000, -40);
        poprz = 200;
        for (i = 3300; i < 4000; i = i + 1) begin      // temperatura nierosnąca ze wzrostem kodu
            @(negedge clk) kod = i;
            @(negedge clk);
            if ($signed(tc) > poprz) begin $display("TSD niemonotoniczna przy kodzie %0d", i); errors = errors + 1; end
            poprz = $signed(tc);
        end

        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

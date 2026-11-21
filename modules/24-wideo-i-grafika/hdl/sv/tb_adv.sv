// Testbench (SystemVerilog) 24.02: adv7513_konfig z modelem odbiornika I2C (adres 0x39). Model rejestruje zapisy (rejestr, wartość),
// potwierdza bajty (ACK) i mierzy czasy magistrali: okres i stany SCL, t_HD;STA, t_SU;STO, t_BUF (wymagania
// trybu standardowego 100 kHz: 4,0 / 4,7 µs). Przebiegi: seria po resecie, seria cykliczna (OKRES), seria
// z niewłaściwym adresem odbiornika (NACK -> blad), seria na żądanie (start) po przywróceniu adresu.
`timescale 1ns / 1ps
`default_nettype none

module tb_adv;
    logic clk = 1'b0;
    always #125 clk = ~clk;                       // 4 MHz: ćwierć okresu SCL = 10 taktów = 2,5 µs
    logic rst = 1'b1;
    int errors = 0;

    logic  start = 1'b0;
    logic zajety, gotowe, blad, scl_o, sda_o;
    logic  s_sda = 1'b1;                            // odbiornik: 0 = ściąga SDA (ACK)
    logic scl;
    assign scl = scl_o;
    logic sda;
    assign sda = sda_o & s_sda;

    adv7513_konfig #(.F_CLK(4000000), .F_I2C(100000), .OKRES(30000)) dut (
        .clk(clk), .rst(rst), .start(start), .zajety(zajety), .gotowe(gotowe), .blad(blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(sda));

    // oczekiwana tablica — przepisana z dokumentacji, niezależnie od kodu modułu
    logic [15:0] ocz [0:16];
    initial begin
        ocz[0]  = 16'h4110; ocz[1]  = 16'h9803; ocz[2]  = 16'h9AE0; ocz[3]  = 16'h9C30; ocz[4]  = 16'h9D61;
        ocz[5]  = 16'hA2A4; ocz[6]  = 16'hA3A4; ocz[7]  = 16'hE0D0; ocz[8]  = 16'hF900; ocz[9]  = 16'h1500;
        ocz[10] = 16'h1630; ocz[11] = 16'h1700; ocz[12] = 16'h1846; ocz[13] = 16'hAF16; ocz[14] = 16'hBA60;
        ocz[15] = 16'hD6C0; ocz[16] = 16'h96F6;
    end

    // ---- model odbiornika I2C
    logic  [6:0]  adr_modelu = 7'h39;
    logic         akt = 1'b0, pierwsze = 1'b0;
    int     bity = 0, nr_b = 0, n_zap = 0, n_start = 0, n_stop = 0, bl_tab = 0;
    logic  [7:0]  bajt = 8'd0, rej = 8'd0;
    realtime    t_scl_g = 0, t_scl_d = 0, t_start = 0, t_stop = -1.0e9;
    realtime    min_h = 1.0e9, min_l = 1.0e9, min_hdsta = 1.0e9, min_susto = 1.0e9, min_buf = 1.0e9, min_okr = 1.0e9;
    realtime    t_g_pop = 0;

    always @(negedge sda) if (scl === 1'b1 && !rst) begin       // START
        n_start = n_start + 1;
        if ($realtime - t_stop < min_buf) min_buf = $realtime - t_stop;
        t_start = $realtime; akt = 1'b1; pierwsze = 1'b1; bity = 0; nr_b = 0;
    end
    always @(posedge sda) if (scl === 1'b1 && !rst) begin       // STOP
        n_stop = n_stop + 1;
        t_stop = $realtime;
        if (t_stop - t_scl_g < min_susto) min_susto = t_stop - t_scl_g;
        akt = 1'b0;
    end
    always @(posedge scl) begin
        if (t_scl_d > 0 && $realtime - t_scl_d < min_l && !pierwsze) min_l = $realtime - t_scl_d;
        if (t_g_pop > 0 && $realtime - t_g_pop < min_okr) min_okr = $realtime - t_g_pop;
        t_g_pop = $realtime;
        t_scl_g = $realtime;
        if (akt && bity < 8) begin bajt = {bajt[6:0], sda}; bity = bity + 1; end
    end
    always @(negedge scl) begin
        if (pierwsze) begin
            if ($realtime - t_start < min_hdsta) min_hdsta = $realtime - t_start;
            pierwsze = 1'b0;
        end else if ($realtime - t_scl_g < min_h) min_h = $realtime - t_scl_g;
        t_scl_d = $realtime;
        if (akt && bity == 8) begin                               // po 8 bitach: decyzja o ACK
            bity = 9;
            case (nr_b)
                0: if (bajt == {adr_modelu, 1'b0}) s_sda = 1'b0; else akt = 1'b0;
                1: begin rej = bajt; s_sda = 1'b0; end
                default: begin
                    if (n_zap < 34 && {rej, bajt} != ocz[n_zap % 17]) begin
                        if (bl_tab < 5) $display("zapis %0d: %h <- %h, oczekiwano %h", n_zap, rej, bajt, ocz[n_zap % 17]);
                        bl_tab = bl_tab + 1;
                    end
                    n_zap = n_zap + 1;
                    s_sda = 1'b0;
                end
            endcase
        end else if (bity == 9) begin                             // koniec taktu ACK
            s_sda = 1'b1; bity = 0; nr_b = nr_b + 1;
        end
    end

    realtime t0, t_serii;
    int  n_przed;
    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        // 1. seria po resecie
        t0 = $realtime;
        @(posedge zajety); @(negedge zajety);
        t_serii = $realtime - t0;
        $display("seria po resecie: %0d zapisow, %.2f ms, gotowe = %b, blad = %b", n_zap, t_serii / 1.0e6, gotowe, blad);
        if (n_zap != 17 || !gotowe || blad) errors = errors + 1;
        // 2. seria cykliczna
        @(posedge zajety); @(negedge zajety);
        $display("seria cykliczna: razem %0d zapisow, gotowe = %b", n_zap, gotowe);
        if (n_zap != 34 || !gotowe || blad) errors = errors + 1;
        // 3. odbiornik pod innym adresem: brak ACK
        adr_modelu = 7'h3D;
        n_przed = n_zap;
        @(posedge zajety); @(negedge zajety);
        $display("odbiornik pod adresem 0x3D: zapisow %0d, gotowe = %b, blad = %b", n_zap - n_przed, gotowe, blad);
        if (n_zap != n_przed || gotowe || !blad) errors = errors + 1;
        // 4. adres przywrócony, seria na żądanie
        adr_modelu = 7'h39;
        @(negedge clk) start = 1'b1;
        @(negedge clk) start = 1'b0;
        @(posedge zajety); @(negedge zajety);
        $display("seria na zadanie: zapisow %0d, gotowe = %b, blad = %b", n_zap - n_przed, gotowe, blad);
        if (n_zap - n_przed != 17 || !gotowe || blad) errors = errors + 1;
        $display("START %0d, STOP %0d; bledow w tablicy %0d", n_start, n_stop, bl_tab);
        $display("SCL: okres min %.2f us (%.1f kHz), stan wysoki min %.2f us, niski min %.2f us",
                 min_okr / 1000.0, 1.0e6 / min_okr, min_h / 1000.0, min_l / 1000.0);
        $display("t_HD;STA min %.2f us, t_SU;STO min %.2f us, t_BUF min %.2f us",
                 min_hdsta / 1000.0, min_susto / 1000.0, min_buf / 1000.0);
        if (bl_tab != 0 || n_start != n_stop) errors = errors + 1;
        if (min_okr < 10000.0 || min_h < 4000.0 || min_l < 4700.0) errors = errors + 1;
        if (min_hdsta < 4000.0 || min_susto < 4000.0 || min_buf < 4700.0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

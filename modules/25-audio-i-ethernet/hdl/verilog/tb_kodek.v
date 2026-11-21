// Testbench 25.01: i2c_zapisy z tablicą konfiguracji kodeka TLV320AIC3254 (adres 0x18) i modelem kodeka
// z rejestrem strony (rejestr 0 wybiera stronę, osobne rejestry stron 0 i 1). Sprawdza: wszystkie wpisy z ACK,
// przerwę po programowym resecie (wpis 0xFF), zawartość kluczowych rejestrów na stronach 0 i 1 po serii,
// końcową stronę 0 i czas serii.
`timescale 1ns / 1ps
`default_nettype none

module tb_kodek;
    reg clk = 1'b0;
    always #40 clk = ~clk;                        // 12,5 MHz
    reg rst = 1'b1;
    integer errors = 0;

    localparam integer N = 42;
    localparam [16*N-1:0] TAB = {
        16'h00_00, 16'h01_01, 16'hFF_01,                                         // strona 0, reset, przerwa
        16'h0B_81, 16'h0C_82, 16'h0D_00, 16'h0E_80, 16'h12_81, 16'h13_82, 16'h14_80, // NDAC, MDAC, DOSR, NADC, MADC, AOSR
        16'h1B_20, 16'h3C_08, 16'h3D_01,                                         // I2S 24 bity, PRB_P8, PRB_R1
        16'h00_01, 16'h01_08, 16'h02_00, 16'h7B_01, 16'h14_25, 16'h0A_00,         // strona 1: zasilanie analogowe
        16'h0C_08, 16'h0D_08, 16'h0E_08, 16'h0F_08, 16'h03_00, 16'h04_00,         // DAC -> HPL/HPR/LOL/LOR
        16'h10_00, 16'h11_00, 16'h12_00, 16'h13_00, 16'h09_3C, 16'h47_32,         // wzmocnienia 0 dB, wyjścia on
        16'h34_40, 16'h36_40, 16'h37_40, 16'h39_40, 16'h3B_0C, 16'h3C_0C,         // IN1 -> MICPGA, 6 dB
        16'h00_00, 16'h3F_D6, 16'h40_00, 16'h51_C0, 16'h52_00                     // strona 0: DAC, ADC on
    };

    reg  start = 1'b0;
    wire zajety, gotowe, blad, scl_o, sda_o;
    reg  s_sda = 1'b1;
    wire scl = scl_o;
    wire sda = sda_o & s_sda;
    i2c_zapisy #(.F_CLK(12500000), .F_I2C(100000), .OKRES(0), .ADRES(7'h18), .N(N), .TAB(TAB)) dut (
        .clk(clk), .rst(rst), .start(start), .zajety(zajety), .gotowe(gotowe), .blad(blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(sda));

    // ---- model kodeka
    reg  [7:0] mem0 [0:127];
    reg  [7:0] mem1 [0:127];
    reg  [7:0] strona = 8'd0;
    reg        akt = 1'b0;
    integer    bity = 0, nr_b = 0, n_zap = 0, i;
    reg  [7:0] bajt = 0, rej = 0;
    realtime   t_stop = 0, max_przerwa = 0, t_reset = 0;
    always @(negedge sda) if (scl === 1'b1 && !rst) begin
        if (t_stop > 0 && $realtime - t_stop > max_przerwa) max_przerwa = $realtime - t_stop;
        akt = 1'b1; bity = 0; nr_b = 0;
    end
    always @(posedge sda) if (scl === 1'b1 && !rst) begin akt = 1'b0; t_stop = $realtime; end
    always @(posedge scl) if (akt && bity < 8) begin bajt = {bajt[6:0], sda}; bity = bity + 1; end
    always @(negedge scl) begin
        if (akt && bity == 8) begin
            bity = 9;
            case (nr_b)
                0: if (bajt == {7'h18, 1'b0}) s_sda = 1'b0; else akt = 1'b0;
                1: begin rej = bajt; s_sda = 1'b0; end
                default: begin
                    n_zap = n_zap + 1;
                    if (rej == 8'd0) strona = bajt;
                    else if (strona == 8'd0) mem0[rej[6:0]] = bajt;
                    else mem1[rej[6:0]] = bajt;
                    if (rej == 8'd1 && strona == 8'd0 && bajt == 8'h01) t_reset = $realtime;
                    s_sda = 1'b0;
                end
            endcase
        end else if (bity == 9) begin
            s_sda = 1'b1; bity = 0; nr_b = nr_b + 1;
        end
    end

    task spr(input integer str, input [7:0] r, input [7:0] w);
        reg [7:0] v;
        begin
            v = (str == 0) ? mem0[r[6:0]] : mem1[r[6:0]];
            if (v !== w) begin
                $display("strona %0d rejestr %h = %h, oczekiwano %h", str, r, v, w);
                errors = errors + 1;
            end
        end
    endtask

    realtime t0;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin mem0[i] = 8'hXX; mem1[i] = 8'hXX; end
        repeat (5) @(posedge clk);
        rst = 1'b0;
        t0 = $realtime;
        @(posedge zajety); @(negedge zajety);
        $display("seria: %0d zapisow w %.2f ms, gotowe = %b, blad = %b, strona koncowa %0d", n_zap, ($realtime - t0) / 1.0e6,
                 gotowe, blad, strona);
        $display("najdluzsza przerwa miedzy transakcjami (po resecie kodeka): %.2f ms", max_przerwa / 1.0e6);
        if (n_zap != N - 1 || !gotowe || blad || strona != 0) errors = errors + 1;
        if (max_przerwa < 1.0e6) errors = errors + 1;                      // ≥ 1 ms po programowym resecie
        spr(0, 8'h0B, 8'h81); spr(0, 8'h0C, 8'h82); spr(0, 8'h0E, 8'h80); spr(0, 8'h12, 8'h81);
        spr(0, 8'h13, 8'h82); spr(0, 8'h14, 8'h80); spr(0, 8'h1B, 8'h20); spr(0, 8'h3F, 8'hD6);
        spr(0, 8'h40, 8'h00); spr(0, 8'h51, 8'hC0); spr(0, 8'h52, 8'h00);
        spr(1, 8'h01, 8'h08); spr(1, 8'h02, 8'h00); spr(1, 8'h09, 8'h3C); spr(1, 8'h0C, 8'h08);
        spr(1, 8'h0F, 8'h08); spr(1, 8'h14, 8'h25); spr(1, 8'h3B, 8'h0C); spr(1, 8'h3C, 8'h0C);
        spr(0, 8'h3C, 8'h08);                                               // ten sam numer, inna strona
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

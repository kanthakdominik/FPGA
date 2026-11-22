// Testbench 27.07: rv_soc — rdzeń potokowy rv_potok z pamięcią blokową (odczyt synchroniczny), rejestrami
// systemowymi i peryferium pwm_avl. Ten sam program i ten sam wzorzec co tb_rv_jedno: k-ty zapis rdzenia
// (porty mon_*) = k-ty zapis ISS, liczba instrukcji jak w ISS. Wypisuje CPI potoku (bąbelki load-use i kary
// skoków) i tekst z rejestru KONSOLA.
`timescale 1ns / 1ps
`default_nettype none

module tb_rv_soc;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;

    reg  [67:0] wzor [0:1023];
    reg  [31:0] liczby [0:1];
    wire [31:0] led, mon_adr, mon_dane;
    wire [3:0]  mon_strb;
    wire        pwm_wy, pwm_irq, koniec, znak_wazny, wycofana;
    wire [7:0]  znak;
    rv_soc #(.SLOWA(2048), .PLIK("test_prog.hex")) dut (.clk(clk), .rst(rst), .wej(32'h0000_000F), .led(led),
        .pwm_wy(pwm_wy), .pwm_irq(pwm_irq), .koniec(koniec), .znak(znak), .znak_wazny(znak_wazny),
        .wycofana(wycofana), .mon_adr(mon_adr), .mon_dane(mon_dane), .mon_strb(mon_strb));

    wire [31:0] maska = {{8{mon_strb[3]}}, {8{mon_strb[2]}}, {8{mon_strb[1]}}, {8{mon_strb[0]}}};
    integer k = 0, takty = 0, instr = 0, bl = 0, i;
    reg     stop = 1'b0, stop2 = 1'b0;          // stop2: takt później — zapis TOHOST opuszcza WB
    reg [8*64-1:0] konsola = 0;

    always @(posedge clk) if (!rst && !stop2) begin
        if (stop) stop2 = 1'b1;
        takty = takty + 1;
        if (wycofana) instr = instr + 1;
        if (znak_wazny) konsola = {konsola[8*63-1:0], znak};
        if (mon_strb != 4'd0) begin
            if ({mon_adr, mon_dane & maska, mon_strb} !== wzor[k]) begin
                if (bl < 5) $display("zapis %0d: adres 0x%08h dane 0x%08h maska %b, ISS: 0x%08h 0x%08h %b", k,
                                     mon_adr, mon_dane & maska, mon_strb, wzor[k][67:36], wzor[k][35:4], wzor[k][3:0]);
                bl = bl + 1;
            end
            k = k + 1;
            if (mon_adr == 32'h1000_0008) stop = 1'b1;
        end
    end

    initial begin
        $readmemh("test_zapisy.hex", wzor);
        $readmemh("test_liczby.hex", liczby);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        i = 0;
        while (!stop && i < 100000) begin @(negedge clk); i = i + 1; end
        repeat (4) @(negedge clk);                    // instrukcja zapisu TOHOST i wcześniejsze opuszczają WB
        $display("konsola: %0s", konsola);
        $display("LED = 0x%08h", led);
        $display("rv_potok: zapisow %0d (ISS %0d), niezgodnych %0d; instrukcji %0d (ISS %0d), taktow %0d, CPI = %0.3f",
                 k, liczby[0], bl, instr, liczby[1], takty, 1.0 * takty / instr);
        if (!stop || k != liczby[0] || bl != 0 || instr != liczby[1]) errors = errors + 1;
        if (led != 32'h55) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

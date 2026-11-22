// Symulacja programu w C na rv_soc (27.03, 27.07): wczytuje prog_c.hex (make), wypisuje tekst z rejestru KONSOLA
// i kończy się po zapisie pod TOHOST; PASS, gdy zapisana wartość = 1 (main zwróciło 0).
`timescale 1ns / 1ps
`default_nettype none

module sim_c;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;

    wire [31:0] led, mon_adr, mon_dane;
    wire [3:0]  mon_strb;
    wire        pwm_wy, pwm_irq, koniec, znak_wazny, wycofana;
    wire [7:0]  znak;
    rv_soc #(.SLOWA(2048), .PLIK("prog_c.hex")) dut (.clk(clk), .rst(rst), .wej(32'd0), .led(led),
        .pwm_wy(pwm_wy), .pwm_irq(pwm_irq), .koniec(koniec), .znak(znak), .znak_wazny(znak_wazny),
        .wycofana(wycofana), .mon_adr(mon_adr), .mon_dane(mon_dane), .mon_strb(mon_strb));

    integer takty = 0, instr = 0;
    reg [31:0] wynik = 32'd0;
    reg        stop = 1'b0;
    always @(posedge clk) if (!rst && !stop) begin
        takty = takty + 1;
        if (wycofana) instr = instr + 1;
        if (znak_wazny) $write("%c", znak);
        if (mon_strb != 4'd0 && mon_adr == 32'h1000_0008) begin
            wynik = mon_dane;
            stop = 1'b1;
        end
    end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        while (!stop && takty < 2000000) @(negedge clk);
        repeat (3) @(negedge clk);
        $display("instrukcji %0d, taktow %0d, CPI = %0.3f, LED = 0x%08h", instr, takty, 1.0 * takty / instr, led);
        if (stop && wynik == 32'd1) $display("PASS");
        else                        $display("FAIL: wynik 0x%08h", wynik);
        $finish;
    end
endmodule

`default_nettype wire

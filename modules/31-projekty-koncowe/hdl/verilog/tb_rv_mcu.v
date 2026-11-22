// Testbench projektu 6 (31.06): rv_mcu z programem mcu.S (mcu_sym.hex: OKRES_LED = 3000 taktów, PWM 10/40).
// UART 50 000 b/s przy 1 MHz (20 taktów na bit). Sprawdzane: powitanie, odstępy zmian LED z licznika
// i porównania (3000 taktów ± czas odpytywania flagi), wypełnienie PWM, echo z zamianą liter i dopisaniem LF, pożegnanie
// i zakończenie programu zapisem TOHOST.
`timescale 1ns / 1ps
`default_nettype none

module tb_rv_mcu;
    localparam integer BIT = 20;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg rx = 1'b1;
    wire tx, pwm_wy, koniec, wycofana;
    wire [31:0] led;
    integer errors = 0;
    integer takt = 0;
    integer instr = 0;
    always @(posedge clk) begin
        takt <= takt + 1;
        if (wycofana) instr <= instr + 1;
    end

    rv_mcu #(.SLOWA(1024), .PLIK("mcu_sym.hex"), .CLK_HZ(1_000_000), .BAUD(50_000)) dut (.clk(clk), .rst(rst),
        .wej(32'h0000_000F), .led(led), .uart_rx(rx), .uart_tx(tx), .pwm_wy(pwm_wy), .koniec(koniec),
        .wycofana(wycofana));

    task wyslij(input [7:0] b);
        integer i;
        begin
            rx = 1'b0; repeat (BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin rx = b[i]; repeat (BIT) @(posedge clk); end
            rx = 1'b1; repeat (BIT) @(posedge clk);
        end
    endtask

    reg [255:0] linia = 256'd0;
    reg [255:0] ostatnia = 256'd0;
    integer     nlinii = 0;
    reg [7:0]   b;
    integer     k;
    always begin
        @(negedge tx);
        repeat (BIT + BIT / 2) @(posedge clk);
        for (k = 0; k < 8; k = k + 1) begin b[k] = tx; repeat (BIT) @(posedge clk); end
        if (b == 8'h0A) begin ostatnia = linia; linia = 256'd0; nlinii = nlinii + 1; end
        else if (b != 8'h0D) linia = {linia[247:0], b};
    end

    task oczekuj(input [255:0] wzor);
        integer n0, t;
        begin
            n0 = nlinii; t = 0;
            while (nlinii == n0 && t < 50_000) begin @(posedge clk); t = t + 1; end
            if (nlinii == n0) begin $display("FAIL: brak linii \"%0s\"", wzor); errors = errors + 1; end
            else if (ostatnia !== wzor) begin
                $display("FAIL: linia \"%0s\", oczekiwana \"%0s\"", ostatnia, wzor); errors = errors + 1;
            end else
                $display("UART: \"%0s\"", ostatnia);
        end
    endtask

    // zmiany LED: odstępy w taktach
    reg [31:0] led_p = 32'd0;
    integer    t_led = -1;
    integer    odstep_min = 1 << 30;
    integer    odstep_max = 0;
    integer    zmian = 0;
    always @(posedge clk) begin
        led_p <= led;
        if (led != led_p && !rst) begin
            if (t_led >= 0) begin
                if (takt - t_led < odstep_min) odstep_min = takt - t_led;
                if (takt - t_led > odstep_max) odstep_max = takt - t_led;
            end
            t_led = takt;
            zmian = zmian + 1;
        end
    end

    integer i, wys;
    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        oczekuj("RISC-V MCU (31.06)");
        wys = 0;
        for (i = 0; i < 400; i = i + 1) begin @(posedge clk); if (pwm_wy) wys = wys + 1; end
        $display("PWM: %0d taktow stanu wysokiego na 400 (oczekiwane 100)", wys);
        if (wys != 100) errors = errors + 1;
        repeat (12_000) @(posedge clk);
        $display("LED: %0d zmian, odstepy %0d..%0d taktow (porownanie co 3000, odpytywanie flagi +- 40), LED = %0d", zmian, odstep_min,
                 odstep_max, led);
        if (zmian < 4 || odstep_min < 2960 || odstep_max > 3040) errors = errors + 1;
        wyslij("A"); wyslij("b"); wyslij("c"); wyslij(" "); wyslij("x"); wyslij("y"); wyslij("z");
        wyslij("!"); wyslij(8'h0D);
        oczekuj("ABC XYZ!");
        wyslij("q");
        oczekuj("");
        oczekuj("KONIEC");
        k = 0;
        while (!koniec && k < 20_000) begin @(posedge clk); k = k + 1; end
        if (!koniec) begin $display("FAIL: program nie zapisal TOHOST"); errors = errors + 1; end
        $display("instrukcji wykonanych: %0d w %0d taktach", instr, takt);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

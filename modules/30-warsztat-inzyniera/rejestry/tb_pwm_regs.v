// Test integracyjny (30.01): sterownik testowy używa wyłącznie stałych z wygenerowanego pwm_avl_regs.vh
// i sprawdza na rzeczywistym pwm_avl z modułu 27, że mapa rejestrów z opisu JSON zgadza się ze sprzętem:
// wartości po resecie, zapis i odczyt, flaga W1C i przerwanie.
//   iverilog -g2005 -I rejestry/wygenerowane rejestry/tb_pwm_regs.v ../27-procesory-i-soc/hdl/verilog/pwm_avl.v
`timescale 1ns / 1ps
`default_nettype none

module tb_pwm_regs;
    `include "pwm_avl_regs.vh"

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg         rst = 1'b1;
    reg  [1:0]  address = 2'd0;
    reg         read = 1'b0;
    reg         write = 1'b0;
    reg  [31:0] writedata = 32'd0;
    wire [31:0] readdata;
    wire        irq, pwm;
    integer     errors = 0;
    integer     i;
    integer     wysokie;
    reg  [31:0] v;

    pwm_avl dut (.clk(clk), .rst(rst), .address(address), .read(read), .write(write), .writedata(writedata),
                 .readdata(readdata), .irq(irq), .pwm(pwm));

    task zapisz(input [1:0] a, input [31:0] d);
        begin
            @(negedge clk); address = a; writedata = d; write = 1'b1;
            @(negedge clk); write = 1'b0;
        end
    endtask

    task czytaj(input [1:0] a, output [31:0] d);
        begin
            @(negedge clk); address = a; read = 1'b1;
            @(negedge clk); read = 1'b0; d = readdata;          // readLatency = 1
        end
    endtask

    task oczekuj(input [1:0] a, input [31:0] wart, input [8*20-1:0] co);
        begin
            czytaj(a, v);
            if (v !== wart) begin
                $display("FAIL: %0s: odczyt 0x%08h, oczekiwane 0x%08h", co, v, wart);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        oczekuj(PWM_AVL_STER_OFF,   PWM_AVL_STER_RESET,   "STER po resecie");
        oczekuj(PWM_AVL_OKRES_OFF,  PWM_AVL_OKRES_RESET,  "OKRES po resecie");
        oczekuj(PWM_AVL_WYPELN_OFF, PWM_AVL_WYPELN_RESET, "WYPELN po resecie");
        oczekuj(PWM_AVL_STATUS_OFF, PWM_AVL_STATUS_RESET, "STATUS po resecie");

        zapisz(PWM_AVL_OKRES_OFF, 32'd10);
        zapisz(PWM_AVL_WYPELN_OFF, 32'd3);
        oczekuj(PWM_AVL_OKRES_OFF, 32'd10, "OKRES");
        oczekuj(PWM_AVL_WYPELN_OFF, 32'd3, "WYPELN");
        zapisz(PWM_AVL_STER_OFF, (32'd1 << PWM_AVL_STER_WL_POZ));
        wysokie = 0;
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk); if (pwm) wysokie = wysokie + 1;
        end
        if (wysokie != 30) begin
            $display("FAIL: %0d taktow stanu wysokiego na 100 (oczekiwane 30)", wysokie);
            errors = errors + 1;
        end
        czytaj(PWM_AVL_STATUS_OFF, v);
        if (!v[PWM_AVL_STATUS_KONIEC_POZ]) begin
            $display("FAIL: KONIEC nie ustawiony po okresach"); errors = errors + 1;
        end
        if (irq) begin
            $display("FAIL: przerwanie bez PRZ"); errors = errors + 1;
        end
        zapisz(PWM_AVL_STER_OFF, (32'd1 << PWM_AVL_STER_WL_POZ) | (32'd1 << PWM_AVL_STER_PRZ_POZ));
        @(negedge clk);
        if (!irq) begin
            $display("FAIL: brak przerwania przy KONIEC i PRZ"); errors = errors + 1;
        end
        zapisz(PWM_AVL_STER_OFF, 32'd1 << PWM_AVL_STER_PRZ_POZ);           // stop, flaga zostaje
        zapisz(PWM_AVL_STATUS_OFF, 32'd1 << PWM_AVL_STATUS_KONIEC_POZ);    // W1C
        @(negedge clk);
        if (irq) begin
            $display("FAIL: zapis 1 do KONIEC nie skasowal przerwania"); errors = errors + 1;
        end
        czytaj(PWM_AVL_STATUS_OFF, v);
        if (v[PWM_AVL_STATUS_KONIEC_POZ] || v[PWM_AVL_STATUS_WYJSCIE_POZ]) begin
            $display("FAIL: STATUS po skasowaniu i wylaczeniu = 0x%08h", v); errors = errors + 1;
        end
        $display("mapa rejestrow z opisu JSON zgodna z pwm_avl: reset 4/4, zapis/odczyt, %0d/100 taktow wysokich, W1C i przerwanie", wysokie);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

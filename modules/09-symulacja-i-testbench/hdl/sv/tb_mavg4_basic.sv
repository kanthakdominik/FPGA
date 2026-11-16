// Pierwszy testbench mavg4: generator zegara, reset, zadania (task) podające pobudzenia
// na opadającym zboczu i ręcznie policzone wartości oczekiwane. Przypadki: odpowiedź na skok,
// zmiana znaku, zaokrąglenie w dół liczb ujemnych, wstrzymanie (in_valid = 0), reset w trakcie pracy.
`timescale 1ns / 1ps

module tb_mavg4_basic;
    localparam realtime T = 10ns;              // okres zegara

    logic              clk = 1'b0, rst = 1'b1, in_valid = 1'b0, out_valid;
    logic signed [7:0] x = '0, y;

    always #(T / 2) clk = ~clk;                // generator zegara: zmiana co pół okresu

    mavg4 dut (.*);

    int errors = 0;

    // reset przez n taktów; zmiany na opadającym zboczu — z dala od zbocza, na którym układ próbkuje
    task automatic reset(int n);
        @(negedge clk);
        rst      = 1'b1;
        in_valid = 1'b0;
        repeat (n) @(negedge clk);
        rst = 1'b0;
    endtask

    // jedna próbka i sprawdzenie wyjścia po zboczu
    task automatic send(logic signed [7:0] value, logic signed [7:0] expected);
        in_valid = 1'b1;
        x        = value;
        @(negedge clk);
        in_valid = 1'b0;
        if (out_valid !== 1'b1 || y !== expected) begin
            $display("t=%0t: x=%0d -> y=%0d out_valid=%b, oczekiwano %0d", $time, value, y, out_valid, expected);
            errors++;
        end
    endtask

    // takt bez danych: out_valid = 0, y bez zmian
    task automatic idle(logic signed [7:0] expected);
        @(negedge clk);
        if (out_valid !== 1'b0 || y !== expected) begin
            $display("t=%0t: bez danych y=%0d out_valid=%b, oczekiwano %0d i 0", $time, y, out_valid, expected);
            errors++;
        end
    endtask

    initial begin
        reset(2);
        idle(0);                               // po resecie: y = 0, out_valid = 0

        send(40, 10);                          // skok: (40 + 0 + 0 + 0) / 4
        send(40, 20);
        send(40, 30);
        send(40, 40);                          // okno pełne
        send(-40, 20);                         // zmiana znaku: (-40 + 40 + 40 + 40) / 4
        send(-40, 0);
        send(-40, -20);
        send(-40, -40);
        send(-1, -31);                         // -121 / 4 = -30,25 -> floor = -31 (nie -30!)
        idle(-31);                             // wstrzymanie: wyjście trzyma wartość
        idle(-31);
        send(127, 11);                         // okno {127, -1, -40, -40}: 46 / 4 = 11,5 -> 11
        reset(1);
        idle(0);                               // reset w trakcie pracy zeruje okno
        send(-128, -32);                       // wartość skrajna

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

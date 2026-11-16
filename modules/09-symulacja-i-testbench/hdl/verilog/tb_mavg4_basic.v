// Pierwszy testbench mavg4: generator zegara, reset, zadania (task) podające pobudzenia
// na opadającym zboczu i ręcznie policzone wartości oczekiwane. Przypadki: odpowiedź na skok,
// zmiana znaku, zaokrąglenie w dół liczb ujemnych, wstrzymanie (in_valid = 0), reset w trakcie pracy.
`default_nettype none
`timescale 1ns / 1ps

module tb_mavg4_basic;
    localparam real T = 10.0;                  // okres zegara [ns]

    reg               clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    reg  signed [7:0] x = 8'sd0;
    wire              out_valid;
    wire signed [7:0] y;

    // generator zegara: zmiana co pół okresu
    always #(T / 2) clk = ~clk;

    mavg4 dut (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(out_valid), .y(y));

    integer errors = 0;

    // reset przez n taktów; zmiany na opadającym zboczu — z dala od zbocza, na którym układ próbkuje
    task reset;
        input integer n;
        begin
            @(negedge clk) rst = 1'b1; in_valid = 1'b0;
            repeat (n) @(negedge clk);
            rst = 1'b0;
        end
    endtask

    // jedna próbka i sprawdzenie wyjścia po zboczu
    task send;
        input signed [7:0] value;
        input signed [7:0] expected;
        begin
            in_valid = 1'b1;
            x        = value;
            @(negedge clk);
            in_valid = 1'b0;
            if (out_valid !== 1'b1 || y !== expected) begin
                $display("t=%0t: x=%0d -> y=%0d out_valid=%b, oczekiwano %0d", $time, value, y, out_valid, expected);
                errors = errors + 1;
            end
        end
    endtask

    // takt bez danych: out_valid = 0, y bez zmian
    task idle;
        input signed [7:0] expected;
        begin
            @(negedge clk);
            if (out_valid !== 1'b0 || y !== expected) begin
                $display("t=%0t: bez danych y=%0d out_valid=%b, oczekiwano %0d i 0", $time, y, out_valid, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        reset(2);
        idle(8'sd0);                           // po resecie: y = 0, out_valid = 0

        send(8'sd40, 8'sd10);                  // skok: (40 + 0 + 0 + 0) / 4
        send(8'sd40, 8'sd20);
        send(8'sd40, 8'sd30);
        send(8'sd40, 8'sd40);                  // okno pełne
        send(-8'sd40, 8'sd20);                 // zmiana znaku: (-40 + 40 + 40 + 40) / 4
        send(-8'sd40, 8'sd0);
        send(-8'sd40, -8'sd20);
        send(-8'sd40, -8'sd40);
        send(-8'sd1, -8'sd31);                 // -121 / 4 = -30,25 -> floor = -31 (nie -30!)
        idle(-8'sd31);                         // wstrzymanie: wyjście trzyma wartość
        idle(-8'sd31);
        send(8'sd127, 8'sd11);                 // okno {127, -1, -40, -40}: 46 / 4 = 11,5 -> 11
        reset(1);
        idle(8'sd0);                           // reset w trakcie pracy zeruje okno
        send(8'h80, -8'sd32);                  // wartość skrajna -128 (8'h80; zapis -8'sd128 przepełnia stałą)

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

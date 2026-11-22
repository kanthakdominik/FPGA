// Testbench zadania 9: CLK_HZ = 1 MHz, BAUD = 100 kb/s (10 taktów na bit). Odbiornik w testbenchu czeka na
// zbocze bitu startu, próbkuje w środku bitów i sprawdza bit startu, bajt i bit stopu. Bajty: 0x55,
// 0xA3, 0x00, 0xFF i 20 losowych; drugi start w trakcie nadawania musi zostać zignorowany.
`timescale 1ns / 1ps
`default_nettype none

module tb_uart_tx;
    localparam integer BIT = 10;
    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg        start = 1'b0;
    reg  [7:0] data = 8'd0;
    wire       ready, tx;
    always #500 clk = ~clk;                         // 1 MHz

    uart_tx #(.CLK_HZ(1_000_000), .BAUD(100_000)) dut (.clk(clk), .rst(rst), .start(start), .data(data),
                                                       .ready(ready), .tx(tx));

    reg [7:0] sent [0:63];
    integer   errors = 0, n_sent = 0, n_got = 0, i, k, seed = 4;
    reg [7:0] b;

    // odbiornik: zbocze bitu startu, potem próbki na zboczu opadającym zegara w okolicy środka każdego bitu
    // (błąd podzielnika o 1 takt na bit przesunąłby próbkę bitu stopu o 9 taktów — poza bit)
    always begin
        @(negedge tx);
        repeat (BIT / 2) @(negedge clk);                     // środek bitu startu
        if (tx !== 1'b0) begin $display("%0t: falszywy bit startu", $time); errors = errors + 1; end
        repeat (BIT) @(negedge clk);                         // środek bitu 0
        for (k = 0; k < 8; k = k + 1) begin b[k] = tx; repeat (BIT) @(negedge clk); end
        if (tx !== 1'b1) begin $display("%0t: brak bitu stopu", $time); errors = errors + 1; end
        if (b !== sent[n_got]) begin $display("%0t: odebrano %h, oczekiwano %h", $time, b, sent[n_got]); errors = errors + 1; end
        n_got = n_got + 1;
    end

    task send(input [7:0] v);
        begin
            @(negedge clk);
            while (!ready) @(negedge clk);
            data = v; start = 1'b1;
            sent[n_sent] = v; n_sent = n_sent + 1;
            @(negedge clk) start = 1'b0;
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (5) @(negedge clk);
        send(8'h55); send(8'hA3); send(8'h00); send(8'hFF);
        // start w trakcie nadawania — ignorowany
        repeat (30) @(negedge clk);
        data = 8'h77; start = 1'b1;
        @(negedge clk) start = 1'b0;
        for (i = 0; i < 20; i = i + 1) send($random(seed));
        @(negedge clk);
        while (!ready) @(negedge clk);
        repeat (2 * BIT) @(negedge clk);
        $display("wyslanych %0d, odebranych %0d", n_sent, n_got);
        if (n_got != n_sent) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #10000000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire

// Testbench ram_sp: trzy tryby (READ_FIRST, WRITE_FIRST, NO_CHANGE) na tych samych losowych operacjach.
// Model pamięci w testbenchu; sprawdzane wyjście po każdym takcie, także przy zapisie (różnica trybów).
`timescale 1ns / 1ps
module tb_ram_sp;
    localparam W = 8, AW = 4;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic           we = 1'b0;
    logic  [AW-1:0] addr = {AW{1'b0}};
    logic  [W-1:0]  din = {W{1'b0}};
    logic [W-1:0]  d0, d1, d2;
    ram_sp #(.W(W), .AW(AW), .TRYB(0)) u0 (.clk(clk), .we(we), .addr(addr), .din(din), .dout(d0));
    ram_sp #(.W(W), .AW(AW), .TRYB(1)) u1 (.clk(clk), .we(we), .addr(addr), .din(din), .dout(d1));
    ram_sp #(.W(W), .AW(AW), .TRYB(2)) u2 (.clk(clk), .we(we), .addr(addr), .din(din), .dout(d2));

    logic [W-1:0] model [0:(1<<AW)-1];
    logic [W-1:0] e0, e1, e2;
    int i, n, errors = 0, n_zap = 0;

    initial begin
        // wypełnienie: zapis każdego adresu (wyjście trybu NO_CHANGE nieznane do pierwszego odczytu)
        for (i = 0; i < (1 << AW); i = i + 1) begin
            @(negedge clk) we = 1'b1; addr = i; din = $random;
            model[i] = din;
        end
        @(negedge clk) we = 1'b0; addr = 0;
        @(negedge clk);
        e2 = model[0];
        for (n = 0; n < 2000; n = n + 1) begin
            @(negedge clk);
            we = ($random % 3 == 0); addr = $random; din = $random;
            // oczekiwania po zboczu
            e0 = model[addr];
            e1 = we ? din : model[addr];
            if (!we) e2 = model[addr];
            if (we) begin model[addr] = din; n_zap = n_zap + 1; end
            @(posedge clk); #1;
            if (d0 !== e0 || d1 !== e1 || d2 !== e2) begin
                $display("%0t: we=%b addr=%0d: READ_FIRST %h/%h WRITE_FIRST %h/%h NO_CHANGE %h/%h",
                         $time, we, addr, d0, e0, d1, e1, d2, e2);
                errors = errors + 1;
            end
        end
        if (errors == 0 && n_zap > 400) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule


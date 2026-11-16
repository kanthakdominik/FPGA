// 10.04 — asercje SVA dołączone przez bind do trzech egzemplarzy alu_hs: poprawnego (BUG = 0),
// z błędem arytmetyki (BUG = 1) i z błędem protokołu (BUG = 2). Oczekiwane: dla BUG = 0 brak naruszeń
// i wszystkie scenariusze cover osiągnięte; dla BUG = 1 brak naruszeń (asercje protokołu nie widzą błędu
// w danych — to zadanie modelu i scoreboardu, 10.05); dla BUG = 2 naruszenia a_no_ovw / a_out_hold.
`timescale 1ns / 1ps

bind alu_hs alu_sva #(.W(W)) u_sva (.*);

// pobudzenia losowe zgodne z protokołem: źródło trzyma operację do przyjęcia
module sva_bench #(
    parameter int BUG = 0
) (
    input logic clk
);
    localparam int W = 8;
    logic         rst = 1'b1, in_valid = 1'b0, out_ready = 1'b0;
    logic         in_ready, out_valid, carry, zero, err;
    logic [2:0]   op = '0;
    logic [W-1:0] a = '0, b = '0, res;
    logic         pending = 1'b0;                     // operacja czeka na przyjęcie

    alu_hs #(.W(W), .BUG(BUG)) dut (.*);

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            if (!pending) begin
                in_valid = ($urandom_range(3) != 0);
                op       = 3'($urandom);
                a        = ($urandom_range(3) == 0) ? '0 : W'($urandom);
                b        = W'($urandom);
            end
            out_ready = (n % 500 < 100) ? ($urandom_range(5) == 0) : 1'($urandom);
            if (n == 1500) rst = 1'b1;                      // reset w trakcie pracy
            if (n == 1502) rst = 1'b0;
            #1;
            pending = in_valid && !in_ready && !rst;        // stan tuż przed zboczem
            @(negedge clk);
        end
    end
endmodule

module tb_sva;
    logic clk = 1'b0;
    int   errors = 0;

    always #5 clk = ~clk;

    sva_bench #(.BUG(0)) b0 (.clk(clk));
    sva_bench #(.BUG(1)) b1 (.clk(clk));
    sva_bench #(.BUG(2)) b2 (.clk(clk));

    initial begin
        repeat (3010) @(posedge clk);
        $display("BUG=0: naruszen %0d, cover: stall3=%0d b2b=%0d err_op=%0d",
                 b0.dut.u_sva.n_fail, b0.dut.u_sva.n_stall3, b0.dut.u_sva.n_b2b, b0.dut.u_sva.n_err_op);
        $display("BUG=1: naruszen %0d", b1.dut.u_sva.n_fail);
        $display("BUG=2: naruszen %0d", b2.dut.u_sva.n_fail);
        if (b0.dut.u_sva.n_fail != 0) begin
            $display("BLAD: naruszenia w ukladzie poprawnym"); errors++;
        end
        if (b0.dut.u_sva.n_stall3 == 0 || b0.dut.u_sva.n_b2b == 0 || b0.dut.u_sva.n_err_op == 0) begin
            $display("BLAD: nieosiagniety scenariusz cover"); errors++;
        end
        if (b1.dut.u_sva.n_fail != 0) begin
            $display("BLAD: asercje protokolu nie powinny widziec bledu arytmetyki"); errors++;
        end
        if (b2.dut.u_sva.n_fail == 0) begin
            $display("BLAD: nie wykryto bledu protokolu (BUG=2)"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

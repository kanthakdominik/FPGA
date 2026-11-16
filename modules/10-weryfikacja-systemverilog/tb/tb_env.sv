// 10.05 — środowisko warstwowe na trzech egzemplarzach alu_hs: poprawnym (BUG = 0), z błędem arytmetyki
// (BUG = 1) i z błędem protokołu (BUG = 2). To samo środowisko, inny wirtualny interfejs.
// Oczekiwane: BUG = 0 — zero błędów scoreboardu i pełne pokrycie funkcjonalne; BUG = 1 i BUG = 2 — błędy
// wykryte. Asercje SVA (10.04) dołączone przez bind działają równolegle.
`timescale 1ns / 1ps

import alu_txn_pkg::*;
import alu_env_pkg::*;

bind alu_hs alu_sva #(.W(W)) u_sva (.*);

module env_bench #(
    parameter int BUG = 0
) (
    input logic clk
);
    alu_if #(.W(W)) vif (.clk(clk));

    alu_hs #(.W(W), .BUG(BUG)) dut (
        .clk(clk), .rst(vif.rst), .in_valid(vif.in_valid), .in_ready(vif.in_ready), .op(vif.op), .a(vif.a),
        .b(vif.b), .out_valid(vif.out_valid), .out_ready(vif.out_ready), .res(vif.res), .carry(vif.carry),
        .zero(vif.zero), .err(vif.err)
    );

    bit  done = 0;
    int  errors = 0, n_checked = 0;
    real coverage = 0.0;

    initial begin
        alu_cfg cfg;
        alu_env env;
        cfg = new();
        env = new(cfg, vif);
        env.run();
        errors    = env.errors();
        n_checked = env.sb.n_checked;
        coverage  = env.sb.cov.coverage();
        $display("BUG=%0d: sprawdzonych %0d, bledow scoreboardu %0d, pokrycie %0.1f %%, naruszen SVA %0d",
                 BUG, n_checked, env.sb.n_err, coverage, dut.u_sva.n_fail);
        if (env.timed_out) $display("BUG=%0d: przekroczony limit czasu - nie wszystkie wyniki odebrane", BUG);
        done = 1;
    end
endmodule

module tb_env;
    logic clk = 1'b0;
    int   errors = 0;

    always #5 clk = ~clk;

    env_bench #(.BUG(0)) b0 (.clk(clk));
    env_bench #(.BUG(1)) b1 (.clk(clk));
    env_bench #(.BUG(2)) b2 (.clk(clk));

    initial begin
        wait (b0.done && b1.done && b2.done);
        if (b0.errors != 0 || b0.dut.u_sva.n_fail != 0) begin
            $display("BLAD: bledy w ukladzie poprawnym"); errors++;
        end
        if (b0.coverage < 100.0) begin
            $display("BLAD: pokrycie funkcjonalne %0.1f %% < 100 %%", b0.coverage); errors++;
        end
        if (b1.errors == 0) begin
            $display("BLAD: scoreboard nie wykryl bledu arytmetyki (BUG=1)"); errors++;
        end
        if (b2.errors == 0 || b2.dut.u_sva.n_fail == 0) begin
            $display("BLAD: nie wykryto bledu protokolu (BUG=2)"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

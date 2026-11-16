// Asercje SVA dla alu_hs — protokół valid/ready, opóźnienie, flagi. Dołączane do układu poleceniem bind
// (kod układu bez zmian). Naruszenia liczone w n_fail zamiast przerywać symulację — testbench sprawdza,
// czy układ poprawny ich nie ma, a układ z błędem je ma. Pokrycie scenariuszy: liczniki w akcjach cover.
module alu_sva #(
    parameter int W = 8
) (
    input logic         clk,
    input logic         rst,
    input logic         in_valid,
    input logic         in_ready,
    input logic [2:0]   op,
    input logic [W-1:0] a,
    input logic [W-1:0] b,
    input logic         out_valid,
    input logic         out_ready,
    input logic [W-1:0] res,
    input logic         carry,
    input logic         zero,
    input logic         err
);
    int n_fail = 0, n_stall3 = 0, n_b2b = 0, n_err_op = 0;

    function automatic void fail(string name);
        n_fail++;
        if (n_fail <= 5) $display("%t: naruszenie %s", $time, name);
    endfunction

    default clocking cb @(posedge clk);
    endclocking

    default disable iff (rst);

    sequence s_in_xfer;
        in_valid && in_ready;
    endsequence

    // dane czekające na odbiór nie zmieniają się (ta sama właściwość dla wejścia i wyjścia)
    property p_hold(logic v, logic r, logic [W+2:0] d);
        v && !r |=> v && $stable(d);
    endproperty

    // 1. wyjście: wynik trzymany do odebrania
    a_out_hold: assert property (p_hold(out_valid, out_ready, {res, carry, zero, err})) else fail("a_out_hold");
    // 2. przyjęta operacja daje wynik w następnym takcie
    a_latency:  assert property (s_in_xfer |=> out_valid) else fail("a_latency");
    // 3. rejestr zajęty i nieodbierany — układ nie przyjmuje nowej operacji
    a_no_ovw:   assert property (out_valid && !out_ready |-> !in_ready) else fail("a_no_ovw");
    // 4. bez przyjęcia i po odebraniu wyjście opada
    a_drain:    assert property (out_valid && out_ready && !in_valid |=> !out_valid) else fail("a_drain");
    // 5. flagi
    a_zero:     assert property (out_valid |-> zero == (res == '0)) else fail("a_zero");
    a_err:      assert property (s_in_xfer and op == 3'd7 |=> err && res == '0) else fail("a_err");
    a_carry:    assert property (s_in_xfer and !(op inside {3'd0, 3'd1}) |=> !carry) else fail("a_carry");
    // 6. reset (poza disable iff): w takcie po resecie brak wyniku
    a_reset:    assert property (@(posedge clk) disable iff (1'b0) rst |=> !out_valid) else fail("a_reset");

    // założenie o otoczeniu: źródło trzyma operację do przyjęcia. W symulacji sprawdzane jak asercja,
    // w weryfikacji formalnej (moduł 13) ogranicza pobudzenia.
    m_in_hold:  assume property (p_hold(in_valid, in_ready, {op, a, b})) else fail("m_in_hold");

    // scenariusze, które test powinien wywołać
    c_stall3: cover property (out_valid && !out_ready [*3] ##1 out_ready) n_stall3++;
    c_b2b:    cover property (s_in_xfer [*4]) n_b2b++;
    c_err_op: cover property (s_in_xfer and op == 3'd7) n_err_op++;
endmodule

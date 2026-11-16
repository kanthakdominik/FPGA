// Model pokrycia funkcjonalnego ALU — klasa z wbudowaną grupą pokrycia. Próbkowana transakcją z wejściami
// i odpowiedzią (z modelu albo z układu). Używana w 10.03 i w środowisku warstwowym 10.05.
package alu_cov_pkg;
    import alu_txn_pkg::*;

    class alu_cov;
        alu_txn t;                                       // transakcja bieżąca — czytana przez coverpointy

        covergroup cg;
            option.per_instance = 1;
            cp_op: coverpoint t.op {
                bins legal[] = {[OP_ADD:OP_SHR]};        // osobny bin dla każdego kodu
                bins bad     = {OP_BAD};
            }
            cp_a: coverpoint t.a {
                bins zero = {8'h00};
                bins one  = {8'h01};
                bins low  = {[8'h02:8'h7F]};
                bins high = {[8'h80:8'hFE]};
                bins max  = {8'hFF};
            }
            cp_b: coverpoint t.b {
                bins zero = {8'h00};
                bins one  = {8'h01};
                bins low  = {[8'h02:8'h7F]};
                bins high = {[8'h80:8'hFE]};
                bins max  = {8'hFF};
            }
            cp_shift: coverpoint t.b[2:0] iff (t.op inside {OP_SHL, OP_SHR}) {
                bins amount[] = {[0:7]};
            }
            cp_carry: coverpoint t.carry iff (t.op == OP_ADD) {
                bins no = {0};
                bins yes = {1};
            }
            cp_borrow: coverpoint t.carry iff (t.op == OP_SUB) {
                bins no = {0};
                bins yes = {1};
            }
            cp_sub_eq: coverpoint (t.a == t.b) iff (t.op == OP_SUB) {
                bins equal = {1};
            }
            cp_zero: coverpoint t.zero iff (!t.err) {
                bins yes = {1};
            }
            cp_seq: coverpoint t.op {                     // przejścia między kolejnymi operacjami
                bins add_then_sub = (OP_ADD => OP_SUB);
                bins sub_then_add = (OP_SUB => OP_ADD);
                bins same_twice   = (OP_XOR => OP_XOR);
            }
            x_op_a: cross cp_op, cp_a {
                ignore_bins skip_bad = binsof(cp_op.bad);
            }
            x_op_b: cross cp_op, cp_b {
                ignore_bins skip_bad = binsof(cp_op.bad);
            }
        endgroup

        function new();
            cg = new();
        endfunction

        function void sample(alu_txn tr);
            t = tr;
            cg.sample();
        endfunction

        function real coverage();
            return cg.get_inst_coverage();
        endfunction
    endclass
endpackage

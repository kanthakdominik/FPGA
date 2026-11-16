// 10.03 — pokrycie funkcjonalne: ile transakcji potrzeba do zamknięcia pokrycia przy losowaniu
// równomiernym, a ile przy losowaniu sterowanym pokryciem (wartości brzegowe + kod niedozwolony).
// Sprawdzane: losowanie równomierne nie domyka pokrycia w 1000 transakcji, sterowane domyka do 100 %.
`timescale 1ns / 1ps

import alu_txn_pkg::*;
import alu_cov_pkg::*;

module tb_coverage;
    int errors = 0;

    initial begin
        alu_txn      t;
        alu_txn_edge e;
        alu_txn_bad  bad;
        alu_cov      cov_u, cov_d;
        real         c_u;
        int          n;

        // 1. losowanie równomierne: 1000 transakcji
        cov_u = new();
        t     = new();
        repeat (1000) begin
            void'(t.randomize());
            t.predict();
            cov_u.sample(t);
        end
        c_u = cov_u.coverage();
        $display("rownomierne, 1000 transakcji: pokrycie %0.1f %%", c_u);
        $display("  cp_a %0.1f %%  x_op_a %0.1f %%  cp_sub_eq %0.1f %%  cp_op %0.1f %%",
                 cov_u.cg.cp_a.get_inst_coverage(), cov_u.cg.x_op_a.get_inst_coverage(),
                 cov_u.cg.cp_sub_eq.get_inst_coverage(), cov_u.cg.cp_op.get_inst_coverage());
        if (c_u >= 100.0) begin
            $display("BLAD: losowanie rownomierne nie powinno domknac pokrycia"); errors++;
        end

        // 2. losowanie sterowane: co trzecia transakcja z wartości brzegowych, co ósma SUB z a == b,
        //    co setna z kodem niedozwolonym — do pełnego pokrycia albo limitu
        cov_d = new();
        e     = new();
        bad   = new();
        n     = 0;
        while (cov_d.coverage() < 100.0 && n < 20000) begin
            case ($urandom_range(99))
                0:                   begin void'(bad.randomize()); t = bad; end
                1, 2, 3, 4, 5,
                6, 7, 8, 9, 10, 11,
                12:                  begin void'(e.randomize() with { op == OP_SUB; a == b; }); t = e; end
                default:             begin
                    if ($urandom_range(2) == 0) begin void'(e.randomize()); t = e; end
                    else                        begin t = new(); void'(t.randomize()); end
                end
            endcase
            t.predict();
            cov_d.sample(t);
            n++;
        end
        $display("sterowane: pokrycie %0.1f %% po %0d transakcjach", cov_d.coverage(), n);
        if (cov_d.coverage() < 100.0) begin
            $display("BLAD: nie domknieto pokrycia");
            $display("  cp_op %0.1f cp_a %0.1f cp_b %0.1f cp_shift %0.1f cp_carry %0.1f cp_borrow %0.1f",
                     cov_d.cg.cp_op.get_inst_coverage(), cov_d.cg.cp_a.get_inst_coverage(),
                     cov_d.cg.cp_b.get_inst_coverage(), cov_d.cg.cp_shift.get_inst_coverage(),
                     cov_d.cg.cp_carry.get_inst_coverage(), cov_d.cg.cp_borrow.get_inst_coverage());
            $display("  cp_sub_eq %0.1f cp_zero %0.1f cp_seq %0.1f x_op_a %0.1f x_op_b %0.1f",
                     cov_d.cg.cp_sub_eq.get_inst_coverage(), cov_d.cg.cp_zero.get_inst_coverage(),
                     cov_d.cg.cp_seq.get_inst_coverage(), cov_d.cg.x_op_a.get_inst_coverage(),
                     cov_d.cg.x_op_b.get_inst_coverage());
            errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

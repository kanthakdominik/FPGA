// Środowisko warstwowe dla alu_hs (10.05): generator → driver → [układ] → monitor → scoreboard.
// Komponenty łączą skrzynki pocztowe (mailbox); dostęp do sygnałów tylko przez wirtualny interfejs.
package alu_env_pkg;
    import alu_txn_pkg::*;
    import alu_cov_pkg::*;

    typedef virtual alu_if #(.W(W)) vif_t;

    // konfiguracja testu — jedno miejsce na parametry scenariusza
    class alu_cfg;
        int n_txn      = 2000;   // liczba operacji
        int edge_pct   = 30;     // % operacji z wartości brzegowych
        int bad_pct    = 2;      // % operacji z kodem niedozwolonym
        int idle_pct   = 20;     // % taktów bez operacji na wejściu
        int ready_pct  = 60;     // % taktów z out_ready = 1
        int timeout_ns = 200000; // limit czasu testu
    endclass

    class alu_generator;
        alu_cfg                cfg;
        mailbox #(alu_txn)     to_drv;
        int                    n_sent = 0;

        function new(alu_cfg cfg, mailbox #(alu_txn) to_drv);
            this.cfg    = cfg;
            this.to_drv = to_drv;
        endfunction

        task run();
            alu_txn      t;
            alu_txn_edge e;
            alu_txn_bad  bad;
            repeat (cfg.n_txn) begin
                int k = $urandom_range(99);
                if (k < cfg.bad_pct) begin
                    bad = new(); t = bad;
                end else if (k < cfg.bad_pct + cfg.edge_pct) begin
                    e = new(); t = e;
                end else begin
                    t = new();
                end
                if (!t.randomize()) $fatal(1, "randomize() nie powiodlo sie");
                to_drv.put(t);                     // skrzynka ograniczona: czeka, aż driver odbierze
                n_sent++;
            end
        endtask
    endclass

    class alu_driver;
        alu_cfg            cfg;
        vif_t              vif;
        mailbox #(alu_txn) from_gen;

        function new(alu_cfg cfg, vif_t vif, mailbox #(alu_txn) from_gen);
            this.cfg      = cfg;
            this.vif      = vif;
            this.from_gen = from_gen;
        endfunction

        task reset();
            vif.drv_cb.rst       <= 1'b1;
            vif.drv_cb.in_valid  <= 1'b0;
            vif.drv_cb.out_ready <= 1'b0;
            repeat (3) @(vif.drv_cb);
            vif.drv_cb.rst <= 1'b0;
            @(vif.drv_cb);
        endtask

        // strona wejściowa: operacja trzymana do przyjęcia (in_valid && in_ready na zboczu)
        task run_in();
            alu_txn t;
            forever begin
                from_gen.get(t);
                while ($urandom_range(99) < cfg.idle_pct) @(vif.drv_cb);   // przerwa przed operacją
                vif.drv_cb.in_valid <= 1'b1;
                vif.drv_cb.op       <= t.op;
                vif.drv_cb.a        <= t.a;
                vif.drv_cb.b        <= t.b;
                @(vif.drv_cb);
                while (!vif.drv_cb.in_ready) @(vif.drv_cb);
                vif.drv_cb.in_valid <= 1'b0;
            end
        endtask

        // strona wyjściowa: losowe wstrzymanie odbiornika
        task run_out();
            forever begin
                vif.drv_cb.out_ready <= ($urandom_range(99) < cfg.ready_pct);
                @(vif.drv_cb);
            end
        endtask
    endclass

    class alu_monitor;
        vif_t              vif;
        mailbox #(alu_txn) in_box, out_box;

        function new(vif_t vif, mailbox #(alu_txn) in_box, mailbox #(alu_txn) out_box);
            this.vif     = vif;
            this.in_box  = in_box;
            this.out_box = out_box;
        endfunction

        // obserwuje oba przesłania na każdym zboczu; tylko czyta sygnały
        task run();
            alu_txn t;
            forever begin
                @(vif.mon_cb);
                if (vif.mon_cb.rst) continue;
                if (vif.mon_cb.out_valid && vif.mon_cb.out_ready) begin
                    t       = new();
                    t.res   = vif.mon_cb.res;
                    t.carry = vif.mon_cb.carry;
                    t.zero  = vif.mon_cb.zero;
                    t.err   = vif.mon_cb.err;
                    out_box.put(t);
                end
                if (vif.mon_cb.in_valid && vif.mon_cb.in_ready) begin
                    t    = new();
                    t.op = op_e'(vif.mon_cb.op);
                    t.a  = vif.mon_cb.a;
                    t.b  = vif.mon_cb.b;
                    in_box.put(t);
                end
            end
        endtask
    endclass

    class alu_scoreboard;
        mailbox #(alu_txn) in_box, out_box;
        alu_cov            cov;
        alu_txn            expected[$];      // przewidywania w kolejności przyjęcia
        int                n_checked = 0, n_err = 0;

        function new(mailbox #(alu_txn) in_box, mailbox #(alu_txn) out_box);
            this.in_box  = in_box;
            this.out_box = out_box;
            cov          = new();
        endfunction

        task run();
            fork
                forever begin : przewidywanie
                    alu_txn t;
                    in_box.get(t);
                    t.predict();
                    expected.push_back(t);
                end
                forever begin : porownanie
                    alu_txn got, exp;
                    out_box.get(got);
                    n_checked++;
                    if (expected.size() == 0) begin
                        report("wynik bez przyjetej operacji", got, null);
                        continue;
                    end
                    exp = expected.pop_front();
                    if (!got.same_result(exp)) report("niezgodny wynik", got, exp);
                    cov.sample(exp);
                end
            join_none
        endtask

        function void report(string what, alu_txn got, alu_txn exp);
            n_err++;
            if (n_err <= 5)
                $display("%t scoreboard: %s: otrzymano res=%0d c=%b z=%b e=%b, oczekiwano %s", $time, what,
                         got.res, got.carry, got.zero, got.err, exp == null ? "-" : exp.convert2string());
        endfunction
    endclass

    class alu_env;
        alu_cfg            cfg;
        alu_generator      gen;
        alu_driver         drv;
        alu_monitor        mon;
        alu_scoreboard     sb;
        mailbox #(alu_txn) gen2drv, in_box, out_box;
        bit                timed_out = 0;

        function new(alu_cfg cfg, vif_t vif);
            this.cfg = cfg;
            gen2drv  = new(1);                   // ograniczona: generator nie wyprzedza drivera
            in_box   = new();
            out_box  = new();
            gen      = new(cfg, gen2drv);
            drv      = new(cfg, vif, gen2drv);
            mon      = new(vif, in_box, out_box);
            sb       = new(in_box, out_box);
        endfunction

        // przebieg testu: reset, wszystkie komponenty współbieżnie, koniec po sprawdzeniu wszystkich
        // wyników albo po przekroczeniu limitu czasu
        task run();
            drv.reset();
            fork
                gen.run();
                drv.run_in();
                drv.run_out();
                mon.run();
                sb.run();
            join_none
            fork
                while (!(gen.n_sent == cfg.n_txn && sb.n_checked == cfg.n_txn)) #10ns;
                begin
                    #(cfg.timeout_ns * 1ns);
                    timed_out = 1;
                end
            join_any
            disable fork;
        endtask

        function int errors();
            int e = sb.n_err + (timed_out ? 1 : 0) + sb.expected.size();
            return e;
        endfunction
    endclass
endpackage

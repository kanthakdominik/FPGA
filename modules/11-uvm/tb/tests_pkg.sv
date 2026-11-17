// Testy UVM dla axil_regs. Wybór testu: +UVM_TESTNAME=<nazwa>. Wynik: linia PASS albo FAIL w raporcie
// (liczba UVM_ERROR i UVM_FATAL oraz naruszeń reguł AXI w interfejsie).
//
//   smoke_test        kilka zapisów i odczytów (11.01)
//   phases_test       kolejność faz i fabryka: podmiana typu transakcji i drivera (11.02)
//   rand_test         losowy ruch, scoreboard, pokrycie; liczba transakcji z config_db / +N_ITEMS (11.03–11.06)
//   reg_reset_test    RAL: wbudowana sekwencja uvm_reg_hw_reset_seq (11.07)
//   reg_bitbash_test  RAL: wbudowana sekwencja uvm_reg_bit_bash_seq (11.07)
//   reg_access_test   RAL: zapis/odczyt/mirror przez model, efekty uboczne STATUS, wynik ALU (11.07)
//   full_test         wszystko po kolei, wymagane 100 % pokrycia (11.08)
package tests_pkg;
    import uvm_pkg::*;
    import axil_pkg::*;
    import regs_ral_pkg::*;
    import env_pkg::*;
    `include "uvm_macros.svh"

    // ---------------------------------------------------------------- test bazowy
    class base_test extends uvm_test;
        `uvm_component_utils(base_test)
        regs_env        env;
        env_cfg         cfg;
        virtual axil_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axil_if)::get(this, "", "vif", vif))
                `uvm_fatal("CFG", "brak wirtualnego interfejsu (vif) w config_db")
            cfg                 = env_cfg::type_id::create("cfg");
            cfg.agent_cfg       = axil_agent_cfg::type_id::create("agent_cfg");
            cfg.agent_cfg.vif   = vif;
            configure(cfg);                                   // test pochodny zmienia konfigurację
            uvm_config_db #(env_cfg)::set(this, "env", "cfg", cfg);
            env = regs_env::type_id::create("env", this);
        endfunction

        virtual function void configure(env_cfg c);
        endfunction

        function void end_of_elaboration_phase(uvm_phase phase);
            if (uvm_report_enabled(UVM_MEDIUM)) uvm_root::get().print_topology();
        endfunction

        task wait_reset();
            do @(posedge vif.clk); while (vif.rst);
            repeat (2) @(posedge vif.clk);
        endtask

        function void report_phase(uvm_phase phase);
            uvm_report_server svr = uvm_report_server::get_server();
            int n = svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL) + vif.n_fail;
            if (vif.n_fail != 0) $display("naruszen regul AXI: %0d", vif.n_fail);
            if (n == 0) $display("PASS");
            else        $display("FAIL: %0d bledow", n);
        endfunction
    endclass

    // ---------------------------------------------------------------- 11.01
    class smoke_seq extends axil_base_seq;
        `uvm_object_utils(smoke_seq)
        function new(string name = "smoke_seq");
            super.new(name);
        endfunction
        task body();
            bit [31:0] d;
            bit [1:0]  r;
            read(5'h00, d, r);
            if (d != 32'h414C_5531) `uvm_error("SMOKE", $sformatf("ID = 0x%08h", d))
            write(5'h18, 32'hCAFE_F00D, r);
            read(5'h18, d, r);
            if (d != 32'hCAFE_F00D) `uvm_error("SMOKE", $sformatf("SCRATCH = 0x%08h", d))
            write(5'h08, 32'd200, r);
            write(5'h0C, 32'd100, r);
            write(5'h04, 32'd0, r);                            // ADD
            read(5'h10, d, r);
            if (d[10:0] != {1'b0, 1'b0, 1'b1, 8'd44}) `uvm_error("SMOKE", $sformatf("RESULT = 0x%08h", d))
            read(5'h1C, d, r);
            if (r != 2'b10) `uvm_error("SMOKE", "brak SLVERR dla 0x1C")
        endtask
    endclass

    class smoke_test extends base_test;
        `uvm_component_utils(smoke_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            smoke_seq seq = smoke_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.start(env.agent.sqr);
            phase.drop_objection(this);
        endtask
    endclass

    // ---------------------------------------------------------------- 11.02
    // transakcja z innymi ograniczeniami i driver z dłuższymi wstrzymaniami — podstawiane przez fabrykę
    class axil_item_slow extends axil_item;
        `uvm_object_utils(axil_item_slow)
        constraint c_ready { ready_delay inside {[3:6]}; }      // nadpisuje c_ready klasy bazowej
        function new(string name = "axil_item_slow");
            super.new(name);
        endfunction
    endclass

    class axil_driver_logged extends axil_driver;
        `uvm_component_utils(axil_driver_logged)
        int n_items = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        virtual protected task drive_write(axil_item t);
            n_items++;
            super.drive_write(t);
        endtask
        virtual protected task drive_read(axil_item t);
            n_items++;
            super.drive_read(t);
        endtask
    endclass

    // komponent zapisujący kolejność faz
    class phase_logger extends uvm_component;
        `uvm_component_utils(phase_logger)
        string order[$];
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);              order.push_back("build");    endfunction
        function void connect_phase(uvm_phase phase);            order.push_back("connect");  endfunction
        function void end_of_elaboration_phase(uvm_phase phase); order.push_back("end_of_elaboration"); endfunction
        function void start_of_simulation_phase(uvm_phase phase); order.push_back("start_of_simulation"); endfunction
        task run_phase(uvm_phase phase);                         order.push_back("run");      endtask
        function void extract_phase(uvm_phase phase);            order.push_back("extract");  endfunction
    endclass

    class phases_test extends base_test;
        `uvm_component_utils(phases_test)
        phase_logger log;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            // podmiany w fabryce przed utworzeniem komponentów
            axil_item::type_id::set_type_override(axil_item_slow::get_type());
            set_inst_override_by_type("env.agent.drv", axil_driver::get_type(), axil_driver_logged::get_type());
            super.build_phase(phase);
            log = phase_logger::type_id::create("log", this);
        endfunction
        task run_phase(uvm_phase phase);
            axil_rand_seq seq = axil_rand_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.n_items = 50;
            seq.start(env.agent.sqr);
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            axil_item          t = axil_item::type_id::create("t");
            axil_item_slow     s;
            axil_driver_logged d;
            string             got = "";
            foreach (log.order[i]) got = {got, log.order[i], " "};
            `uvm_info("FAZY", got, UVM_LOW)
            if (got != "build connect end_of_elaboration start_of_simulation run extract ")
                `uvm_error("FAZY", "niewlasciwa kolejnosc faz")
            if (!$cast(s, t)) `uvm_error("FABRYKA", "create() nie zwrocil axil_item_slow")
            if (!$cast(d, env.agent.drv)) `uvm_error("FABRYKA", "driver nie zostal podmieniony")
            else if (d.n_items != 50) `uvm_error("FABRYKA", $sformatf("driver obsluzyl %0d transakcji", d.n_items))
            `uvm_info("FABRYKA", $sformatf("transakcja: %s, driver: %s", t.get_type_name(),
                      env.agent.drv.get_type_name()), UVM_LOW)
        endfunction
    endclass

    // ---------------------------------------------------------------- 11.03–11.06
    class rand_test extends base_test;
        `uvm_component_utils(rand_test)
        int unsigned n_items = 1000;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            int unsigned n;
            super.build_phase(phase);
            // kolejność ważności: +N_ITEMS z linii poleceń > config_db > wartość domyślna
            void'(uvm_config_db #(int unsigned)::get(this, "", "n_items", n_items));
            if ($value$plusargs("N_ITEMS=%d", n)) n_items = n;
        endfunction
        task run_phase(uvm_phase phase);
            axil_rand_seq seq = axil_rand_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.n_items = n_items;
            seq.start(env.agent.sqr);
            repeat (5) @(posedge vif.clk);
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            if (env.sb.n_checked != n_items)
                `uvm_error("TEST", $sformatf("scoreboard sprawdzil %0d z %0d", env.sb.n_checked, n_items))
        endfunction
    endclass

    // ---------------------------------------------------------------- 11.07
    class reg_reset_test extends base_test;
        `uvm_component_utils(reg_reset_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void configure(env_cfg c);
            c.has_coverage = 0;                                // test rejestrów: pokrycie ruchu niepotrzebne
        endfunction
        task run_phase(uvm_phase phase);
            uvm_reg_hw_reset_seq seq = uvm_reg_hw_reset_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.model = env.regs;
            seq.start(null);
            phase.drop_objection(this);
        endtask
    endclass

    class reg_bitbash_test extends base_test;
        `uvm_component_utils(reg_bitbash_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void configure(env_cfg c);
            c.has_coverage = 0;
        endfunction
        task run_phase(uvm_phase phase);
            uvm_reg_bit_bash_seq seq = uvm_reg_bit_bash_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.model = env.regs;
            seq.start(null);
            phase.drop_objection(this);
        endtask
    endclass

    // dostęp przez model rejestrów: zapisy pól, odczyt z porównaniem (mirror), efekty uboczne
    class reg_access_seq extends uvm_reg_sequence #(uvm_sequence #(uvm_reg_item));
        `uvm_object_utils(reg_access_seq)
        regs_block regs;
        function new(string name = "reg_access_seq");
            super.new(name);
        endfunction

        task body();
            uvm_status_e   st;
            uvm_reg_data_t v;
            // operandy i operacja — przez pola i całe rejestry
            regs.opa.write(st, 8'd200);
            regs.opb.write(st, 8'd100);
            regs.ctrl.op.set(3'd0);
            regs.ctrl.irq_en.set(1'b1);
            regs.ctrl.update(st);                              // zapis tylko, gdy model różni się od mirror
            // RESULT jest volatile: przewidywana wartość ustawiana ręcznie przed sprawdzeniem
            void'(regs.result.predict({21'd0, 1'b0, 1'b0, 1'b1, 8'd44}));
            regs.result.mirror(st, UVM_CHECK);
            // efekt uboczny: CTRL z OP = 7 ustawia STATUS.ERR — model RAL tego nie wie, ustawiamy predict()
            regs.ctrl.write(st, {23'd0, 1'b1, 5'd0, 3'd7});
            void'(regs.status.predict(1));
            regs.status.mirror(st, UVM_CHECK);
            if (env_irq() !== 1'b1) `uvm_error("RAL", "irq nie ustawione")
            // W1C: zapis 0 nie kasuje, zapis 1 kasuje
            regs.status.write(st, 0);
            regs.status.mirror(st, UVM_CHECK);                  // nadal 1
            regs.status.write(st, 1);
            regs.status.mirror(st, UVM_CHECK);                  // teraz 0 (predyktor zna W1C)
            // SCRATCH: zapis, odczyt i porównanie z mirror
            regs.scratch.write(st, 32'h1234_5678);
            regs.scratch.read(st, v);
            if (v != 32'h1234_5678) `uvm_error("RAL", $sformatf("SCRATCH = 0x%08h", v))
            regs.scratch.mirror(st, UVM_CHECK);
        endtask

        virtual axil_if vif;
        function bit env_irq();
            return vif.irq;
        endfunction
    endclass

    class reg_access_test extends base_test;
        `uvm_component_utils(reg_access_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            reg_access_seq seq = reg_access_seq::type_id::create("seq");
            phase.raise_objection(this);
            wait_reset();
            seq.regs  = env.regs;
            seq.model = env.regs;
            seq.vif   = vif;
            seq.start(null);
            phase.drop_objection(this);
        endtask
    endclass

    // ---------------------------------------------------------------- 11.08
    class full_test extends base_test;
        `uvm_component_utils(full_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            uvm_reg_hw_reset_seq rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
            reg_access_seq       ral_seq = reg_access_seq::type_id::create("ral_seq");
            axil_rand_seq        rnd_seq = axil_rand_seq::type_id::create("rnd_seq");
            phase.raise_objection(this);
            wait_reset();
            rst_seq.model = env.regs;
            rst_seq.start(null);
            ral_seq.regs  = env.regs;
            ral_seq.model = env.regs;
            ral_seq.vif   = vif;
            ral_seq.start(null);
            rnd_seq.n_items = 2000;
            rnd_seq.start(env.agent.sqr);
            repeat (5) @(posedge vif.clk);
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            if (env.cov.coverage() < 100.0)
                `uvm_error("TEST", $sformatf("pokrycie funkcjonalne %0.1f %% < 100 %%", env.cov.coverage()))
        endfunction
    endclass
endpackage

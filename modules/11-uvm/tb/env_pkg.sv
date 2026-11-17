// Środowisko dla axil_regs: agent AXI4-Lite, scoreboard z własnym modelem bloku, kolektor pokrycia,
// model rejestrów (RAL) z adapterem i predyktorem zasilanym z monitora.
package env_pkg;
    import uvm_pkg::*;
    import axil_pkg::*;
    import regs_ral_pkg::*;
    `include "uvm_macros.svh"

    class env_cfg extends uvm_object;
        `uvm_object_utils(env_cfg)
        axil_agent_cfg agent_cfg;
        bit            has_scoreboard = 1;
        bit            has_coverage   = 1;
        function new(string name = "env_cfg");
            super.new(name);
        endfunction
    endclass

    // ---------------------------------------------------------------- scoreboard
    // Model referencyjny bloku napisany niezależnie od RAL i od RTL: rejestry, efekty uboczne (ERR przy
    // zapisie CTRL z OP = 7, W1C), wynik ALU na liczbach całkowitych, odpowiedzi OKAY/SLVERR.
    class regs_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(regs_scoreboard)
        uvm_analysis_imp #(axil_item, regs_scoreboard) imp;

        bit [2:0]  op;
        bit        irq_en, err;
        bit [7:0]  opa, opb;
        bit [31:0] scratch;
        int        n_checked = 0, n_mismatch = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            imp = new("imp", this);
        endfunction

        static function bit [31:0] merge(bit [31:0] old, bit [31:0] d, bit [3:0] strb);
            for (int i = 0; i < 4; i++) if (strb[i]) old[8*i +: 8] = d[8*i +: 8];
            return old;
        endfunction

        function bit [31:0] alu_result();
            int x = opa, y = opb, r = 0, c = 0, e = 0, sh = opb % 8;
            case (op)
                0: begin r = (x + y) % 256; c = (x + y > 255); end
                1: begin r = (x - y + 256) % 256; c = (x < y); end
                2: r = x & y;
                3: r = x | y;
                4: r = x ^ y;
                5: r = (x * (1 << sh)) % 256;
                6: r = x / (1 << sh);
                default: e = 1;
            endcase
            return {21'd0, 1'(e), 1'(r == 0), 1'(c), 8'(r)};
        endfunction

        function bit [31:0] read_value(int idx);
            case (idx)
                0: return 32'h414C_5531;
                1: return {23'd0, irq_en, 5'd0, op};
                2: return {24'd0, opa};
                3: return {24'd0, opb};
                4: return alu_result();
                5: return {31'd0, err};
                6: return scratch;
                default: return 32'd0;
            endcase
        endfunction

        function void write(axil_item t);
            int        idx      = t.addr[4:2];
            bit [1:0]  exp_resp = (idx == 7) ? 2'b10 : 2'b00;
            bit [31:0] v;
            n_checked++;
            if (t.resp != exp_resp) mismatch(t, $sformatf("resp=%b, oczekiwano %b", t.resp, exp_resp));
            if (t.dir == AXIL_READ) begin
                if (t.data != read_value(idx))
                    mismatch(t, $sformatf("dane 0x%08h, oczekiwano 0x%08h", t.data, read_value(idx)));
                return;
            end
            case (idx)
                1: begin
                    v      = merge({23'd0, irq_en, 5'd0, op}, t.data, t.strb);
                    op     = v[2:0];
                    irq_en = v[8];
                    if (op == 3'd7) err = 1'b1;
                end
                2: opa = 8'(merge({24'd0, opa}, t.data, t.strb));
                3: opb = 8'(merge({24'd0, opb}, t.data, t.strb));
                5: if (t.strb[0] && t.data[0]) err = 1'b0;
                6: scratch = merge(scratch, t.data, t.strb);
                default: ;
            endcase
        endfunction

        function void mismatch(axil_item t, string what);
            n_mismatch++;
            `uvm_error("SB", {t.convert2string(), ": ", what})
        endfunction

        function void reset_model();
            op = 0; irq_en = 0; err = 0; opa = 0; opb = 0; scratch = 0;
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("SB", $sformatf("sprawdzonych transakcji: %0d, niezgodnych: %0d", n_checked, n_mismatch),
                      UVM_LOW)
        endfunction
    endclass

    // ---------------------------------------------------------------- pokrycie
    class axil_coverage extends uvm_subscriber #(axil_item);
        `uvm_component_utils(axil_coverage)
        axil_item t;

        covergroup cg;
            option.per_instance = 1;
            cp_dir:  coverpoint t.dir;
            cp_reg:  coverpoint t.addr[4:2] {
                bins regs[] = {[0:6]};
                bins unmapped = {7};
            }
            cp_resp: coverpoint t.resp {
                bins okay   = {2'b00};
                bins slverr = {2'b10};
            }
            cp_strb: coverpoint t.strb iff (t.dir == AXIL_WRITE) {
                bins full    = {4'hF};
                bins one     = {4'h1, 4'h2, 4'h4, 4'h8};
                bins two     = {4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC};
                bins three   = {4'h7, 4'hB, 4'hD, 4'hE};
            }
            x_dir_reg: cross cp_dir, cp_reg;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(axil_item t);
            this.t = t;
            cg.sample();
        endfunction

        function real coverage();
            return cg.get_inst_coverage();
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("COV", $sformatf("pokrycie funkcjonalne: %0.1f %%", coverage()), UVM_LOW)
        endfunction
    endclass

    // ---------------------------------------------------------------- środowisko
    class regs_env extends uvm_env;
        `uvm_component_utils(regs_env)
        env_cfg                         cfg;
        axil_agent                      agent;
        regs_scoreboard                 sb;
        axil_coverage                   cov;
        regs_block                      regs;
        axil_reg_adapter                adapter;
        uvm_reg_predictor #(axil_item)  predictor;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db #(env_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("CFG", "brak konfiguracji srodowiska (cfg)")
            uvm_config_db #(axil_agent_cfg)::set(this, "agent*", "cfg", cfg.agent_cfg);
            agent = axil_agent::type_id::create("agent", this);
            if (cfg.has_scoreboard) sb  = regs_scoreboard::type_id::create("sb", this);
            if (cfg.has_coverage)   cov = axil_coverage::type_id::create("cov", this);
            regs = regs_block::type_id::create("regs");
            regs.configure(null, "");
            regs.build();
            adapter   = axil_reg_adapter::type_id::create("adapter");
            predictor = uvm_reg_predictor #(axil_item)::type_id::create("predictor", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            if (cfg.has_scoreboard) agent.mon.ap.connect(sb.imp);
            if (cfg.has_coverage)   agent.mon.ap.connect(cov.analysis_export);
            // model rejestrów: zapisy i odczyty idą przez agenta, mirror aktualizuje predyktor z monitora
            if (agent.cfg.is_active == UVM_ACTIVE) regs.default_map.set_sequencer(agent.sqr, adapter);
            regs.default_map.set_auto_predict(0);
            predictor.map     = regs.default_map;
            predictor.adapter = adapter;
            agent.mon.ap.connect(predictor.bus_in);
        endfunction
    endclass
endpackage

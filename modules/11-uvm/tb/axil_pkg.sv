// Agent AXI4-Lite (master) dla UVM: transakcja, konfiguracja, driver, monitor, sekwencer, agent
// i sekwencje podstawowe. Niezależny od układu — działa z każdym podrzędnym AXI4-Lite (adres 5 bitów).
package axil_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit {AXIL_READ = 1'b0, AXIL_WRITE = 1'b1} axil_dir_e;

    // ---------------------------------------------------------------- transakcja
    class axil_item extends uvm_sequence_item;
        `uvm_object_utils(axil_item)

        rand axil_dir_e   dir;
        rand bit [4:0]    addr;
        rand bit [31:0]   data;           // zapis: dane do zapisu; odczyt: wypełnia driver/monitor
        rand bit [3:0]    strb;
        rand int          lag;            // zapis: takty W po AW (> 0), AW po W (< 0), razem (0)
        rand int unsigned ready_delay;    // takty wstrzymania BREADY/RREADY
        bit [1:0]         resp;           // odpowiedź układu

        constraint c_align { addr[1:0] == 2'b00; }
        constraint c_strb  { soft strb == 4'hF; }
        constraint c_lag   { lag inside {[-3:3]}; lag dist {0 := 4, [-3:-1] :/ 3, [1:3] :/ 3}; }
        constraint c_ready { ready_delay dist {0 := 6, [1:4] :/ 4}; }

        function new(string name = "axil_item");
            super.new(name);
        endfunction

        virtual function void do_copy(uvm_object rhs);
            axil_item t;
            if (!$cast(t, rhs)) `uvm_fatal("COPY", "zly typ obiektu")
            super.do_copy(rhs);
            dir         = t.dir;
            addr        = t.addr;
            data        = t.data;
            strb        = t.strb;
            lag         = t.lag;
            ready_delay = t.ready_delay;
            resp        = t.resp;
        endfunction

        virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
            axil_item t;
            if (!$cast(t, rhs)) return 0;
            return super.do_compare(rhs, comparer) && dir == t.dir && addr == t.addr && data == t.data &&
                   resp == t.resp && (dir == AXIL_READ || strb == t.strb);
        endfunction

        virtual function string convert2string();
            return $sformatf("%s 0x%02h data=0x%08h strb=%b resp=%b", dir == AXIL_WRITE ? "WR" : "RD",
                             addr, data, strb, resp);
        endfunction
    endclass

    // ---------------------------------------------------------------- konfiguracja agenta
    class axil_agent_cfg extends uvm_object;
        `uvm_object_utils(axil_agent_cfg)
        virtual axil_if         vif;
        uvm_active_passive_enum is_active = UVM_ACTIVE;
        function new(string name = "axil_agent_cfg");
            super.new(name);
        endfunction
    endclass

    typedef uvm_sequencer #(axil_item) axil_sequencer;

    // ---------------------------------------------------------------- driver
    class axil_driver extends uvm_driver #(axil_item);
        `uvm_component_utils(axil_driver)
        virtual axil_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            axil_agent_cfg cfg;
            super.build_phase(phase);
            if (!uvm_config_db #(axil_agent_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("CFG", "brak konfiguracji agenta (cfg)")
            vif = cfg.vif;
        endfunction

        task run_phase(uvm_phase phase);
            vif.drv_cb.awvalid <= 1'b0;
            vif.drv_cb.wvalid  <= 1'b0;
            vif.drv_cb.bready  <= 1'b0;
            vif.drv_cb.arvalid <= 1'b0;
            vif.drv_cb.rready  <= 1'b0;
            forever begin
                seq_item_port.get_next_item(req);
                // wyrównanie do zdarzenia bloku clocking: sekwencja mogła ruszyć w tym samym kroku czasu
                // co zbocze, ale przed zdarzeniem clocking — wtedy zapis „<=” i @(drv_cb) trafiłyby w to
                // samo zbocze i valid nie pojawiłby się na magistrali
                @(vif.drv_cb);
                while (vif.rst) @(vif.drv_cb);
                if (req.dir == AXIL_WRITE) drive_write(req);
                else                       drive_read(req);
                `uvm_info("DRV", req.convert2string(), UVM_HIGH)
                seq_item_port.item_done();
            end
        endtask

        // AW i W z przesunięciem lag taktów; potem B z opóźnionym BREADY
        virtual protected task drive_write(axil_item t);
            bit aw_done = 0, w_done = 0;
            int k = 0;
            vif.drv_cb.awaddr <= t.addr;
            vif.drv_cb.wdata  <= t.data;
            vif.drv_cb.wstrb  <= t.strb;
            while (!(aw_done && w_done)) begin
                vif.drv_cb.awvalid <= !aw_done && (t.lag >= 0 || k >= -t.lag);
                vif.drv_cb.wvalid  <= !w_done  && (t.lag <= 0 || k >= t.lag);
                @(vif.drv_cb);
                if (vif.awvalid && vif.drv_cb.awready) aw_done = 1;
                if (vif.wvalid && vif.drv_cb.wready)   w_done  = 1;
                k++;
            end
            vif.drv_cb.awvalid <= 1'b0;
            vif.drv_cb.wvalid  <= 1'b0;
            repeat (t.ready_delay) @(vif.drv_cb);
            vif.drv_cb.bready <= 1'b1;
            do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
            t.resp = vif.drv_cb.bresp;
            vif.drv_cb.bready <= 1'b0;
        endtask

        virtual protected task drive_read(axil_item t);
            vif.drv_cb.araddr  <= t.addr;
            vif.drv_cb.arvalid <= 1'b1;
            do @(vif.drv_cb); while (!vif.drv_cb.arready);
            vif.drv_cb.arvalid <= 1'b0;
            repeat (t.ready_delay) @(vif.drv_cb);
            vif.drv_cb.rready <= 1'b1;
            do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
            t.data = vif.drv_cb.rdata;
            t.resp = vif.drv_cb.rresp;
            vif.drv_cb.rready <= 1'b0;
        endtask
    endclass

    // ---------------------------------------------------------------- monitor
    // Odtwarza transakcje z przesłań na kanałach: zapis kończy przesłanie B, odczyt — przesłanie R.
    // AW i W mogą przyjść w dowolnej kolejności — monitor trzyma je w kolejkach.
    class axil_monitor extends uvm_monitor;
        `uvm_component_utils(axil_monitor)
        virtual axil_if                vif;
        uvm_analysis_port #(axil_item) ap;
        int                            n_wr = 0, n_rd = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            axil_agent_cfg cfg;
            super.build_phase(phase);
            if (!uvm_config_db #(axil_agent_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("CFG", "brak konfiguracji agenta (cfg)")
            vif = cfg.vif;
            ap  = new("ap", this);
        endfunction

        task run_phase(uvm_phase phase);
            bit [4:0]  aw_q[$], ar_q[$];
            bit [35:0] w_q[$];
            axil_item  t;
            forever begin
                @(vif.mon_cb);
                if (vif.mon_cb.rst) begin
                    aw_q.delete(); w_q.delete(); ar_q.delete();
                    continue;
                end
                // B przed AW/W: odpowiedź w tym takcie dotyczy danych przyjętych wcześniej
                if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
                    t      = axil_item::type_id::create("t");
                    t.dir  = AXIL_WRITE;
                    if (aw_q.size() == 0 || w_q.size() == 0)
                        `uvm_error("MON", "odpowiedz B bez przyjetych AW i W")
                    else begin
                        t.addr          = aw_q.pop_front();
                        {t.strb, t.data} = w_q.pop_front();
                    end
                    t.resp = vif.mon_cb.bresp;
                    n_wr++;
                    ap.write(t);
                end
                if (vif.mon_cb.awvalid && vif.mon_cb.awready) aw_q.push_back(vif.mon_cb.awaddr);
                if (vif.mon_cb.wvalid && vif.mon_cb.wready)   w_q.push_back({vif.mon_cb.wstrb, vif.mon_cb.wdata});
                if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
                    t      = axil_item::type_id::create("t");
                    t.dir  = AXIL_READ;
                    if (ar_q.size() == 0) `uvm_error("MON", "dane R bez przyjetego AR")
                    else t.addr = ar_q.pop_front();
                    t.data = vif.mon_cb.rdata;
                    t.resp = vif.mon_cb.rresp;
                    t.strb = 4'h0;
                    n_rd++;
                    ap.write(t);
                end
                if (vif.mon_cb.arvalid && vif.mon_cb.arready) ar_q.push_back(vif.mon_cb.araddr);
            end
        endtask
    endclass

    // ---------------------------------------------------------------- agent
    class axil_agent extends uvm_agent;
        `uvm_component_utils(axil_agent)
        axil_agent_cfg cfg;
        axil_driver    drv;
        axil_sequencer sqr;
        axil_monitor   mon;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db #(axil_agent_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("CFG", "brak konfiguracji agenta (cfg)")
            mon = axil_monitor::type_id::create("mon", this);
            if (cfg.is_active == UVM_ACTIVE) begin
                drv = axil_driver::type_id::create("drv", this);
                sqr = axil_sequencer::type_id::create("sqr", this);
            end
        endfunction

        function void connect_phase(uvm_phase phase);
            if (cfg.is_active == UVM_ACTIVE) drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    // ---------------------------------------------------------------- sekwencje
    class axil_base_seq extends uvm_sequence #(axil_item);
        `uvm_object_utils(axil_base_seq)

        function new(string name = "axil_base_seq");
            super.new(name);
        endfunction

        task write(bit [4:0] a, bit [31:0] d, output bit [1:0] resp, input bit [3:0] s = 4'hF);
            axil_item t = axil_item::type_id::create("t");
            start_item(t);
            if (!t.randomize() with { dir == AXIL_WRITE; addr == a; data == d; strb == s; })
                `uvm_fatal("SEQ", "randomize() nie powiodlo sie")
            finish_item(t);
            resp = t.resp;
        endtask

        task read(bit [4:0] a, output bit [31:0] d, output bit [1:0] resp);
            axil_item t = axil_item::type_id::create("t");
            start_item(t);
            if (!t.randomize() with { dir == AXIL_READ; addr == a; })
                `uvm_fatal("SEQ", "randomize() nie powiodlo sie")
            finish_item(t);
            d    = t.data;
            resp = t.resp;
        endtask
    endclass

    // n losowych transakcji; część z niepełnym WSTRB
    class axil_rand_seq extends axil_base_seq;
        `uvm_object_utils(axil_rand_seq)
        int unsigned n_items = 200;

        function new(string name = "axil_rand_seq");
            super.new(name);
        endfunction

        task body();
            repeat (n_items) begin
                axil_item t       = axil_item::type_id::create("t");
                bit       partial = ($urandom_range(3) == 0);         // co czwarty zapis z niepełnym WSTRB
                start_item(t);
                if (!t.randomize() with { strb != 4'h0; local::partial -> strb != 4'hF; })
                    `uvm_fatal("SEQ", "randomize() nie powiodlo sie")
                finish_item(t);
            end
        endtask
    endclass
endpackage

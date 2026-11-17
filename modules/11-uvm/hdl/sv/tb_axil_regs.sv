// Testbench axil_regs (bez UVM — wersja „z modułu 09”): procedury mastera AXI4-Lite z losową kolejnością
// AW/W, losowymi opóźnieniami i wstrzymaniami BREADY/RREADY; model rejestrów w zmiennych testbencha.
// Sprawdzane: wartości po resecie, każdy odczyt (dane i RRESP), BRESP, stabilność B i R przy wstrzymaniu,
// irq po każdej operacji. Pokrycie: zapis i odczyt każdego adresu, SLVERR, kasowanie W1C, irq = 1,
// częściowy WSTRB, kolejność AW przed W i W przed AW.
`timescale 1ns / 1ps

module tb_axil_regs;
    logic        clk = 1'b0, rst = 1'b1;
    logic        s_awvalid = 1'b0, s_wvalid = 1'b0, s_bready = 1'b0, s_arvalid = 1'b0, s_rready = 1'b0;
    logic [4:0]  s_awaddr = '0, s_araddr = '0;
    logic [31:0] s_wdata = '0;
    logic [3:0]  s_wstrb = '0;
    logic        s_awready, s_wready, s_bvalid, s_arready, s_rvalid, irq;
    logic [1:0]  s_bresp, s_rresp;
    logic [31:0] s_rdata;

    always #5 clk = ~clk;

    axil_regs dut (.*);

    // ---- model rejestrów ----
    logic [2:0]  m_op = '0;
    logic        m_irq_en = 1'b0, m_err = 1'b0;
    logic [7:0]  m_opa = '0, m_opb = '0;
    logic [31:0] m_scratch = '0;

    function automatic logic [31:0] m_result();
        int x = m_opa, y = m_opb, r = 0, c = 0, e = 0, sh = m_opb % 8;
        case (m_op)
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

    function automatic logic [31:0] m_read(int idx);
        case (idx)
            0: return 32'h414C_5531;
            1: return {23'd0, m_irq_en, 5'd0, m_op};
            2: return {24'd0, m_opa};
            3: return {24'd0, m_opb};
            4: return m_result();
            5: return {31'd0, m_err};
            6: return m_scratch;
            default: return '0;
        endcase
    endfunction

    function automatic logic [31:0] strb_merge(logic [31:0] old, logic [31:0] d, logic [3:0] strb);
        for (int i = 0; i < 4; i++) if (strb[i]) old[8*i +: 8] = d[8*i +: 8];
        return old;
    endfunction

    task automatic m_write(int idx, logic [31:0] d, logic [3:0] strb);
        logic [31:0] v;
        case (idx)
            1: begin
                v = strb_merge({23'd0, m_irq_en, 5'd0, m_op}, d, strb);
                m_op = v[2:0]; m_irq_en = v[8];
                if (v[2:0] == 3'd7) m_err = 1'b1;
            end
            2: begin v = strb_merge({24'd0, m_opa}, d, strb); m_opa = v[7:0]; end
            3: begin v = strb_merge({24'd0, m_opb}, d, strb); m_opb = v[7:0]; end
            5: if (strb[0] && d[0]) m_err = 1'b0;
            6: m_scratch = strb_merge(m_scratch, d, strb);
            default: ;
        endcase
    endtask

    // ---- statystyki i błędy ----
    int errors = 0, n_wr [8] = '{default: 0}, n_rd [8] = '{default: 0};
    int n_slverr_w = 0, n_slverr_r = 0, n_w1c = 0, n_irq = 0, n_part = 0, n_aw_first = 0, n_w_first = 0;

    task automatic fail(string msg);
        errors++;
        if (errors <= 10) $display("%0t: %s", $time, msg);
    endtask

    // ---- procedury mastera ----
    task automatic axi_write(logic [4:0] addr, logic [31:0] d, logic [3:0] strb, output logic [1:0] resp);
        int mode = $urandom_range(2), lag = $urandom_range(1, 3), t = 0;
        bit aw_done = 0, w_done = 0, stalled = 0;
        logic [1:0] held;
        if (mode == 1) n_aw_first++;
        if (mode == 2) n_w_first++;
        while (!(aw_done && w_done)) begin
            @(negedge clk);
            s_awvalid = !aw_done && (mode != 2 || t >= lag);
            s_awaddr  = addr;
            s_wvalid  = !w_done && (mode != 1 || t >= lag);
            s_wdata   = d;
            s_wstrb   = strb;
            #1;
            if (s_awvalid && s_awready) aw_done = 1;
            if (s_wvalid && s_wready)   w_done = 1;
            t++;
        end
        @(negedge clk);
        s_awvalid = 1'b0;
        s_wvalid  = 1'b0;
        forever begin
            s_bready = ($urandom_range(2) != 0);
            #1;
            if (stalled && (!s_bvalid || s_bresp !== held)) fail("B zmienione podczas wstrzymania");
            if (s_bvalid && s_bready) begin resp = s_bresp; break; end
            stalled = s_bvalid;
            held    = s_bresp;
            @(negedge clk);
        end
        @(negedge clk);
        s_bready = 1'b0;
    endtask

    task automatic axi_read(logic [4:0] addr, output logic [31:0] d, output logic [1:0] resp);
        bit stalled = 0;
        logic [33:0] held;
        do begin
            @(negedge clk);
            s_arvalid = 1'b1;
            s_araddr  = addr;
            #1;
        end while (!s_arready);
        @(negedge clk);
        s_arvalid = 1'b0;
        forever begin
            s_rready = ($urandom_range(2) != 0);
            #1;
            if (stalled && (!s_rvalid || {s_rresp, s_rdata} !== held)) fail("R zmienione podczas wstrzymania");
            if (s_rvalid && s_rready) begin d = s_rdata; resp = s_rresp; break; end
            stalled = s_rvalid;
            held    = {s_rresp, s_rdata};
            @(negedge clk);
        end
        @(negedge clk);
        s_rready = 1'b0;
    endtask

    task automatic check_read(int idx);
        logic [31:0] d;
        logic [1:0]  resp;
        axi_read(5'(idx * 4), d, resp);
        n_rd[idx]++;
        if (idx == 7) n_slverr_r++;
        if (resp !== ((idx == 7) ? 2'b10 : 2'b00)) fail($sformatf("RRESP=%b dla adresu 0x%02h", resp, idx * 4));
        if (d !== m_read(idx)) fail($sformatf("odczyt 0x%02h: %h, oczekiwano %h", idx * 4, d, m_read(idx)));
    endtask

    task automatic do_write(int idx, logic [31:0] d, logic [3:0] strb);
        logic [1:0] resp;
        axi_write(5'(idx * 4), d, strb, resp);
        n_wr[idx]++;
        if (idx == 7) n_slverr_w++;
        if (idx == 5 && strb[0] && d[0] && m_err) n_w1c++;
        if (idx == 6 && strb != 4'hF && strb != 4'h0) n_part++;
        m_write(idx, d, strb);
        if (resp !== ((idx == 7) ? 2'b10 : 2'b00)) fail($sformatf("BRESP=%b dla adresu 0x%02h", resp, idx * 4));
    endtask

    initial begin
        int          idx;
        logic [31:0] d;
        logic [3:0]  strb;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // 1. wartości po resecie
        for (int i = 0; i < 8; i++) check_read(i);
        // 2. operacje losowe
        for (int n = 0; n < 1500; n++) begin
            idx  = $urandom_range(7);
            d    = $urandom;
            strb = ($urandom_range(3) == 0) ? 4'($urandom) : 4'hF;
            if (idx == 1) d[2:0] = ($urandom_range(3) == 0) ? 3'd7 : 3'($urandom_range(6)); // OP = 7: co 4. zapis CTRL
            if ($urandom_range(1)) do_write(idx, d, strb);
            else                   check_read(idx);
            if (irq !== (m_err && m_irq_en)) fail($sformatf("irq=%b, oczekiwano %b", irq, m_err && m_irq_en));
            if (irq) n_irq++;
        end

        foreach (n_wr[i]) if (n_wr[i] == 0 || n_rd[i] == 0) fail($sformatf("pokrycie: adres 0x%02h", i * 4));
        if (n_slverr_w == 0 || n_slverr_r == 0 || n_w1c == 0 || n_irq == 0 || n_part == 0 ||
            n_aw_first == 0 || n_w_first == 0)
            fail($sformatf("pokrycie: slverr %0d/%0d w1c %0d irq %0d wstrb %0d aw_first %0d w_first %0d",
                           n_slverr_w, n_slverr_r, n_w1c, n_irq, n_part, n_aw_first, n_w_first));
        $display("zapisow kasujacych ERR: %0d, taktow z irq: %0d", n_w1c, n_irq);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

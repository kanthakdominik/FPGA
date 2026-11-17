// Testbench axil_regs: procedury mastera AXI4-Lite z losową kolejnością AW/W, losowymi opóźnieniami
// i wstrzymaniami BREADY/RREADY; model rejestrów w zmiennych testbencha. Sprawdzane: wartości po resecie,
// każdy odczyt (dane i RRESP), BRESP, stabilność B i R przy wstrzymaniu, irq po każdej operacji.
// Pokrycie: zapis i odczyt każdego adresu, SLVERR, kasowanie W1C, irq = 1, częściowy WSTRB,
// kolejność AW przed W i W przed AW.
`default_nettype none
`timescale 1ns / 1ps

module tb_axil_regs;
    reg         clk = 1'b0, rst = 1'b1;
    reg         s_awvalid = 1'b0, s_wvalid = 1'b0, s_bready = 1'b0, s_arvalid = 1'b0, s_rready = 1'b0;
    reg  [4:0]  s_awaddr = 5'd0, s_araddr = 5'd0;
    reg  [31:0] s_wdata = 32'd0;
    reg  [3:0]  s_wstrb = 4'd0;
    wire        s_awready, s_wready, s_bvalid, s_arready, s_rvalid, irq;
    wire [1:0]  s_bresp, s_rresp;
    wire [31:0] s_rdata;

    always #5 clk = ~clk;

    axil_regs dut (.clk(clk), .rst(rst), .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awaddr(s_awaddr),
                   .s_wvalid(s_wvalid), .s_wready(s_wready), .s_wdata(s_wdata), .s_wstrb(s_wstrb),
                   .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bresp(s_bresp), .s_arvalid(s_arvalid),
                   .s_arready(s_arready), .s_araddr(s_araddr), .s_rvalid(s_rvalid), .s_rready(s_rready),
                   .s_rdata(s_rdata), .s_rresp(s_rresp), .irq(irq));

    integer seed = 11;

    // ---- model rejestrów ----
    reg [2:0]  m_op = 3'd0;
    reg        m_irq_en = 1'b0, m_err = 1'b0;
    reg [7:0]  m_opa = 8'd0, m_opb = 8'd0;
    reg [31:0] m_scratch = 32'd0;

    function [31:0] m_result;
        input dummy;
        integer x, y, r, c, e, sh;
        begin
            x = m_opa; y = m_opb; r = 0; c = 0; e = 0; sh = m_opb % 8;
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
            m_result = {21'd0, e[0], r == 0, c[0], r[7:0]};
        end
    endfunction

    function [31:0] m_read;
        input integer idx;
        begin
            case (idx)
                0: m_read = 32'h414C_5531;
                1: m_read = {23'd0, m_irq_en, 5'd0, m_op};
                2: m_read = {24'd0, m_opa};
                3: m_read = {24'd0, m_opb};
                4: m_read = m_result(0);
                5: m_read = {31'd0, m_err};
                6: m_read = m_scratch;
                default: m_read = 32'd0;
            endcase
        end
    endfunction

    function [31:0] strb_merge;
        input [31:0] old;
        input [31:0] d;
        input [3:0]  strb;
        integer i;
        begin
            strb_merge = old;
            for (i = 0; i < 4; i = i + 1) if (strb[i]) strb_merge[8*i +: 8] = d[8*i +: 8];
        end
    endfunction

    reg [31:0] mv;
    task m_write;
        input integer idx;
        input [31:0] d;
        input [3:0]  strb;
        begin
            case (idx)
                1: begin
                    mv = strb_merge({23'd0, m_irq_en, 5'd0, m_op}, d, strb);
                    m_op = mv[2:0]; m_irq_en = mv[8];
                    if (mv[2:0] == 3'd7) m_err = 1'b1;
                end
                2: begin mv = strb_merge({24'd0, m_opa}, d, strb); m_opa = mv[7:0]; end
                3: begin mv = strb_merge({24'd0, m_opb}, d, strb); m_opb = mv[7:0]; end
                5: if (strb[0] && d[0]) m_err = 1'b0;
                6: m_scratch = strb_merge(m_scratch, d, strb);
                default: ;
            endcase
        end
    endtask

    // ---- statystyki i błędy ----
    integer errors = 0, n_slverr_w = 0, n_slverr_r = 0, n_w1c = 0, n_irq = 0, n_part = 0;
    integer n_aw_first = 0, n_w_first = 0, i, n;
    integer n_wr [0:7];
    integer n_rd [0:7];

    task fail;
        input [8*80-1:0] msg;
        begin
            errors = errors + 1;
            if (errors <= 10) $display("%0t: %0s", $time, msg);
        end
    endtask

    // ---- procedury mastera ----
    integer    mode, lag, t;
    reg        aw_done, w_done, stalled, got;
    reg [1:0]  held_b;
    reg [33:0] held_r;

    task axi_write;
        input  [4:0]  addr;
        input  [31:0] d;
        input  [3:0]  strb;
        output [1:0]  resp;
        begin
            mode = $unsigned($random(seed)) % 3;
            lag  = 1 + $unsigned($random(seed)) % 3;
            t = 0; aw_done = 0; w_done = 0; stalled = 0; got = 0;
            if (mode == 1) n_aw_first = n_aw_first + 1;
            if (mode == 2) n_w_first  = n_w_first + 1;
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
                t = t + 1;
            end
            @(negedge clk);
            s_awvalid = 1'b0;
            s_wvalid  = 1'b0;
            while (!got) begin
                s_bready = ($unsigned($random(seed)) % 3) != 0;
                #1;
                if (stalled && (!s_bvalid || s_bresp !== held_b)) fail("B zmienione podczas wstrzymania");
                if (s_bvalid && s_bready) begin
                    resp = s_bresp;
                    got  = 1;
                end else begin
                    stalled = s_bvalid;
                    held_b  = s_bresp;
                    @(negedge clk);
                end
            end
            @(negedge clk);
            s_bready = 1'b0;
        end
    endtask

    task axi_read;
        input  [4:0]  addr;
        output [31:0] d;
        output [1:0]  resp;
        begin
            stalled = 0; got = 0;
            @(negedge clk);
            s_arvalid = 1'b1;
            s_araddr  = addr;
            #1;
            while (!s_arready) begin
                @(negedge clk);
                #1;
            end
            @(negedge clk);
            s_arvalid = 1'b0;
            while (!got) begin
                s_rready = ($unsigned($random(seed)) % 3) != 0;
                #1;
                if (stalled && (!s_rvalid || {s_rresp, s_rdata} !== held_r)) fail("R zmienione podczas wstrzymania");
                if (s_rvalid && s_rready) begin
                    d    = s_rdata;
                    resp = s_rresp;
                    got  = 1;
                end else begin
                    stalled = s_rvalid;
                    held_r  = {s_rresp, s_rdata};
                    @(negedge clk);
                end
            end
            @(negedge clk);
            s_rready = 1'b0;
        end
    endtask

    reg [31:0] rd_d;
    reg [1:0]  rd_resp;
    reg [8*80-1:0] txt;

    task check_read;
        input integer idx;
        begin
            axi_read(idx * 4, rd_d, rd_resp);
            n_rd[idx] = n_rd[idx] + 1;
            if (idx == 7) n_slverr_r = n_slverr_r + 1;
            if (rd_resp !== ((idx == 7) ? 2'b10 : 2'b00)) begin
                $sformat(txt, "RRESP=%b dla adresu 0x%02h", rd_resp, idx * 4); fail(txt);
            end
            if (rd_d !== m_read(idx)) begin
                $sformat(txt, "odczyt 0x%02h: %h, oczekiwano %h", idx * 4, rd_d, m_read(idx)); fail(txt);
            end
        end
    endtask

    reg [1:0] wr_resp;

    task do_write;
        input integer idx;
        input [31:0] d;
        input [3:0]  strb;
        begin
            axi_write(idx * 4, d, strb, wr_resp);
            n_wr[idx] = n_wr[idx] + 1;
            if (idx == 7) n_slverr_w = n_slverr_w + 1;
            if (idx == 5 && strb[0] && d[0] && m_err) n_w1c = n_w1c + 1;
            if (idx == 6 && strb != 4'hF && strb != 4'h0) n_part = n_part + 1;
            m_write(idx, d, strb);
            if (wr_resp !== ((idx == 7) ? 2'b10 : 2'b00)) begin
                $sformat(txt, "BRESP=%b dla adresu 0x%02h", wr_resp, idx * 4); fail(txt);
            end
        end
    endtask

    integer    idx;
    reg [31:0] d;
    reg [3:0]  strb;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin n_wr[i] = 0; n_rd[i] = 0; end
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // 1. wartości po resecie
        for (i = 0; i < 8; i = i + 1) check_read(i);
        // 2. operacje losowe
        for (n = 0; n < 1500; n = n + 1) begin
            idx  = $unsigned($random(seed)) % 8;
            d    = $random(seed);
            strb = ($unsigned($random(seed)) % 4 == 0) ? $random(seed) : 4'hF;
            if (idx == 1) begin                                       // OP = 7: co 4. zapis CTRL
                if ($unsigned($random(seed)) % 4 == 0) d[2:0] = 3'd7;
                else                                   d[2:0] = $unsigned($random(seed)) % 7;
            end
            if ($random(seed) & 1) do_write(idx, d, strb);
            else                   check_read(idx);
            if (irq !== (m_err && m_irq_en)) fail("irq niezgodne z modelem");
            if (irq) n_irq = n_irq + 1;
        end

        for (i = 0; i < 8; i = i + 1)
            if (n_wr[i] == 0 || n_rd[i] == 0) begin
                $sformat(txt, "pokrycie: adres 0x%02h", i * 4); fail(txt);
            end
        if (n_slverr_w == 0 || n_slverr_r == 0 || n_w1c == 0 || n_irq == 0 || n_part == 0 ||
            n_aw_first == 0 || n_w_first == 0) begin
            $display("pokrycie: slverr %0d/%0d w1c %0d irq %0d wstrb %0d aw_first %0d w_first %0d",
                     n_slverr_w, n_slverr_r, n_w1c, n_irq, n_part, n_aw_first, n_w_first);
            errors = errors + 1;
        end
        $display("zapisow kasujacych ERR: %0d, operacji z irq: %0d", n_w1c, n_irq);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

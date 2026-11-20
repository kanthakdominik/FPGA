// Testbench (SystemVerilog) 21.04: Wishbone B4 w trybie potokowym — master z kolejką żądań -> wb_dekoder -> wb_ram
// (STALL co 3. takt) i wb_rejestry. Żądania w jednym cyklu CYC idą jedno za drugim bez czekania na ACK;
// odpowiedzi (ACK albo ERR, dane odczytu) sprawdzane w kolejności żądań. Sprawdzane: 64 zapisy i 64 odczyty
// pamięci w potoku, przepustowość przy STALL, rejestry (ID, SKRYTKA z maską SEL), ERR z rejestrów
// i z dekodera, 20 cykli z losową mieszanką pamięci i rejestrów.
`timescale 1ns / 1ps
`default_nettype none

module tb_wb;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0, seed = 31;
    function int los(input int zakres);
        los = ($random(seed) & 32'h7fff_ffff) % zakres;
    endfunction

    logic         cyc = 0, stb = 0, we = 0;
    logic  [9:0]  adr = 0;
    logic  [31:0] dat_w = 0;
    logic  [3:0]  sel = 0;
    logic [31:0] dat_r;
    logic        ack, err, stall;
    logic        s0_stb, s0_ack, s0_stall, s1_stb, s1_ack, s1_err, s1_stall, s_cyc, s_we;
    logic [8:0]  s0_adr;
    logic [3:0]  s1_adr, s_sel;
    logic [31:0] s0_dat, s1_dat, s_dat;
    logic [31:0] ster;
    logic        irq;

    wb_dekoder u_dek (.clk(clk), .rst(rst), .m_cyc(cyc), .m_stb(stb), .m_we(we), .m_adr(adr), .m_dat_i(dat_w),
        .m_sel(sel), .m_dat_o(dat_r), .m_ack(ack), .m_err(err), .m_stall(stall),
        .s0_stb(s0_stb), .s0_adr(s0_adr), .s0_dat_o(s0_dat), .s0_ack(s0_ack), .s0_stall(s0_stall),
        .s1_stb(s1_stb), .s1_adr(s1_adr), .s1_dat_o(s1_dat), .s1_ack(s1_ack), .s1_err(s1_err), .s1_stall(s1_stall),
        .s_cyc(s_cyc), .s_we(s_we), .s_dat_i(s_dat), .s_sel(s_sel));
    wb_ram #(.AW(9), .CO(3)) u_ram (.clk(clk), .rst(rst), .cyc(s_cyc), .stb(s0_stb), .we(s_we), .adr(s0_adr),
        .dat_i(s_dat), .sel(s_sel), .dat_o(s0_dat), .ack(s0_ack), .stall(s0_stall));
    wb_rejestry u_rej (.clk(clk), .rst(rst), .cyc(s_cyc), .stb(s1_stb), .we(s_we), .adr(s1_adr), .dat_i(s_dat),
        .sel(s_sel), .dat_o(s1_dat), .ack(s1_ack), .err(s1_err), .stall(s1_stall),
        .ster(ster), .stan(32'h0), .zdarz(8'h0), .irq(irq));

    // kolejka żądań jednego cyklu i oczekiwane odpowiedzi
    logic         q_we  [0:127];
    logic  [9:0]  q_adr [0:127];
    logic  [31:0] q_dat [0:127];
    logic  [3:0]  q_sel [0:127];
    logic         o_err [0:127];
    logic  [31:0] o_dat [0:127];                     // oczekiwane dane odczytu (dla zapisu nieistotne)
    int     nq, n_odp;
    logic  [31:0] ram_m [0:511];
    logic  [31:0] skr_m;

    always @(posedge clk) begin
        if (cyc && (ack || err)) begin
            if (ack && err) errors = errors + 1;
            if (n_odp >= nq || err !== o_err[n_odp] || (!q_we[n_odp] && ack && dat_r !== o_dat[n_odp])) begin
                if (errors < 10) $display("odpowiedz %0d (adres %h): ack %b err %b dane %h, oczekiwano err %b dane %h",
                    n_odp, q_adr[n_odp], ack, err, dat_r, o_err[n_odp], o_dat[n_odp]);
                errors = errors + 1;
            end
            n_odp = n_odp + 1;
        end
    end

    // dopisanie żądania z obliczeniem oczekiwanej odpowiedzi na modelu
    function [31:0] maskuj(input [31:0] stare, input [31:0] nowe, input [3:0] s);
        logic [31:0] m;
        begin
            m = {{8{s[3]}}, {8{s[2]}}, {8{s[1]}}, {8{s[0]}}};
            maskuj = (stare & ~m) | (nowe & m);
        end
    endfunction

    task dodaj(input w, input [9:0] a, input [31:0] d, input [3:0] s);
        begin
            q_we[nq] = w; q_adr[nq] = a; q_dat[nq] = d; q_sel[nq] = s;
            o_err[nq] = 1'b0; o_dat[nq] = 32'h0;
            if (!a[9]) begin
                if (w) ram_m[a[8:0]] = maskuj(ram_m[a[8:0]], d, s);
                o_dat[nq] = ram_m[a[8:0]];
            end else if (a[9:4] == 6'b100000 && a[3:0] <= 4'd5) begin
                if (a[3:0] == 4'd5 && w) skr_m = maskuj(skr_m, d, s);
                if (a[3:0] == 4'd0) o_dat[nq] = 32'h2102_0001;
                else if (a[3:0] == 4'd5) o_dat[nq] = skr_m;
                else o_err[nq] = 1'b1;              // inne rejestry nie są tu sprawdzane: pomijamy w losowaniu
            end else
                o_err[nq] = 1'b1;
            nq = nq + 1;
        end
    endtask

    int t0, t1;
    task cykl;                                     // wykonanie kolejki w jednym cyklu CYC
        int k;
        begin
            n_odp = 0;
            @(negedge clk) cyc = 1'b1;
            for (k = 0; k < nq; k = k + 1) begin
                stb = 1'b1; we = q_we[k]; adr = q_adr[k]; dat_w = q_dat[k]; sel = q_sel[k];
                @(posedge clk); while (stall) @(posedge clk);
                if (k == 0) t0 = $time;
                t1 = $time;
                @(negedge clk);
            end
            stb = 1'b0;
            while (n_odp < nq) @(negedge clk);
            cyc = 1'b0;
            @(negedge clk);
        end
    endtask

    int i, r;
    logic [9:0] a;
    initial begin
        skr_m = 0;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        // pamięć: 64 zapisy w jednym cyklu, potem 64 odczyty
        nq = 0;
        for (i = 0; i < 64; i = i + 1) dodaj(1'b1, i * 7, $random(seed), 4'hF);
        cykl;
        $display("zapis 64 slow w potoku: %0d taktow (STALL co 3. takt)", (t1 - t0) / 10 + 1);
        if ((t1 - t0) / 10 + 1 > 97) errors = errors + 1;
        nq = 0;
        for (i = 0; i < 64; i = i + 1) dodaj(1'b0, i * 7, 0, 4'hF);
        cykl;
        // rejestry i błędy
        nq = 0;
        dodaj(1'b0, 10'h200, 0, 4'hF);                       // ID
        dodaj(1'b1, 10'h205, 32'hDEAD_BEEF, 4'hF);
        dodaj(1'b1, 10'h205, 32'h0000_1100, 4'b0010);
        dodaj(1'b0, 10'h205, 0, 4'hF);
        dodaj(1'b0, 10'h20A, 0, 4'hF);                       // ERR z rejestrów
        dodaj(1'b0, 10'h300, 0, 4'hF);                       // ERR z dekodera
        dodaj(1'b0, 10'h000, 0, 4'hF);
        cykl;
        // losowe mieszane cykle
        for (r = 0; r < 20; r = r + 1) begin
            nq = 0;
            for (i = 0; i < 5 + los(20); i = i + 1) begin
                case (los(4))
                    0: a = 10'h200;
                    1: a = 10'h205;
                    2: a = 10'h210 + los(64);                 // poza mapą
                    default: a = los(512);
                endcase
                dodaj(a == 10'h200 ? 1'b0 : los(2), a, $random(seed), los(16));
            end
            cykl;
        end
        $display("Wishbone: zapisy i odczyty w potoku, rejestry, ERR z rejestrow i z dekodera, 20 cykli losowych");
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

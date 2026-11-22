// Testbench (SystemVerilog) zadania 11: źródło wysyła kolejne liczby z losowym s_valid (dane i valid trzymane do przyjęcia),
// odbiorca losowo zatrzymuje m_ready. Sprawdzane: każda liczba dotarła dokładnie raz i w kolejności, m_valid
// i m_data stoją, dopóki odbiorca nie przyjmie; przy s_valid = m_ready = 1 przez 100 taktów — 100 przesłań
// (pełna przepustowość mimo rejestrowanego s_ready).
`timescale 1ns / 1ps
`default_nettype none

module tb_skid_buffer;
    logic        clk = 1'b0;
    logic        rst = 1'b1;
    logic        s_valid = 1'b0;
    logic  [7:0] s_data = 8'd0;
    logic       s_ready;
    logic       m_valid;
    logic [7:0] m_data;
    logic        m_ready = 1'b0;
    always #5 clk = ~clk;

    skid_buffer #(.W(8)) dut (.clk(clk), .rst(rst), .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
                              .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data));

    int   errors = 0, n_sent = 0, n_got = 0, i, seed = 2, tryb = 0, n_full_rate = 0;
    logic       s_acc = 1'b0;
    logic       m_stall = 1'b0;
    logic [7:0] m_data_p = 8'd0;

    // zbocze: przyjęcia po obu stronach i zasada „valid nie znika bez ready”
    always @(posedge clk)
        if (!rst) begin
            s_acc = s_valid && s_ready;
            if (s_acc) n_sent = n_sent + 1;
            if (m_stall && (!m_valid || m_data !== m_data_p)) begin
                $display("%0t: wyjscie zmienilo sie bez m_ready", $time); errors = errors + 1;
            end
            if (m_valid && m_ready) begin
                if (m_data !== n_got[7:0]) begin
                    $display("%0t: odebrano %0d, oczekiwano %0d", $time, m_data, n_got[7:0]); errors = errors + 1;
                end
                n_got = n_got + 1;
                if (tryb == 1) n_full_rate = n_full_rate + 1;
            end
            m_stall  = m_valid && !m_ready;
            m_data_p = m_data;
        end

    // źródło i odbiorca: zmiany na zboczu opadającym
    always @(negedge clk)
        if (!rst) begin
            if (s_acc || !s_valid) begin
                s_valid = (tryb == 1) ? 1'b1 : (tryb == 2) ? 1'b0 : ($unsigned($random(seed)) % 100 < 70);
                s_data  = n_sent[7:0];
                s_acc   = 1'b0;
            end
            m_ready = (tryb != 0) ? 1'b1 : ($unsigned($random(seed)) % 100 < 60);
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (1500) @(posedge clk);
        tryb = 1;                          // pełna przepustowość
        repeat (5) @(negedge clk);
        n_full_rate = 0;
        repeat (100) @(negedge clk);       // dokładnie 100 zboczy narastających
        i = n_full_rate;
        tryb = 0;
        repeat (500) @(posedge clk);
        @(posedge clk) tryb = 2;           // koniec źródła (po przyjęciu bieżącego słowa), odbiór reszty
        repeat (20) @(posedge clk);
        $display("wyslanych %0d, odebranych %0d; przeslan w 100 taktach przy pelnym ruchu: %0d", n_sent, n_got, i);
        if (n_sent != n_got) begin $display("zgubione lub zdublowane slowa"); errors = errors + 1; end
        if (i != 100) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #200000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire

// Testbench bufora skid: losowe valid nadawcy i ready odbiorcy; kolejność i komplet słów,
// stabilność danych przy wstrzymaniu wyjścia, a przy ciągłym przepływie — jedno słowo na takt.
`timescale 1ns / 1ps

module tb_skid_buffer;
    localparam int W = 8, N = 200;

    logic clk = 1'b0, rst = 1'b1;
    stream_if #(.W(W)) s_if ();
    stream_if #(.W(W)) m_if ();

    always #5 clk = ~clk;

    skid_buffer #(.W(W)) dut (.clk, .rst, .s(s_if.sink), .m(m_if.source));

    int errors = 0;

    initial begin
        int          next_in = 0, next_out = 0, cycles = 0;
        logic        s_fire = 1'b0, m_fire = 1'b0, m_stall = 1'b0;
        logic [W-1:0] data_prev = '0;
        logic [15:0] lfsr = 16'h1D0B;

        s_if.valid = 1'b0; s_if.data = '0; m_if.ready = 1'b0;
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // faza 1: losowy przepływ w obie strony
        while (next_out < N && cycles < 10 * N) begin
            @(negedge clk);
            cycles++;
            if (m_fire) begin                            // słowo odebrane na ostatnim zboczu
                if (data_prev != W'(next_out)) begin
                    $display("odebrano %0d, oczekiwano %0d", data_prev, next_out); errors++;
                end
                next_out++;
            end
            if (m_stall && !(m_if.valid && m_if.data == data_prev)) begin
                $display("zmiana wyjscia przy ready = 0"); errors++;
            end
            if (s_fire) next_in++;
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 16'hB400) : (lfsr >> 1);
            if (!s_if.valid || s_fire) begin             // nowa decyzja tylko po przesłaniu lub przy valid = 0
                s_if.valid = (next_in < N) && lfsr[0];
                s_if.data  = W'(next_in);
            end
            m_if.ready = lfsr[3] | lfsr[5];
            // stan widoczny aż do następnego zbocza narastającego
            s_fire    = s_if.valid && s_if.ready;
            m_fire    = m_if.valid && m_if.ready;
            m_stall   = m_if.valid && !m_if.ready;
            data_prev = m_if.data;
        end
        if (next_out != N) begin
            $display("odebrano %0d z %0d slow", next_out, N); errors++;
        end

        // faza 2: ciągły przepływ — przepustowość jedno słowo na takt
        s_if.valid = 1'b1; m_if.ready = 1'b1;
        repeat (3) @(negedge clk);
        cycles = 0;
        repeat (50) begin
            @(negedge clk);
            cycles += (m_if.valid && s_if.ready);
        end
        if (cycles != 50) begin
            $display("przy ciaglym przeplywie tylko %0d slow na 50 taktow", cycles); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

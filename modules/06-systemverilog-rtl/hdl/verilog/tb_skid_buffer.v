// Testbench bufora skid: losowe valid i ready; kolejność i komplet słów, stabilność danych
// przy wstrzymaniu wyjścia, a przy ciągłym przepływie — jedno słowo na takt.
`default_nettype none
`timescale 1ns / 1ps

module tb_skid_buffer;
    localparam integer W = 8, N = 200;

    reg          clk = 1'b0, rst = 1'b1;
    reg  [W-1:0] s_data = 0;
    reg          s_valid = 1'b0, m_ready = 1'b0;
    wire         s_ready, m_valid;
    wire [W-1:0] m_data;

    always #5 clk = ~clk;

    skid_buffer #(.W(W)) dut (.clk(clk), .rst(rst), .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
                              .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready));

    integer errors = 0, next_in = 0, next_out = 0, cycles = 0;
    reg       s_fire = 1'b0, m_fire = 1'b0, m_stall = 1'b0;
    reg [W-1:0] data_prev = 0;
    reg [15:0]  lfsr = 16'h1D0B;

    initial begin
        @(negedge clk); @(negedge clk);
        rst = 1'b0;
        while (next_out < N && cycles < 10 * N) begin
            @(negedge clk);
            cycles = cycles + 1;
            if (m_fire) begin
                if (data_prev !== next_out[W-1:0]) begin
                    $display("odebrano %0d, oczekiwano %0d", data_prev, next_out); errors = errors + 1;
                end
                next_out = next_out + 1;
            end
            if (m_stall && !(m_valid && m_data === data_prev)) begin
                $display("zmiana wyjscia przy ready = 0"); errors = errors + 1;
            end
            if (s_fire) next_in = next_in + 1;
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 16'hB400) : (lfsr >> 1);
            if (!s_valid || s_fire) begin
                s_valid = (next_in < N) && lfsr[0];
                s_data  = next_in;
            end
            m_ready   = lfsr[3] | lfsr[5];
            s_fire    = s_valid && s_ready;
            m_fire    = m_valid && m_ready;
            m_stall   = m_valid && !m_ready;
            data_prev = m_data;
        end
        if (next_out != N) begin
            $display("odebrano %0d z %0d slow", next_out, N); errors = errors + 1;
        end

        s_valid = 1'b1; m_ready = 1'b1;
        repeat (3) @(negedge clk);
        cycles = 0;
        repeat (50) begin
            @(negedge clk);
            cycles = cycles + (m_valid && s_ready);
        end
        if (cycles != 50) begin
            $display("przy ciaglym przeplywie tylko %0d slow na 50 taktow", cycles); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

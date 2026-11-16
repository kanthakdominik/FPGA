// Testbench pack4: losowe valid po stronie bajtów, losowe ready po stronie słów (z okresem silnego
// przeciążenia), na końcu pełna przepustowość. Sprawdzane: kolejność i zawartość słów (model — kolejka bajtów),
// stabilność m_valid/m_data przy wstrzymaniu, brak zgubionych słów, s_ready = 1 przy pełnym przepływie.
// Źródło przestrzega zasady: raz podane valid i dane trzyma do przesłania.
`default_nettype none
`timescale 1ns / 1ps

module tb_pack4;
    reg         clk = 1'b0, rst = 1'b1, s_valid = 1'b0, m_ready = 1'b0;
    reg  [7:0]  s_data = 8'd0;
    wire        s_ready, m_valid;
    wire [31:0] m_data;

    always #5 clk = ~clk;

    pack4 dut (.clk(clk), .rst(rst), .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
               .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready));

    reg  [7:0]  bytes [0:8191];                // przyjęte bajty w kolejności
    reg  [31:0] held, e;
    reg         stalled = 1'b0, pending = 1'b0;
    integer     nin = 0, nout = 0, n, errors = 0, backpressure = 0, seed = 53;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 2600; n = n + 1) begin
            // 1. reguła wstrzymania: słowo niewzięte w poprzednim takcie musi stać bez zmian
            if (stalled && (m_valid !== 1'b1 || m_data !== held)) begin
                $display("takt %0d: zmiana m_valid/m_data podczas wstrzymania", n); errors = errors + 1;
            end
            // 2. nowe pobudzenia na ten takt
            if (n < 1000)      m_ready = $random(seed) & 1;
            else if (n < 1500) m_ready = (($random(seed) & 7) == 0);        // silne przeciążenie
            else if (n < 2500) m_ready = 1'b1;
            else               m_ready = 1'b1;                              // opróżnianie
            if (!pending) begin                                             // poprzedni bajt przesłany
                s_valid = (n >= 2500) ? 1'b0 : (n >= 1500) ? 1'b1 : (($random(seed) & 3) != 0);
                s_data  = $random(seed);
            end
            #1;
            // 3. przesłania w tym takcie
            if (s_valid && s_ready) begin
                bytes[nin] = s_data; nin = nin + 1;
            end
            pending = s_valid && !s_ready;     // bajt czeka — źródło trzyma valid i dane
            if (pending) backpressure = backpressure + 1;
            if (n >= 1500 && n < 2500 && !s_ready) begin
                $display("takt %0d: s_ready = 0 przy pelnym przeplywie", n); errors = errors + 1;
            end
            if (m_valid && m_ready) begin
                e = {bytes[4*nout+3], bytes[4*nout+2], bytes[4*nout+1], bytes[4*nout]};
                if (4 * nout + 3 >= nin || m_data !== e) begin
                    $display("slowo %0d: %h, oczekiwano %h", nout, m_data, e); errors = errors + 1;
                end
                nout = nout + 1;
            end
            stalled = m_valid && !m_ready;
            held    = m_data;
            @(negedge clk);
        end

        if (nout != nin / 4) begin
            $display("odebrano %0d slow z %0d bajtow", nout, nin); errors = errors + 1;
        end
        if (backpressure == 0) begin
            $display("test nie sprawdzil wstrzymania po stronie bajtow"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

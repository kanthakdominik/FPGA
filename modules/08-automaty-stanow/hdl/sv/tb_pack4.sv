// Testbench pack4: losowe valid po stronie bajtów, losowe ready po stronie słów (z okresem silnego
// przeciążenia), na końcu pełna przepustowość. Sprawdzane: kolejność i zawartość słów (model — kolejka bajtów),
// stabilność m_valid/m_data przy wstrzymaniu, brak zgubionych słów, s_ready = 1 przy pełnym przepływie.
// Źródło przestrzega zasady: raz podane valid i dane trzyma do przesłania.
`timescale 1ns / 1ps

module tb_pack4;
    logic        clk = 1'b0, rst = 1'b1, s_valid = 1'b0, m_ready = 1'b0, s_ready, m_valid;
    logic [7:0]  s_data = '0;
    logic [31:0] m_data;

    always #5 clk = ~clk;

    pack4 dut (.*);

    logic [7:0]  bytes [$];                    // przyjęte bajty, jeszcze nie spakowane w odebrane słowa
    logic [31:0] held;
    logic        stalled = 1'b0, pending = 1'b0;
    int          nin = 0, nout = 0, errors = 0, backpressure = 0;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 0; n < 2600; n++) begin
            // 1. reguła wstrzymania: słowo niewzięte w poprzednim takcie musi stać bez zmian
            if (stalled && (m_valid != 1'b1 || m_data != held)) begin
                $display("takt %0d: zmiana m_valid/m_data podczas wstrzymania", n); errors++;
            end
            // 2. nowe pobudzenia na ten takt
            if (n < 1000)      m_ready = 1'($urandom);
            else if (n < 1500) m_ready = ($urandom_range(7) == 0);           // silne przeciążenie
            else               m_ready = 1'b1;                                // pełny przepływ, opróżnianie
            if (!pending) begin                                               // poprzedni bajt przesłany
                s_valid = (n >= 2500) ? 1'b0 : (n >= 1500) ? 1'b1 : ($urandom_range(3) != 0);
                s_data  = 8'($urandom);
            end
            #1;
            // 3. przesłania w tym takcie
            if (s_valid && s_ready) begin
                bytes.push_back(s_data); nin++;
            end
            pending = s_valid && !s_ready;     // bajt czeka — źródło trzyma valid i dane
            if (pending) backpressure++;
            if (n >= 1500 && n < 2500 && !s_ready) begin
                $display("takt %0d: s_ready = 0 przy pelnym przeplywie", n); errors++;
            end
            if (m_valid && m_ready) begin
                logic [31:0] e;
                if (bytes.size() < 4) begin
                    $display("slowo %0d przed przyjeciem 4 bajtow", nout); errors++;
                end else begin
                    e = {bytes[3], bytes[2], bytes[1], bytes[0]};
                    if (m_data != e) begin
                        $display("slowo %0d: %h, oczekiwano %h", nout, m_data, e); errors++;
                    end
                    repeat (4) void'(bytes.pop_front());
                end
                nout++;
            end
            stalled = m_valid && !m_ready;
            held    = m_data;
            @(negedge clk);
        end

        if (nout != nin / 4) begin
            $display("odebrano %0d slow z %0d bajtow", nout, nin); errors++;
        end
        if (backpressure == 0) begin
            $display("test nie sprawdzil wstrzymania po stronie bajtow"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

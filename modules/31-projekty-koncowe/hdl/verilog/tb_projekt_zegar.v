// Testbench projektu 1 (31.01): komendy wysyłane szeregowo jak z terminala, odpowiedzi odbierane i porównywane.
// Skala czasu: 1 s = 10 000 taktów (CS_DZIEL = 100), bit UART = 20 taktów (1 MHz / 50 000 b/s).
`timescale 1ns / 1ps
`default_nettype none

module tb_projekt_zegar;
    localparam integer BIT = 20, CS = 100, SEK = 100 * CS;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg rx = 1'b1;
    wire tx, biegnie, pominieto, blad_ramki;
    wire [23:0] czas, stoper;
    integer errors = 0;
    integer takt = 0;
    always @(posedge clk) takt <= takt + 1;

    projekt_zegar #(.CLK_HZ(1_000_000), .BAUD(50_000), .CS_DZIEL(CS)) dut (.clk(clk), .rst(rst), .rx(rx), .tx(tx),
        .czas(czas), .stoper(stoper), .biegnie(biegnie), .pominieto(pominieto), .blad_ramki(blad_ramki));

    // ---- nadajnik testbencha (terminal)
    task wyslij(input [7:0] b);
        integer i;
        begin
            rx = 1'b0; repeat (BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin rx = b[i]; repeat (BIT) @(posedge clk); end
            rx = 1'b1; repeat (BIT) @(posedge clk);
        end
    endtask

    // ---- odbiornik testbencha: linie zakończone LF (CR pomijany), wyrównane do prawej
    reg [127:0] linia = 128'd0;
    reg [127:0] ostatnia = 128'd0;
    integer     nlinii = 0;
    reg [7:0]   b;
    integer     k;
    always begin
        @(negedge tx);
        repeat (BIT + BIT / 2) @(posedge clk);
        for (k = 0; k < 8; k = k + 1) begin b[k] = tx; repeat (BIT) @(posedge clk); end
        if (b == 8'h0A) begin
            ostatnia = linia; linia = 128'd0; nlinii = nlinii + 1;
        end else if (b != 8'h0D)
            linia = {linia[119:0], b};
    end

    task czekaj_linie;
        integer n0, t;
        begin
            n0 = nlinii; t = 0;
            while (nlinii == n0 && t < 20_000) begin @(posedge clk); t = t + 1; end
            if (nlinii == n0) begin $display("FAIL: brak odpowiedzi"); errors = errors + 1; end
        end
    endtask

    task oczekuj(input [127:0] wzor, input [8*12-1:0] co);
        begin
            czekaj_linie;
            if (ostatnia !== wzor) begin
                $display("FAIL: %0s: odpowiedz \"%0s\", oczekiwane \"%0s\"", co, ostatnia, wzor);
                errors = errors + 1;
            end else
                $display("%0s -> %0s", co, ostatnia);
        end
    endtask

    task komenda(input [8*8-1:0] s, input integer n);
        integer i;
        for (i = n - 1; i >= 0; i = i - 1) wyslij(s[i*8 +: 8]);
    endtask

    // setne z ostatnich 8 znaków "mm:ss.cc"
    function integer setne(input [127:0] l);
        setne = ((l[63:56] - 48) * 10 + (l[55:48] - 48)) * 6000 + ((l[39:32] - 48) * 10 + (l[31:24] - 48)) * 100
                + (l[15:8] - 48) * 10 + (l[7:0] - 48);
    endfunction

    task sprawdz_setne(input integer zmierzone, input integer takty, input [8*12-1:0] co);
        integer ocz;
        begin
            ocz = takty / CS;
            if (zmierzone < ocz - 1 || zmierzone > ocz + 1) begin
                $display("FAIL: %0s: %0d setnych, oczekiwane %0d +- 1", co, zmierzone, ocz);
                errors = errors + 1;
            end else
                $display("%0s: %0d setnych (z czasu testbencha %0d)", co, zmierzone, ocz);
        end
    endtask

    integer t_s, t_l, t_p, n0;
    initial begin
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);
        komenda("?", 1);         oczekuj("00:00:00", "?");
        komenda("T235958", 7);   oczekuj("OK", "T235958");
        repeat (3 * SEK) @(posedge clk);
        komenda("?", 1);         oczekuj("00:00:01", "? po 3 s");
        komenda("t010203", 7);   oczekuj("OK", "t010203");
        komenda("?", 1);         oczekuj("01:02:03", "?");
        komenda("T240000", 7);   oczekuj("ERR", "T240000");
        komenda("T125960", 7);   oczekuj("ERR", "T125960");
        komenda("T1a", 3);       oczekuj("ERR", "T1a");
        komenda("X", 1);         oczekuj("ERR", "X");
        komenda("?", 1);         czekaj_linie;                      // minęły sekundy, godzina i minuta bez zmian
        if (ostatnia[127:64] != 64'd0 || ostatnia[63:16] != "01:02:") begin
            $display("FAIL: ? po blednych komendach: \"%0s\"", ostatnia); errors = errors + 1;
        end else
            $display("? po blednych komendach -> %0s", ostatnia);

        t_s = takt; komenda("S", 1); oczekuj("OK", "S");
        if (!biegnie) begin $display("FAIL: stoper nie biegnie"); errors = errors + 1; end
        repeat (12_000) @(posedge clk);
        t_l = takt; komenda("L", 1); czekaj_linie;
        if (ostatnia[127:80] != 48'd0 || ostatnia[79:64] != "L ") begin
            $display("FAIL: L: \"%0s\"", ostatnia); errors = errors + 1;
        end
        sprawdz_setne(setne(ostatnia), t_l - t_s, "L");
        repeat (5000) @(posedge clk);
        t_p = takt; komenda("P", 1); oczekuj("OK", "P");
        repeat (2 * SEK) @(posedge clk);
        komenda("W", 1); czekaj_linie;
        sprawdz_setne(setne(ostatnia), t_p - t_s, "W po pauzie");
        if (biegnie) begin $display("FAIL: stoper biegnie po P"); errors = errors + 1; end
        komenda("R", 1);         oczekuj("OK", "R");
        komenda("W", 1);         oczekuj("00:00.00", "W po R");

        // dwie komendy jedna po drugiej: druga odpowiedź przepada, flaga pominieto
        n0 = nlinii;
        komenda("??", 2);
        repeat (6000) @(posedge clk);
        if (nlinii - n0 != 1 || !pominieto) begin
            $display("FAIL: %0d odpowiedzi na dwie komendy naraz, pominieto = %b", nlinii - n0, pominieto);
            errors = errors + 1;
        end else
            $display("?? naraz     -> 1 odpowiedz, flaga pominieto = 1");
        if (blad_ramki) begin $display("FAIL: blad ramki"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

// Testbench (SystemVerilog) I²C (20.03): i2c_master (DIV = 10, SCL 1,25 MHz przy 50 MHz) z behawioralnym modelem
// slave'a (adres 0x50, 256 rejestrów, wskaźnik z autoinkrementacją — jak pamięć EEPROM 24xx),
// linie open-drain jako iloczyn logiczny wyjść z podciąganiem. Slave losowo rozciąga zegar
// (trzyma SCL nisko do 3 µs po zboczu opadającym). Sprawdzane:
//   zapis 32 bajtów (START, adres+W, wskaźnik, dane, STOP), odczyt z powtórzonym STARTEM
//   (adres+W, wskaźnik, Sr, adres+R, dane z ACK, ostatni z NACK, STOP), brak ACK pod złym adresem,
//   minimalny czas stanu wysokiego SCL mimo rozciągania, przegrany arbitraż (drugi master ściąga SDA).
`timescale 1ns / 1ps
`default_nettype none

module tb_i2c;
    localparam DIV = 10;
    logic clk = 1'b0;
    always #10 clk = ~clk;
    logic rst = 1'b1;

    logic  [2:0] rozkaz = 3'd0;
    logic        wykonaj = 1'b0, nack_wy = 1'b0;
    logic  [7:0] wdane = 8'd0;
    logic       gotowy, wykonane, nack_we, utrata, m_scl_oe, m_sda_oe;
    logic [7:0] rdane;
    logic        s_scl_oe = 1'b0, s_sda_oe = 1'b0, obcy_sda_oe = 1'b0;
    logic       scl;
    assign scl = !(m_scl_oe || s_scl_oe);                // podciąganie + open-drain
    logic       sda;
    assign sda = !(m_sda_oe || s_sda_oe || obcy_sda_oe);

    i2c_master #(.DIV(DIV)) dut (.clk(clk), .rst(rst), .rozkaz(rozkaz), .wykonaj(wykonaj), .wdane(wdane),
        .nack_wy(nack_wy), .gotowy(gotowy), .wykonane(wykonane), .rdane(rdane), .nack_we(nack_we),
        .utrata(utrata), .scl_i(scl), .scl_oe(m_scl_oe), .sda_i(sda), .sda_oe(m_sda_oe));

    // ---------------- model slave'a
    localparam [6:0] ADR = 7'h50;
    logic  [7:0] mem [0:255];
    logic  [7:0] ptr = 8'd0, bajt = 8'd0;
    int    tryb = 0, n = 0, n_rozc = 0;             // tryb: 0 nieadresowany, 1 adres, 2 zapis, 3 odczyt
    logic        rw = 1'b0, pierwszy = 1'b0, mack = 1'b0, rozciagaj = 1'b1;

    always @(negedge sda) if (scl) begin tryb = 1; n = 0; end      // START / powtórzony START
    always @(posedge sda) if (scl) begin tryb = 0; s_sda_oe = 1'b0; end  // STOP

    always @(posedge scl) begin
        if (tryb == 1 || tryb == 2) begin
            if (n < 8) bajt = {bajt[6:0], sda};
            n = n + 1;
        end else if (tryb == 3) begin
            if (n == 8) mack = sda;                          // ACK mastera po bajcie
            n = n + 1;
        end
    end

    always @(negedge scl) begin
        if ((tryb == 1 || tryb == 2) && n == 8) begin        // po 8 bitach: ACK
            if (tryb == 1) begin
                if (bajt[7:1] == ADR) begin s_sda_oe = 1'b1; rw = bajt[0]; end
                else tryb = 0;                               // nie nasz adres: NACK (linia zwolniona)
            end else begin
                if (pierwszy) begin ptr = bajt; pierwszy = 1'b0; end
                else begin mem[ptr] = bajt; ptr = ptr + 1; end
                s_sda_oe = 1'b1;
            end
        end else if (n == 9 && tryb != 0) begin              // koniec bitu ACK
            s_sda_oe = 1'b0;
            n = 0;
            if (tryb == 1) begin
                if (rw) begin tryb = 3; s_sda_oe = !mem[ptr][7]; end
                else begin tryb = 2; pierwszy = 1'b1; end
            end else if (tryb == 3) begin
                if (!mack) begin ptr = ptr + 1; s_sda_oe = !mem[ptr][7]; end
                else tryb = 0;                               // NACK — koniec odczytu
            end
        end else if (tryb == 3 && n >= 1 && n <= 7) begin
            s_sda_oe = !mem[ptr][7 - n];                     // kolejny bit danych
        end else if (tryb == 3 && n == 8) begin
            s_sda_oe = 1'b0;                                 // zwolnij SDA na ACK mastera
        end
        // rozciąganie zegara: losowo trzymaj SCL nisko
        if (rozciagaj && tryb != 0 && ($random & 3) == 0) begin
            s_scl_oe = 1'b1;
            n_rozc   = n_rozc + 1;
            #(200 + ($random & 2047));
            s_scl_oe = 1'b0;
        end
    end

    // ---------------- pomiar stanu wysokiego SCL
    realtime t_wys;
    real     min_wys = 1.0e9;
    always @(posedge scl) t_wys = $realtime;
    always @(negedge scl) if (!rst && $realtime - t_wys < min_wys) min_wys = $realtime - t_wys;

    // ---------------- rozkazy
    int errors = 0, i;
    task wykonaj_rozkaz(input [2:0] r, input [7:0] d, input nack);
        begin
            @(negedge clk);
            wait (gotowy);
            @(negedge clk);
            rozkaz = r; wdane = d; nack_wy = nack; wykonaj = 1'b1;
            @(negedge clk) wykonaj = 1'b0;
            wait (wykonane);
            @(negedge clk);
        end
    endtask

    logic [7:0] wzor [0:31];
    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 8'hEE;
        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (20) @(negedge clk);

        // zapis 32 bajtów od rejestru 0x40
        wykonaj_rozkaz(1, 0, 0);
        wykonaj_rozkaz(3, {ADR, 1'b0}, 0);  if (nack_we) begin $display("brak ACK adresu"); errors = errors + 1; end
        wykonaj_rozkaz(3, 8'h40, 0);         if (nack_we) errors = errors + 1;
        for (i = 0; i < 32; i = i + 1) begin
            wzor[i] = $random;
            wykonaj_rozkaz(3, wzor[i], 0);  if (nack_we) errors = errors + 1;
        end
        wykonaj_rozkaz(2, 0, 0);
        for (i = 0; i < 32; i = i + 1)
            if (mem[8'h40 + i] !== wzor[i]) begin $display("zapis: rejestr %h = %h", 8'h40 + i, mem[8'h40 + i]); errors = errors + 1; end

        // odczyt: wskaźnik, powtórzony START, 32 bajty
        wykonaj_rozkaz(1, 0, 0);
        wykonaj_rozkaz(3, {ADR, 1'b0}, 0);
        wykonaj_rozkaz(3, 8'h40, 0);
        wykonaj_rozkaz(1, 0, 0);                              // Sr
        wykonaj_rozkaz(3, {ADR, 1'b1}, 0);  if (nack_we) errors = errors + 1;
        for (i = 0; i < 32; i = i + 1) begin
            wykonaj_rozkaz(4, 0, i == 31);                   // ostatni bajt z NACK
            if (rdane !== wzor[i]) begin $display("odczyt %0d: %h, oczekiwano %h", i, rdane, wzor[i]); errors = errors + 1; end
        end
        wykonaj_rozkaz(2, 0, 0);

        // zły adres
        wykonaj_rozkaz(1, 0, 0);
        wykonaj_rozkaz(3, {7'h51, 1'b0}, 0);
        if (!nack_we) begin $display("ACK pod zlym adresem"); errors = errors + 1; end
        wykonaj_rozkaz(2, 0, 0);
        if (!scl || !sda) begin $display("magistrala nie zwolniona po STOP"); errors = errors + 1; end

        $display("rozciagniec zegara: %0d, najkrotszy stan wysoki SCL %0.0f ns (wymagane >= %0d ns)", n_rozc, min_wys,
                 2 * DIV * 20);
        if (n_rozc < 20 || min_wys < 2 * DIV * 20 - 1) errors = errors + 1;

        // arbitraż: drugi master nadaje 0 tam, gdzie nasz nadaje 1 (bit 6 adresu 0x7F)
        rozciagaj = 1'b0;
        wykonaj_rozkaz(1, 0, 0);
        fork
            wykonaj_rozkaz(3, 8'hFE, 0);
            begin
                @(posedge scl); @(negedge scl);              // po bicie 7 (1 = 1)
                #50 obcy_sda_oe = 1'b1;                       // obcy master wystawia 0 w bicie 6
            end
        join
        obcy_sda_oe = 1'b0;
        if (!utrata || m_sda_oe || m_scl_oe) begin $display("arbitraz: utrata=%b", utrata); errors = errors + 1; end
        else $display("arbitraz przegrany poprawnie, linie zwolnione");

        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

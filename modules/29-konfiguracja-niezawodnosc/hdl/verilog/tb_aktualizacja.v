// Testbench 29.02: crc32 (wartość kontrolna i 256 bajtów względem funkcji wzorcowej) i aktualizacja z modelem
// rdzenia Dual Configuration (rejestry offset 0 i 1, zajętość 531 taktów po zapisie offsetu 1, zapisy w czasie
// zajętości ignorowane). Sprawdza: kolejność i zawartość zapisów, brak zapisu wyzwalającego w czasie zajętości,
// wybrany obraz, odmowę przy złym CRC i wyzerowanie licznika nadzorującego.
`timescale 1ns / 1ps
`default_nettype none

module tb_aktualizacja;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;
    integer i;

    // ---------------------------------------------------------------- CRC
    reg        zeruj = 1'b0;
    reg        cwe = 1'b0;
    reg  [7:0] bajt = 8'd0;
    wire [31:0] crc;
    crc32 u_crc (.clk(clk), .zeruj(zeruj), .we(cwe), .bajt(bajt), .crc(crc));

    function [31:0] krok(input [31:0] c, input [7:0] b);
        integer k;
        reg [31:0] t;
        begin
            t = c ^ {24'd0, b};
            for (k = 0; k < 8; k = k + 1) t = t[0] ? (t >> 1) ^ 32'hEDB8_8320 : (t >> 1);
            krok = t;
        end
    endfunction

    reg [8*9-1:0] napis = "123456789";
    reg [31:0] wz;

    // ---------------------------------------------------------------- aktualizacja + model rdzenia
    reg         start = 1'b0;
    reg         obraz = 1'b0;
    reg         obraz_ok = 1'b0;
    reg         pies = 1'b0;
    wire [2:0]  av_address;
    wire        av_write, av_read, zajety, odmowa, wyzwolono;
    wire [31:0] av_writedata;
    aktualizacja #(.CZAS(600)) dut (.clk(clk), .rst(rst), .start(start), .obraz(obraz), .obraz_ok(obraz_ok),
        .pies(pies), .av_address(av_address), .av_write(av_write), .av_writedata(av_writedata), .av_read(av_read),
        .zajety(zajety), .odmowa(odmowa), .wyzwolono(wyzwolono));

    integer busy = 0;
    integer zapisy = 0;
    integer ignorowane = 0;
    integer rekonf = 0;
    integer psy = 0;
    integer odmowy = 0;
    integer t_ovr = -1;
    integer t_rek = -1;
    integer takt = 0;
    reg     m_ovr = 1'b0;
    reg     m_sel = 1'b0;
    reg     obraz_rek = 1'b0;
    always @(posedge clk) begin
        takt = takt + 1;
        if (busy > 0) busy = busy - 1;
        if (odmowa) odmowy = odmowy + 1;
        if (av_write) begin
            zapisy = zapisy + 1;
            if (av_address == 3'd0 && av_writedata[1]) psy = psy + 1;            // watchdog: działa zawsze
            if (busy > 0) ignorowane = ignorowane + 1;
            else if (av_address == 3'd1) begin
                m_ovr = av_writedata[0]; m_sel = av_writedata[1]; busy = 531; t_ovr = takt;
            end else if (av_address == 3'd0 && av_writedata[0]) begin
                rekonf = rekonf + 1; obraz_rek = m_ovr ? m_sel : 1'b0; t_rek = takt;
            end
        end
    end

    task impuls_start(input o, input ok);
        begin
            @(negedge clk) begin start = 1'b1; obraz = o; obraz_ok = ok; end
            @(negedge clk) start = 1'b0;
        end
    endtask

    initial begin
        // CRC-32
        @(negedge clk) zeruj = 1'b1;
        @(negedge clk) zeruj = 1'b0;
        for (i = 8; i >= 0; i = i - 1) begin
            @(negedge clk) begin cwe = 1'b1; bajt = napis[8*i +: 8]; end
        end
        @(negedge clk) cwe = 1'b0;
        $display("CRC-32(\"123456789\") = 0x%08h (oczekiwane 0xCBF43926)", crc);
        if (crc !== 32'hCBF4_3926) errors = errors + 1;
        @(negedge clk) zeruj = 1'b1;
        @(negedge clk) zeruj = 1'b0;
        wz = 32'hFFFF_FFFF;
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk) begin cwe = 1'b1; bajt = (i * 37 + 11) & 8'hFF; end
            wz = krok(wz, (i * 37 + 11) & 8'hFF);
        end
        @(negedge clk) cwe = 1'b0;
        $display("CRC-32 256 bajtow: 0x%08h, funkcja wzorcowa 0x%08h", crc, ~wz);
        if (crc !== ~wz) errors = errors + 1;

        // aktualizacja
        repeat (2) @(negedge clk);
        rst = 1'b0;
        impuls_start(1'b1, 1'b0);                                         // złe CRC: odmowa
        repeat (5) @(negedge clk);
        if (odmowy != 1 || zapisy != 0) begin $display("FAIL: brak odmowy albo zapis przy zlym CRC"); errors = errors + 1; end
        @(negedge clk) pies = 1'b1;
        @(negedge clk) pies = 1'b0;
        repeat (3) @(negedge clk);
        if (psy != 1) begin $display("FAIL: brak zerowania licznika nadzorujacego"); errors = errors + 1; end
        impuls_start(1'b1, 1'b1);                                         // obraz 1, CRC dobre
        while (!wyzwolono) @(negedge clk);
        repeat (3) @(negedge clk);
        $display("zapis config_sel (obraz %0d, nadpisanie %0d) w takcie %0d, wyzwolenie w takcie %0d (odstep %0d > 531)",
                 m_sel, m_ovr, t_ovr, t_rek, t_rek - t_ovr);
        $display("zapisow %0d, zignorowanych w czasie zajetosci %0d, rekonfiguracji %0d z obrazu %0d",
                 zapisy, ignorowane, rekonf, obraz_rek);
        if (rekonf != 1 || obraz_rek != 1'b1 || ignorowane != 0 || t_rek - t_ovr <= 531 || !zajety)
            errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

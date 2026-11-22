// Testbench 27.07: rdzeń jednocyklowy rv_jedno z idealną pamięcią (odczyt kombinacyjny, 8 KB) i prostymi
// rejestrami we/wy (każdy adres 0x1000_0xxx przechowuje zapisaną wartość). Program test.S (test_prog.hex,
// złożony przez program/rvasm.py); każdy zapis rdzenia porównywany z k-tym zapisem symulatora ISS
// (test_zapisy.hex: adres, dane, maska bajtów); koniec — zapis pod TOHOST. Liczba wycofanych instrukcji
// porównana z ISS, CPI wypisane.
`timescale 1ns / 1ps
`default_nettype none

module tb_rv_jedno;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;

    reg  [31:0] pam [0:2047];
    reg  [31:0] io  [0:127];
    reg  [67:0] wzor [0:1023];
    reg  [31:0] liczby [0:1];
    wire [31:0] i_adr, d_adr, d_wdane;
    wire [3:0]  d_wstrb;
    wire        d_odczyt, wycofana;
    wire [31:0] i_dane = pam[i_adr[12:2]];
    wire [31:0] d_rdane = (d_adr[31:28] == 4'h0) ? pam[d_adr[12:2]] : io[d_adr[8:2]];
    rv_jedno dut (.clk(clk), .rst(rst), .i_adr(i_adr), .i_dane(i_dane), .d_adr(d_adr), .d_wdane(d_wdane),
        .d_wstrb(d_wstrb), .d_odczyt(d_odczyt), .d_rdane(d_rdane), .wycofana(wycofana));

    wire [31:0] maska = {{8{d_wstrb[3]}}, {8{d_wstrb[2]}}, {8{d_wstrb[1]}}, {8{d_wstrb[0]}}};
    integer k = 0, takty = 0, instr = 0, bl = 0, i;
    reg     koniec = 1'b0;
    reg [8*64-1:0] konsola = 0;

    always @(posedge clk) if (!rst && !koniec) begin
        takty = takty + 1;
        if (wycofana) instr = instr + 1;
        if (d_wstrb != 4'd0) begin
            if ({d_adr, d_wdane & maska, d_wstrb} !== wzor[k]) begin
                if (bl < 5) $display("zapis %0d: adres 0x%08h dane 0x%08h maska %b, ISS: 0x%08h 0x%08h %b", k,
                                     d_adr, d_wdane & maska, d_wstrb, wzor[k][67:36], wzor[k][35:4], wzor[k][3:0]);
                bl = bl + 1;
            end
            k = k + 1;
            if (d_adr[31:28] == 4'h0) begin
                for (i = 0; i < 4; i = i + 1)
                    if (d_wstrb[i]) pam[d_adr[12:2]][8*i +: 8] <= d_wdane[8*i +: 8];
            end else begin
                io[d_adr[8:2]] <= (io[d_adr[8:2]] & ~maska) | (d_wdane & maska);
                if (d_adr == 32'h1000_000C) konsola = {konsola[8*63-1:0], d_wdane[7:0]};
                if (d_adr == 32'h1000_0008) koniec = 1'b1;
            end
        end
    end

    initial begin
        for (i = 0; i < 2048; i = i + 1) pam[i] = 32'd0;
        for (i = 0; i < 128; i = i + 1) io[i] = 32'd0;
        $readmemh("test_prog.hex", pam);
        $readmemh("test_zapisy.hex", wzor);
        $readmemh("test_liczby.hex", liczby);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        i = 0;
        while (!koniec && i < 100000) begin @(negedge clk); i = i + 1; end
        $display("konsola: %0s", konsola);
        $display("rv_jedno: zapisow %0d (ISS %0d), niezgodnych %0d; instrukcji %0d (ISS %0d), taktow %0d, CPI = %0.3f",
                 k, liczby[0], bl, instr, liczby[1], takty, 1.0 * takty / instr);
        if (!koniec || k != liczby[0] || bl != 0 || instr != liczby[1]) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

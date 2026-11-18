// Testbench ufm_sterownik z modelem rdzenia On-Chip Flash (ufm_model poniżej): pamięć 1024 słów
// (strony po 64 słowa) skasowana do 0xFFFFFFFF, rejestry statusu i kontrolny jak w dokumentacji,
// waitrequest, opóźnienie odczytu, czasy zapisu i kasowania, ochrona sektora, zapis jako AND (flash
// zmienia tylko 1 -> 0). Sprawdzane: odczyt skasowanej komórki, zapis i odczyt, nadpisanie bez kasowania
// (wynik AND), kasowanie strony (inna strona nietknięta), przywrócenie ochrony po każdej operacji,
// brak zapisów i kasowań przy włączonej ochronie.
`timescale 1ns / 1ps
module ufm_model #(
    parameter AW = 10, STRONA = 64, T_ZAPIS = 30, T_KASUJ = 200, SEKTOR = 1
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          csr_addr, csr_read, csr_write,
    input  logic [31:0]   csr_writedata,
    output logic  [31:0]   csr_readdata,
    input  logic [AW-1:0] data_addr,
    input  logic          data_read, data_write,
    input  logic [31:0]   data_writedata,
    input  logic [3:0]    data_burstcount,
    output logic          data_waitrequest,
    output logic           data_readdatavalid,
    output logic  [31:0]   data_readdata
);
    logic [31:0] mem [0:(1<<AW)-1];
    logic [31:0] ctrl;
    logic [1:0]  busy;
    logic        rs, ws, es;
    int    licz, i, bledy_ochrony = 0;
    logic [AW-1:0] adr_op;
    logic [31:0]   dane_op;
    logic [1:0]    czekaj_rd;
    logic chroniony;
    assign chroniony = ctrl[22 + SEKTOR];
    assign data_waitrequest = (busy != 2'b00);

    initial for (i = 0; i < (1 << AW); i = i + 1) mem[i] = 32'hFFFF_FFFF;

    always @(posedge clk) begin
        data_readdatavalid <= 1'b0;
        if (csr_read) csr_readdata <= csr_addr ? ctrl : {22'h3FFFFF, 5'b00000, es, ws, rs, busy};
        if (rst) begin
            ctrl <= 32'hFFFF_FFFF; busy <= 2'b00; rs <= 1'b0; ws <= 1'b0; es <= 1'b0;
        end else begin
            if (csr_write && csr_addr) begin
                ctrl <= csr_writedata;
                if (busy == 2'b00 && csr_writedata[19:0] < (1 << AW)) begin    // kasowanie strony
                    if (csr_writedata[22 + SEKTOR]) begin es <= 1'b0; bledy_ochrony = bledy_ochrony + 1; end
                    else begin busy <= 2'b01; licz = T_KASUJ; adr_op <= csr_writedata[AW-1:0]; end
                end
            end
            case (busy)
                2'b00: begin
                    if (data_write) begin
                        if (chroniony || data_burstcount != 4'd1) begin
                            ws <= 1'b0;
                            if (chroniony) bledy_ochrony = bledy_ochrony + 1;
                        end else begin
                            busy <= 2'b10; licz = T_ZAPIS; adr_op <= data_addr; dane_op <= data_writedata;
                        end
                    end else if (data_read) begin
                        busy <= 2'b11; czekaj_rd <= 2'd2; adr_op <= data_addr;
                    end
                end
                2'b10: begin
                    licz = licz - 1;
                    if (licz == 0) begin mem[adr_op] <= mem[adr_op] & dane_op; ws <= 1'b1; busy <= 2'b00; end
                end
                2'b01: begin
                    licz = licz - 1;
                    if (licz == 0) begin
                        for (i = 0; i < STRONA; i = i + 1)
                            mem[(adr_op / STRONA) * STRONA + i] <= 32'hFFFF_FFFF;
                        es <= 1'b1; busy <= 2'b00;
                    end
                end
                default: begin                          // odczyt: dane po dwóch taktach
                    czekaj_rd <= czekaj_rd - 2'd1;
                    if (czekaj_rd == 2'd1) begin
                        data_readdata <= mem[adr_op]; data_readdatavalid <= 1'b1; rs <= 1'b1; busy <= 2'b00;
                    end
                end
            endcase
        end
    end
endmodule

module tb_ufm_sterownik;
    localparam AW = 10;
    logic clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;
    logic           start = 1'b0;
    logic  [1:0]    op = 2'd0;
    logic  [AW-1:0] addr = 0;
    logic  [31:0]   wdata = 0;
    logic          busy, done, ok;
    logic [31:0]   rdata;
    logic          csr_addr, csr_read, csr_write, data_read, data_write, waitreq, rdvalid;
    logic [31:0]   csr_wd, csr_rd, data_wd, data_rd;
    logic [AW-1:0] data_addr;
    logic [3:0]    burst;
    ufm_sterownik #(.AW(AW), .SEKTOR(1), .CZEKAJ(4)) dut (
        .clk(clk), .rst(rst), .start(start), .op(op), .addr(addr), .wdata(wdata),
        .busy(busy), .done(done), .ok(ok), .rdata(rdata),
        .csr_addr(csr_addr), .csr_read(csr_read), .csr_write(csr_write), .csr_writedata(csr_wd), .csr_readdata(csr_rd),
        .data_addr(data_addr), .data_read(data_read), .data_write(data_write), .data_writedata(data_wd),
        .data_burstcount(burst), .data_waitrequest(waitreq), .data_readdatavalid(rdvalid), .data_readdata(data_rd));
    ufm_model #(.AW(AW)) flash (
        .clk(clk), .rst(rst), .csr_addr(csr_addr), .csr_read(csr_read), .csr_write(csr_write), .csr_writedata(csr_wd),
        .csr_readdata(csr_rd), .data_addr(data_addr), .data_read(data_read), .data_write(data_write),
        .data_writedata(data_wd), .data_burstcount(burst), .data_waitrequest(waitreq),
        .data_readdatavalid(rdvalid), .data_readdata(data_rd));

    int errors = 0;
    task polecenie(input [1:0] o, input [AW-1:0] a, input [31:0] d);
        begin
            @(negedge clk) start = 1'b1; op = o; addr = a; wdata = d;
            @(negedge clk) start = 1'b0;
            wait (done);
            @(negedge clk);
            if (!flash.chroniony) begin $display("%0t: ochrona nie przywrocona", $time); errors = errors + 1; end
        end
    endtask
    task oczekuj(input [31:0] v, input [8*40-1:0] opis);
        begin
            if (!ok || rdata !== v) begin
                $display("%0s: ok=%b, odczyt %h, oczekiwano %h", opis, ok, rdata, v);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        #23 rst = 1'b0;
        polecenie(2'd0, 10'd5, 0);              oczekuj(32'hFFFF_FFFF, "odczyt skasowanej");
        polecenie(2'd1, 10'd5, 32'h1234_5678);  if (!ok) begin $display("zapis: ws = 0"); errors = errors + 1; end
        polecenie(2'd1, 10'd100, 32'hCAFE_0001);
        polecenie(2'd0, 10'd5, 0);              oczekuj(32'h1234_5678, "odczyt po zapisie");
        polecenie(2'd1, 10'd5, 32'hFFFF_0000);  // nadpisanie bez kasowania: tylko 1 -> 0
        polecenie(2'd0, 10'd5, 0);              oczekuj(32'h1234_0000, "nadpisanie bez kasowania (AND)");
        polecenie(2'd2, 10'd7, 0);              if (!ok) begin $display("kasowanie: es = 0"); errors = errors + 1; end
        polecenie(2'd0, 10'd5, 0);              oczekuj(32'hFFFF_FFFF, "po kasowaniu strony");
        polecenie(2'd0, 10'd100, 0);            oczekuj(32'hCAFE_0001, "inna strona nietknieta");
        polecenie(2'd1, 10'd5, 32'h0000_00A5);
        polecenie(2'd0, 10'd5, 0);              oczekuj(32'h0000_00A5, "zapis po kasowaniu");
        if (flash.bledy_ochrony != 0) begin $display("operacje przy wlaczonej ochronie: %0d", flash.bledy_ochrony); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #200000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule


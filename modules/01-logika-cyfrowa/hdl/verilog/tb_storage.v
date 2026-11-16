// Testbench elementów pamiętających: rejestr z zezwoleniem, przerzutnik z resetem asynchronicznym, zatrzask.
// Pobudzenia zmieniane na opadającym zboczu zegara.
`default_nettype none
`timescale 1ns / 1ps

module tb_storage;
    reg        clk  = 1'b0;
    reg        rst  = 1'b1;
    reg        en   = 1'b0;
    reg  [7:0] d    = 8'h00;
    wire [7:0] q;
    reg        arst = 1'b1;
    reg        fd   = 1'b0;
    wire       fq;
    reg        le   = 1'b0;
    reg        ld   = 1'b0;
    wire       lq;

    always #5 clk = ~clk;

    register_en #(.W(8)) u_reg (.clk(clk), .rst(rst), .en(en), .d(d), .q(q));
    dff_arst             u_ff  (.clk(clk), .arst(arst), .d(fd), .q(fq));
    d_latch              u_lat (.en(le), .d(ld), .q(lq));

    integer errors;

    task check(input ok, input [8*48-1:0] msg);
        begin
            if (!ok) begin
                $display("%0s", msg); errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        @(negedge clk);                          // pierwsze zbocze narastające wykonało reset
        check(q === 8'h00, "register_en: brak resetu synchronicznego");
        check(fq === 1'b0, "dff_arst: brak resetu asynchronicznego");

        // rejestr: zapis, pamiętanie przy en = 0, ponowny zapis
        rst = 1'b0; en = 1'b1; d = 8'hA5;
        @(negedge clk); check(q === 8'hA5, "register_en: brak zapisu przy en=1");
        en = 1'b0; d = 8'h3C;
        @(negedge clk); check(q === 8'hA5, "register_en: zmiana wyjscia przy en=0");
        en = 1'b1;
        @(negedge clk); check(q === 8'h3C, "register_en: brak zapisu po en=1");
        // reset synchroniczny działa dopiero na zboczu zegara
        rst = 1'b1;
        #1;            check(q === 8'h3C, "register_en: reset bez zbocza zegara");
        @(negedge clk); check(q === 8'h00, "register_en: brak resetu na zboczu");
        rst = 1'b0;

        // przerzutnik z resetem asynchronicznym
        arst = 1'b0; fd = 1'b1;
        @(negedge clk); check(fq === 1'b1, "dff_arst: brak zapisu na zboczu zegara");
        arst = 1'b1;
        #1;            check(fq === 1'b0, "dff_arst: reset nie zadzialal od razu");
        arst = 1'b0;
        @(negedge clk); check(fq === 1'b1, "dff_arst: brak zapisu po resecie");

        // zatrzask: przezroczysty przy en = 1, pamięta przy en = 0
        le = 1'b1; ld = 1'b1;
        #1; check(lq === 1'b1, "d_latch: brak przezroczystosci (1)");
        ld = 1'b0;
        #1; check(lq === 1'b0, "d_latch: brak przezroczystosci (0)");
        le = 1'b0;
        #1; ld = 1'b1;
        #1; check(lq === 1'b0, "d_latch: zmiana wyjscia przy en=0");

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

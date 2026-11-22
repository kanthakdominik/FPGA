// Testbench zadania 10: zapisy z różną kolejnością kanałów (AW przed W, W przed AW, oba razem), z maską bajtów
// i z opóźnionym bready (bvalid musi czekać), potem odczyty z opóźnionym rready; model 4 rejestrów. Na końcu
// 200 losowych zapisów i odczytów.
`timescale 1ns / 1ps
`default_nettype none

module tb_axil_regs;
    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg  [3:0]  awaddr = 4'd0;
    reg         awvalid = 1'b0;
    wire        awready;
    reg  [31:0] wdata = 32'd0;
    reg  [3:0]  wstrb = 4'd0;
    reg         wvalid = 1'b0;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready = 1'b0;
    reg  [3:0]  araddr = 4'd0;
    reg         arvalid = 1'b0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 1'b0;
    wire [31:0] reg0, reg1, reg2, reg3;
    always #5 clk = ~clk;

    axil_regs dut (.clk(clk), .rst(rst), .awaddr(awaddr), .awvalid(awvalid), .awready(awready), .wdata(wdata),
                   .wstrb(wstrb), .wvalid(wvalid), .wready(wready), .bresp(bresp), .bvalid(bvalid), .bready(bready),
                   .araddr(araddr), .arvalid(arvalid), .arready(arready), .rdata(rdata), .rresp(rresp),
                   .rvalid(rvalid), .rready(rready), .reg0(reg0), .reg1(reg1), .reg2(reg2), .reg3(reg3));

    reg [31:0] model [0:3];
    integer    errors = 0, n_wr = 0, n_rd = 0, i, b, seed = 8;
    integer    cyc, aw_done, w_done, seen, done;

    task axi_write(input [1:0] idx, input [31:0] d, input [3:0] s, input integer d_aw, input integer d_w,
                   input integer d_b);
        begin
            cyc = 0; aw_done = 0; w_done = 0;
            awaddr = {idx, 2'b00}; wdata = d; wstrb = s;
            while (!(aw_done && w_done)) begin
                @(negedge clk);
                awvalid = !aw_done && cyc >= d_aw;
                wvalid  = !w_done && cyc >= d_w;
                cyc = cyc + 1;
                @(posedge clk);
                if (awvalid && awready) aw_done = 1;
                if (wvalid && wready)   w_done = 1;
            end
            @(negedge clk);
            awvalid = 1'b0; wvalid = 1'b0;
            // odpowiedź: bready opóźnione o d_b taktów; bvalid nie może zniknąć przed przyjęciem
            cyc = 0; seen = 0; done = 0;
            while (!done) begin
                bready = (cyc >= d_b);
                cyc = cyc + 1;
                @(posedge clk);
                if (bvalid) seen = 1;
                else if (seen) begin $display("%0t: bvalid zniknelo bez bready", $time); errors = errors + 1; end
                if (bvalid && bready) begin
                    if (bresp !== 2'b00) begin $display("%0t: bresp=%b", $time, bresp); errors = errors + 1; end
                    done = 1;
                end else if (cyc > 50) begin
                    $display("%0t: brak odpowiedzi B", $time); errors = errors + 1; done = 1;
                end
                @(negedge clk);
            end
            bready = 1'b0;
        end
    endtask

    task model_write(input [1:0] idx, input [31:0] d, input [3:0] s);
        begin
            for (b = 0; b < 4; b = b + 1) if (s[b]) model[idx][8 * b +: 8] = d[8 * b +: 8];
            n_wr = n_wr + 1;
        end
    endtask

    task axi_read(input [1:0] idx, input integer d_r);
        begin
            @(negedge clk);
            araddr = {idx, 2'b00}; arvalid = 1'b1;
            @(posedge clk);
            while (!arready) @(posedge clk);
            @(negedge clk) arvalid = 1'b0;
            cyc = 0; done = 0;
            while (!done) begin
                rready = (cyc >= d_r);
                cyc = cyc + 1;
                @(posedge clk);
                if (rvalid && rready) begin
                    if (rdata !== model[idx] || rresp !== 2'b00) begin
                        $display("%0t: rejestr %0d: odczyt %h, oczekiwano %h", $time, idx, rdata, model[idx]);
                        errors = errors + 1;
                    end
                    n_rd = n_rd + 1;
                    done = 1;
                end else if (cyc > 50) begin
                    $display("%0t: brak odpowiedzi R", $time); errors = errors + 1; done = 1;
                end
                @(negedge clk);
            end
            rready = 1'b0;
        end
    endtask

    reg [1:0]  r_idx;
    reg [31:0] r_d;
    reg [3:0]  r_s;

    initial begin
        for (i = 0; i < 4; i = i + 1) model[i] = 32'd0;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        axi_write(2'd0, 32'h1111_1111, 4'hF, 0, 3, 0); model_write(2'd0, 32'h1111_1111, 4'hF);   // AW przed W
        axi_write(2'd1, 32'h2222_2222, 4'hF, 4, 0, 2); model_write(2'd1, 32'h2222_2222, 4'hF);   // W przed AW
        axi_write(2'd2, 32'h3333_3333, 4'hF, 0, 0, 5); model_write(2'd2, 32'h3333_3333, 4'hF);   // razem
        axi_write(2'd3, 32'hDEAD_BEEF, 4'hF, 1, 1, 0); model_write(2'd3, 32'hDEAD_BEEF, 4'hF);
        axi_write(2'd3, 32'h0000_AA00, 4'b0010, 0, 0, 1); model_write(2'd3, 32'h0000_AA00, 4'b0010); // jeden bajt
        axi_write(2'd0, 32'hFFFF_0000, 4'b1100, 2, 0, 0); model_write(2'd0, 32'hFFFF_0000, 4'b1100);
        for (i = 0; i < 4; i = i + 1) axi_read(i[1:0], i);
        if (reg3 !== 32'hDEAD_AABF || reg0 !== 32'hFFFF_1111) begin
            $display("wyjscia rejestrow: reg0=%h reg3=%h", reg0, reg3); errors = errors + 1;
        end
        for (i = 0; i < 200; i = i + 1) begin
            r_idx = $random(seed); r_d = $random(seed); r_s = $random(seed);
            if ($unsigned($random(seed)) % 2) begin
                axi_write(r_idx, r_d, r_s, $unsigned($random(seed)) % 3, $unsigned($random(seed)) % 3,
                          $unsigned($random(seed)) % 3);
                model_write(r_idx, r_d, r_s);
            end else
                axi_read(r_idx, $unsigned($random(seed)) % 3);
        end
        $display("zapisow %0d, odczytow %0d", n_wr, n_rd);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #200000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire

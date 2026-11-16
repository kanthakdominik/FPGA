// Testbench traffic_fsm dla trzech kodowań (binarne, one-hot, Graya): normalna praca porównana z modelem
// oraz wstrzykiwane przekłamania pojedynczych bitów stanu. Model zna kody stanów z tabeli (zapis niezależny
// od funkcji w układzie). Sprawdzane: wyjścia, err, powrót do R2 ze stanu nielegalnego, oraz to, że one-hot
// wykrywa każde pojedyncze przekłamanie, a kodowania 3-bitowe — nie.
`default_nettype none
`timescale 1ns / 1ps

module tb_traffic_fsm;
    reg        clk = 1'b0, rst = 1'b1, tick = 1'b0;
    reg  [2:0] up0 = 3'd0, up2 = 3'd0;
    reg  [5:0] up1 = 6'd0;
    wire [2:0] ns0, ew0, ns1, ew1, ns2, ew2;
    wire       err0, err1, err2;

    always #5 clk = ~clk;

    traffic_fsm #(.ENC(0)) u_bin  (.clk(clk), .rst(rst), .tick(tick), .upset(up0), .ns(ns0), .ew(ew0), .err(err0));
    traffic_fsm #(.ENC(1)) u_hot  (.clk(clk), .rst(rst), .tick(tick), .upset(up1), .ns(ns1), .ew(ew1), .err(err1));
    traffic_fsm #(.ENC(2)) u_gray (.clk(clk), .rst(rst), .tick(tick), .upset(up2), .ns(ns2), .ew(ew2), .err(err2));

    integer idx [0:2];                         // indeks stanu modelu, -1 = nielegalny
    integer tmr [0:2];
    integer detected [0:2], missed [0:2];
    integer errors = 0, n, k, seed = 29;
    reg [5:0] upk;

    // kody stanów z tabeli: binarne 0..5, one-hot 1 << i, Graya 000 001 011 010 110 111
    function [5:0] code_of;
        input integer enc, i;
        begin
            case (enc)
                1:       code_of = 6'd1 << i;
                2:       case (i) 0: code_of = 6'd0; 1: code_of = 6'd1; 2: code_of = 6'd3;
                                  3: code_of = 6'd2; 4: code_of = 6'd6; default: code_of = 6'd7; endcase
                default: code_of = i;
            endcase
        end
    endfunction

    function integer decode;
        input integer enc;
        input [5:0] c;
        integer i;
        begin
            decode = -1;
            for (i = 0; i < 6; i = i + 1)
                if (code_of(enc, i) == c) decode = i;
        end
    endfunction

    function integer last_of;                  // czas trwania stanu - 1 (w impulsach tick)
        input integer i;
        begin
            case (i) 0, 3: last_of = 3; 1, 4: last_of = 1; default: last_of = 0; endcase
        end
    endfunction

    task check;
        input integer k;
        input [2:0] ns, ew;
        input err;
        reg [2:0] e_ns, e_ew;
        begin
            e_ns = (idx[k] == 0) ? 3'b001 : (idx[k] == 1) ? 3'b010 : 3'b100;
            e_ew = (idx[k] == 3) ? 3'b001 : (idx[k] == 4) ? 3'b010 : 3'b100;
            if (ns !== e_ns || ew !== e_ew || err !== (idx[k] == -1)) begin
                $display("takt %0d, kodowanie %0d: ns=%b ew=%b err=%b, model stan %0d", n, k, ns, ew, err, idx[k]);
                errors = errors + 1;
            end
        end
    endtask

    task step_model;                           // stan po zboczu: przejście, potem XOR przekłamania
        input integer k;
        input [5:0] upset;
        integer nidx, ntmr, newidx;
        begin
            if (idx[k] == -1) begin
                nidx = 5; ntmr = 0;
            end else if (tick && tmr[k] == last_of(idx[k])) begin
                nidx = (idx[k] + 1) % 6; ntmr = 0;
            end else begin
                nidx = idx[k]; ntmr = tmr[k] + (tick ? 1 : 0);
            end
            newidx = decode(k, code_of(k, nidx) ^ upset);
            if (upset != 0) begin
                if (newidx == -1) detected[k] = detected[k] + 1;
                else              missed[k]   = missed[k] + 1;
            end
            idx[k] = newidx;
            tmr[k] = ntmr;
        end
    endtask

    initial begin
        for (k = 0; k < 3; k = k + 1) begin
            idx[k] = 5; tmr[k] = 0; detected[k] = 0; missed[k] = 0;
        end
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 3000; n = n + 1) begin
            check(0, ns0, ew0, err0);
            check(1, ns1, ew1, err1);
            check(2, ns2, ew2, err2);
            tick = $random(seed) & 1;
            up0 = (($random(seed) & 15) == 0) ? (3'd1 << (($random(seed) & 32'h7fffffff) % 3)) : 3'd0;
            up1 = (($random(seed) & 15) == 0) ? (6'd1 << (($random(seed) & 32'h7fffffff) % 6)) : 6'd0;
            up2 = (($random(seed) & 15) == 0) ? (3'd1 << (($random(seed) & 32'h7fffffff) % 3)) : 3'd0;
            @(negedge clk);
            step_model(0, {3'd0, up0});
            step_model(1, up1);
            step_model(2, {3'd0, up2});
        end

        $display("przeklamania wykryte/niewykryte: binarne %0d/%0d, one-hot %0d/%0d, Graya %0d/%0d",
                 detected[0], missed[0], detected[1], missed[1], detected[2], missed[2]);
        if (missed[1] != 0 || detected[1] == 0) begin
            $display("one-hot powinien wykryc kazde pojedyncze przeklamanie"); errors = errors + 1;
        end
        if (detected[0] == 0 || missed[0] == 0 || detected[2] == 0 || missed[2] == 0) begin
            $display("test nie pokazal obu przypadkow dla kodowan 3-bitowych"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

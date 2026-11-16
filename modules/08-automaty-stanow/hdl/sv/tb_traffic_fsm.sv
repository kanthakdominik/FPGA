// Testbench traffic_fsm dla trzech kodowań (binarne, one-hot, Graya): normalna praca porównana z modelem
// oraz wstrzykiwane przekłamania pojedynczych bitów stanu. Model zna kody stanów z tabeli (zapis niezależny
// od funkcji w układzie). Sprawdzane: wyjścia, err, powrót do R2 ze stanu nielegalnego, oraz to, że one-hot
// wykrywa każde pojedyncze przekłamanie, a kodowania 3-bitowe — nie.
`timescale 1ns / 1ps

module tb_traffic_fsm;
    logic       clk = 1'b0, rst = 1'b1, tick = 1'b0;
    logic [2:0] up0 = '0, up2 = '0;
    logic [5:0] up1 = '0;
    logic [2:0] ns [3], ew [3];
    logic       err [3];

    always #5 clk = ~clk;

    traffic_fsm #(.ENC(0)) u_bin  (.clk, .rst, .tick, .upset(up0), .light_ns(ns[0]), .light_ew(ew[0]), .err(err[0]));
    traffic_fsm #(.ENC(1)) u_hot  (.clk, .rst, .tick, .upset(up1), .light_ns(ns[1]), .light_ew(ew[1]), .err(err[1]));
    traffic_fsm #(.ENC(2)) u_gray (.clk, .rst, .tick, .upset(up2), .light_ns(ns[2]), .light_ew(ew[2]), .err(err[2]));

    int idx [3] = '{5, 5, 5};                  // indeks stanu modelu, -1 = nielegalny
    int tmr [3] = '{0, 0, 0};
    int detected [3] = '{0, 0, 0}, missed [3] = '{0, 0, 0};
    int errors = 0;

    // kody stanów z tabeli: binarne 0..5, one-hot 1 << i, Graya 000 001 011 010 110 111
    function automatic logic [5:0] code_of(int enc, int i);
        case (enc)
            1:       return 6'd1 << i;
            2:       case (i)
                         0: return 6'd0;  1: return 6'd1;  2: return 6'd3;
                         3: return 6'd2;  4: return 6'd6;  default: return 6'd7;
                     endcase
            default: return 6'(i);
        endcase
    endfunction

    function automatic int decode(int enc, logic [5:0] c);
        for (int i = 0; i < 6; i++)
            if (code_of(enc, i) == c) return i;
        return -1;
    endfunction

    function automatic int last_of(int i);     // czas trwania stanu - 1 (w impulsach tick)
        return (i == 0 || i == 3) ? 3 : (i == 1 || i == 4) ? 1 : 0;
    endfunction

    function automatic void check(int k, int n);
        logic [2:0] e_ns = (idx[k] == 0) ? 3'b001 : (idx[k] == 1) ? 3'b010 : 3'b100;
        logic [2:0] e_ew = (idx[k] == 3) ? 3'b001 : (idx[k] == 4) ? 3'b010 : 3'b100;
        if (ns[k] != e_ns || ew[k] != e_ew || err[k] != (idx[k] == -1)) begin
            $display("takt %0d, kodowanie %0d: ns=%b ew=%b err=%b, model stan %0d", n, k, ns[k], ew[k], err[k], idx[k]);
            errors++;
        end
    endfunction

    function automatic void step_model(int k, logic [5:0] upset);   // przejście, potem XOR przekłamania
        int nidx, ntmr, newidx;
        if (idx[k] == -1) begin
            nidx = 5; ntmr = 0;
        end else if (tick && tmr[k] >= last_of(idx[k])) begin
            nidx = (idx[k] + 1) % 6; ntmr = 0;
        end else begin
            nidx = idx[k]; ntmr = tmr[k] + int'(tick);
        end
        newidx = decode(k, code_of(k, nidx) ^ upset);
        if (upset != '0) begin
            if (newidx == -1) detected[k]++;
            else              missed[k]++;
        end
        idx[k] = newidx;
        tmr[k] = ntmr;
    endfunction

    function automatic logic [5:0] flip(int width);  // pojedyncze przekłamanie co ok. 16 taktów
        return ($urandom_range(15) == 0) ? 6'd1 << $urandom_range(width - 1) : 6'd0;
    endfunction

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            for (int k = 0; k < 3; k++) check(k, n);
            tick = 1'($urandom);
            up0  = 3'(flip(3));
            up1  = flip(6);
            up2  = 3'(flip(3));
            @(negedge clk);
            step_model(0, {3'd0, up0});
            step_model(1, up1);
            step_model(2, {3'd0, up2});
        end

        $display("przeklamania wykryte/niewykryte: binarne %0d/%0d, one-hot %0d/%0d, Graya %0d/%0d",
                 detected[0], missed[0], detected[1], missed[1], detected[2], missed[2]);
        if (missed[1] != 0 || detected[1] == 0) begin
            $display("one-hot powinien wykryc kazde pojedyncze przeklamanie"); errors++;
        end
        if (detected[0] == 0 || missed[0] == 0 || detected[2] == 0 || missed[2] == 0) begin
            $display("test nie pokazal obu przypadkow dla kodowan 3-bitowych"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

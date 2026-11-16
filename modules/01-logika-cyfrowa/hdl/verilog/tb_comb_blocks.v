// Testbench bloków kombinacyjnych: multiplekser, dekoder, enkoder priorytetowy, komparator.
// Sprawdza wszystkie kombinacje wejść.
`default_nettype none
`timescale 1ns / 1ps

module tb_comb_blocks;
    reg  [3:0] d0, d1, d2, d3;
    reg  [1:0] sel;
    wire [3:0] my;
    reg  [2:0] da;
    wire [7:0] dy;
    reg  [7:0] pa;
    wire [2:0] py;
    wire       pv;
    reg  [3:0] ca, cb;
    wire       eq, lt, gt;

    mux4       #(.W(4)) u_mux (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(sel), .y(my));
    decoder    #(.N(3)) u_dec (.a(da), .y(dy));
    prio_enc   #(.N(8)) u_pe  (.a(pa), .y(py), .valid(pv));
    comparator #(.W(4)) u_cmp (.a(ca), .b(cb), .eq(eq), .lt(lt), .gt(gt));

    integer errors, i, j, exp_idx;

    initial begin
        errors = 0;

        // multiplekser: każde wejście ma inną wartość, sprawdzamy wszystkie sel
        d0 = 4'h1; d1 = 4'h2; d2 = 4'h4; d3 = 4'h8;
        for (i = 0; i < 4; i = i + 1) begin
            sel = i; #1;
            if (my !== (4'b0001 << i)) begin
                $display("mux4: sel=%0d y=%h", i, my); errors = errors + 1;
            end
        end

        // dekoder: dokładnie jedna jedynka na pozycji a
        for (i = 0; i < 8; i = i + 1) begin
            da = i; #1;
            if (dy !== (8'b0000_0001 << i)) begin
                $display("decoder: a=%0d y=%b", i, dy); errors = errors + 1;
            end
        end

        // enkoder priorytetowy: wszystkie 256 wartości, wzorzec liczony niezależnie
        for (i = 0; i < 256; i = i + 1) begin
            pa = i; #1;
            exp_idx = -1;
            for (j = 0; j < 8; j = j + 1)
                if (pa[j]) exp_idx = j;
            if (i == 0) begin
                if (pv !== 1'b0) begin
                    $display("prio_enc: valid=1 dla a=0"); errors = errors + 1;
                end
            end else if (pv !== 1'b1 || py !== exp_idx[2:0]) begin
                $display("prio_enc: a=%b y=%0d valid=%b", pa, py, pv); errors = errors + 1;
            end
        end

        // komparator: wszystkie pary liczb 4-bitowych
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                ca = i; cb = j; #1;
                if (eq !== (i == j) || lt !== (i < j) || gt !== (i > j)) begin
                    $display("comparator: %0d ? %0d -> eq=%b lt=%b gt=%b", i, j, eq, lt, gt);
                    errors = errors + 1;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

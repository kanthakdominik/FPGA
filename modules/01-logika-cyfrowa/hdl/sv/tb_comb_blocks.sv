// Testbench bloków kombinacyjnych: multiplekser, dekoder, enkoder priorytetowy, komparator.
// Sprawdza wszystkie kombinacje wejść.
`timescale 1ns / 1ps

module tb_comb_blocks;
    logic [3:0] d0, d1, d2, d3, my;
    logic [1:0] sel;
    logic [2:0] da;
    logic [7:0] dy;
    logic [7:0] pa;
    logic [2:0] py;
    logic       pv;
    logic [3:0] ca, cb;
    logic       eq, lt, gt;

    mux4       #(.W(4)) u_mux (.*, .y(my));
    decoder    #(.N(3)) u_dec (.a(da), .y(dy));
    prio_enc   #(.N(8)) u_pe  (.a(pa), .y(py), .valid(pv));
    comparator #(.W(4)) u_cmp (.a(ca), .b(cb), .eq, .lt, .gt);

    int errors = 0;

    function automatic int highest_bit(logic [7:0] v);
        int idx = -1;
        for (int b = 0; b < 8; b++)
            if (v[b]) idx = b;
        return idx;
    endfunction

    initial begin
        // multiplekser: każde wejście ma inną wartość, sprawdzamy wszystkie sel
        d0 = 4'h1; d1 = 4'h2; d2 = 4'h4; d3 = 4'h8;
        for (int i = 0; i < 4; i++) begin
            sel = 2'(i); #1;
            if (my !== 4'(1 << i)) begin
                $display("mux4: sel=%0d y=%h", i, my); errors++;
            end
        end

        // dekoder: dokładnie jedna jedynka na pozycji a
        for (int i = 0; i < 8; i++) begin
            da = 3'(i); #1;
            if (dy !== 8'(1 << i)) begin
                $display("decoder: a=%0d y=%b", i, dy); errors++;
            end
        end

        // enkoder priorytetowy: wszystkie 256 wartości, wzorzec liczony niezależnie
        for (int i = 0; i < 256; i++) begin
            pa = 8'(i); #1;
            if (i == 0) begin
                if (pv !== 1'b0) begin
                    $display("prio_enc: valid=1 dla a=0"); errors++;
                end
            end else if (pv !== 1'b1 || int'(py) != highest_bit(pa)) begin
                $display("prio_enc: a=%b y=%0d valid=%b", pa, py, pv); errors++;
            end
        end

        // komparator: wszystkie pary liczb 4-bitowych
        for (int i = 0; i < 16; i++)
            for (int j = 0; j < 16; j++) begin
                ca = 4'(i); cb = 4'(j); #1;
                if (eq !== (i == j) || lt !== (i < j) || gt !== (i > j)) begin
                    $display("comparator: %0d ? %0d -> eq=%b lt=%b gt=%b", i, j, eq, lt, gt);
                    errors++;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

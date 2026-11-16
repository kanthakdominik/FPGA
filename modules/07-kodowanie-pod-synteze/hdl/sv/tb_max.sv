// Testbench max_chain i max_tree: przypadki brzegowe i losowe wektory, porównanie z modelem
// „element, od którego żaden inny nie jest większy” (inny zapis niż w układach).
`timescale 1ns / 1ps

module tb_max;
    localparam int N = 8, W = 8;

    logic [N-1:0][W-1:0] x = '0;
    logic [W-1:0]        y_chain, y_tree;

    max_chain #(.N(N), .W(W)) u_chain (.x, .y(y_chain));
    max_tree  #(.N(N), .W(W)) u_tree  (.x, .y(y_tree));

    int errors = 0;

    task automatic check();
        logic [W-1:0] e = '0;
        for (int i = 0; i < N; i++) begin
            int greater = 0;
            for (int j = 0; j < N; j++)
                if (x[j] > x[i]) greater++;
            if (greater == 0) e = x[i];
        end
        if (y_chain != e || y_tree != e) begin
            $display("x=%h: chain=%0d tree=%0d, oczekiwano %0d", x, y_chain, y_tree, e);
            errors++;
        end
    endtask

    initial begin
        x = '0;  #1 check();                   // same zera
        x = '1;  #1 check();                   // same maksima
        for (int k = 0; k < N; k++) begin      // maksimum na każdej pozycji
            x    = '0;
            x[k] = W'(200 + k);
            #1 check();
        end
        for (int k = 0; k < 1000; k++) begin
            for (int i = 0; i < N; i++)        // druga połowa: wartości 0..3 — dużo remisów
                x[i] = (k < 500) ? W'($urandom) : W'($urandom_range(3));
            #1 check();
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

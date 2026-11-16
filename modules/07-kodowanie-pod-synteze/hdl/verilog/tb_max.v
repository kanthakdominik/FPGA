// Testbench max_chain i max_tree: przypadki brzegowe i losowe wektory, porównanie z modelem
// „element, od którego żaden inny nie jest większy” (inny zapis niż w układach).
`default_nettype none
`timescale 1ns / 1ps

module tb_max;
    localparam N = 8, W = 8;

    reg  [N*W-1:0] x = {N*W{1'b0}};
    wire [W-1:0]   y_chain, y_tree;

    max_chain #(.N(N), .W(W)) u_chain (.x(x), .y(y_chain));
    max_tree  #(.N(N), .W(W)) u_tree  (.x(x), .y(y_tree));

    integer errors = 0, k, i, j, greater, seed = 7;
    reg [W-1:0] e;

    task check;
        begin
            e = {W{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                greater = 0;
                for (j = 0; j < N; j = j + 1)
                    if (x[j*W +: W] > x[i*W +: W]) greater = greater + 1;
                if (greater == 0) e = x[i*W +: W];
            end
            if (y_chain !== e || y_tree !== e) begin
                $display("x=%h: chain=%0d tree=%0d, oczekiwano %0d", x, y_chain, y_tree, e);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        x = {N*W{1'b0}};  #1 check;            // same zera
        x = {N*W{1'b1}};  #1 check;            // same maksima
        for (k = 0; k < N; k = k + 1) begin    // maksimum na każdej pozycji
            x = {N*W{1'b0}};
            x[k*W +: W] = 200 + k;
            #1 check;
        end
        for (k = 0; k < 1000; k = k + 1) begin
            for (i = 0; i < N; i = i + 1)       // druga połowa: wartości 0..3 — dużo remisów
                x[i*W +: W] = (k < 500) ? $random(seed) : ($random(seed) & 3);
            #1 check;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

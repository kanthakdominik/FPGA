// Testbench secded_koder + secded_dekoder (K = 32, słowo 39 bitów): 300 losowych słów bez błędu,
// każdy z 39 pojedynczych błędów dla każdego słowa (poprawa i flaga), wszystkie 741 par błędów dla
// 20 słów (wykrycie, brak flagi pojedynczego). Słowa testowe: losowe, 0 i same jedynki.
`timescale 1ns / 1ps
module tb_secded;
    localparam K = 32, R = 6, N = K + R + 1;
    logic  [K-1:0] dane;
    logic [N-1:0] kod;
    logic  [N-1:0] blad;
    logic [K-1:0] odz;
    logic         poj, pod;
    logic [R-1:0] syn;
    secded_koder   #(.K(K), .R(R)) u_k (.dane(dane), .kod(kod));
    secded_dekoder #(.K(K), .R(R)) u_d (.kod(kod ^ blad), .dane(odz), .pojedynczy(poj), .podwojny(pod), .syndrom(syn));

    int s, i, j, errors = 0, n_poj = 0, n_pod = 0;
    initial begin
        for (s = 0; s < 300; s = s + 1) begin
            dane = (s == 0) ? 32'd0 : (s == 1) ? 32'hFFFF_FFFF : $random;
            blad = {N{1'b0}};
            #1;
            if (odz !== dane || poj || pod) begin $display("bez bledu: %h -> %h", dane, odz); errors = errors + 1; end
            for (i = 0; i < N; i = i + 1) begin
                blad = {{(N-1){1'b0}}, 1'b1} << i;
                #1;
                n_poj = n_poj + 1;
                if (odz !== dane || !poj || pod) begin
                    $display("pojedynczy na pozycji %0d: %h -> %h, poj=%b pod=%b", i, dane, odz, poj, pod);
                    errors = errors + 1;
                end
            end
            if (s < 20)
                for (i = 0; i < N; i = i + 1)
                    for (j = i + 1; j < N; j = j + 1) begin
                        blad = ({{(N-1){1'b0}}, 1'b1} << i) | ({{(N-1){1'b0}}, 1'b1} << j);
                        #1;
                        n_pod = n_pod + 1;
                        if (!pod || poj) begin
                            $display("podwojny %0d,%0d: poj=%b pod=%b", i, j, poj, pod);
                            errors = errors + 1;
                        end
                    end
        end
        $display("bledy pojedyncze: %0d, podwojne: %0d", n_poj, n_pod);
        if (errors == 0 && n_poj == 300 * N && n_pod == 20 * N * (N - 1) / 2) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule


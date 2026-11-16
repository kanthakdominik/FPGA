// Testbench reset_sync i reg_styles: asynchroniczne ustawienie i synchroniczne zdjęcie resetu,
// różnica między resetem asynchronicznym, synchronicznym i rejestrem bez resetu.
`timescale 1ns / 1ps

module tb_reset;
    logic       clk = 1'b0, arst_n = 1'b0, arst = 1'b0, srst = 1'b0;
    logic [7:0] d = 8'h00, q_async, q_sync, q_none;
    logic       rst;

    always #5 clk = ~clk;                      // zbocza narastające w 5, 15, 25 … ns

    reset_sync #(.STAGES(2)) u_rs (.clk, .arst_n, .rst);
    reg_styles #(.W(8))      u_rg (.clk, .arst, .srst, .d, .q_async, .q_sync, .q_none);

    int errors = 0;

    function automatic void ensure(bit ok, string msg);
        if (!ok) begin
            $display("t=%0t: %s", $time, msg);
            errors++;
        end
    endfunction

    initial begin
        // --- reset_sync
        #1 ensure(rst === 1'b1, "brak resetu przed pierwszym zboczem");
        #6 arst_n = 1'b1;                                         // t = 7: zdjęcie między zboczami
        @(posedge clk) #1 ensure(rst === 1'b1, "reset zdjety po 1 takcie");
        @(posedge clk) #1 ensure(rst === 1'b0, "reset nie zdjety po 2 taktach");
        #2 arst_n = 1'b0;                                         // ustawienie w środku taktu
        #1 ensure(rst === 1'b1, "reset nie ustawiony asynchronicznie");
        @(negedge clk) arst_n = 1'b1;
        @(posedge clk) #1 ensure(rst === 1'b1, "reset zdjety po 1 takcie (2)");
        @(posedge clk) #1 ensure(rst === 1'b0, "reset nie zdjety po 2 taktach (2)");

        // --- reg_styles
        @(negedge clk) d = 8'hA5;
        @(posedge clk) #1 ensure(q_async == 8'hA5 && q_sync == 8'hA5 && q_none == 8'hA5, "zapis A5");
        arst = 1'b1;                                              // reset asynchroniczny w środku taktu
        #1 ensure(q_async == 8'h00, "q_async nie wyzerowany bez zbocza");
        ensure(q_sync == 8'hA5 && q_none == 8'hA5, "reset asynchroniczny zmienil inne rejestry");
        @(negedge clk) begin arst = 1'b0; srst = 1'b1; d = 8'h3C; end
        @(posedge clk) #1 ensure(q_async == 8'h3C && q_sync == 8'h00 && q_none == 8'h3C, "reset synchroniczny");
        @(negedge clk) begin srst = 1'b0; d = 8'h5A; end
        @(posedge clk) #1 ensure(q_async == 8'h5A && q_sync == 8'h5A && q_none == 8'h5A, "zapis 5A");
        srst = 1'b1;                                              // reset synchroniczny bez zbocza
        #1 ensure(q_sync == 8'h5A, "q_sync wyzerowany bez zbocza");
        @(posedge clk) #1 ensure(q_sync == 8'h00, "q_sync nie wyzerowany na zboczu");

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

// Testbench shift_piso i shift_sipo połączonych szeregowo: bajt wpisany równolegle wychodzi bit po bicie
// (od najstarszego) i po 8 przesunięciach pojawia się na wyjściu deserializatora. Przesunięcia z przerwami.
`timescale 1ns / 1ps

module tb_shift;
    logic       clk = 1'b0, load = 1'b0, shift = 1'b0, ser;
    logic [7:0] din = '0, dout;

    always #5 clk = ~clk;

    shift_piso #(.W(8)) u_tx (.clk, .load, .shift, .din, .sout(ser));
    shift_sipo #(.W(8)) u_rx (.clk, .shift, .sin(ser), .dout);

    int errors = 0;

    initial begin
        for (int n = 0; n < 100; n++) begin
            logic [7:0] value;
            int         k;
            value = 8'($urandom);              // zmienne bloku są statyczne: wartość nadana jawnie w każdym obiegu
            k     = 0;
            @(negedge clk);
            load  = 1'b1;
            din   = value;
            shift = n[0];                      // co drugi bajt: load i shift razem — load ma pierwszeństwo
            @(negedge clk);
            load  = 1'b0;
            while (k < 8) begin
                shift = ($urandom_range(2) != 0);
                if (ser != value[7-k]) begin
                    $display("bajt %0d bit %0d: sout=%b, oczekiwano %b", n, 7 - k, ser, value[7-k]); errors++;
                end
                @(negedge clk);
                if (shift) k++;
            end
            shift = 1'b0;
            if (dout != value) begin
                $display("bajt %0d: dout=%h, oczekiwano %h", n, dout, value); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

// Testbench shift_piso i shift_sipo połączonych szeregowo: bajt wpisany równolegle wychodzi bit po bicie
// (od najstarszego) i po 8 przesunięciach pojawia się na wyjściu deserializatora. Przesunięcia z przerwami.
`default_nettype none
`timescale 1ns / 1ps

module tb_shift;
    reg        clk = 1'b0, load = 1'b0, shift = 1'b0;
    reg  [7:0] din = 8'h00, byte_;
    wire       ser;
    wire [7:0] dout;

    always #5 clk = ~clk;

    shift_piso #(.W(8)) u_tx (.clk(clk), .load(load), .shift(shift), .din(din), .sout(ser));
    shift_sipo #(.W(8)) u_rx (.clk(clk), .shift(shift), .sin(ser), .dout(dout));

    integer errors = 0, n, k, seed = 5;

    initial begin
        for (n = 0; n < 100; n = n + 1) begin
            byte_ = $random(seed);
            @(negedge clk);
            load  = 1'b1;
            din   = byte_;
            shift = n[0];                      // co drugi bajt: load i shift razem — load ma pierwszeństwo
            @(negedge clk);
            load  = 1'b0;
            k     = 0;
            while (k < 8) begin
                shift = (($random(seed) % 3) != 0);
                if (ser !== byte_[7-k]) begin
                    $display("bajt %0d bit %0d: sout=%b, oczekiwano %b", n, 7 - k, ser, byte_[7-k]); errors = errors + 1;
                end
                @(negedge clk);
                if (shift) k = k + 1;
            end
            shift = 1'b0;
            if (dout !== byte_) begin
                $display("bajt %0d: dout=%h, oczekiwano %h", n, dout, byte_); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

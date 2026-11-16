// Testbench LFSR (W = 8, wielomian x^8 + x^6 + x^5 + x^4 + 1): stan nigdy nie jest zerem,
// nie powtarza się przed upływem okresu i wraca do stanu początkowego po dokładnie 255 krokach.
`default_nettype none
`timescale 1ns / 1ps

module tb_lfsr;
    localparam integer W = 8;

    reg          clk = 1'b0, rst = 1'b1, en = 1'b0;
    wire [W-1:0] q;
    reg          seen [0:255];

    always #5 clk = ~clk;

    lfsr #(.W(W), .TAPS(8'hB8), .SEED(8'h01)) dut (.clk(clk), .rst(rst), .en(en), .q(q));

    integer errors = 0, k;
    reg [W-1:0] model;

    initial begin
        for (k = 0; k < 256; k = k + 1) seen[k] = 1'b0;
        @(negedge clk);
        rst = 1'b0; en = 1'b1;
        model = 8'h01;
        for (k = 0; k < 255; k = k + 1) begin
            if (q !== model) begin
                $display("krok %0d: q=%h model=%h", k, q, model); errors = errors + 1;
            end
            if (q == 0 || seen[q]) begin
                $display("krok %0d: stan %h zero lub powtorzony", k, q); errors = errors + 1;
            end
            seen[q] = 1'b1;
            // model: przesunięcie w prawo, XOR z wielomianem, gdy wysunięty bit = 1
            model = model[0] ? ((model >> 1) ^ 8'hB8) : (model >> 1);
            @(negedge clk);
        end
        if (q !== 8'h01) begin
            $display("po 255 krokach q=%h zamiast 01", q); errors = errors + 1;
        end
        // en = 0: stan zatrzymany
        en = 1'b0;
        @(negedge clk); @(negedge clk);
        if (q !== 8'h01) begin
            $display("zmiana stanu przy en=0"); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

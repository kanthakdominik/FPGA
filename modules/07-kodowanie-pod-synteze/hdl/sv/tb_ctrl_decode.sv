// Testbench ctrl_decode: wszystkie 32 kombinacje wejść, model zapisany równaniami na bitach.
`timescale 1ns / 1ps

module tb_ctrl_decode;
    logic [2:0] op = '0;
    logic       valid = 1'b0, busy = 1'b0, rd_en, wr_en, err;
    logic [1:0] sel;

    ctrl_decode dut (.*);

    int errors = 0;

    initial begin
        for (int v = 0; v < 32; v++) begin
            logic       go, e_rd, e_wr, e_err;
            logic [1:0] e_sel;
            {valid, busy, op} = 5'(v);
            #1;
            go    = valid & ~op[2] & ~busy;     // dozwolona operacja, nic nie blokuje
            e_err = valid & op[2];
            e_rd  = go & op[0];                 // READ (001) i RMW (011)
            e_wr  = go & op[1];                 // WRITE (010) i RMW (011)
            e_sel = go ? op[1:0] : 2'd0;
            if ({rd_en, wr_en, sel, err} !== {e_rd, e_wr, e_sel, e_err}) begin
                $display("valid=%b busy=%b op=%b: rd=%b wr=%b sel=%b err=%b", valid, busy, op, rd_en, wr_en, sel, err);
                errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

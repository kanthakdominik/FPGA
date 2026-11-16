// Testbench ctrl_decode: wszystkie 32 kombinacje wejść, model zapisany równaniami na bitach.
`default_nettype none
`timescale 1ns / 1ps

module tb_ctrl_decode;
    reg  [2:0] op = 3'd0;
    reg        valid = 1'b0, busy = 1'b0;
    wire       rd_en, wr_en, err;
    wire [1:0] sel;

    ctrl_decode dut (.op(op), .valid(valid), .busy(busy), .rd_en(rd_en), .wr_en(wr_en), .sel(sel), .err(err));

    integer errors = 0, v;
    reg       go, e_rd, e_wr, e_err;
    reg [1:0] e_sel;

    initial begin
        for (v = 0; v < 32; v = v + 1) begin
            {valid, busy, op} = v;
            #1;
            go    = valid & ~op[2] & ~busy;     // dozwolona operacja, nic nie blokuje
            e_err = valid & op[2];
            e_rd  = go & op[0];                 // READ (001) i RMW (011)
            e_wr  = go & op[1];                 // WRITE (010) i RMW (011)
            e_sel = go ? op[1:0] : 2'd0;
            if ({rd_en, wr_en, sel, err} !== {e_rd, e_wr, e_sel, e_err}) begin
                $display("valid=%b busy=%b op=%b: rd=%b wr=%b sel=%b err=%b", valid, busy, op, rd_en, wr_en, sel, err);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire

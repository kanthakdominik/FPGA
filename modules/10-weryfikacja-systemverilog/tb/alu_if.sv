// Interfejs ALU: sygnały układu i bloki taktowania (clocking) dla drivera i monitora.
// Wejścia bloku próbkowane tuż przed zboczem (#1step), wyjścia zmieniane 1 ns po zboczu —
// testbench nie ściga się z układem o to, kto pierwszy zobaczy zbocze.
interface alu_if #(
    parameter int W = 8
) (
    input logic clk
);
    logic         rst;
    logic         in_valid, in_ready;
    logic [2:0]   op;
    logic [W-1:0] a, b;
    logic         out_valid, out_ready;
    logic [W-1:0] res;
    logic         carry, zero, err;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output rst, in_valid, op, a, b, out_ready;
        input  in_ready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst, in_valid, in_ready, op, a, b, out_valid, out_ready, res, carry, zero, err;
    endclocking

    modport drv (clocking drv_cb);
    modport mon (clocking mon_cb);
endinterface

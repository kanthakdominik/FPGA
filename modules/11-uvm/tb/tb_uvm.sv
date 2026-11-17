// Górny moduł środowiska UVM: zegar, reset, interfejs, układ, przekazanie interfejsu do config_db,
// uruchomienie testu wybranego przez +UVM_TESTNAME. BUG — parametr układu (Verilator: -GBUG=n).
`timescale 1ns / 1ps

module tb_uvm #(
    parameter int BUG = 0
);
    import uvm_pkg::*;
    import tests_pkg::*;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    axil_if vif (.clk(clk));

    initial begin
        vif.rst = 1'b1;
        repeat (5) @(posedge clk);
        vif.rst <= 1'b0;
    end

    axil_regs #(.BUG(BUG)) dut (
        .clk(clk), .rst(vif.rst),
        .s_awvalid(vif.awvalid), .s_awready(vif.awready), .s_awaddr(vif.awaddr),
        .s_wvalid(vif.wvalid), .s_wready(vif.wready), .s_wdata(vif.wdata), .s_wstrb(vif.wstrb),
        .s_bvalid(vif.bvalid), .s_bready(vif.bready), .s_bresp(vif.bresp),
        .s_arvalid(vif.arvalid), .s_arready(vif.arready), .s_araddr(vif.araddr),
        .s_rvalid(vif.rvalid), .s_rready(vif.rready), .s_rdata(vif.rdata), .s_rresp(vif.rresp),
        .irq(vif.irq)
    );

    initial begin
        uvm_config_db #(virtual axil_if)::set(null, "uvm_test_top", "vif", vif);
        uvm_config_db #(int unsigned)::set(null, "uvm_test_top", "n_items", 1500);
        $display("BUG=%0d", BUG);
        run_test();
    end
endmodule

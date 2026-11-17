// Interfejs AXI4-Lite (adres 5 bitów, dane 32 bity): sygnały, bloki clocking dla drivera (master)
// i monitora oraz asercje reguł handshake z AMBA AXI (valid nie opada przed ready, dane stabilne).
// Liczniki naruszeń czyta test (raport w fazie check).
interface axil_if (
    input logic clk
);
    logic        rst;
    logic        awvalid, awready;
    logic [4:0]  awaddr;
    logic        wvalid, wready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        bvalid, bready;
    logic [1:0]  bresp;
    logic        arvalid, arready;
    logic [4:0]  araddr;
    logic        rvalid, rready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        irq;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output awvalid, awaddr, wvalid, wdata, wstrb, bready, arvalid, araddr, rready;
        input  awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst, awvalid, awready, awaddr, wvalid, wready, wdata, wstrb, bvalid, bready, bresp,
              arvalid, arready, araddr, rvalid, rready, rdata, rresp, irq;
    endclocking

    // ---- reguły handshake: źródło trzyma valid i dane do przyjęcia ----
    int n_fail = 0;

    function automatic void fail(string name);
        n_fail++;
        if (n_fail <= 5) $display("%t: axil_if: naruszenie %s", $time, name);
    endfunction

    property p_hold(logic v, logic r, logic [63:0] d);
        @(posedge clk) disable iff (rst) v && !r |=> v && $stable(d);
    endproperty

    a_aw: assert property (p_hold(awvalid, awready, {59'd0, awaddr}))          else fail("AW");
    a_w:  assert property (p_hold(wvalid, wready, {28'd0, wstrb, wdata}))     else fail("W");
    a_b:  assert property (p_hold(bvalid, bready, {62'd0, bresp}))            else fail("B");
    a_ar: assert property (p_hold(arvalid, arready, {59'd0, araddr}))         else fail("AR");
    a_r:  assert property (p_hold(rvalid, rready, {30'd0, rresp, rdata}))     else fail("R");
    a_rst: assert property (@(posedge clk) rst |=> !bvalid && !rvalid)       else fail("reset");
endinterface

// Przemiana w dół (DDC, 26.06): sygnał rzeczywisty x mnożony przez cos i -sin z NCO (częstotliwość nośnej ftw)
// daje składowe I i Q pasma podstawowego (iloczyny zaokrąglone do 16 bitów), potem decymacja CIC przez 8
// w każdej gałęzi. Próbka x jest opóźniona o 2 takty, żeby spotkać się z próbką NCO dla tej samej fazy.
`default_nettype none

module ddc (
    input  wire               clk,
    input  wire               rst,
    input  wire               we,
    input  wire signed [15:0] x,
    input  wire        [31:0] ftw,
    output wire signed [15:0] i_wy,
    output wire signed [15:0] q_wy,
    output wire               wy_wazne
);
    wire signed [15:0] s, c;
    wire               nw;
    nco u_nco (.clk(clk), .rst(rst), .we(we), .ftw(ftw), .sin_o(s), .cos_o(c), .wazne(nw));

    reg signed [15:0] x1, x2, mi, mq;
    reg               mw;
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [31:0] pi = x2 * c + 32'sd16384;
    wire signed [31:0] pq = -(x2 * s) + 32'sd16384;
    /* verilator lint_on WIDTHEXPAND */
    wire signed [16:0] ri = pi[31:15];
    wire signed [16:0] rq = pq[31:15];
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
        if (rst) begin
            x1 <= 16'sd0; x2 <= 16'sd0; mi <= 16'sd0; mq <= 16'sd0; mw <= 1'b0;
        end else begin
            x1 <= x;
            x2 <= x1;
            mw <= nw;
            mi <= (ri > 17'sd32767) ? 16'sh7FFF : (ri < -17'sd32768) ? 16'sh8000 : ri[15:0];
            mq <= (rq > 17'sd32767) ? 16'sh7FFF : (rq < -17'sd32768) ? 16'sh8000 : rq[15:0];
        end
    end

    /* verilator lint_off UNUSEDSIGNAL */
    wire wq_nieuzyte;                              // tak samo jak wy_wazne
    /* verilator lint_on UNUSEDSIGNAL */
    cic_dec #(.R(8)) u_ci (.clk(clk), .rst(rst), .we(mw), .x(mi), .y(i_wy), .y_wazne(wy_wazne));
    cic_dec #(.R(8)) u_cq (.clk(clk), .rst(rst), .we(mw), .x(mq), .y(q_wy), .y_wazne(wq_nieuzyte));
endmodule

`default_nettype wire

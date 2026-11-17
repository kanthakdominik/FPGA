// Dzielnik kombinacyjny ze ścieżką wielotaktową (14.04): q = a / b, r = a % b.
// start = 1 zapisuje argumenty do a_r, b_r; wynik trafia do q, r dokładnie N taktów później (done = 1).
// Między a_r/b_r a q/r jest długa logika kombinacyjna, ale argumenty są stałe przez N taktów,
// więc ścieżka ma N okresów zegara: set_multicycle_path -setup N, -hold N-1 (pliki .sdc modułu).
// b = 0: q = same jedynki, r = a (jak w wielu procesorach RISC-V).
`default_nettype none

module dzielnik_mc #(
    parameter W  = 16,                     // szerokość dzielnej
    parameter V  = 8,                      // szerokość dzielnika
    parameter N  = 4                       // liczba taktów na dzielenie (>= 2)
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,             // ignorowane, gdy busy
    input  wire [W-1:0] a,
    input  wire [V-1:0] b,
    output reg          busy,
    output reg          done,              // 1 takt, wynik ważny od tego taktu
    output reg  [W-1:0] q,
    output reg  [V-1:0] r
);
    localparam CW = $clog2(N);
    /* verilator lint_off WIDTHTRUNC */        // stała mieści się w CW bitach z definicji CW
    localparam [CW-1:0] LAST = N - 1;
    /* verilator lint_on WIDTHTRUNC */
    localparam [CW-1:0] ONE  = 1;

    reg  [W-1:0]  a_r;
    reg  [V-1:0]  b_r;
    reg  [CW-1:0] cnt;
    wire [W-1:0]  b_w = {{(W-V){1'b0}}, b_r};
    wire [W-1:0]  q_c = a_r / b_w;
    /* verilator lint_off UNUSEDSIGNAL */      // reszta < b mieści się w V bitach; starsze bity zawsze 0
    wire [W-1:0]  r_c = a_r % b_w;
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0;
            cnt  <= {CW{1'b0}};
        end else if (!busy) begin
            if (start) begin
                a_r  <= a;
                b_r  <= b;
                busy <= 1'b1;
                cnt  <= {CW{1'b0}};
            end
        end else if (cnt == LAST) begin
            // jedyny takt, w którym wynik jest zapisywany: N taktów po zapisie argumentów
            q    <= (b_r == {V{1'b0}}) ? {W{1'b1}} : q_c;
            r    <= (b_r == {V{1'b0}}) ? a_r[V-1:0] : r_c[V-1:0];
            busy <= 1'b0;
            done <= 1'b1;
        end else begin
            cnt <= cnt + ONE;
        end
    end
endmodule

`default_nettype wire

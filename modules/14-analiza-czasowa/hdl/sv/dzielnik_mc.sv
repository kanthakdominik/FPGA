// Dzielnik kombinacyjny ze ścieżką wielotaktową (14.04): q = a / b, r = a % b.
// start = 1 zapisuje argumenty do a_r, b_r; wynik trafia do q_r, r_r dokładnie N taktów później (done = 1).
// Między a_r/b_r a q_r/r_r jest długa logika kombinacyjna, ale argumenty są stałe przez N taktów,
// więc ścieżka ma N okresów zegara: set_multicycle_path -setup N, -hold N-1 (pliki .sdc modułu).
// b = 0: q = same jedynki, r = a (jak w wielu procesorach RISC-V).
module dzielnik_mc #(
    parameter int W = 16,                  // szerokość dzielnej
    parameter int V = 8,                   // szerokość dzielnika
    parameter int N = 4                    // liczba taktów na dzielenie (>= 2)
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,            // ignorowane, gdy busy
    input  logic [W-1:0] a,
    input  logic [V-1:0] b,
    output logic         busy,
    output logic         done,             // 1 takt, wynik ważny od tego taktu
    output logic [W-1:0] q,
    output logic [V-1:0] r
);
    localparam int CW = $clog2(N);
    localparam logic [CW-1:0] LAST = CW'(N - 1);

    logic [W-1:0]  a_r;
    logic [V-1:0]  b_r;
    logic [CW-1:0] cnt;

    always_ff @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0;
            cnt  <= '0;
        end else if (!busy) begin
            if (start) begin
                a_r  <= a;
                b_r  <= b;
                busy <= 1'b1;
                cnt  <= '0;
            end
        end else if (cnt == LAST) begin
            // jedyny takt, w którym wynik jest zapisywany: N taktów po zapisie argumentów
            q    <= (b_r == '0) ? '1  : a_r / W'(b_r);
            r    <= (b_r == '0) ? V'(a_r) : V'(a_r % W'(b_r));
            busy <= 1'b0;
            done <= 1'b1;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule

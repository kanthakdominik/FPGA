// Eliminacja drgań styków: wyjście zmienia stan dopiero, gdy wejście jest stabilne przez STABLE_CYCLES taktów.
module debouncer #(
    parameter int STABLE_CYCLES = 500000           // 10 ms przy 50 MHz
) (
    input  logic clk,
    input  logic rst,
    input  logic noisy,
    output logic clean,
    output logic changed
);
    localparam int CW = $clog2(STABLE_CYCLES);

    logic [1:0]    sync = '0;
    logic [CW-1:0] cnt  = '0;

    always_ff @(posedge clk) begin
        sync    <= {sync[0], noisy};
        changed <= 1'b0;
        if (rst) begin
            clean <= 1'b0;
            cnt   <= '0;
        end else if (sync[1] == clean) begin
            cnt <= '0;
        end else if (cnt == CW'(STABLE_CYCLES - 1)) begin
            clean   <= sync[1];
            changed <= 1'b1;
            cnt     <= '0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule

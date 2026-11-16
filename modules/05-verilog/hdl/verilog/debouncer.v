// Eliminacja drgań styków: wyjście zmienia stan dopiero, gdy wejście jest stabilne przez STABLE_CYCLES taktów.
// Wejście asynchroniczne przechodzi przez synchronizator dwuprzerzutnikowy.
`default_nettype none

module debouncer #(
    parameter integer STABLE_CYCLES = 500000       // 10 ms przy 50 MHz
) (
    input  wire clk,
    input  wire rst,                               // synchroniczny, aktywny wysoki
    input  wire noisy,                             // np. przycisk
    output reg  clean,
    output reg  changed                            // impuls 1 takt przy zmianie clean
);
    localparam integer CW = $clog2(STABLE_CYCLES);

    reg [1:0]    sync = 2'b00;
    reg [CW-1:0] cnt  = {CW{1'b0}};

    // logika kombinacyjna: assign
    wire differs = sync[1] ^ clean;
    wire done    = (cnt == STABLE_CYCLES - 1);

    // logika sekwencyjna: always @(posedge clk)
    always @(posedge clk) begin
        sync    <= {sync[0], noisy};
        changed <= 1'b0;
        if (rst) begin
            clean <= 1'b0;
            cnt   <= {CW{1'b0}};
        end else if (!differs) begin
            cnt <= {CW{1'b0}};                     // wejście jak wyjście: licz od nowa
        end else if (done) begin
            clean   <= sync[1];                    // stabilne wystarczająco długo
            changed <= 1'b1;
            cnt     <= {CW{1'b0}};
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule

`default_nettype wire

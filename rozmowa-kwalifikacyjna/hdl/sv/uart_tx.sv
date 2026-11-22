// Zadanie 9: nadajnik UART 8N1. Ramka w rejestrze przesuwnym {stop, dane, start}, wysyłana od najmłodszego
// bitu; każdy bit trwa DIV = CLK_HZ / BAUD taktów. start przyjmowany tylko przy ready (inaczej ignorowany).
`default_nettype none

module uart_tx #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer BAUD   = 115_200
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] data,
    output logic       ready,
    output logic       tx
);
    localparam integer DIV  = CLK_HZ / BAUD;
    localparam integer CW   = $clog2(DIV);
    localparam integer LAST = DIV - 1;

    logic [9:0]    sh = 10'h3FF;          // linia w spoczynku: 1
    logic [3:0]    nbit = 4'd0;
    logic [CW-1:0] cnt = {CW{1'b0}};
    logic          busy = 1'b0;

    always_ff @(posedge clk)
        if (rst) begin
            sh   <= 10'h3FF;
            nbit <= 4'd0;
            cnt  <= {CW{1'b0}};
            busy <= 1'b0;
        end else if (!busy) begin
            if (start) begin
                sh   <= {1'b1, data, 1'b0};
                nbit <= 4'd0;
                cnt  <= {CW{1'b0}};
                busy <= 1'b1;
            end
        end else if (cnt == LAST[CW-1:0]) begin
            cnt <= {CW{1'b0}};
            sh  <= {1'b1, sh[9:1]};
            if (nbit == 4'd9) busy <= 1'b0;     // bit stopu wysłany w całości
            else              nbit <= nbit + 4'd1;
        end else
            cnt <= cnt + 1'b1;

    assign tx    = sh[0];
    assign ready = !busy;
endmodule

`default_nettype wire

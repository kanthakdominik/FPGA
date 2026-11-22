// Dekoder komunikatów MIDI (31.03) z bajtów UART (31 250 b/s z MIDI albo dowolna szybkość z komputera).
//   9n kk vv — Note On (vv = 0 działa jak Note Off), 8n kk vv — Note Off, Bn 7B/78 xx — wszystkie dźwięki wyłącz,
//   Cn pp — zmiana programu (kształt fali: pp mod 4), An/En (2 bajty), Dn (1 bajt) — pomijane.
// Obsługuje running status (kolejne komunikaty bez bajtu statusu), bajty czasu rzeczywistego F8–FF w środku
// komunikatu (pomijane bez przerywania), F0–F7 kasują running status. Kanał MIDI jest ignorowany (tryb omni).
`default_nettype none

module midi_parser (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] dane,
    input  wire       wazne,
    output reg        ev_on = 1'b0,
    output reg        ev_off = 1'b0,
    output reg        ev_wszystkie = 1'b0,
    output reg        ev_prog = 1'b0,
    output reg  [6:0] nuta = 7'd0,
    output reg  [6:0] vel = 7'd0,
    output reg  [1:0] prog = 2'd0
);
    reg [7:0] status = 8'd0;
    reg       drugi = 1'b0;                       // czeka na drugi bajt danych
    reg [6:0] d1 = 7'd0;
    wire [3:0] typ = status[7:4];
    wire       dwa = (typ == 4'h8 || typ == 4'h9 || typ == 4'hA || typ == 4'hB || typ == 4'hE);

    always @(posedge clk) begin
        ev_on <= 1'b0; ev_off <= 1'b0; ev_wszystkie <= 1'b0; ev_prog <= 1'b0;
        if (rst) begin
            status <= 8'd0; drugi <= 1'b0;
        end else if (wazne) begin
            if (dane >= 8'hF8) begin
                // czas rzeczywisty: bez wpływu na komunikat w toku
            end else if (dane[7]) begin
                status <= (dane >= 8'hF0) ? 8'd0 : dane;
                drugi  <= 1'b0;
            end else if (status != 8'd0) begin
                if (dwa && !drugi) begin
                    d1    <= dane[6:0];
                    drugi <= 1'b1;
                end else begin
                    drugi <= 1'b0;
                    case (typ)
                        4'h9: begin
                            nuta <= d1;
                            vel  <= dane[6:0];
                            if (dane[6:0] != 7'd0) ev_on <= 1'b1;
                            else                   ev_off <= 1'b1;
                        end
                        4'h8: begin nuta <= d1; ev_off <= 1'b1; end
                        4'hB: if (d1 == 7'd123 || d1 == 7'd120) ev_wszystkie <= 1'b1;
                        4'hC: begin prog <= dane[1:0]; ev_prog <= 1'b1; end
                        default: ;
                    endcase
                end
            end
        end
    end
endmodule

`default_nettype wire

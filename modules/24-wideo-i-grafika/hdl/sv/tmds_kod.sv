// Koder TMDS (24.02) według DVI 1.0, rozdz. 3.3.3: 8 bitów danych -> 10 bitów z minimalizacją zmian (XOR/XNOR,
// bit 8) i równoważeniem składowej stałej (inwersja, bit 9, licznik nierównowagi cnt). Poza obszarem aktywnym
// (de = 0) — jeden z czterech znaków sterujących (c = {C1, C0}: na kanale niebieskim C0 = HS, C1 = VS).
// Dwa stopnie potoku: opóźnienie 2 takty. Bit q[0] jest wysyłany jako pierwszy.
`default_nettype none

module tmds_kod (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] d,
    input  logic [1:0] c,
    input  logic       de,
    output logic  [9:0] q
);
    function [3:0] jedynki(input [7:0] v);
        integer i;
        begin
            jedynki = 4'd0;
            for (i = 0; i < 8; i = i + 1) jedynki = jedynki + {3'd0, v[i]};
        end
    endfunction

    // stopień 1: minimalizacja zmian
    logic [3:0] n1d;
    assign n1d = jedynki(d);
    logic       xnor_;
    assign xnor_ = (n1d > 4'd4) || (n1d == 4'd4 && !d[0]);
    function [8:0] minim(input [7:0] v, input xn);
        integer i;
        begin
            minim[0] = v[0];
            for (i = 1; i < 8; i = i + 1)
                minim[i] = xn ? ~(minim[i-1] ^ v[i]) : (minim[i-1] ^ v[i]);
            minim[8] = ~xn;
        end
    endfunction
    logic [8:0] qm_k;
    assign qm_k = minim(d, xnor_);

    logic [8:0] qm;
    logic [1:0] c1;
    logic       de1;
    always_ff @(posedge clk) begin
        qm  <= qm_k;
        c1  <= c;
        de1 <= de;
    end

    // stopień 2: równoważenie (cnt — nierównowaga wysłanego strumienia w jednostkach (jedynki - zera)/2·2)
    logic [3:0]        n1q;
    assign n1q = jedynki(qm[7:0]);
    logic signed [4:0] roz;
    assign roz = $signed({1'b0, n1q}) - $signed(5'd4);       // (n1q - n0q) / 2
    logic  signed [4:0] cnt;
    logic  signed [4:0] cnt_n;
    logic         [9:0] q_n;
    always_comb begin
        if (cnt == 5'sd0 || roz == 5'sd0) begin
            q_n = {~qm[8], qm[8], qm[8] ? qm[7:0] : ~qm[7:0]};
            cnt_n = qm[8] ? cnt + roz + roz : cnt - roz - roz;
        end else if ((cnt > 5'sd0 && roz > 5'sd0) || (cnt < 5'sd0 && roz < 5'sd0)) begin
            q_n = {1'b1, qm[8], ~qm[7:0]};
            cnt_n = cnt + (qm[8] ? 5'sd2 : 5'sd0) - roz - roz;
        end else begin
            q_n = {1'b0, qm[8], qm[7:0]};
            cnt_n = cnt - (qm[8] ? 5'sd0 : 5'sd2) + roz + roz;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            q   <= 10'b1101010100;
            cnt <= 5'sd0;
        end else if (!de1) begin
            cnt <= 5'sd0;
            case (c1)
                2'b00:   q <= 10'b1101010100;
                2'b01:   q <= 10'b0010101011;
                2'b10:   q <= 10'b0101010100;
                default: q <= 10'b1010101011;
            endcase
        end else begin
            q   <= q_n;
            cnt <= cnt_n;
        end
    end
endmodule

`default_nettype wire

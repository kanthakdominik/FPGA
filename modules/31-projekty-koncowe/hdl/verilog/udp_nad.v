// Nadawca ramek UDP/IPv4 (25.04): po impulsie start wysyła strumień bajtów ramki Ethernet bez preambuły i FCS
// (te dodaje mii_tx): nagłówek Ethernet (14 B), IPv4 (20 B, z sumą kontrolną), UDP (8 B, suma 0 — dozwolone w
// IPv4), potem dlugosc bajtów danych ze strumienia p_*. Pola adresowe podawane na wejściach i zapamiętywane przy
// starcie. Identyfikator IP rośnie z każdym datagramem. Wyjście m_* podłącza się do s_* nadajnika mii_tx.
`default_nettype none

module udp_nad (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [10:0] dlugosc,                 // bajty danych UDP (1..1472)
    input  wire [47:0] mac_zr,
    input  wire [47:0] mac_cel,
    input  wire [31:0] ip_zr,
    input  wire [31:0] ip_cel,
    input  wire [15:0] port_zr,
    input  wire [15:0] port_cel,
    output reg         zajety,
    input  wire [7:0]  p_dane,
    input  wire        p_wazne,
    output wire        p_gotowy,
    output wire [7:0]  m_dane,
    output wire        m_wazne,
    output wire        m_ostatni,
    input  wire        m_gotowy
);
    reg  [47:0] r_mac_zr, r_mac_cel;
    reg  [31:0] r_ip_zr, r_ip_cel;
    reg  [15:0] r_pz, r_pc, r_dl_ip, r_dl_udp, r_id, r_suma;
    reg  [10:0] r_dl, i;
    reg         r_sum_ok;                       // suma policzona (takt po starcie)

    // suma kontrolna nagłówka IPv4: suma słów 16-bitowych z przeniesieniami, zwinięta i zanegowana
    wire [19:0] s20 = 20'h4500 + {4'd0, r_dl_ip} + {4'd0, r_id} + 20'h4000 + 20'h4011
                    + {4'd0, r_ip_zr[31:16]} + {4'd0, r_ip_zr[15:0]} + {4'd0, r_ip_cel[31:16]} + {4'd0, r_ip_cel[15:0]};
    wire [16:0] s17 = {1'b0, s20[15:0]} + {13'd0, s20[19:16]};
    wire [15:0] suma = ~(s17[15:0] + {15'd0, s17[16]});

    function [7:0] nagl(input [5:0] k);
        case (k)
            6'd0:  nagl = r_mac_cel[47:40];  6'd1:  nagl = r_mac_cel[39:32];  6'd2:  nagl = r_mac_cel[31:24];
            6'd3:  nagl = r_mac_cel[23:16];  6'd4:  nagl = r_mac_cel[15:8];   6'd5:  nagl = r_mac_cel[7:0];
            6'd6:  nagl = r_mac_zr[47:40];   6'd7:  nagl = r_mac_zr[39:32];   6'd8:  nagl = r_mac_zr[31:24];
            6'd9:  nagl = r_mac_zr[23:16];   6'd10: nagl = r_mac_zr[15:8];    6'd11: nagl = r_mac_zr[7:0];
            6'd12: nagl = 8'h08;             6'd13: nagl = 8'h00;                               // typ: IPv4
            6'd14: nagl = 8'h45;             6'd15: nagl = 8'h00;                               // wersja, IHL; DSCP
            6'd16: nagl = r_dl_ip[15:8];     6'd17: nagl = r_dl_ip[7:0];
            6'd18: nagl = r_id[15:8];        6'd19: nagl = r_id[7:0];
            6'd20: nagl = 8'h40;             6'd21: nagl = 8'h00;                               // DF, bez fragmentacji
            6'd22: nagl = 8'h40;             6'd23: nagl = 8'h11;                               // TTL 64, UDP
            6'd24: nagl = r_suma[15:8];      6'd25: nagl = r_suma[7:0];
            6'd26: nagl = r_ip_zr[31:24];    6'd27: nagl = r_ip_zr[23:16];    6'd28: nagl = r_ip_zr[15:8];
            6'd29: nagl = r_ip_zr[7:0];
            6'd30: nagl = r_ip_cel[31:24];   6'd31: nagl = r_ip_cel[23:16];   6'd32: nagl = r_ip_cel[15:8];
            6'd33: nagl = r_ip_cel[7:0];
            6'd34: nagl = r_pz[15:8];        6'd35: nagl = r_pz[7:0];
            6'd36: nagl = r_pc[15:8];        6'd37: nagl = r_pc[7:0];
            6'd38: nagl = r_dl_udp[15:8];    6'd39: nagl = r_dl_udp[7:0];
            default: nagl = 8'h00;                                                              // suma UDP = 0
        endcase
    endfunction

    wire w_nagl = (i < 11'd42);
    assign m_dane    = w_nagl ? nagl(i[5:0]) : p_dane;
    assign m_wazne   = zajety && r_sum_ok && (w_nagl || p_wazne);
    assign m_ostatni = !w_nagl && (i == r_dl + 11'd41);
    assign p_gotowy  = zajety && r_sum_ok && !w_nagl && m_gotowy;

    always @(posedge clk) begin
        if (rst) begin
            zajety <= 1'b0; r_sum_ok <= 1'b0; i <= 11'd0; r_id <= 16'd0; r_suma <= 16'd0;
            r_mac_zr <= 48'd0; r_mac_cel <= 48'd0; r_ip_zr <= 32'd0; r_ip_cel <= 32'd0;
            r_pz <= 16'd0; r_pc <= 16'd0; r_dl <= 11'd0; r_dl_ip <= 16'd0; r_dl_udp <= 16'd0;
        end else if (!zajety) begin
            if (start) begin
                zajety    <= 1'b1;
                r_sum_ok  <= 1'b0;
                i         <= 11'd0;
                r_mac_zr  <= mac_zr;  r_mac_cel <= mac_cel;
                r_ip_zr   <= ip_zr;   r_ip_cel  <= ip_cel;
                r_pz      <= port_zr; r_pc      <= port_cel;
                r_dl      <= dlugosc;
                r_dl_ip   <= {5'd0, dlugosc} + 16'd28;
                r_dl_udp  <= {5'd0, dlugosc} + 16'd8;
                r_id      <= r_id + 1'b1;
            end
        end else if (!r_sum_ok) begin
            r_suma   <= suma;                       // pola już zapamiętane — suma z rejestrów
            r_sum_ok <= 1'b1;
        end else if (m_wazne && m_gotowy) begin
            if (m_ostatni) zajety <= 1'b0;
            else           i <= i + 1'b1;
        end
    end
endmodule

`default_nettype wire

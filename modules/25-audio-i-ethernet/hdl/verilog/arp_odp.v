// Odpowiadanie na zapytania ARP (25.04). Część odbiorcza (clk_rx) analizuje bajty z mii_rx: ramka do nas albo
// rozgłoszeniowa, typ 0x0806, Ethernet/IPv4 (0001/0800/6/4), operacja 1 (zapytanie), szukany adres IP = ip_moj,
// poprawne CRC. Zapamiętuje adres MAC i IP pytającego i zgłasza odpowiedź do części nadawczej (clk_tx) bitem
// przełączanym przez synchronizator. Część nadawcza wystawia strumień 42 bajtów odpowiedzi (operacja 2;
// uzupełnienie do 60 B robi mii_tx) i podaje nauczony adres pytającego (np. komputera — cel datagramów UDP).
`default_nettype none

module arp_odp (
    input  wire        clk_rx,
    input  wire        rst_rx,
    input  wire [7:0]  r_dane,
    input  wire        r_wazne,
    input  wire        r_koniec,
    input  wire        r_crc_ok,
    input  wire [47:0] mac_moj,
    input  wire [31:0] ip_moj,
    input  wire        clk_tx,
    input  wire        rst_tx,
    output wire        chce,                    // odpowiedź gotowa do wysłania
    output wire [7:0]  m_dane,
    output wire        m_wazne,
    output wire        m_ostatni,
    input  wire        m_gotowy,
    output reg  [47:0] mac_pyt,                 // nauczony adres pytającego (domena clk_tx)
    output reg  [31:0] ip_pyt,
    output reg         nauczony
);
    // ---------------------------------------------------------------- analiza (clk_rx)
    reg  [5:0]   k;                             // indeks bajtu (nasycony na 63)
    reg          zgodne;                        // wszystkie sprawdzone pola się zgadzają
    reg  [47:0]  sha;
    reg  [31:0]  spa;
    reg  [47:0]  sha_z;                         // zatrzaśnięte dla domeny nadawczej
    reg  [31:0]  spa_z;
    reg          t_odp = 1'b0;

    function [7:0] oczek(input [5:0] j, input [31:0] ip);                     // pola stałe
        case (j)
            6'd12: oczek = 8'h08; 6'd13: oczek = 8'h06;                         // ARP
            6'd14: oczek = 8'h00; 6'd15: oczek = 8'h01;                         // Ethernet
            6'd16: oczek = 8'h08; 6'd17: oczek = 8'h00;                         // IPv4
            6'd18: oczek = 8'h06; 6'd19: oczek = 8'h04;
            6'd20: oczek = 8'h00; 6'd21: oczek = 8'h01;                         // zapytanie
            6'd38: oczek = ip[31:24]; 6'd39: oczek = ip[23:16]; 6'd40: oczek = ip[15:8]; 6'd41: oczek = ip[7:0];
            default: oczek = 8'h00;                                             // nieużywane
        endcase
    endfunction
    wire spr = (k >= 6'd12 && k <= 6'd21) || (k >= 6'd38 && k <= 6'd41);
    reg  [7:0]  mac_bajt;                                                     // bajt k (0..5) adresu MAC
    always @(*)
        case (k[2:0])
            3'd0: mac_bajt = mac_moj[47:40];  3'd1: mac_bajt = mac_moj[39:32];  3'd2: mac_bajt = mac_moj[31:24];
            3'd3: mac_bajt = mac_moj[23:16];  3'd4: mac_bajt = mac_moj[15:8];   default: mac_bajt = mac_moj[7:0];
        endcase
    wire        cel_ok = (r_dane == 8'hFF) || (r_dane == mac_bajt);           // bajty 0..5: nasz albo rozgłoszeniowy

    always @(posedge clk_rx) begin
        if (rst_rx) begin
            k <= 6'd0; zgodne <= 1'b1; sha <= 48'd0; spa <= 32'd0; sha_z <= 48'd0; spa_z <= 32'd0; t_odp <= 1'b0;
        end else begin
            if (r_wazne) begin
                if (k != 6'd63) k <= k + 1'b1;
                if (k < 6'd6 && !cel_ok) zgodne <= 1'b0;
                if (spr && r_dane != oczek(k, ip_moj)) zgodne <= 1'b0;
                if (k >= 6'd22 && k <= 6'd27) sha <= {sha[39:0], r_dane};
                if (k >= 6'd28 && k <= 6'd31) spa <= {spa[23:0], r_dane};
            end
            if (r_koniec) begin
                if (zgodne && r_crc_ok && k >= 6'd42) begin
                    sha_z <= sha;
                    spa_z <= spa;
                    t_odp <= ~t_odp;
                end
                k      <= 6'd0;
                zgodne <= 1'b1;
            end
        end
    end

    // ---------------------------------------------------------------- odpowiedź (clk_tx)
    reg  [2:0]  s_odp = 3'd0;
    reg         czeka;
    reg  [5:0]  i;
    reg  [47:0] t_mac;
    reg  [31:0] t_ip;
    function [7:0] odp(input [5:0] j);
        case (j)
            6'd0: odp = t_mac[47:40]; 6'd1: odp = t_mac[39:32]; 6'd2: odp = t_mac[31:24];
            6'd3: odp = t_mac[23:16]; 6'd4: odp = t_mac[15:8];  6'd5: odp = t_mac[7:0];
            6'd6: odp = mac_moj[47:40]; 6'd7: odp = mac_moj[39:32]; 6'd8: odp = mac_moj[31:24];
            6'd9: odp = mac_moj[23:16]; 6'd10: odp = mac_moj[15:8]; 6'd11: odp = mac_moj[7:0];
            6'd12: odp = 8'h08; 6'd13: odp = 8'h06; 6'd14: odp = 8'h00; 6'd15: odp = 8'h01;
            6'd16: odp = 8'h08; 6'd17: odp = 8'h00; 6'd18: odp = 8'h06; 6'd19: odp = 8'h04;
            6'd20: odp = 8'h00; 6'd21: odp = 8'h02;                             // odpowiedź
            6'd22: odp = mac_moj[47:40]; 6'd23: odp = mac_moj[39:32]; 6'd24: odp = mac_moj[31:24];
            6'd25: odp = mac_moj[23:16]; 6'd26: odp = mac_moj[15:8]; 6'd27: odp = mac_moj[7:0];
            6'd28: odp = ip_moj[31:24]; 6'd29: odp = ip_moj[23:16]; 6'd30: odp = ip_moj[15:8]; 6'd31: odp = ip_moj[7:0];
            6'd32: odp = t_mac[47:40]; 6'd33: odp = t_mac[39:32]; 6'd34: odp = t_mac[31:24];
            6'd35: odp = t_mac[23:16]; 6'd36: odp = t_mac[15:8]; 6'd37: odp = t_mac[7:0];
            6'd38: odp = t_ip[31:24]; 6'd39: odp = t_ip[23:16]; 6'd40: odp = t_ip[15:8];
            default: odp = t_ip[7:0];
        endcase
    endfunction
    assign chce      = czeka;
    assign m_wazne   = czeka;
    assign m_dane    = odp(i);
    assign m_ostatni = (i == 6'd41);

    always @(posedge clk_tx) begin
        s_odp <= {s_odp[1:0], t_odp};
        if (rst_tx) begin
            czeka <= 1'b0; i <= 6'd0; t_mac <= 48'd0; t_ip <= 32'd0;
            mac_pyt <= 48'd0; ip_pyt <= 32'd0; nauczony <= 1'b0;
        end else begin
            if (s_odp[2] != s_odp[1] && !czeka) begin              // nowe zapytanie (dane stabilne od zatrzaśnięcia)
                czeka    <= 1'b1;
                i        <= 6'd0;
                t_mac    <= sha_z;
                t_ip     <= spa_z;
                mac_pyt  <= sha_z;
                ip_pyt   <= spa_z;
                nauczony <= 1'b1;
            end else if (czeka && m_gotowy) begin
                if (i == 6'd41) czeka <= 1'b0;
                else            i <= i + 1'b1;
            end
        end
    end
endmodule

`default_nettype wire

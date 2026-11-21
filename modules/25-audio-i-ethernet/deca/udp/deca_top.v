// DECA — strumień UDP do komputera (moduł 25, 25.03–25.05): PHY DP83620 przez MII (100 Mb/s), MAC z mii_tx/mii_rx,
// ARP (arp_odp) i datagramy UDP (udp_nad) z danymi testowymi: 1024 B = numer pakietu (4 B, big-endian) + bajty
// (numer + i) mod 256. Adres FPGA: 02:00:00:00:00:01, 192.168.1.200, port źródłowy 5005, docelowy 5006.
// Do czasu zapytania ARP od komputera datagramy idą na adres rozgłoszeniowy (FF…FF, 255.255.255.255), potem do
// nauczonego adresu komputera (skrypt odbior_udp.py wysyła najpierw pakiet do FPGA, co wywołuje zapytanie ARP).
// SW[1] = 1 — nadawanie; SW[0] = 0 — pakiet co ok. 1 ms (8,2 Mb/s danych), 1 — pakiety jeden za drugim (ok. 94 Mb/s danych).
// MDIO: po zwolnieniu resetu PHY wyszukanie adresu PHY (rejestr 2 ≠ 0xFFFF), potem odczyt stanu łącza co ok. 0,17 s.
// Diody (0 = świeci): LED[0] PHY znaleziony, LED[1] łącze aktywne, LED[2] adres komputera nauczony z ARP,
// LED[3] nadawanie, LED[7:4] — bity licznika pakietów. KEY[0] — reset. Ograniczenia: udp.sdc.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,
    input  wire       NET_TX_CLK,
    output wire [3:0] NET_TXD,
    output wire       NET_TX_EN,
    input  wire       NET_RX_CLK,
    input  wire [3:0] NET_RXD,
    input  wire       NET_RX_DV,
    input  wire       NET_RX_ER,
    input  wire       NET_COL,
    input  wire       NET_CRS,
    output wire       NET_RESET_n,
    output wire       NET_MDC,
    inout  wire       NET_MDIO,
    output wire       NET_PCF_EN
);
    localparam [47:0] MAC_FPGA = 48'h02_00_00_00_00_01;
    localparam [31:0] IP_FPGA  = {8'd192, 8'd168, 8'd1, 8'd200};
    assign NET_PCF_EN = 1'b0;

    // ---------------------------------------------------------------- domena 50 MHz: reset PHY, MDIO, diody
    wire clk = MAX10_CLK1_50;
    reg [1:0]  rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];
    reg [19:0] lr = 20'd0;                      // 10 ms resetu PHY, potem 10 ms na jego rozruch
    always @(posedge clk) if (rst) lr <= 20'd0; else if (lr != 20'd1000000) lr <= lr + 1'b1;
    assign NET_RESET_n = (lr >= 20'd500000);
    wire phy_gotowy = (lr == 20'd1000000);

    reg         m_start = 1'b0;
    reg  [4:0]  m_phy = 5'd0, m_rej = 5'd2;
    wire [15:0] m_rdane;
    wire        m_got, m_zaj, mdio_o, mdio_oe;
    mdio #(.DIV(10)) u_mdio (.clk(clk), .rst(!phy_gotowy), .start(m_start), .zapis(1'b0), .phy(m_phy), .rej(m_rej),
                             .wdane(16'd0), .rdane(m_rdane), .gotowe(m_got), .zajety(m_zaj), .mdc(NET_MDC),
                             .mdio_o(mdio_o), .mdio_oe(mdio_oe), .mdio_i(NET_MDIO));
    assign NET_MDIO = mdio_oe ? mdio_o : 1'bz;
    reg        znaleziony = 1'b0, lacze = 1'b0;
    reg [22:0] okres = 23'd0;
    always @(posedge clk) begin
        m_start <= 1'b0;
        if (!phy_gotowy) begin
            znaleziony <= 1'b0; lacze <= 1'b0; m_phy <= 5'd0; m_rej <= 5'd2; okres <= 23'd0;
        end else begin
            okres <= okres + 1'b1;
            if (!m_zaj && !m_start && okres[22:0] == 23'd0 && znaleziony) begin m_rej <= 5'd1; m_start <= 1'b1; end
            if (!m_zaj && !m_start && !znaleziony && okres[9:0] == 10'd0) m_start <= 1'b1;   // szukanie: rejestr 2
            if (m_got) begin
                if (!znaleziony) begin
                    if (m_rdane != 16'hFFFF && m_rdane != 16'h0000) znaleziony <= 1'b1;
                    else m_phy <= m_phy + 1'b1;
                end else
                    lacze <= m_rdane[2];                                // BMSR: stan łącza
            end
        end
    end

    // ---------------------------------------------------------------- domena odbioru (NET_RX_CLK)
    reg [1:0] rrs = 2'b00;
    always @(posedge NET_RX_CLK or posedge rst) if (rst) rrs <= 2'b00; else rrs <= {rrs[0], 1'b1};
    wire rst_rx = ~rrs[1];
    wire [7:0]  r_dane;
    wire        r_wazne, r_koniec, r_crc_ok, r_blad;
    wire [10:0] r_dl;
    mii_rx u_rx (.clk(NET_RX_CLK), .rst(rst_rx), .rxd(NET_RXD), .rx_dv(NET_RX_DV), .rx_er(NET_RX_ER),
                 .m_dane(r_dane), .m_wazne(r_wazne), .koniec(r_koniec), .crc_ok(r_crc_ok), .dlugosc(r_dl),
                 .blad(r_blad));

    // ---------------------------------------------------------------- domena nadawania (NET_TX_CLK)
    wire tclk = NET_TX_CLK;
    reg [1:0] trs = 2'b00;
    always @(posedge tclk or posedge rst) if (rst) trs <= 2'b00; else trs <= {trs[0], 1'b1};
    wire rst_tx = ~trs[1];
    reg [1:0] sw_t = 2'b00;
    always @(posedge tclk) sw_t <= SW;

    wire        a_chce, a_wazne, a_ost, nauczony;
    wire [7:0]  a_dane;
    wire [47:0] mac_pc;
    wire [31:0] ip_pc;
    wire        tx_gotowy;
    reg  [1:0]  wyb = 2'd0;                     // 0 — nic, 1 — ARP, 2 — UDP
    arp_odp u_arp (.clk_rx(NET_RX_CLK), .rst_rx(rst_rx), .r_dane(r_dane), .r_wazne(r_wazne), .r_koniec(r_koniec),
                   .r_crc_ok(r_crc_ok), .mac_moj(MAC_FPGA), .ip_moj(IP_FPGA),
                   .clk_tx(tclk), .rst_tx(rst_tx), .chce(a_chce), .m_dane(a_dane), .m_wazne(a_wazne),
                   .m_ostatni(a_ost), .m_gotowy(tx_gotowy && wyb == 2'd1),
                   .mac_pyt(mac_pc), .ip_pyt(ip_pc), .nauczony(nauczony));

    reg         u_start = 1'b0;
    reg  [31:0] nr = 32'd0;                     // numer pakietu
    wire        u_zaj, p_got, u_wazne, u_ost;
    wire [7:0]  u_dane;
    reg  [10:0] pidx = 11'd0;                    // indeks bajtu danych
    wire [7:0]  p_dane = (pidx == 11'd0) ? nr[31:24] : (pidx == 11'd1) ? nr[23:16] :
                         (pidx == 11'd2) ? nr[15:8]  : (pidx == 11'd3) ? nr[7:0] : (pidx[7:0] + nr[7:0]);
    udp_nad u_udp (.clk(tclk), .rst(rst_tx), .start(u_start), .dlugosc(11'd1024), .mac_zr(MAC_FPGA),
                   .mac_cel(nauczony ? mac_pc : 48'hFFFF_FFFF_FFFF), .ip_zr(IP_FPGA),
                   .ip_cel(nauczony ? ip_pc : 32'hFFFF_FFFF), .port_zr(16'd5005), .port_cel(16'd5006),
                   .zajety(u_zaj), .p_dane(p_dane), .p_wazne(1'b1), .p_gotowy(p_got),
                   .m_dane(u_dane), .m_wazne(u_wazne), .m_ostatni(u_ost), .m_gotowy(tx_gotowy && wyb == 2'd2));
    always @(posedge tclk) if (u_start) pidx <= 11'd0; else if (p_got) pidx <= pidx + 1'b1;

    // wybór źródła ramki i tempo nadawania
    reg [15:0] odstep = 16'd0;
    always @(posedge tclk) begin
        u_start <= 1'b0;
        if (odstep != 16'd0) odstep <= odstep - 1'b1;
        if (rst_tx) begin
            wyb <= 2'd0; nr <= 32'd0; odstep <= 16'd0;
        end else case (wyb)
            2'd0:
                if (a_chce) wyb <= 2'd1;
                else if (sw_t[1] && odstep == 16'd0 && !u_zaj) begin
                    u_start <= 1'b1;
                    wyb     <= 2'd2;
                    odstep  <= sw_t[0] ? 16'd0 : 16'd25000;            // 1 ms przy 25 MHz
                end
            2'd1: if (a_wazne && a_ost && tx_gotowy) wyb <= 2'd0;
            default: if (u_wazne && u_ost && tx_gotowy) begin wyb <= 2'd0; nr <= nr + 1'b1; end
        endcase
    end
    wire [7:0] s_dane    = (wyb == 2'd1) ? a_dane : u_dane;
    wire       s_wazne   = (wyb == 2'd1) ? a_wazne : (wyb == 2'd2) ? u_wazne : 1'b0;
    wire       s_ostatni = (wyb == 2'd1) ? a_ost : u_ost;
    wire       przerwa;
    mii_tx u_tx (.clk(tclk), .rst(rst_tx), .s_dane(s_dane), .s_wazne(s_wazne), .s_ostatni(s_ostatni),
                 .s_gotowy(tx_gotowy), .txd(NET_TXD), .tx_en(NET_TX_EN), .przerwa(przerwa));

    // ---------------------------------------------------------------- diody (synchronizacja do 50 MHz)
    reg [5:0] s1 = 6'd0, s2 = 6'd0;
    always @(posedge clk) begin s1 <= {nauczony, sw_t[1], nr[13:10]}; s2 <= s1; end
    assign LED = ~{s2[3:0], s2[4], s2[5], lacze, znaleziony};
endmodule

`default_nettype wire

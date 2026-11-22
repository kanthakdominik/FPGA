// Peryferium „UDP z pamięci” dla systemu Nios V (31.04). Procesor wpisuje adres bufora (wyrównany do 4 B),
// długość danych (1..1472 B), adresy i porty, a potem START; blok sam czyta bufor masterem Avalon-MM (np. z DDR3),
// składa datagram UDP/IPv4 (udp_nad), zapisuje całą ramkę do kolejki asynchronicznej 2048 × 9 b i dopiero gotową
// ramkę wysyła w domenie zegara nadawania MII (mii_tx, 25 MHz z PHY) — nadajnik nigdy nie czeka na pamięć.
// Mapa rejestrów (słowa 32-bitowe, readLatency 1):
//   0 STER     W: bit 0 START (impuls), RW: bit 1 PRZ (zezwolenie na przerwanie)
//   1 STATUS   R: bit 0 ZAJETY;  R/W1C: bit 1 KONIEC (ramka wysłana)
//   2 ADRES    RW: adres bajtowy bufora (bity 1:0 = 0)       3 DLUGOSC  RW: bajty danych UDP (11 bitów)
//   4 IP_ZR    5 IP_CEL    6 PORTY {źródłowy, docelowy}    7/8 MAC_ZR [47:32]/[31:0]    9/10 MAC_CEL
//   11 PAKIETY R: liczba wysłanych ramek
// Przerwanie (poziomem): irq = KONIEC & PRZ. Master czyta słowa pojedynczo (bez burstów), do 8 odczytów
// w locie lub w buforze; bajty słowa od najmłodszego (little-endian, jak procesor Nios V).
`default_nettype none

module udp_dma (
    input  wire        clk,
    input  wire        rst,
    // slave Avalon-MM (rejestry)
    input  wire [3:0]  s_address,
    input  wire        s_read,
    input  wire        s_write,
    input  wire [31:0] s_writedata,
    output reg  [31:0] s_readdata = 32'd0,
    output wire        irq,
    // master Avalon-MM (odczyt bufora)
    output reg  [31:0] m_address = 32'd0,
    output reg         m_read = 1'b0,
    input  wire        m_waitrequest,
    input  wire [31:0] m_readdata,
    input  wire        m_readdatavalid,
    // MII nadawanie (domena tx_clk)
    input  wire        tx_clk,
    input  wire        tx_rst,
    output wire [3:0]  txd,
    output wire        tx_en
);
    // ---------------------------------------------------------------- rejestry
    reg        prz = 1'b0;
    reg        koniec = 1'b0;
    reg [31:0] r_adres = 32'd0;
    reg [10:0] r_dl = 11'd0;
    reg [31:0] r_ip_zr = 32'd0;
    reg [31:0] r_ip_cel = 32'd0;
    reg [31:0] r_porty = 32'd0;
    reg [47:0] r_mac_zr = 48'd0;
    reg [47:0] r_mac_cel = 48'd0;
    reg [31:0] pakiety = 32'd0;
    reg        zajety = 1'b0;
    wire       start = s_write && s_address == 4'd0 && s_writedata[0] && !zajety && r_dl != 11'd0;
    assign irq = koniec && prz;

    always @(posedge clk)
        if (s_read)
            case (s_address)
                4'd0:    s_readdata <= {30'd0, prz, 1'b0};
                4'd1:    s_readdata <= {30'd0, koniec, zajety};
                4'd2:    s_readdata <= r_adres;
                4'd3:    s_readdata <= {21'd0, r_dl};
                4'd4:    s_readdata <= r_ip_zr;
                4'd5:    s_readdata <= r_ip_cel;
                4'd6:    s_readdata <= r_porty;
                4'd7:    s_readdata <= {16'd0, r_mac_zr[47:32]};
                4'd8:    s_readdata <= r_mac_zr[31:0];
                4'd9:    s_readdata <= {16'd0, r_mac_cel[47:32]};
                4'd10:   s_readdata <= r_mac_cel[31:0];
                4'd11:   s_readdata <= pakiety;
                default: s_readdata <= 32'd0;
            endcase

    // ---------------------------------------------------------------- odczyt bufora i serializacja
    reg  [31:0] bufor [0:7];
    reg  [2:0]  wp = 3'd0;
    reg  [2:0]  rp = 3'd0;
    reg  [3:0]  ile = 4'd0;                 // słowa w buforze
    reg  [3:0]  w_locie = 4'd0;             // odczyty przyjęte, dane jeszcze nie wróciły
    reg  [9:0]  slowa_do = 10'd0;           // słowa jeszcze do zlecenia
    reg  [10:0] bajty_do = 11'd0;           // bajty danych jeszcze do oddania
    reg  [1:0]  bi = 2'd0;                  // bajt w słowie
    wire [31:0] slowo = bufor[rp];
    wire [7:0]  p_dane = slowo[8 * bi +: 8];
    wire        p_wazne = (ile != 4'd0);
    wire        p_gotowy;
    wire        bierz = p_wazne && p_gotowy;
    wire        zdejmij = bierz && (bi == 2'd3 || bajty_do == 11'd1);
    wire        przyjety = m_read && !m_waitrequest;

    always @(posedge clk) begin
        if (rst) begin
            m_read <= 1'b0; wp <= 3'd0; rp <= 3'd0; ile <= 4'd0; w_locie <= 4'd0; slowa_do <= 10'd0;
            bajty_do <= 11'd0; bi <= 2'd0;
        end else begin
            if (start) begin
                m_address <= {r_adres[31:2], 2'b00};
                slowa_do  <= {1'b0, r_dl[10:2]} + {9'd0, r_dl[1:0] != 2'd0};
                bajty_do  <= r_dl;
                bi        <= 2'd0;
            end else begin
                // zlecanie odczytów: jeden na raz na magistrali, nie więcej niż 8 w locie i w buforze
                if (przyjety) begin
                    m_read    <= 1'b0;
                    m_address <= m_address + 32'd4;
                    slowa_do  <= slowa_do - 10'd1;
                end else if (!m_read && slowa_do != 10'd0 && w_locie + ile < 4'd8)
                    m_read <= 1'b1;
            end
            if (m_readdatavalid) begin
                bufor[wp] <= m_readdata;
                wp <= wp + 3'd1;
            end
            w_locie <= w_locie + (przyjety ? 4'd1 : 4'd0) - (m_readdatavalid ? 4'd1 : 4'd0);
            ile     <= ile + (m_readdatavalid ? 4'd1 : 4'd0) - (zdejmij ? 4'd1 : 4'd0);
            if (bierz) begin
                bajty_do <= bajty_do - 11'd1;
                bi       <= zdejmij ? 2'd0 : bi + 2'd1;
            end
            if (zdejmij) rp <= rp + 3'd1;
        end
    end

    // ---------------------------------------------------------------- datagram i kolejka ramki
    wire [7:0] f_dane;
    wire       f_wazne, f_ostatni, f_pelna;
    /* verilator lint_off PINCONNECTEMPTY */
    udp_nad u_udp (.clk(clk), .rst(rst), .start(start), .dlugosc(r_dl), .mac_zr(r_mac_zr), .mac_cel(r_mac_cel),
        .ip_zr(r_ip_zr), .ip_cel(r_ip_cel), .port_zr(r_porty[31:16]), .port_cel(r_porty[15:0]), .zajety(),
        .p_dane(p_dane), .p_wazne(p_wazne), .p_gotowy(p_gotowy), .m_dane(f_dane), .m_wazne(f_wazne),
        .m_ostatni(f_ostatni), .m_gotowy(!f_pelna));
    /* verilator lint_on PINCONNECTEMPTY */
    wire       f_zapis = f_wazne && !f_pelna;

    wire [8:0] k_dane;
    wire       k_pusta, k_czyt;
    async_fifo #(.W(9), .AW(11)) u_kol (.wr_clk(clk), .wr_rst(rst), .wr_en(f_zapis), .wr_data({f_ostatni, f_dane}),
        .wr_full(f_pelna), .rd_clk(tx_clk), .rd_rst(tx_rst), .rd_en(k_czyt), .rd_data(k_dane), .rd_empty(k_pusta));

    // przekazanie: ramka w kolejce (przełącznik ramka_t) i potwierdzenie wysłania (wyslano_t)
    reg        ramka_t = 1'b0;
    reg        wyslano_t = 1'b0;
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0]  s_wysl = 2'b00;
    always @(posedge clk) s_wysl <= {s_wysl[0], wyslano_t};
    reg        czeka_tx = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            zajety <= 1'b0; koniec <= 1'b0; ramka_t <= 1'b0; czeka_tx <= 1'b0; pakiety <= 32'd0; prz <= 1'b0;
        end else begin
            if (s_write)
                case (s_address)
                    4'd0:  prz <= s_writedata[1];
                    4'd1:  if (s_writedata[1]) koniec <= 1'b0;
                    4'd2:  r_adres <= {s_writedata[31:2], 2'b00};
                    4'd3:  r_dl <= s_writedata[10:0];
                    4'd4:  r_ip_zr <= s_writedata;
                    4'd5:  r_ip_cel <= s_writedata;
                    4'd6:  r_porty <= s_writedata;
                    4'd7:  r_mac_zr[47:32] <= s_writedata[15:0];
                    4'd8:  r_mac_zr[31:0] <= s_writedata;
                    4'd9:  r_mac_cel[47:32] <= s_writedata[15:0];
                    4'd10: r_mac_cel[31:0] <= s_writedata;
                    default: ;
                endcase
            if (start) zajety <= 1'b1;
            if (f_zapis && f_ostatni) begin                  // cała ramka w kolejce
                ramka_t  <= ~ramka_t;
                czeka_tx <= 1'b1;
            end
            if (czeka_tx && s_wysl[1] == ramka_t) begin       // nadajnik potwierdził
                czeka_tx <= 1'b0;
                zajety   <= 1'b0;
                koniec   <= 1'b1;                            // ustawienie wygrywa z kasowaniem w tym takcie
                pakiety  <= pakiety + 32'd1;
            end
        end
    end

    // ---------------------------------------------------------------- domena nadawania MII
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_ramka = 2'b00;
    reg       nadaje = 1'b0;
    wire      t_gotowy;
    wire      t_wazne = nadaje && !k_pusta;
    assign    k_czyt = t_wazne && t_gotowy;
    always @(posedge tx_clk) begin
        s_ramka <= {s_ramka[0], ramka_t};
        if (tx_rst) begin
            nadaje <= 1'b0; wyslano_t <= 1'b0;
        end else if (!nadaje) begin
            if (s_ramka[1] != wyslano_t) nadaje <= 1'b1;
        end else if (k_czyt && k_dane[8]) begin
            nadaje    <= 1'b0;
            wyslano_t <= s_ramka[1];
        end
    end
    /* verilator lint_off PINCONNECTEMPTY */
    mii_tx u_mii (.clk(tx_clk), .rst(tx_rst), .s_dane(k_dane[7:0]), .s_wazne(t_wazne), .s_ostatni(k_dane[8]),
        .s_gotowy(t_gotowy), .txd(txd), .tx_en(tx_en), .przerwa());
    /* verilator lint_on PINCONNECTEMPTY */
endmodule

`default_nettype wire

-- Testbench projektu 4 (31.04), VHDL: procesor, pamięć z losowym waitrequest i opóźnieniem, odbiór mii_rx —
-- te same sprawdzenia co tb_udp_dma.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_udp_dma is
end entity tb_udp_dma;

architecture sim of tb_udp_dma is
  constant MAC_FPGA : std_logic_vector(47 downto 0) := x"020000000001";
  constant MAC_PC   : std_logic_vector(47 downto 0) := x"001B213C4D5E";
  constant IP_FPGA  : std_logic_vector(31 downto 0) := x"C0A801C8";
  constant IP_PC    : std_logic_vector(31 downto 0) := x"C0A80164";
  signal clk, tclk : std_logic := '0';
  signal fin  : boolean := false;
  signal rst  : std_logic := '1';
  signal s_address : unsigned(3 downto 0) := (others => '0');
  signal s_read, s_write : std_logic := '0';
  signal s_writedata : std_logic_vector(31 downto 0) := (others => '0');
  signal s_readdata, m_readdata : std_logic_vector(31 downto 0) := (others => '0');
  signal irq, m_read : std_logic;
  signal m_address : unsigned(31 downto 0);
  signal m_waitrequest : std_logic := '1';
  signal m_readdatavalid : std_logic := '0';
  signal txd : std_logic_vector(3 downto 0);
  signal tx_en : std_logic;
  signal odczytow : natural := 0;
  signal r_dane : std_logic_vector(7 downto 0);
  signal r_wazne, r_koniec, r_crc_ok, r_blad : std_logic;
  signal r_dl : unsigned(10 downto 0);
  type ramka_t is array (0 to 2047) of std_logic_vector(7 downto 0);
  signal ramka : ramka_t;
  signal ramek, crc_zle, dl_ost : natural := 0;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
  function wzor(i : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned((i * 7 + 3) mod 256, 8));
  end function;
begin
  clk  <= not clk after 10 ns when not fin else clk;
  tclk <= not tclk after 20.3 ns when not fin else tclk;

  dut : entity work.udp_dma
    port map (clk => clk, rst => rst, s_address => s_address, s_read => s_read, s_write => s_write,
              s_writedata => s_writedata, s_readdata => s_readdata, irq => irq, m_address => m_address,
              m_read => m_read, m_waitrequest => m_waitrequest, m_readdata => m_readdata,
              m_readdatavalid => m_readdatavalid, tx_clk => tclk, tx_rst => rst, txd => txd, tx_en => tx_en);

  pamiec : process (clk)
    type q_adr_t is array (0 to 31) of natural;
    variable q_adr, q_t : q_adr_t;
    variable q_gl, q_og, takt, t_ost, t_nowy, a : natural := 0;
    variable los : std_logic_vector(31 downto 0) := x"12345678";
  begin
    if rising_edge(clk) then
      takt := takt + 1;
      los := los(30 downto 0) & (los(31) xor los(21) xor los(1) xor los(0));
      if m_read = '1' and m_waitrequest = '0' then
        t_nowy := takt + 1 + (to_integer(unsigned(los(10 downto 8))) mod 6);
        if t_nowy < t_ost then t_nowy := t_ost; end if;
        t_ost := t_nowy;
        q_adr(q_og mod 32) := to_integer(m_address);
        q_t(q_og mod 32) := t_nowy;
        q_og := q_og + 1;
        odczytow <= odczytow + 1;
      end if;
      m_waitrequest <= los(3) and los(7);
      m_readdatavalid <= '0';
      if q_gl /= q_og and q_t(q_gl mod 32) <= takt then
        a := q_adr(q_gl mod 32);
        m_readdata <= wzor(a + 3) & wzor(a + 2) & wzor(a + 1) & wzor(a);
        m_readdatavalid <= '1';
        q_gl := q_gl + 1;
      end if;
    end if;
  end process;

  u_rx : entity work.mii_rx
    port map (clk => tclk, rst => rst, rxd => txd, rx_dv => tx_en, rx_er => '0', m_dane => r_dane,
              m_wazne => r_wazne, koniec => r_koniec, crc_ok => r_crc_ok, dlugosc => r_dl, blad => r_blad);
  odbior : process (tclk)
    variable nb : natural := 0;
  begin
    if rising_edge(tclk) then
      if r_wazne = '1' then ramka(nb) <= r_dane; nb := nb + 1; end if;
      if r_koniec = '1' then
        ramek <= ramek + 1;
        if r_crc_ok = '0' or r_blad = '1' then crc_zle <= crc_zle + 1; end if;
        dl_ost <= to_integer(r_dl);
        nb := 0;
      end if;
    end if;
  end process;

  process
    variable bledy : integer := 0;
    variable odczyt : std_logic_vector(31 downto 0);

    procedure zapisz(a : natural; d : std_logic_vector(31 downto 0)) is
    begin
      wait until falling_edge(clk);
      s_address <= to_unsigned(a, 4); s_writedata <= d; s_write <= '1';
      wait until falling_edge(clk);
      s_write <= '0';
    end procedure;
    procedure czytaj(a : natural) is
    begin
      wait until falling_edge(clk);
      s_address <= to_unsigned(a, 4); s_read <= '1';
      wait until falling_edge(clk);
      s_read <= '0'; odczyt := s_readdata;
    end procedure;
    impure function bajty(k, n : natural) return std_logic_vector is
      variable v : std_logic_vector(8 * n - 1 downto 0);
    begin
      for j in 0 to n - 1 loop
        v(8 * (n - j) - 1 downto 8 * (n - j - 1)) := ramka(k + j);
      end loop;
      return v;
    end function;
    impure function s16(k : natural) return natural is
    begin
      return to_integer(unsigned(bajty(k, 2)));
    end function;
    procedure sprawdz_ramke(adres, dl : natural) is
      variable oczek_dl, suma, bl_danych : natural;
    begin
      if 42 + dl < 60 then oczek_dl := 60; else oczek_dl := 42 + dl; end if;
      if dl_ost /= oczek_dl then
        pisz("FAIL: dlugosc ramki " & integer'image(dl_ost) & ", oczekiwana " & integer'image(oczek_dl));
        bledy := bledy + 1;
      end if;
      if bajty(0, 6) /= MAC_PC or bajty(6, 6) /= MAC_FPGA or s16(12) /= 16#0800# then
        pisz("FAIL: naglowek Ethernet"); bledy := bledy + 1;
      end if;
      suma := 0;
      for k in 0 to 9 loop suma := suma + s16(14 + 2 * k); end loop;
      suma := (suma mod 65536) + suma / 65536;
      if ramka(14) /= x"45" or s16(16) /= 28 + dl or ramka(23) /= x"11" or
         bajty(26, 4) /= IP_FPGA or bajty(30, 4) /= IP_PC or suma /= 16#FFFF# then
        pisz("FAIL: naglowek IPv4"); bledy := bledy + 1;
      end if;
      if s16(34) /= 5005 or s16(36) /= 5006 or s16(38) /= 8 + dl then
        pisz("FAIL: naglowek UDP"); bledy := bledy + 1;
      end if;
      bl_danych := 0;
      for k in 0 to dl - 1 loop
        if ramka(42 + k) /= wzor(adres + k) then bl_danych := bl_danych + 1; end if;
      end loop;
      if bl_danych /= 0 then pisz("FAIL: " & integer'image(bl_danych) & " bajtow danych niezgodnych"); bledy := bledy + 1; end if;
      pisz("ramka " & integer'image(ramek) & ": " & integer'image(dl_ost) & " B (dane " & integer'image(dl)
           & " B), CRC bledow " & integer'image(crc_zle) & ", danych niezgodnych " & integer'image(bl_danych));
    end procedure;
    procedure wyslij_pakiet(adres, dl : natural; dwa_starty : boolean) is
      variable t, r0 : natural;
    begin
      r0 := ramek;
      zapisz(2, std_logic_vector(to_unsigned(adres, 32)));
      zapisz(3, std_logic_vector(to_unsigned(dl, 32)));
      zapisz(0, x"00000003");
      if dwa_starty then zapisz(0, x"00000003"); end if;
      t := 0;
      while irq /= '1' and t < 200_000 loop wait until rising_edge(clk); t := t + 1; end loop;
      if irq /= '1' then pisz("FAIL: brak przerwania"); bledy := bledy + 1; end if;
      czytaj(1);
      if odczyt(1 downto 0) /= "10" then pisz("FAIL: STATUS"); bledy := bledy + 1; end if;
      zapisz(1, x"00000002");
      wait until falling_edge(clk);
      if irq = '1' then pisz("FAIL: przerwanie po kasowaniu"); bledy := bledy + 1; end if;
      t := 0;
      while ramek = r0 and t < 100_000 loop wait until rising_edge(tclk); t := t + 1; end loop;
      for i in 1 to 4 loop wait until rising_edge(tclk); end loop;
      sprawdz_ramke(adres, dl);
    end procedure;
  begin
    for i in 1 to 5 loop wait until rising_edge(clk); end loop;
    rst <= '0';
    zapisz(4, IP_FPGA);
    zapisz(5, IP_PC);
    zapisz(6, std_logic_vector(to_unsigned(5005, 16)) & std_logic_vector(to_unsigned(5006, 16)));
    zapisz(7, x"0000" & MAC_FPGA(47 downto 32));
    zapisz(8, MAC_FPGA(31 downto 0));
    zapisz(9, x"0000" & MAC_PC(47 downto 32));
    zapisz(10, MAC_PC(31 downto 0));
    czytaj(6);
    if odczyt /= std_logic_vector(to_unsigned(5005, 16)) & std_logic_vector(to_unsigned(5006, 16)) then
      pisz("FAIL: odczyt rejestru PORTY"); bledy := bledy + 1;
    end if;
    wyslij_pakiet(16#100#, 1001, false);
    wyslij_pakiet(16#1000#, 18, false);
    wyslij_pakiet(16#400#, 1472, true);
    czytaj(11);
    pisz("PAKIETY = " & integer'image(to_integer(unsigned(odczyt))) & ", ramek odebranych " & integer'image(ramek)
         & ", z bledem CRC " & integer'image(crc_zle) & ", odczytow pamieci " & integer'image(odczytow));
    if to_integer(unsigned(odczyt)) /= 3 or ramek /= 3 or crc_zle /= 0 or odczytow /= 251 + 5 + 368 then
      pisz("FAIL: liczniki"); bledy := bledy + 1;
    end if;
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;

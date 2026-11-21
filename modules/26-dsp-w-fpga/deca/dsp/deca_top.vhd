-- DECA — generator i filtr (moduł 26, 26.01 i 26.03): NCO -> filtr FIR (31 współczynników, fc ≈ 4,9 kHz)
-- -> dwa przetworniki sigma-delta na złączu GPIO0 (3,3 V). Zegar 50 MHz, próbki co 1024 takty: fs = 48 828 Hz.
--   GPIO0_D(0) — sygnał po filtrze, GPIO0_D(1) — przed filtrem (każde przez filtr RC, np. 1 kΩ + 10 nF).
--   SW(0) = 0 — stała częstotliwość, KEY(1) wybiera kolejną z 8 (250 Hz ... 8 kHz), LED(k) pokazuje numer;
--   SW(0) = 1 — przemiatanie 100 Hz -> 12 kHz w ok. 2 s, diody jako linijka częstotliwości.
--   SW(1) = 1 — fala prostokątna zamiast sinusa. KEY(0) — reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);    -- 0 = wciśnięty
    SW            : in  std_logic_vector(1 downto 0);    -- 0 = w dół
    LED           : out std_logic_vector(7 downto 0) := (others => '1');  -- 0 = świeci
    GPIO0_D       : out std_logic_vector(1 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  constant WSP   : std_logic_vector(16 * 31 - 1 downto 0) := x"00000027005B008B00810000FEF1FD9FFCC0FD48000005110BC3129317AB198E17AB12930BC305110000FD48FCC0FD9FFEF100000081008B005B00270000";   -- h_30 ... h_0 (Q1.15)
  constant F_MIN : unsigned(31 downto 0) := to_unsigned(8796093, 32);      -- 100 Hz
  constant F_MAX : unsigned(31 downto 0) := to_unsigned(1055531163, 32);   -- 12 kHz
  constant KROK  : unsigned(31 downto 0) := to_unsigned(10718, 32);        -- ok. 2 s przemiatania
  type f_tab_t is array (0 to 7) of natural;
  constant F_TAB : f_tab_t := (21990233, 43980465, 87960930, 175921860,     -- 250 Hz, 500 Hz, 1 kHz, 2 kHz
                               263882791, 351843721, 527765581, 703687442); -- 3, 4, 6, 8 kHz

  signal clk      : std_logic;
  signal rs       : std_logic_vector(1 downto 0) := "11";
  signal rst      : std_logic;
  signal licz_ms       : natural range 0 to 49999 := 0;
  signal k1       : std_logic_vector(1 downto 0) := "11";
  signal nacisk   : std_logic := '0';
  signal dz       : unsigned(9 downto 0) := (others => '0');
  signal we       : std_logic := '0';
  signal idx      : unsigned(2 downto 0) := "010";
  signal f_sw     : unsigned(31 downto 0) := to_unsigned(8796093, 32);
  signal ftw      : unsigned(31 downto 0);
  signal s, c     : signed(15 downto 0);
  signal s_wazne  : std_logic;
  signal x_we     : signed(15 downto 0);
  signal surowy   : signed(15 downto 0) := (others => '0');
  signal y        : signed(15 downto 0);
  signal yv       : std_logic;
begin
  clk <= MAX10_CLK1_50;
  rst <= rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      rs     <= rs(0) & not KEY(0);
      nacisk <= '0';
      if licz_ms = 49999 then licz_ms <= 0; else licz_ms <= licz_ms + 1; end if;
      if licz_ms = 0 then                                   -- KEY(1) próbkowany co 1 ms
        k1 <= k1(0) & KEY(1);
        if k1(0) = '0' and k1(1) = '1' then nacisk <= '1'; end if;
      end if;
      dz <= dz + 1;
      we <= '1' when dz = 0 else '0';
      if rst = '1' then
        idx <= "010"; f_sw <= F_MIN;
      else
        if nacisk = '1' then idx <= idx + 1; end if;
        if we = '1' then
          if f_sw >= F_MAX then f_sw <= F_MIN; else f_sw <= f_sw + KROK; end if;
        end if;
      end if;
      if SW(0) = '1' then
        LED <= not std_logic_vector(shift_right(unsigned'(x"FF"), 7 - to_integer(f_sw(29 downto 27))));
      else
        LED <= not std_logic_vector(shift_left(unsigned'(x"01"), to_integer(idx)));
      end if;
      if s_wazne = '1' then surowy <= x_we; end if;
    end if;
  end process;

  ftw  <= f_sw when SW(0) = '1' else to_unsigned(F_TAB(to_integer(idx)), 32);
  x_we <= to_signed(-16000, 16) when SW(1) = '1' and s(15) = '1' else
          to_signed(16000, 16)  when SW(1) = '1' else
          shift_right(s, 1);

  u_nco : entity work.nco port map (clk => clk, rst => rst, we => we, ftw => ftw, sin_o => s, cos_o => c,
                                    wazne => s_wazne);
  u_fir : entity work.fir_transp generic map (N => 31)
    port map (clk => clk, rst => rst, we => s_wazne, x => x_we, wsp => WSP, y => y, y_wazne => yv);
  u_d0 : entity work.sd_dac port map (clk => clk, rst => rst, x => y,      q => GPIO0_D(0));
  u_d1 : entity work.sd_dac port map (clk => clk, rst => rst, x => surowy, q => GPIO0_D(1));
end architecture rtl;

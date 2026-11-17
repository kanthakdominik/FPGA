-- Moduł nadrzędny DECA - VHDL. Projekt do analizy czasowej (moduł 14):
--   PLL: 50 MHz -> clk_sys 100 MHz (zegar generowany, 14.03),
--   dzielnik_mc: dzielenie co 0,25 s, ścieżka wielotaktowa N = 8 (14.04),
--   spi_master: SPI 25 MHz na złączu P8 - interfejs z zegarem przesyłanym razem z danymi (14.06):
--     GPIO0_D(0) = SCLK, GPIO0_D(1) = MOSI, GPIO0_D(2) = CS_N (wyjścia), GPIO0_D(3) = MISO (wejście);
--     zworka GPIO0_D(1) - GPIO0_D(3) zamyka pętlę: odebrany bajt = wysłany.
--   KEY(0) - reset; SW(0) = '0': LED = bajt odebrany przez SPI, '1': LED = iloraz (SW(1) = '1': reszta).
-- Ograniczenia: sta.sdc. Komponent altpll wiąże Quartus z biblioteką altera_mf; w GHDL zostaje niepowiązany.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);   -- '0' = wciśnięty
    SW            : in    std_logic_vector(1 downto 0);   -- '0' = w dół
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    GPIO0_D       : inout std_logic_vector(3 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component altpll
    generic (
      intended_device_family : string;
      lpm_type               : string;
      operation_mode         : string;
      pll_type               : string;
      inclk0_input_frequency : natural;
      clk0_multiply_by       : natural;
      clk0_divide_by         : natural;
      clk0_duty_cycle        : natural;
      clk0_phase_shift       : string;
      compensate_clock       : string;
      width_clock            : natural
    );
    port (
      inclk  : in  std_logic_vector(1 downto 0);
      areset : in  std_logic;
      clk    : out std_logic_vector(4 downto 0);
      locked : out std_logic
    );
  end component;

  signal pll_in      : std_logic_vector(1 downto 0);
  signal pll_clk     : std_logic_vector(4 downto 0);
  signal clk_sys     : std_logic;
  signal locked      : std_logic;
  signal rst_n_async : std_logic;
  signal rst_sync    : std_logic_vector(1 downto 0) := "00";
  signal rst         : std_logic;
  signal sw_meta, sw_s : std_logic_vector(1 downto 0) := "00";
  signal div         : natural range 0 to 24999999 := 0;
  signal tick        : std_logic := '0';
  signal cnt8        : unsigned(7 downto 0) := (others => '0');
  signal lfsr        : unsigned(15 downto 0) := x"ACE1";
  signal q           : unsigned(15 downto 0);
  signal r           : unsigned(7 downto 0);
  signal d_busy, d_done : std_logic;
  signal s_busy, s_done, sclk, mosi, cs_n : std_logic;
  signal tx8         : std_logic_vector(7 downto 0);
  signal rx          : std_logic_vector(7 downto 0);
  signal rx_last, q_last, r_last : std_logic_vector(7 downto 0) := (others => '0');
  signal led_r       : std_logic_vector(7 downto 0) := (others => '1');
begin
  -- PLL: 50 MHz -> 100 MHz
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10",
      lpm_type               => "altpll",
      operation_mode         => "NORMAL",
      pll_type               => "AUTO",
      inclk0_input_frequency => 20000,           -- ps
      clk0_multiply_by       => 2,
      clk0_divide_by         => 1,
      clk0_duty_cycle        => 50,
      clk0_phase_shift       => "0",
      compensate_clock       => "CLK0",
      width_clock            => 5
    )
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => locked);
  pll_in  <= '0' & MAX10_CLK1_50;
  clk_sys <= pll_clk(0);

  -- reset: KEY(0) albo brak synchronizacji PLL; zdjęcie synchroniczne z clk_sys
  rst_n_async <= KEY(0) and locked;
  process (clk_sys, rst_n_async)
  begin
    if rst_n_async = '0' then
      rst_sync <= "00";
    elsif rising_edge(clk_sys) then
      rst_sync <= rst_sync(0) & '1';
    end if;
  end process;
  rst <= not rst_sync(1);

  process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      -- przełączniki: dwa przerzutniki synchronizujące
      sw_meta <= SW;
      sw_s    <= sw_meta;
      -- impuls co 0,25 s, licznik bajtów i LFSR jako dzielna
      if div = 24999999 then
        div  <= 0;
        tick <= '1';
      else
        div  <= div + 1;
        tick <= '0';
      end if;
      if tick = '1' then
        cnt8 <= cnt8 + 1;
        lfsr <= lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
      end if;
    end if;
  end process;

  u_dziel : entity work.dzielnik_mc
    generic map (W => 16, V => 8, N => 8)
    port map (clk => clk_sys, rst => rst, start => tick, a => lfsr, b => cnt8,
              busy => d_busy, done => d_done, q => q, r => r);

  u_spi : entity work.spi_master
    generic map (DIV => 2)
    port map (clk => clk_sys, rst => rst, start => tick, tx => tx8, busy => s_busy,
              done => s_done, rx => rx, sclk => sclk, mosi => mosi, cs_n => cs_n, miso => GPIO0_D(3));
  tx8 <= std_logic_vector(cnt8);
  GPIO0_D(0) <= sclk;
  GPIO0_D(1) <= mosi;
  GPIO0_D(2) <= cs_n;
  GPIO0_D(3) <= 'Z';

  -- diody
  process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if s_done = '1' then
        rx_last <= rx;
      end if;
      if d_done = '1' then
        q_last <= std_logic_vector(q(7 downto 0));
        r_last <= std_logic_vector(r);
      end if;
      if sw_s(0) = '1' then
        if sw_s(1) = '1' then
          led_r <= not r_last;
        else
          led_r <= not q_last;
        end if;
      else
        led_r <= not rx_last;
      end if;
    end if;
  end process;
  LED <= led_r;
end architecture rtl;

-- Moduł nadrzędny DECA - VHDL. Projekt do zamykania timingu i analizy mocy (moduł 16):
--   PLL: 50 MHz -> clk_sys 150 MHz,
--   sumator_drzewo (PIPE stopni potoku): osiem 16-bitowych próbek z LFSR w każdym takcie (16.01, 16.04),
--   izolacja_operandow (ISO): mnożenie 16 x 16, dane ważne co czwarty takt (16.06).
--   Wyniki składane w sumy kontrolne XOR, żeby synteza nie usunęła logiki.
--   KEY(0) - reset; SW(0) = '0': LED = suma kontrolna drzewa, '1': LED = suma kontrolna iloczynów.
-- Ograniczenia: wydajnosc.sdc. Komponent altpll wiąże Quartus z biblioteką altera_mf.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  generic (
    PIPE : natural := 2;
    ISO  : boolean := true
  );
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);   -- '0' = wciśnięty
    SW            : in  std_logic_vector(1 downto 0);   -- '0' = w dół
    LED           : out std_logic_vector(7 downto 0)    -- '0' = świeci
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
  signal sw_sync     : std_logic_vector(1 downto 0) := "00";
  signal lfsr        : std_logic_vector(15 downto 0) := x"ACE1";
  signal okno        : std_logic_vector(127 downto 0) := (others => '0');
  signal faza        : unsigned(1 downto 0) := (others => '0');
  signal m_in_valid  : std_logic;
  signal s_valid, m_valid : std_logic;
  signal s_y         : std_logic_vector(18 downto 0);
  signal m_p         : std_logic_vector(31 downto 0);
  signal csum_s, csum_m : std_logic_vector(7 downto 0) := (others => '0');
  signal led_r       : std_logic_vector(7 downto 0) := (others => '1');
begin
  -- PLL: 50 MHz -> 150 MHz
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10",
      lpm_type               => "altpll",
      operation_mode         => "NORMAL",
      pll_type               => "AUTO",
      inclk0_input_frequency => 20000,           -- ps
      clk0_multiply_by       => 3,
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

  -- przełącznik, LFSR, linia ośmiu ostatnich wartości, faza dla danych mnożarki
  process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      sw_sync <= sw_sync(0) & SW(0);
      lfsr    <= lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
      okno    <= okno(111 downto 0) & lfsr;
      faza    <= faza + 1;
    end if;
  end process;

  u_sum : entity work.sumator_drzewo
    generic map (W => 16, PIPE => PIPE)
    port map (clk => clk_sys, rst => rst, in_valid => '1', x => okno, out_valid => s_valid, y => s_y);

  m_in_valid <= '1' when faza = 0 else '0';
  u_mnoz : entity work.izolacja_operandow
    generic map (W => 16, ISO => ISO)
    port map (clk => clk_sys, rst => rst, in_valid => m_in_valid, a => lfsr, b => okno(31 downto 16),
              out_valid => m_valid, p => m_p);

  -- sumy kontrolne i diody
  process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst = '1' then
        csum_s <= (others => '0');
        csum_m <= (others => '0');
      else
        if s_valid = '1' then
          csum_s <= (csum_s(6 downto 0) & csum_s(7)) xor s_y(7 downto 0) xor s_y(15 downto 8)
                    xor ("00000" & s_y(18 downto 16));
        end if;
        if m_valid = '1' then
          csum_m <= (csum_m(6 downto 0) & csum_m(7)) xor m_p(7 downto 0) xor m_p(15 downto 8)
                    xor m_p(23 downto 16) xor m_p(31 downto 24);
        end if;
      end if;
      if sw_sync(1) = '1' then
        led_r <= not csum_m;
      else
        led_r <= not csum_s;
      end if;
    end if;
  end process;
  LED <= led_r;
end architecture rtl;

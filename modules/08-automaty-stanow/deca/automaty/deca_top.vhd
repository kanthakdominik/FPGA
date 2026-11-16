-- Moduł nadrzędny DECA — VHDL. Automaty z modułu 08 na płytce:
--   KEY(0)  — reset (ustawienie asynchroniczne, zdjęcie synchroniczne),
--   KEY(1)  — przycisk przez debounce_fsm (10 ms),
--   SW(0)   — '0': procesor tiny_cpu wykonuje 4 kroki na sekundę; '1': jeden krok na każde naciśnięcie KEY(1),
--   SW(1)   — '0': LED = ostatnia wartość OUT procesora (ciąg Fibonacciego modulo 256, dwójkowo);
--             '1': LED(7:4) = liczba zboczy KEY(1) bez filtra, LED(3:0) = liczba naciśnięć po filtracji.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);    -- '0' = wciśnięty
    SW            : in  std_logic_vector(1 downto 0);    -- '0' = w dół
    LED           : out std_logic_vector(7 downto 0) := (others => '1')  -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst                             : std_logic;
  signal rst_sync                             : std_logic_vector(1 downto 0) := "00";
  signal sw_meta, sw_s                        : std_logic_vector(1 downto 0);
  signal btn                                  : std_logic;
  signal key_raw, key_level, key_rise, key_fall : std_logic;
  signal key_raw_d                            : std_logic := '0';
  signal div                                  : unsigned(23 downto 0) := (others => '0');
  signal tick4, step, out_valid, halted       : std_logic := '0';
  signal fib                                  : std_logic_vector(7 downto 0);
  signal pc                                   : std_logic_vector(3 downto 0);
  signal raw_cnt, deb_cnt                     : unsigned(3 downto 0) := (others => '0');
begin
  clk <= MAX10_CLK1_50;

  -- reset z KEY(0) — synchronizator resetu (07.02)
  p_rst : process (clk, KEY(0))
  begin
    if KEY(0) = '0' then
      rst_sync <= "00";
    elsif rising_edge(clk) then
      rst_sync <= rst_sync(0) & '1';
    end if;
  end process p_rst;
  rst <= not rst_sync(1);

  -- przełączniki — dwa przerzutniki synchronizujące
  p_sw : process (clk)
  begin
    if rising_edge(clk) then
      sw_meta <= SW;
      sw_s    <= sw_meta;
    end if;
  end process p_sw;

  -- KEY(1): synchronizacja i filtr drgań w debounce_fsm
  btn <= not KEY(1);
  u_key : entity work.debounce_fsm generic map (N => 500_000)
    port map (clk => clk, rst => rst, btn => btn, raw => key_raw, level => key_level, rise => key_rise, fall => key_fall);

  -- impuls 4 Hz do pracy ciągłej (07.04)
  p_tick : process (clk)
  begin
    if rising_edge(clk) then
      if div = 12_499_999 then
        div   <= (others => '0');
        tick4 <= '1';
      else
        div   <= div + 1;
        tick4 <= '0';
      end if;
    end if;
  end process p_tick;

  -- procesor sekwencyjny z programem domyślnym (ciąg Fibonacciego)
  step <= key_rise when sw_s(0) = '1' else tick4;
  u_cpu : entity work.tiny_cpu
    port map (clk => clk, rst => rst, step => step, out_data => fib, out_valid => out_valid, halted => halted, pc_o => pc);

  -- liczniki: zbocza wejścia bez filtra (widać drgania) i naciśnięcia po filtracji
  p_cnt : process (clk)
  begin
    if rising_edge(clk) then
      key_raw_d <= key_raw;
      if rst = '1' then
        raw_cnt <= (others => '0');
        deb_cnt <= (others => '0');
      else
        if key_raw = '1' and key_raw_d = '0' then
          raw_cnt <= raw_cnt + 1;
        end if;
        if key_rise = '1' then
          deb_cnt <= deb_cnt + 1;
        end if;
      end if;
    end if;
  end process p_cnt;

  p_led : process (clk)
  begin
    if rising_edge(clk) then
      if sw_s(1) = '1' then
        LED <= not std_logic_vector(raw_cnt & deb_cnt);
      else
        LED <= not fib;
      end if;
    end if;
  end process p_led;
end architecture rtl;

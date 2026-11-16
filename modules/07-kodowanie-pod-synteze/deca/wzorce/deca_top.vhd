-- Moduł nadrzędny DECA — VHDL. Wzorce RTL z modułu 07 na jednej płytce:
--   KEY(0)   — reset przez synchronizator resetu (reset_sync),
--   KEY(1)   — wciśnięty: pauza stopera,
--   SW(1:0)  — wzmocnienie jasności 32, 64, 128 albo 255,
--   LED(3:0) — „oddychająca” fala: jasność z tablicy sinusa (sine_rom), przemnożona przez wzmocnienie
--              i opóźniona liniami opóźniającymi (delay_line) o 0,16 s na każdą kolejną diodę,
--   LED(7:4) — sekundy stopera 0–9 w kodzie dwójkowym (bcd_counter z zezwoleniem 100 Hz z tick_gen).
-- Jeden zegar 50 MHz w całym projekcie; wolne zdarzenia wyznaczają impulsy zezwolenia, nie dzielone zegary.
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
  signal clk, rst, tick, carry  : std_logic;
  signal in_meta, in_sync       : std_logic_vector(2 downto 0);
  signal bcd                    : std_logic_vector(11 downto 0);
  signal phase                  : unsigned(6 downto 0) := (others => '0');
  signal addr                   : std_logic_vector(5 downto 0);
  signal sine                   : std_logic_vector(7 downto 0);
  signal gain                   : unsigned(7 downto 0);
  signal prod                   : unsigned(15 downto 0);
  signal lvl0, lvl1, lvl2, lvl3 : std_logic_vector(7 downto 0);
  signal pwm_cnt                : unsigned(7 downto 0) := (others => '0');
  signal en_sec                 : std_logic;
begin
  clk <= MAX10_CLK1_50;

  u_rst : entity work.reset_sync generic map (STAGES => 2) port map (clk => clk, arst_n => KEY(0), rst => rst);

  -- KEY(1) i SW zmieniają się niezależnie od zegara — dwa przerzutniki synchronizujące (moduł 15)
  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      in_meta <= KEY(1) & SW;
      in_sync <= in_meta;
    end if;
  end process p_sync;

  u_tick : entity work.tick_gen generic map (DIV => 500_000) port map (clk => clk, rst => rst, tick => tick);

  -- stoper 0,00–9,99 s; bcd(11 downto 8) to cyfra sekund
  en_sec <= tick and in_sync(2);
  u_bcd : entity work.bcd_counter generic map (DIGITS => 3)
    port map (clk => clk, rst => rst, en => en_sec, bcd => bcd, carry => carry);

  -- faza 0..127 co 10 ms: pierwsza połowa — rosnąca ćwiartka sinusa, druga — ta sama ćwiartka wstecz
  p_phase : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase <= (others => '0');
      elsif tick = '1' then
        phase <= phase + 1;
      end if;
    end if;
  end process p_phase;

  addr <= std_logic_vector(not phase(5 downto 0)) when phase(6) = '1' else std_logic_vector(phase(5 downto 0));
  u_rom : entity work.sine_rom port map (clk => clk, addr => addr, data => sine);

  -- wzmocnienie: mnożenie 8 x 8 bitów (w MAX 10 — blok mnożarki 9 x 9)
  with in_sync(1 downto 0) select gain <=
    to_unsigned(32, 8)  when "00",
    to_unsigned(64, 8)  when "01",
    to_unsigned(128, 8) when "10",
    to_unsigned(255, 8) when others;

  p_mult : process (clk)
  begin
    if rising_edge(clk) then
      prod <= unsigned(sine) * gain;
    end if;
  end process p_mult;

  -- fala: każda kolejna dioda dostaje jasność sprzed 16 impulsów (0,16 s)
  lvl0 <= std_logic_vector(prod(15 downto 8));
  u_dl1 : entity work.delay_line generic map (W => 8, DEPTH => 16) port map (clk => clk, ce => tick, din => lvl0, dout => lvl1);
  u_dl2 : entity work.delay_line generic map (W => 8, DEPTH => 16) port map (clk => clk, ce => tick, din => lvl1, dout => lvl2);
  u_dl3 : entity work.delay_line generic map (W => 8, DEPTH => 16) port map (clk => clk, ce => tick, din => lvl2, dout => lvl3);

  -- PWM 8-bitowy (ok. 195 kHz) i rejestr na wyjściach — bez szpilek na diodach
  p_pwm : process (clk)
    variable wave : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      pwm_cnt <= pwm_cnt + 1;
      wave(3) := '1' when unsigned(lvl3) > pwm_cnt else '0';
      wave(2) := '1' when unsigned(lvl2) > pwm_cnt else '0';
      wave(1) := '1' when unsigned(lvl1) > pwm_cnt else '0';
      wave(0) := '1' when unsigned(lvl0) > pwm_cnt else '0';
      LED     <= not (bcd(11 downto 8) & wave);
    end if;
  end process p_pwm;
end architecture rtl;

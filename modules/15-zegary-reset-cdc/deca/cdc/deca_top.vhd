-- Moduł nadrzędny DECA - VHDL. Przejścia między domenami (moduł 15): dwa zegary bez wspólnej fazy -
-- clk50 (MAX10_CLK1_50, 50 MHz) i clk10 (ADC_CLK_10, 10 MHz), w SDC jako grupy asynchroniczne.
--   domena clk50 (producent): licznik zapisywany do async_fifo, gdy nie jest pełna; przycisk KEY(1)
--     (synchronizator + wykrycie zbocza) -> sync_pulse; przełączniki SW -> cdc_handshake przy każdej zmianie;
--   domena clk10 (konsument): odczyt z FIFO w każdym takcie i sprawdzenie ciągłości licznika;
--   reset: rst_sekwencer - KEY(0) ustawia reset w obu domenach, zdejmowany najpierw w clk50, potem w clk10.
-- Diody ('0' = świeci): LED(3..0) - liczba naciśnięć KEY(1) odebranych w clk10, LED(5..4) - SW przesłane
-- handshake'iem, LED(6) - miga ok. 1 Hz (clk10 pracuje), LED(7) - błąd ciągłości danych z FIFO (trwały).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    ADC_CLK_10    : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);   -- '0' = wciśnięty
    SW            : in  std_logic_vector(1 downto 0);   -- '0' = w dół
    LED           : out std_logic_vector(7 downto 0)    -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk50, clk10, rst50, rst10 : std_logic;
  signal key1_raw, sw0_s, sw1_s       : std_logic_vector(0 downto 0);
  signal key1, key1_d                 : std_logic := '0';
  signal sw_s, sw_wyslane, sw_b       : std_logic_vector(1 downto 0) := "00";
  signal prod                         : unsigned(7 downto 0) := (others => '0');
  signal full, p_busy, h_ready        : std_logic;
  signal key_nacisk, wyslij_sw        : std_logic;
  signal wr_en                        : std_logic;
  signal dane                         : std_logic_vector(7 downto 0);
  signal empty, key_b, sw_valid       : std_logic;
  signal oczek                        : unsigned(7 downto 0) := (others => '0');
  signal pierwszy                     : std_logic := '1';
  signal blad                         : std_logic := '0';
  signal n_key                        : unsigned(3 downto 0) := (others => '0');
  signal sw_pokaz                     : std_logic_vector(1 downto 0) := "00";
  signal mig                          : unsigned(22 downto 0) := (others => '0');
  signal led_r                        : std_logic_vector(7 downto 0) := (others => '1');
begin
  clk50 <= MAX10_CLK1_50;
  clk10 <= ADC_CLK_10;

  -- reset w kolejności: producent (clk50), potem konsument (clk10)
  u_rst : entity work.rst_sekwencer
    port map (arst_n => KEY(0), clk_a => clk50, rst_a => rst50, clk_b => clk10, rst_b => rst10);

  -- sygnały niezależne - każdy własnym synchronizatorem; odwrócenie KEY dopiero po synchronizacji
  u_key : entity work.sync_bit port map (clk => clk50, d => KEY(1 downto 1), q => key1_raw);
  u_sw0 : entity work.sync_bit port map (clk => clk50, d => SW(0 downto 0), q => sw0_s);
  u_sw1 : entity work.sync_bit port map (clk => clk50, d => SW(1 downto 1), q => sw1_s);
  key1 <= not key1_raw(0);
  sw_s <= sw1_s(0) & sw0_s(0);

  process (clk50)
  begin
    if rising_edge(clk50) then
      key1_d <= key1;
      if rst50 = '1' then
        prod       <= (others => '0');
        sw_wyslane <= "00";
      else
        if full = '0' then
          prod <= prod + 1;
        end if;
        if h_ready = '1' and sw_s /= sw_wyslane then
          sw_wyslane <= sw_s;
        end if;
      end if;
    end if;
  end process;
  key_nacisk <= key1 and not key1_d;         -- zbocze naciśnięcia (bez filtra drgań)
  wyslij_sw  <= h_ready when sw_s /= sw_wyslane else '0';
  wr_en      <= not full;

  u_fifo : entity work.async_fifo
    generic map (W => 8, AW => 4)
    port map (wr_clk => clk50, wr_rst => rst50, wr_en => wr_en, wr_data => std_logic_vector(prod),
              wr_full => full, rd_clk => clk10, rd_rst => rst10, rd_en => '1', rd_data => dane,
              rd_empty => empty);
  u_puls : entity work.sync_pulse
    port map (clk_src => clk50, rst_src => rst50, src_pulse => key_nacisk, busy => p_busy,
              clk_dst => clk10, rst_dst => rst10, dst_pulse => key_b);
  u_hs : entity work.cdc_handshake
    generic map (W => 2)
    port map (clk_src => clk50, rst_src => rst50, send => wyslij_sw, src_data => sw_s, ready => h_ready,
              clk_dst => clk10, rst_dst => rst10, dst_valid => sw_valid, dst_data => sw_b);

  process (clk10)
  begin
    if rising_edge(clk10) then
      mig <= mig + 1;
      if rst10 = '1' then
        pierwszy <= '1';
        blad     <= '0';
        n_key    <= (others => '0');
        sw_pokaz <= "00";
      else
        if empty = '0' then
          if pierwszy = '0' and unsigned(dane) /= oczek then
            blad <= '1';
          end if;
          oczek    <= unsigned(dane) + 1;
          pierwszy <= '0';
        end if;
        if key_b = '1' then
          n_key <= n_key + 1;
        end if;
        if sw_valid = '1' then
          sw_pokaz <= sw_b;
        end if;
      end if;
      led_r <= not (blad & mig(22) & sw_pokaz & std_logic_vector(n_key));
    end if;
  end process;
  LED <= led_r;
end architecture rtl;

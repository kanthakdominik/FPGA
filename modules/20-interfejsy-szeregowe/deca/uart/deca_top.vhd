-- Moduł nadrzędny DECA - VHDL. UART 115 200 b/s 8N1 na złączu GPIO (20.01):
--   GPIO0_D(0) - TX (do wejścia RX przejściówki USB-UART 3,3 V), GPIO0_D(1) - RX (z wyjścia TX przejściówki).
--   Echo: każdy odebrany bajt wraca do komputera; SW(0) w górze - echo zamienia małe litery na wielkie.
--   KEY(1) - wysłanie napisu "DECA UART 115200 8N1", KEY(0) - reset.
--   LED(6 downto 0) - kod ostatniego odebranego znaku, LED(7) - błąd ramki (lepki do resetu).
-- Bez przejściówki: zwora między GPIO0_D(0) i GPIO0_D(1) - napis z KEY(1) wraca i pojawia się na diodach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    GPIO0_D       : inout std_logic_vector(1 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  constant NAPIS : string := "DECA UART 115200 8N1" & CR & LF;
  signal clk, rst       : std_logic;
  signal rs             : std_logic_vector(1 downto 0) := "00";
  signal s_sw           : std_logic_vector(1 downto 0) := "00";
  signal s_key, kp      : std_logic_vector(1 downto 0) := "11";
  signal tx, gotowy, wazne, bl_r : std_logic;
  signal odebr          : std_logic_vector(7 downto 0);
  signal start          : std_logic := '0';
  signal bajt, echo_b   : std_logic_vector(7 downto 0) := x"00";
  signal dz             : unsigned(17 downto 0) := (others => '0');
  signal nacisk         : std_logic;
  signal nadaje, echo, blad : std_logic := '0';
  signal ni             : natural range 1 to NAPIS'length := 1;
  signal ost            : std_logic_vector(6 downto 0) := (others => '0');
  attribute altera_attribute : string;
  attribute altera_attribute of s_sw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  attribute altera_attribute of s_key : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  clk <= MAX10_CLK1_50;

  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst <= not rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_sw  <= SW;
      s_key <= s_key(0) & KEY(1);
    end if;
  end process;

  -- ---- UART
  u_tx : entity work.uart_tx generic map (CLK_HZ => 50_000_000, BAUD => 115_200)
    port map (clk => clk, rst => rst, start => start, dane => bajt, gotowy => gotowy, tx => tx);
  u_rx : entity work.uart_rx generic map (CLK_HZ => 50_000_000, BAUD => 115_200)
    port map (clk => clk, rst => rst, rx => GPIO0_D(1), dane => odebr, wazne => wazne, blad_ramki => bl_r,
              blad_parz => open);
  GPIO0_D(0) <= tx;
  GPIO0_D(1) <= 'Z';

  -- przycisk: zbocze po odczekaniu drgań (próbkowanie co 2^18 taktów)
  process (clk)
  begin
    if rising_edge(clk) then
      dz <= dz + 1;
      if dz = 0 then kp <= kp(0) & s_key(1); end if;
    end if;
  end process;
  nacisk <= '1' when kp = "10" and dz = 0 else '0';

  process (clk)
    variable o : unsigned(7 downto 0);
  begin
    if rising_edge(clk) then
      start <= '0';
      if rst = '1' then
        nadaje <= '0';
        echo   <= '0';
        blad   <= '0';
      else
        if wazne = '1' then
          ost  <= odebr(6 downto 0);
          if bl_r = '1' then blad <= '1'; end if;
          echo <= '1';
          o := unsigned(odebr);
          if s_sw(0) = '1' and o >= character'pos('a') and o <= character'pos('z') then
            echo_b <= std_logic_vector(o - 32);
          else
            echo_b <= odebr;
          end if;
        end if;
        if nacisk = '1' then
          nadaje <= '1';
          ni     <= 1;
        end if;
        if gotowy = '1' and start = '0' then
          if echo = '1' then                                     -- echo ma pierwszeństwo przed napisem
            bajt  <= echo_b;
            start <= '1';
            echo  <= '0';
          elsif nadaje = '1' then
            bajt  <= std_logic_vector(to_unsigned(character'pos(NAPIS(ni)), 8));
            start <= '1';
            if ni = NAPIS'length then
              nadaje <= '0';
            else
              ni <= ni + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  LED <= not (blad & ost);
end architecture rtl;

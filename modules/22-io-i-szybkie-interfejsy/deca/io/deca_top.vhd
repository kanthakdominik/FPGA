-- Moduł nadrzędny DECA - VHDL. Wyjścia o różnej sile i szybkości narastania (22.01) i łącze DDR w pętli
-- przez zworę GPIO0_D(5) -> GPIO0_D(6) (22.02); opis pinów i diod jak w deca_top.v.
-- Rejestry DDR: megafunkcje ALTDDIO_OUT i ALTDDIO_IN (biblioteka altera_mf w Quartusie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    GPIO0_D       : inout std_logic_vector(6 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component altddio_out
    generic (width : natural; intended_device_family : string);
    port (
      datain_h : in  std_logic_vector(width - 1 downto 0);
      datain_l : in  std_logic_vector(width - 1 downto 0);
      outclock : in  std_logic;
      dataout  : out std_logic_vector(width - 1 downto 0)
    );
  end component;
  component altddio_in
    generic (width : natural; intended_device_family : string);
    port (
      datain    : in  std_logic_vector(width - 1 downto 0);
      inclock   : in  std_logic;
      dataout_h : out std_logic_vector(width - 1 downto 0);
      dataout_l : out std_logic_vector(width - 1 downto 0)
    );
  end component;

  signal clk, clk_wej, rst, rst_spr, prost, synch : std_logic := '0';
  signal rs, s_sw, bity, odb, wh, wl, dh, dl : std_logic_vector(1 downto 0) := "00";
  signal s_k1  : std_logic_vector(1 downto 0) := "11";
  signal wyj   : std_logic_vector(1 downto 0);
  signal bledy : std_logic_vector(15 downto 0);
  signal licz7 : std_logic_vector(6 downto 0);
  attribute altera_attribute : string;
  attribute altera_attribute of s_sw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
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
      s_k1  <= s_k1(0) & KEY(1);
      prost <= not prost;
    end if;
  end process;
  GPIO0_D(3 downto 0) <= (others => prost);

  u_gen : entity work.prbs7 generic map (N => 2) port map (clk => clk, rst => rst, en => '1', q => bity);

  clk_wej <= not clk when s_sw(0) = '1' else clk;
  dh <= '1' & bity(1);
  dl <= '0' & bity(0);
  u_wyj : altddio_out generic map (width => 2, intended_device_family => "MAX 10")
    port map (datain_h => dh, datain_l => dl, outclock => clk, dataout => wyj);
  GPIO0_D(5 downto 4) <= wyj;
  u_wej : altddio_in generic map (width => 1, intended_device_family => "MAX 10")
    port map (datain => GPIO0_D(6 downto 6), inclock => clk_wej, dataout_h => wh(0 downto 0),
              dataout_l => wl(0 downto 0));
  GPIO0_D(6) <= 'Z';

  process (clk_wej)
  begin
    if rising_edge(clk_wej) then
      odb <= wh(0) & wl(0);
    end if;
  end process;
  rst_spr <= rst or not s_k1(1);
  u_spr : entity work.prbs7_spr generic map (N => 2)
    port map (clk => clk_wej, rst => rst_spr, en => '1', d => odb, bledy => bledy, synch => synch);

  licz7 <= "1111111" when unsigned(bledy) > 127 else bledy(6 downto 0);
  LED   <= not (licz7 & synch);
end architecture rtl;

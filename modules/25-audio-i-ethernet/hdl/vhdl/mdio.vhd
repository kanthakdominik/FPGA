-- Master MDIO (25.03, IEEE 802.3 klauzula 22): preambuła 32 × 1, ST = 01, OP (10 odczyt, 01 zapis), PHY, rejestr,
-- TA, 16 bitów danych. MDC = clk / (2·DIV). Zmiana MDIO przy opadającym MDC; przy odczycie linia zwolniona od TA,
-- dane PHY próbkowane przy narastającym MDC.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mdio is
  generic (DIV : positive := 10);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    start   : in  std_logic;
    zapis   : in  std_logic;
    phy     : in  std_logic_vector(4 downto 0);
    rej     : in  std_logic_vector(4 downto 0);
    wdane   : in  std_logic_vector(15 downto 0);
    rdane   : out std_logic_vector(15 downto 0) := (others => '0');
    gotowe  : out std_logic := '0';
    zajety  : out std_logic := '0';
    mdc     : out std_logic := '0';
    mdio_o  : out std_logic := '1';
    mdio_oe : out std_logic := '0';
    mdio_i  : in  std_logic
  );
end entity mdio;

architecture rtl of mdio is
  signal t       : natural range 0 to DIV - 1 := 0;
  signal b       : natural range 0 to 64 := 0;
  signal ramka   : std_logic_vector(63 downto 0) := (others => '0');
  signal r_zapis, zaj, zg : std_logic := '0';
  signal rd      : std_logic_vector(15 downto 0) := (others => '0');
begin
  zajety <= zaj;
  mdc    <= zg;
  rdane  <= rd;

  process (clk)
  begin
    if rising_edge(clk) then
      gotowe <= '0';
      if rst = '1' then
        t <= 0; b <= 0; ramka <= (others => '0'); r_zapis <= '0'; rd <= (others => '0'); zaj <= '0';
        zg <= '0'; mdio_o <= '1'; mdio_oe <= '0';
      elsif zaj = '0' then
        zg <= '0';
        if start = '1' then
          zaj <= '1'; r_zapis <= zapis; b <= 0; t <= 0; mdio_oe <= '1'; mdio_o <= '1';
          if zapis = '1' then ramka <= x"FFFFFFFF" & "01" & "01" & phy & rej & "10" & wdane;
          else                ramka <= x"FFFFFFFF" & "01" & "10" & phy & rej & "11" & x"FFFF";
          end if;
        end if;
      elsif t /= DIV - 1 then
        t <= t + 1;
      else
        t  <= 0;
        zg <= not zg;
        if zg = '0' then                                           -- narastające MDC
          if r_zapis = '0' and b >= 48 and b < 64 then rd <= rd(14 downto 0) & mdio_i; end if;
        else                                                       -- opadające MDC
          if b = 64 then
            zaj <= '0'; gotowe <= '1'; mdio_oe <= '0';
          else
            b <= b + 1;
            if b = 63 then
              mdio_o <= '1'; mdio_oe <= '0';
            else
              mdio_o <= ramka(62 - b);
              if r_zapis = '1' or b < 45 then mdio_oe <= '1'; else mdio_oe <= '0'; end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

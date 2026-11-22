-- Plik rejestrów RV32I (27.07): x0 = 0, dwa odczyty kombinacyjne, zapis na zboczu. PRZEZ = true — zapis widoczny
-- w odczycie w tym samym takcie (rdzeń potokowy); w jednocyklowym false (inaczej pętla kombinacyjna).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_rejestry is
  generic (PRZEZ : boolean := false);
  port (
    clk      : in  std_logic;
    we       : in  std_logic;
    wa       : in  std_logic_vector(4 downto 0);
    wd       : in  std_logic_vector(31 downto 0);
    ra1, ra2 : in  std_logic_vector(4 downto 0);
    rd1, rd2 : out std_logic_vector(31 downto 0)
  );
end entity rv_rejestry;

architecture rtl of rv_rejestry is
  type rej_t is array (0 to 31) of std_logic_vector(31 downto 0);
  signal r : rej_t := (others => (others => '0'));

  function czytaj(signal r : rej_t; ra, wa : std_logic_vector; we : std_logic; wd : std_logic_vector)
    return std_logic_vector is
  begin
    if ra = "00000" then
      return x"00000000";
    elsif PRZEZ and we = '1' and wa = ra then
      return wd;
    else
      return r(to_integer(unsigned(ra)));
    end if;
  end function;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' and wa /= "00000" then
        r(to_integer(unsigned(wa))) <= wd;
      end if;
    end if;
  end process;

  rd1 <= czytaj(r, ra1, wa, we, wd);
  rd2 <= czytaj(r, ra2, wa, we, wd);
end architecture rtl;

-- Wyrównanie granicy słowa (22.03): bitslip, dopóki odebrane słowo różni się od WZOR, potem ILE zgodnych
-- słów z rzędu - wyrownane = '1'.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wyrownaj is
  generic (
    N    : positive := 8;
    WZOR : std_logic_vector := x"6B";
    ILE  : positive := 8
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    slowo     : in  std_logic_vector(N - 1 downto 0);
    wazne     : in  std_logic;
    bitslip   : out std_logic := '0';
    wyrownane : out std_logic;
    poslizgi  : out std_logic_vector(7 downto 0)
  );
end entity wyrownaj;

architecture rtl of wyrownaj is
  signal czekaj : natural range 0 to 2 := 0;
  signal zgodne : natural range 0 to ILE := 0;
  signal wyr    : std_logic := '0';
  signal pos    : unsigned(7 downto 0) := (others => '0');
begin
  wyrownane <= wyr;
  poslizgi  <= std_logic_vector(pos);

  process (clk)
  begin
    if rising_edge(clk) then
      bitslip <= '0';
      if rst = '1' then
        czekaj <= 0;
        zgodne <= 0;
        wyr    <= '0';
        pos    <= (others => '0');
      elsif wazne = '1' and wyr = '0' then
        if czekaj /= 0 then
          czekaj <= czekaj - 1;
        elsif slowo = WZOR then
          zgodne <= zgodne + 1;
          if zgodne = ILE - 1 then wyr <= '1'; end if;
        else
          zgodne  <= 0;
          bitslip <= '1';
          pos     <= pos + 1;
          czekaj  <= 2;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

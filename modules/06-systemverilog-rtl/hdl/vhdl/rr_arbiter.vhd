-- Arbiter karuzelowy dla 4 zgłoszeń: pierwszeństwo ma pierwsze zgłoszenie po ostatnio obsłużonym.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rr_arbiter is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    req         : in  std_logic_vector(3 downto 0);
    grant       : out std_logic_vector(3 downto 0);
    grant_idx   : out std_logic_vector(1 downto 0);
    grant_valid : out std_logic
  );
end entity rr_arbiter;

architecture rtl of rr_arbiter is
  signal last : natural range 0 to 3 := 3;
  signal g    : std_logic_vector(3 downto 0);
  signal gi   : natural range 0 to 3;
begin
  process (all)
    variable idx   : natural range 0 to 3;
    variable found : boolean;
  begin
    g     <= (others => '0');
    gi    <= 0;
    found := false;
    for k in 1 to 4 loop
      idx := (last + k) mod 4;
      if req(idx) = '1' and not found then
        g(idx) <= '1';
        gi     <= idx;
        found  := true;
      end if;
    end loop;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last <= 3;
      elsif g /= "0000" then
        last <= gi;
      end if;
    end if;
  end process;

  grant       <= g;
  grant_idx   <= std_logic_vector(to_unsigned(gi, 2));
  grant_valid <= or g;
end architecture rtl;

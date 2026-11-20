-- Mnożenie liczb stałoprzecinkowych ze znakiem w formacie Q (19.01): a (WA, FA) × b (WB, FB) -> p (WO, FO)
-- z zaokrągleniem i nasyceniem przez q_zmien. Pełny iloczyn ma WA+WB bitów i FA+FB ułamkowych.
-- Potok: rejestr iloczynu, rejestr wyniku (2 takty).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity q_mnoz is
  generic (
    WA    : positive := 16;
    FA    : natural  := 15;
    WB    : positive := 16;
    FB    : natural  := 15;
    WO    : positive := 16;
    FO    : natural  := 15;
    ZAOKR : natural  := 2;
    NASYC : boolean  := true
  );
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(WA - 1 downto 0);
    b         : in  std_logic_vector(WB - 1 downto 0);
    out_valid : out std_logic := '0';
    p         : out std_logic_vector(WO - 1 downto 0);
    przepel   : out std_logic
  );
end entity q_mnoz;

architecture rtl of q_mnoz is
  signal iloczyn   : signed(WA + WB - 1 downto 0);
  signal v1        : std_logic := '0';
  signal p_q       : std_logic_vector(WO - 1 downto 0);
  signal przepel_q : std_logic;
begin
  u_q : entity work.q_zmien
    generic map (WI => WA + WB, FI => FA + FB, WO => WO, FO => FO, ZAOKR => ZAOKR, NASYC => NASYC)
    port map (din => std_logic_vector(iloczyn), dout => p_q, przepel => przepel_q);

  process (clk)
  begin
    if rising_edge(clk) then
      iloczyn   <= signed(a) * signed(b);                     -- pełny iloczyn ze znakiem
      v1        <= in_valid;
      p         <= p_q;
      przepel   <= przepel_q;
      out_valid <= v1;
    end if;
  end process;
end architecture rtl;

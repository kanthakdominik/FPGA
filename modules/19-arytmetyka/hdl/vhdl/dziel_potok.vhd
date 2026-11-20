-- Dzielenie bez znaku w pełnym potoku (19.03): W stopni, każdy liczy jeden bit ilorazu;
-- opóźnienie W taktów, nowy wynik w każdym takcie. Przez zero: iloraz = jedynki, reszta = dzielna.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dziel_potok is
  generic (W : positive := 16);
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    dzielna   : in  std_logic_vector(W - 1 downto 0);
    dzielnik  : in  std_logic_vector(W - 1 downto 0);
    out_valid : out std_logic;
    iloraz    : out std_logic_vector(W - 1 downto 0);
    reszta    : out std_logic_vector(W - 1 downto 0)
  );
end entity dziel_potok;

architecture rtl of dziel_potok is
  type slowa_t is array (0 to W) of unsigned(W - 1 downto 0);
  signal q, r, d : slowa_t;
  signal v       : std_logic_vector(0 to W) := (others => '0');
begin
  q(0) <= unsigned(dzielna);
  r(0) <= (others => '0');
  d(0) <= unsigned(dzielnik);
  v(0) <= in_valid;

  g_st : for k in 0 to W - 1 generate
    signal r_przes, roznica : unsigned(W downto 0);
    signal bit_q            : std_logic;
  begin
    r_przes <= r(k) & q(k)(W - 1);
    roznica <= r_przes - ('0' & d(k));
    bit_q   <= not roznica(W);
    process (clk)
    begin
      if rising_edge(clk) then
        q(k + 1) <= q(k)(W - 2 downto 0) & bit_q;
        r(k + 1) <= roznica(W - 1 downto 0) when bit_q = '1' else r_przes(W - 1 downto 0);
        d(k + 1) <= d(k);
        v(k + 1) <= v(k);
      end if;
    end process;
  end generate;

  iloraz    <= std_logic_vector(q(W));
  reszta    <= std_logic_vector(r(W));
  out_valid <= v(W);
end architecture rtl;

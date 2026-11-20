-- Dzielenie iteracyjne z odtwarzaniem reszty (19.03): jeden bit ilorazu na takt, wynik po W+2 taktach.
-- ZNAK = true: dzielenie modułów i poprawka znaków — iloraz zaokrąglony do zera, reszta ze znakiem
-- dzielnej. Dzielenie przez zero: iloraz = same jedynki, reszta = dzielna, dziel_zero = '1' (jak RISC-V).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dziel_iter is
  generic (
    W    : positive := 16;
    ZNAK : boolean  := false
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    dzielna    : in  std_logic_vector(W - 1 downto 0);
    dzielnik   : in  std_logic_vector(W - 1 downto 0);
    busy       : out std_logic := '0';
    done       : out std_logic := '0';
    iloraz     : out std_logic_vector(W - 1 downto 0);
    reszta     : out std_logic_vector(W - 1 downto 0);
    dziel_zero : out std_logic
  );
end entity dziel_iter;

architecture rtl of dziel_iter is
  signal q, r, d          : unsigned(W - 1 downto 0);
  signal dzielna_r        : std_logic_vector(W - 1 downto 0);
  signal licz             : natural range 0 to W;
  signal zajety           : std_logic := '0';
  signal zn_q, zn_r, zero : std_logic;
  signal r_przes, roznica : unsigned(W downto 0);
  signal bit_q            : std_logic;
begin
  -- krok: reszta przesunięta o bit dzielnej, odejmowanie próbne na W+1 bitach
  r_przes <= r & q(W - 1);
  roznica <= r_przes - ('0' & d);
  bit_q   <= not roznica(W);                                   -- brak pożyczki: reszta >= dzielnik
  busy    <= zajety;

  process (clk)
    variable ujemna_a, ujemny_b : boolean;
    variable mod_a, mod_b       : unsigned(W - 1 downto 0);
  begin
    if rising_edge(clk) then
      done <= '0';
      if rst = '1' then
        zajety <= '0';
      elsif zajety = '0' then
        if start = '1' then
          ujemna_a := ZNAK and dzielna(W - 1) = '1';
          ujemny_b := ZNAK and dzielnik(W - 1) = '1';
          mod_a    := unsigned(dzielna);
          mod_b    := unsigned(dzielnik);
          if ujemna_a then mod_a := unsigned(-signed(dzielna)); end if;
          if ujemny_b then mod_b := unsigned(-signed(dzielnik)); end if;
          q         <= mod_a;
          r         <= (others => '0');
          d         <= mod_b;
          dzielna_r <= dzielna;
          zn_q      <= '1' when ujemna_a xor ujemny_b else '0';
          zn_r      <= '1' when ujemna_a else '0';
          zero      <= '1' when unsigned(dzielnik) = 0 else '0';
          licz      <= W;
          zajety    <= '1';
        end if;
      elsif licz /= 0 then
        q    <= q(W - 2 downto 0) & bit_q;
        r    <= roznica(W - 1 downto 0) when bit_q = '1' else r_przes(W - 1 downto 0);
        licz <= licz - 1;
      else
        zajety     <= '0';
        done       <= '1';
        dziel_zero <= zero;
        if zero = '1' then
          iloraz <= (others => '1');
          reszta <= dzielna_r;
        else
          iloraz <= std_logic_vector(-signed(q)) when zn_q = '1' else std_logic_vector(q);
          reszta <= std_logic_vector(-signed(r)) when zn_r = '1' else std_logic_vector(r);
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

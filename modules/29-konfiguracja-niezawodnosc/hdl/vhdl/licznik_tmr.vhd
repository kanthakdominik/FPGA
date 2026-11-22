-- Licznik w potrójnej redundancji (TMR, 29.04): trzy kopie, wynik z głosowania 2 z 3. SPRZEZENIE = 1 — kopie
-- liczą od wyniku głosowania (resynchronizacja), 0 — niezależnie. wstrzyk(k) — odwrócenie bitu wstrzyk_bit
-- w kopii k (port testowy wstrzykiwania błędów).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity licznik_tmr is
  generic (W : positive := 16; SPRZEZENIE : natural range 0 to 1 := 1);
  port (
    clk, rst, en : in  std_logic;
    wstrzyk      : in  std_logic_vector(2 downto 0);
    wstrzyk_bit  : in  std_logic_vector(3 downto 0);
    q            : out std_logic_vector(W - 1 downto 0);
    niezgodny    : out std_logic
  );
end entity licznik_tmr;

architecture rtl of licznik_tmr is
  type kopie_t is array (0 to 2) of unsigned(W - 1 downto 0);
  signal k     : kopie_t := (others => (others => '0'));
  signal g     : std_logic_vector(W - 1 downto 0);
  signal maska : unsigned(W - 1 downto 0);
begin
  u_glos : entity work.tmr_glos generic map (W => W)
    port map (a => std_logic_vector(k(0)), b => std_logic_vector(k(1)), c => std_logic_vector(k(2)),
              y => g, niezgodny => niezgodny);
  maska <= shift_left(to_unsigned(1, W), to_integer(unsigned(wstrzyk_bit)));

  process (clk)
    variable n : unsigned(W - 1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        k <= (others => (others => '0'));
      else
        for i in 0 to 2 loop
          if SPRZEZENIE = 1 then n := unsigned(g); else n := k(i); end if;
          if en = '1' then n := n + 1; end if;
          if wstrzyk(i) = '1' then n := n xor maska; end if;
          k(i) <= n;
        end loop;
      end if;
    end if;
  end process;
  q <= g;
end architecture rtl;

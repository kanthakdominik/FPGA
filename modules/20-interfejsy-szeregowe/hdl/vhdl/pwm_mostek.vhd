-- PWM centrowany z wyjściami komplementarnymi i czasem martwym (20.04): licznik 0 … OKRES−1, OKRES−1 … 0
-- (wartości skrajne po dwa takty), odniesienie = licznik < wyp (wypełnienie wyp/OKRES), wypełnienie pobierane
-- na końcu okresu, każde wyjście włącza się MARTWY taktów po wyłączeniu drugiego.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_mostek is
  generic (
    W      : positive := 10;
    OKRES  : positive := 1000;
    MARTWY : positive := 20
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    wyp      : in  std_logic_vector(W - 1 downto 0);
    gora     : out std_logic := '0';
    dol      : out std_logic := '0';
    poczatek : out std_logic := '0'
  );
end entity pwm_mostek;

architecture rtl of pwm_mostek is
  signal licz   : natural range 0 to OKRES - 1 := 0;
  signal w_gore : boolean := true;
  signal wyp_b  : natural range 0 to OKRES := 0;
  signal ref_s  : std_logic;
  signal ref_d  : std_logic := '0';
  signal t      : natural range 0 to MARTWY := 0;
begin
  ref_s <= '1' when licz < wyp_b else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      poczatek <= '0';
      if rst = '1' then
        licz   <= 0;
        w_gore <= true;
        gora   <= '0';
        dol    <= '0';
        t      <= MARTWY;
      else
        if w_gore then
          if licz = OKRES - 1 then w_gore <= false; else licz <= licz + 1; end if;
        else
          if licz = 0 then w_gore <= true; else licz <= licz - 1; end if;
        end if;
        if licz = 0 and not w_gore then                         -- koniec okresu
          wyp_b    <= minimum(to_integer(unsigned(wyp)), OKRES);
          poczatek <= '1';
        end if;
        ref_d <= ref_s;
        if ref_s /= ref_d then                                  -- zmiana: oba wyłączone przez MARTWY taktów
          gora <= '0';
          dol  <= '0';
          t    <= MARTWY - 1;
        elsif t /= 0 then
          t <= t - 1;
        else
          gora <= ref_s;
          dol  <= not ref_s;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

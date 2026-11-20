-- Aproksymacja funkcji interpolacją liniową z tablic (19.06): x = [k (S bitów) | frac (F-S bitów)],
-- y = baza[k] + nachyl[k]·frac / 2^(F-S), zaokrąglenie i nasycenie do 2^WY - 1.
-- Tablice z plików .hex (gen_aproks.py) wczytywane przez textio — w symulacji i w syntezie narzędzi,
-- które czytają pliki (dla Quartusa: atrybut ram_init_file z plikiem .mif, jak w 18.02).
-- Potok 3 takty: odczyt tablic, mnożenie, dodawanie z nasyceniem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity interp_lin is
  generic (
    F      : positive := 16;
    S      : positive := 6;
    WY     : positive := 16;
    WN     : positive := 11;
    PLIK_B : string   := "interp_baza.hex";
    PLIK_N : string   := "interp_nachyl.hex"
  );
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    x         : in  std_logic_vector(F - 1 downto 0);
    out_valid : out std_logic := '0';
    y         : out std_logic_vector(WY - 1 downto 0)
  );
end entity interp_lin;

architecture rtl of interp_lin is
  constant FR : positive := F - S;
  type tab_t is array (0 to 2 ** S - 1) of unsigned(15 downto 0);

  impure function wczytaj(nazwa : string) return tab_t is
    file plik  : text;
    variable st : file_open_status;
    variable l : line;
    variable v : std_logic_vector(15 downto 0);
    variable t : tab_t := (others => (others => '0'));
    variable ok : boolean;
  begin
    file_open(st, plik, nazwa, read_mode);
    assert st = open_ok report "interp_lin: nie mozna otworzyc " & nazwa severity failure;
    for i in tab_t'range loop
      exit when endfile(plik);
      readline(plik, l);
      -- wiersze mają 3 albo 4 cyfry szesnastkowe: dopełnienie zerami z lewej
      if l'length = 3 then
        hread(l, v(11 downto 0), ok);
        v(15 downto 12) := (others => '0');
      else
        hread(l, v, ok);
      end if;
      t(i) := unsigned(v);
    end loop;
    file_close(plik);
    return t;
  end function;

  constant BAZA   : tab_t := wczytaj(PLIK_B);
  constant NACHYL : tab_t := wczytaj(PLIK_N);

  signal b1, b2 : unsigned(WY - 1 downto 0);
  signal n1     : unsigned(WN - 1 downto 0);
  signal f1     : unsigned(FR - 1 downto 0);
  signal il2    : unsigned(WN + FR - 1 downto 0);
  signal v1, v2 : std_logic := '0';
begin
  process (clk)
    variable k     : natural;
    variable przyr : unsigned(WN + FR - 1 downto 0);
    variable suma  : unsigned(WY downto 0);
  begin
    if rising_edge(clk) then
      -- 1: odczyt tablic
      k  := to_integer(unsigned(x(F - 1 downto FR)));
      b1 <= BAZA(k)(WY - 1 downto 0);
      n1 <= NACHYL(k)(WN - 1 downto 0);
      f1 <= unsigned(x(FR - 1 downto 0));
      v1 <= in_valid;
      -- 2: mnożenie
      il2 <= n1 * f1;
      b2  <= b1;
      v2  <= v1;
      -- 3: dodawanie z zaokrągleniem i nasyceniem
      przyr := il2 + shift_left(to_unsigned(1, WN + FR), FR - 1);
      suma  := ('0' & b2) + resize(shift_right(przyr, FR), WY + 1);
      if suma(WY) = '1' then
        y <= (others => '1');
      else
        y <= std_logic_vector(suma(WY - 1 downto 0));
      end if;
      out_valid <= v2;
    end if;
  end process;
end architecture rtl;

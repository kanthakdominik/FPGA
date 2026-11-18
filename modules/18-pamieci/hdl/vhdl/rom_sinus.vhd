-- ROM z zawartością z pliku (18.02). Dwie drogi inicjalizacji, bo narzędzia różnią się tu najbardziej:
--   * funkcja czytająca plik szesnastkowy przez textio (GHDL, symulatory, Vivado) - generic PLIK;
--     pusty PLIK = brak wczytywania (tak ustawia go projekt dla Quartusa),
--   * atrybut ram_init_file z plikiem .mif - Quartus nie wykonuje textio w syntezie, czyta za to .mif
--     (generic PLIK_MIF).
-- Pliki sinus.hex i sinus.mif generuje hdl/dane/gen_sinus.py. Odczyt synchroniczny -> blok pamięci.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity rom_sinus is
  generic (
    W        : positive := 8;
    AW       : positive := 8;
    PLIK     : string   := "sinus.hex";
    PLIK_MIF : string   := "sinus.mif"
  );
  port (
    clk  : in  std_logic;
    en   : in  std_logic;
    addr : in  std_logic_vector(AW - 1 downto 0);
    dout : out std_logic_vector(W - 1 downto 0)
  );
end entity rom_sinus;

architecture rtl of rom_sinus is
  type rom_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);

  impure function wczytaj(nazwa : string) return rom_t is
    file f       : text;
    variable st  : file_open_status;
    variable l   : line;
    variable v   : std_logic_vector(((W + 3) / 4) * 4 - 1 downto 0);
    variable r   : rom_t := (others => (others => '0'));
  begin
    if nazwa'length = 0 then
      return r;
    end if;
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "rom_sinus: nie mozna otworzyc " & nazwa severity failure;
    for i in rom_t'range loop
      exit when endfile(f);
      readline(f, l);
      hread(l, v);
      r(i) := v(W - 1 downto 0);
    end loop;
    file_close(f);
    return r;
  end function;

  signal rom : rom_t := wczytaj(PLIK);
  attribute ram_init_file : string;
  attribute ram_init_file of rom : signal is PLIK_MIF;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        dout <= rom(to_integer(unsigned(addr)));
      end if;
    end if;
  end process;
end architecture rtl;

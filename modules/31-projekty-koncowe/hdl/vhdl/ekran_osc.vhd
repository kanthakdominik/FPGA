-- Obraz oscyloskopu (31.02), domena zegara piksela: siatka, ramka, poziom wyzwalania, znacznik wyzwolenia
-- i przebieg (odcinek od poprzedniej do bieżącej próbki w każdej kolumnie). Zmiana banku na początku ramki po
-- nowym zrzucie, odczyt pamięci z wyprzedzeniem kolumny, wyjście rejestrowane. Jak w wersjach Verilog i SV.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ekran_osc is
  generic (AW : positive := 9; PRZED : positive := 64; X0 : positive := 64; Y0 : positive := 112);
  port (
    clk, rst    : in  std_logic;
    hs_we, vs_we, de_we : in std_logic;
    x, y        : in  unsigned(11 downto 0);
    nowa_ramka  : in  std_logic;
    poziom      : in  std_logic_vector(11 downto 0);
    gotowy_t    : in  std_logic;
    bank_gotowy : in  std_logic;
    poczatek    : in  unsigned(AW - 1 downto 0);
    potw_t      : out std_logic := '0';
    ram_adr     : out unsigned(AW downto 0);
    ram_dane    : in  std_logic_vector(7 downto 0);
    rgb         : out std_logic_vector(23 downto 0) := (others => '0');
    hs, vs      : out std_logic := '1';
    de          : out std_logic := '0';
    nr_zrzutu   : out unsigned(15 downto 0) := (others => '0')
  );
end entity ekran_osc;

architecture rtl of ekran_osc is
  constant N        : positive := 2 ** AW;
  constant C_TLO    : std_logic_vector(23 downto 0) := x"000000";
  constant C_SIATKA : std_logic_vector(23 downto 0) := x"404040";
  constant C_RAMKA  : std_logic_vector(23 downto 0) := x"808080";
  constant C_POZIOM : std_logic_vector(23 downto 0) := x"FF8000";
  constant C_WYZW   : std_logic_vector(23 downto 0) := x"0060FF";
  constant C_SLAD   : std_logic_vector(23 downto 0) := x"00FF00";
  signal s_got   : std_logic_vector(1 downto 0) := "00";
  signal pt      : std_logic := '0';
  signal bank    : std_logic := '0';
  signal start   : unsigned(AW - 1 downto 0) := (others => '0');
  signal poprz   : unsigned(7 downto 0) := (others => '0');
  signal nr      : unsigned(15 downto 0) := (others => '0');
  signal kol_nast : unsigned(11 downto 0);

  attribute altera_attribute : string;
  attribute altera_attribute of s_got : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  potw_t <= pt;
  nr_zrzutu <= nr;
  kol_nast <= x - X0 + 1;
  ram_adr <= bank & (start + kol_nast(AW - 1 downto 0));

  process (clk)
  begin
    if rising_edge(clk) then
      s_got <= s_got(0) & gotowy_t;
      poprz <= unsigned(ram_dane);
      if rst = '1' then
        pt <= '0'; nr <= (others => '0');
      elsif nowa_ramka = '1' and s_got(1) /= pt then
        bank  <= bank_gotowy;
        start <= poczatek;
        pt    <= s_got(1);
        nr    <= nr + 1;
      end if;
    end if;
  end process;

  process (clk)
    variable w_pole, slad, lin_poz, lin_wyzw, siatka, ramka : boolean;
    variable dx, dy : unsigned(11 downto 0);
    variable w_biez, w_poprz, w_min, w_max, w_poz : unsigned(7 downto 0);
  begin
    if rising_edge(clk) then
      hs <= hs_we; vs <= vs_we; de <= de_we;
      w_pole := x >= X0 and x < X0 + N and y >= Y0 and y < Y0 + 256;
      dx := x - X0;
      dy := y - Y0;
      w_biez := 255 - unsigned(ram_dane);
      if dx = 0 then w_poprz := w_biez; else w_poprz := 255 - poprz; end if;
      if w_biez < w_poprz then w_min := w_biez; w_max := w_poprz; else w_min := w_poprz; w_max := w_biez; end if;
      w_poz := 255 - unsigned(poziom(11 downto 4));
      slad := w_pole and dy(7 downto 0) >= w_min and dy(7 downto 0) <= w_max;
      lin_poz := w_pole and dy(7 downto 0) = w_poz;
      lin_wyzw := w_pole and dx = PRZED;
      siatka := w_pole and (dx(5 downto 0) = 0 or dy(4 downto 0) = 0);
      ramka := ((x = X0 - 1 or x = X0 + N) and y >= Y0 - 1 and y <= Y0 + 256) or
               ((y = Y0 - 1 or y = Y0 + 256) and x >= X0 - 1 and x <= X0 + N);
      if de_we = '0' then rgb <= C_TLO;
      elsif slad then rgb <= C_SLAD;
      elsif lin_poz then rgb <= C_POZIOM;
      elsif lin_wyzw then rgb <= C_WYZW;
      elsif ramka then rgb <= C_RAMKA;
      elsif siatka then rgb <= C_SIATKA;
      else rgb <= C_TLO;
      end if;
    end if;
  end process;
end architecture rtl;

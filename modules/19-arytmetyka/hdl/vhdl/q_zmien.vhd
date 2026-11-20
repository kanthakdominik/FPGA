-- Zmiana formatu liczby stałoprzecinkowej ze znakiem (19.01): z Q o WI bitach (FI ułamkowych)
-- na Q o WO bitach (FO ułamkowych). Układ kombinacyjny.
--   ZAOKR: 0 — obcięcie (w dół), 1 — połówka w górę, 2 — zbieżne (połówka do parzystej).
--   NASYC: true — nasycenie, false — zawijanie. przepel = '1', gdy wynik nie mieści się w zakresie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity q_zmien is
  generic (
    WI    : positive := 16;
    FI    : natural  := 8;
    WO    : positive := 8;
    FO    : natural  := 4;
    ZAOKR : natural  := 2;
    NASYC : boolean  := true
  );
  port (
    din     : in  std_logic_vector(WI - 1 downto 0);
    dout    : out std_logic_vector(WO - 1 downto 0);
    przepel : out std_logic
  );
end entity q_zmien;

architecture rtl of q_zmien is
  constant D  : integer  := FI - FO;
  constant DL : natural  := maximum(-D, 0);
  constant WT : positive := WI + DL + 1;
  constant WR : positive := maximum(WT, WO);

  -- najmniejsza wartość wyjścia 100…0; największa to jej negacja bitowa 011…1
  constant MIN_WY : std_logic_vector(WO - 1 downto 0) := std_logic_vector(shift_left(to_unsigned(1, WO), WO - 1));

  signal t      : signed(WT - 1 downto 0);
  signal tr     : signed(WR - 1 downto 0);
  signal prz    : std_logic;
begin
  g_zaokr : if D > 0 generate
    signal podl   : signed(WT - 1 downto 0);
    signal w_gore : std_logic;
  begin
    podl <= shift_right(resize(signed(din), WT), D);           -- podłoga (obcięcie w dół)
    g_obc : if ZAOKR = 0 generate
      w_gore <= '0';
    elsif ZAOKR = 1 generate
      w_gore <= din(D - 1);                                     -- reszta >= 1/2 LSB wyjścia
    elsif D = 1 generate
      w_gore <= din(0) and podl(0);                             -- dokładnie połowa: do parzystej
    else generate
      w_gore <= din(D - 1) and ((or din(D - 2 downto 0)) or podl(0));
    end generate;
    t <= podl + 1 when w_gore = '1' else podl;
  end;
  else generate
    t <= shift_left(resize(signed(din), WT), DL);               -- dokładnie, bez zaokrąglania
  end generate;

  tr <= resize(t, WR);
  -- wynik mieści się w WO bitach, gdy bity od WO-1 w górę są kopiami bitu znaku
  prz <= '0' when tr(WR - 1 downto WO - 1) = 0 or tr(WR - 1 downto WO - 1) = -1 else '1';
  przepel <= prz;

  g_nasyc : if NASYC generate
    dout <= std_logic_vector(tr(WO - 1 downto 0)) when prz = '0' else
            MIN_WY when tr(WR - 1) = '1' else
            not MIN_WY;
  else generate
    dout <= std_logic_vector(tr(WO - 1 downto 0));
  end generate;
end architecture rtl;

-- CORDIC w pełnym potoku (19.04): obroty o kąty atan(2^-i) samymi przesunięciami i dodawaniami.
--   TRYB = 0 — obrót: (x, y) obrócony o z_in (x_in = A/K, y_in = 0 daje A·cos, A·sin),
--   TRYB = 1 — wektorowanie: x_out = K·|(x, y)|, z_out = z_in + atan2(y, x).
-- Kąt binarny A-bitowy ze znakiem (2^A = pełny obrót); wstępny obrót o ±90° daje cały okrąg.
-- Wzmocnienie K ≈ 1,64676 — wyjścia mają W+2 bitów. Opóźnienie N+2 taktów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordic is
  generic (
    W    : positive := 16;
    A    : positive := 24;                -- bity kąta (A <= 30)
    N    : positive := 18;                -- iteracje (N <= A - 2)
    G    : positive := 4;                 -- bity ochronne ułamka (G >= 2)
    TRYB : natural  := 0
  );
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    x_in      : in  std_logic_vector(W - 1 downto 0);
    y_in      : in  std_logic_vector(W - 1 downto 0);
    z_in      : in  std_logic_vector(A - 1 downto 0);
    out_valid : out std_logic := '0';
    x_out     : out std_logic_vector(W + 1 downto 0);
    y_out     : out std_logic_vector(W + 1 downto 0);
    z_out     : out std_logic_vector(A - 1 downto 0)
  );
end entity cordic;

architecture rtl of cordic is
  constant WI : positive := W + 2 + G;
  type atan_t is array (0 to 30) of std_logic_vector(31 downto 0);
  -- atan(2^-i) w jednostkach 2^-32 pełnego obrotu
  constant ATAN32 : atan_t := (
     0 => x"20000000",
     1 => x"12E4051E",
     2 => x"09FB385B",
     3 => x"051111D4",
     4 => x"028B0D43",
     5 => x"0145D7E1",
     6 => x"00A2F61E",
     7 => x"00517C55",
     8 => x"0028BE53",
     9 => x"00145F2F",
    10 => x"000A2F98",
    11 => x"000517CC",
    12 => x"00028BE6",
    13 => x"000145F3",
    14 => x"0000A2FA",
    15 => x"0000517D",
    16 => x"000028BE",
    17 => x"0000145F",
    18 => x"00000A30",
    19 => x"00000518",
    20 => x"0000028C",
    21 => x"00000146",
    22 => x"000000A3",
    23 => x"00000051",
    24 => x"00000029",
    25 => x"00000014",
    26 => x"0000000A",
    27 => x"00000005",
    28 => x"00000003",
    29 => x"00000001",
    30 => x"00000001"
  );

  -- atan(2^-i) zaokrąglone do A bitów
  function atan_a(i : natural) return signed is
    variable t : unsigned(32 downto 0);
  begin
    t := ('0' & unsigned(ATAN32(i))) + shift_left(to_unsigned(1, 33), 31 - A);
    return signed(t(31 downto 32 - A));
  end function;

  type wek_t is array (0 to N) of signed(WI - 1 downto 0);
  type kat_t is array (0 to N) of signed(A - 1 downto 0);
  signal x, y   : wek_t;
  signal z      : kat_t;
  signal v      : std_logic_vector(0 to N) := (others => '0');
  signal x0, y0 : signed(WI - 1 downto 0);
  constant CWIERC : signed(A - 1 downto 0) := shift_left(to_signed(1, A), A - 2);   -- 90°
begin
  x0 <= shift_left(resize(signed(x_in), WI), G);
  y0 <= shift_left(resize(signed(y_in), WI), G);

  -- obrót wstępny o ±90°
  process (clk)
    variable kw : std_logic_vector(1 downto 0);
  begin
    if rising_edge(clk) then
      v(0) <= in_valid;
      x(0) <= x0;
      y(0) <= y0;
      z(0) <= signed(z_in);
      if TRYB = 0 then
        kw := z_in(A - 1 downto A - 2);
        if kw = "01" then                                     -- (90°, 180°): obrót o +90°
          x(0) <= -y0; y(0) <= x0; z(0) <= signed(z_in) - CWIERC;
        elsif kw = "10" then                                  -- [-180°, -90°): o -90°
          x(0) <= y0; y(0) <= -x0; z(0) <= signed(z_in) + CWIERC;
        end if;
      else
        if x_in(W - 1) = '1' and y_in(W - 1) = '0' then
          x(0) <= y0; y(0) <= -x0; z(0) <= signed(z_in) + CWIERC;
        elsif x_in(W - 1) = '1' then
          x(0) <= -y0; y(0) <= x0; z(0) <= signed(z_in) - CWIERC;
        end if;
      end if;
    end if;
  end process;

  g_it : for k in 0 to N - 1 generate
    constant KAT : signed(A - 1 downto 0) := atan_a(k);
    signal d_plus : boolean;
  begin
    -- obrót: zgodnie ze znakiem reszty kąta; wektorowanie: przeciwnie do znaku y
    d_plus <= z(k)(A - 1) = '0' when TRYB = 0 else y(k)(WI - 1) = '1';
    process (clk)
    begin
      if rising_edge(clk) then
        v(k + 1) <= v(k);
        if d_plus then
          x(k + 1) <= x(k) - shift_right(y(k), k);
          y(k + 1) <= y(k) + shift_right(x(k), k);
          z(k + 1) <= z(k) - KAT;
        else
          x(k + 1) <= x(k) + shift_right(y(k), k);
          y(k + 1) <= y(k) - shift_right(x(k), k);
          z(k + 1) <= z(k) + KAT;
        end if;
      end if;
    end process;
  end generate;

  -- zaokrąglenie: połówka w górę, usunięcie G bitów ochronnych
  process (clk)
    variable xz, yz : signed(WI - 1 downto 0);
  begin
    if rising_edge(clk) then
      xz := x(N) + shift_left(to_signed(1, WI), G - 1);
      yz := y(N) + shift_left(to_signed(1, WI), G - 1);
      out_valid <= v(N);
      x_out     <= std_logic_vector(xz(WI - 1 downto G));
      y_out     <= std_logic_vector(yz(WI - 1 downto G));
      z_out     <= std_logic_vector(z(N));
    end if;
  end process;
end architecture rtl;

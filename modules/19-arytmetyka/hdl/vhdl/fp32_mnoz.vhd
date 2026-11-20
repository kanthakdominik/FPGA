-- Mnożenie liczb zmiennoprzecinkowych IEEE 754 binary32 (19.05), potok 2 takty: zaokrąglenie do
-- najbliższej (połówka do parzystej), liczby zdenormalizowane jak zero (DAZ/FTZ, flaga niedomiar),
-- nadmiar do nieskończoności (flaga nadmiar), NaN i 0 × nieskończoność -> kanoniczny NaN 0x7FC00000.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp32_mnoz is
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(31 downto 0);
    b         : in  std_logic_vector(31 downto 0);
    out_valid : out std_logic := '0';
    p         : out std_logic_vector(31 downto 0);
    nadmiar   : out std_logic;
    niedomiar : out std_logic
  );
end entity fp32_mnoz;

architecture rtl of fp32_mnoz is
  signal s1, nan1, inf1, zero1 : std_logic;
  signal v1                    : std_logic := '0';
  signal m1                    : unsigned(47 downto 0);
  signal e1                    : signed(9 downto 0);       -- wykładnik ze znakiem, z obciążeniem 127
begin
  -- stopień 1: rozpakowanie, mnożenie mantys, suma wykładników
  process (clk)
    variable ea, eb                         : unsigned(7 downto 0);
    variable fa, fb                         : unsigned(22 downto 0);
    variable zero_a, zero_b, inf_a, inf_b, nan_a, nan_b : boolean;
  begin
    if rising_edge(clk) then
      ea := unsigned(a(30 downto 23));  fa := unsigned(a(22 downto 0));
      eb := unsigned(b(30 downto 23));  fb := unsigned(b(22 downto 0));
      zero_a := ea = 0;                 zero_b := eb = 0;
      inf_a  := ea = 255 and fa = 0;    inf_b  := eb = 255 and fb = 0;
      nan_a  := ea = 255 and fa /= 0;   nan_b  := eb = 255 and fb /= 0;
      v1    <= in_valid;
      s1    <= a(31) xor b(31);
      nan1  <= '1' when nan_a or nan_b or (inf_a and zero_b) or (zero_a and inf_b) else '0';
      inf1  <= '1' when inf_a or inf_b else '0';
      zero1 <= '1' when zero_a or zero_b else '0';
      m1    <= ('1' & fa) * ('1' & fb);                       -- jedynka ukryta
      e1    <= signed(resize(ea, 10)) + signed(resize(eb, 10)) - 127;
    end if;
  end process;

  -- stopień 2: normalizacja, zaokrąglenie, zakres, spakowanie
  process (clk)
    variable gora, g, st, w_gore : std_logic;
    variable mant                : unsigned(23 downto 0);
    variable mr                  : unsigned(24 downto 0);
    variable mant2               : unsigned(23 downto 0);
    variable e2                  : signed(9 downto 0);
  begin
    if rising_edge(clk) then
      gora := m1(47);                                         -- iloczyn w [2, 4)
      if gora = '1' then
        mant := m1(47 downto 24); g := m1(23); st := or m1(22 downto 0);
      else
        mant := m1(46 downto 23); g := m1(22); st := or m1(21 downto 0);
      end if;
      w_gore := g and (st or mant(0));                         -- połówka do parzystej
      mr     := ('0' & mant) + w_gore;
      if mr(24) = '1' then mant2 := mr(24 downto 1); else mant2 := mr(23 downto 0); end if;
      e2 := e1;
      if gora = '1' then e2 := e2 + 1; end if;
      if mr(24) = '1' then e2 := e2 + 1; end if;

      out_valid <= v1;
      nadmiar   <= '0';
      niedomiar <= '0';
      if nan1 = '1' then
        p <= x"7FC00000";
      elsif inf1 = '1' then
        p <= s1 & x"FF" & 23x"0";
      elsif zero1 = '1' then
        p <= s1 & 31x"0";
      elsif e2 >= 255 then
        p       <= s1 & x"FF" & 23x"0";
        nadmiar <= '1';
      elsif e2 <= 0 then
        p         <= s1 & 31x"0";
        niedomiar <= '1';
      else
        p <= s1 & std_logic_vector(e2(7 downto 0)) & std_logic_vector(mant2(22 downto 0));
      end if;
    end if;
  end process;
end architecture rtl;

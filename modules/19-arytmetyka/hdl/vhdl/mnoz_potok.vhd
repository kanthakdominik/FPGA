-- Mnożarka z potokiem o LAT stopniach (19.02), operandy ze znakiem (ZNAK = true) albo bez.
-- LAT >= 1 — rejestr wyjściowy, LAT >= 2 — także rejestry wejściowe (oba są w bloku mnożarki),
-- LAT >= 3 — dodatkowe rejestry za mnożarką. Operandy rozszerzone o bit (znakiem albo zerem)
-- i mnożone ze znakiem — jeden kod dla obu rodzajów liczb.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mnoz_potok is
  generic (
    WA   : positive := 18;
    WB   : positive := 18;
    ZNAK : boolean  := true;
    LAT  : natural  := 2
  );
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(WA - 1 downto 0);
    b         : in  std_logic_vector(WB - 1 downto 0);
    out_valid : out std_logic;
    p         : out std_logic_vector(WA + WB - 1 downto 0)
  );
end entity mnoz_potok;

architecture rtl of mnoz_potok is
  constant NW : natural := LAT - minimum(LAT / 2, 1);           -- rejestry za mnożarką (LAT >= 2: LAT - 1)
  type pot_t is array (natural range <>) of std_logic_vector(WA + WB - 1 downto 0);
  signal a_m       : std_logic_vector(WA - 1 downto 0);
  signal b_m       : std_logic_vector(WB - 1 downto 0);
  signal v_m       : std_logic;
  signal a_x       : signed(WA downto 0);
  signal b_x       : signed(WB downto 0);
  signal pelny     : signed(WA + WB + 1 downto 0);
  signal iloczyn   : std_logic_vector(WA + WB - 1 downto 0);
begin
  g_wej : if LAT >= 2 generate
    process (clk)
    begin
      if rising_edge(clk) then
        a_m <= a;
        b_m <= b;
        v_m <= in_valid;
      end if;
    end process;
  else generate
    a_m <= a;
    b_m <= b;
    v_m <= in_valid;
  end generate;

  a_x     <= signed(a_m(WA - 1) & a_m) when ZNAK else signed('0' & a_m);
  b_x     <= signed(b_m(WB - 1) & b_m) when ZNAK else signed('0' & b_m);
  pelny   <= a_x * b_x;                                         -- iloczyn mieści się w WA+WB bitach
  iloczyn <= std_logic_vector(pelny(WA + WB - 1 downto 0));

  g_wyj : if NW = 0 generate
    p         <= iloczyn;
    out_valid <= v_m;
  else generate
    signal rp : pot_t(0 to NW - 1);
    signal rv : std_logic_vector(NW - 1 downto 0) := (others => '0');
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        rp(0) <= iloczyn;
        rv(0) <= v_m;
        for k in 1 to NW - 1 loop
          rp(k) <= rp(k - 1);
          rv(k) <= rv(k - 1);
        end loop;
      end if;
    end process;
    p         <= rp(NW - 1);
    out_valid <= rv(NW - 1);
  end generate;
end architecture rtl;

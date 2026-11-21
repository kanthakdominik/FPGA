-- Testbench 25.03: mdio z modelem PHY (adres 1; rejestry 0–3). Model sprawdza preambułę, ST, kod operacji i adres;
-- przy odczycie wystawia TA = 0 i dane 100 ns po narastającym MDC poprzedniego bitu. Odczyt 2, 3, 1, zapis 0x3100
-- do 0 i odczyt zwrotny, odczyt spod nieistniejącego adresu PHY (0xFFFF).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_mdio is
end entity tb_mdio;

architecture sim of tb_mdio is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal start, zapis : std_logic := '0';
  signal phy, rej : std_logic_vector(4 downto 0) := (others => '0');
  signal wdane, rdane : std_logic_vector(15 downto 0) := (others => '0');
  signal gotowe, zajety, mdc, mdio_o, mdio_oe : std_logic;
  signal p_o : std_logic := '1';
  signal p_oe : std_logic := '0';
  signal linia : std_logic;
  signal bl_ramki : natural := 0;
  signal min_okres : time := 1 sec;
begin
  clk <= not clk after 10 ns when not fin else clk;
  linia <= mdio_o when mdio_oe = '1' else p_o when p_oe = '1' else '1';

  dut : entity work.mdio
    generic map (DIV => 10)
    port map (clk => clk, rst => rst, start => start, zapis => zapis, phy => phy, rej => rej, wdane => wdane,
              rdane => rdane, gotowe => gotowe, zajety => zajety, mdc => mdc, mdio_o => mdio_o, mdio_oe => mdio_oe,
              mdio_i => linia);

  process
    type reg_t is array (0 to 31) of std_logic_vector(15 downto 0);
    variable r : reg_t := (1 => x"7849", 2 => x"2000", 3 => x"5CE1", others => x"0000");
    variable nb, jedynki : natural := 0;
    variable nagl : std_logic_vector(13 downto 0) := (others => '0');
    variable d : std_logic_vector(15 downto 0) := (others => '0');
    variable czyt, nasz : boolean := false;
    variable t_pop : time := 0 ns;
  begin
    wait until rising_edge(mdc);
    if t_pop > 0 ns and now - t_pop < min_okres then min_okres <= now - t_pop; end if;
    t_pop := now;
    if nb = 0 then
      if linia = '1' then jedynki := jedynki + 1;
      elsif jedynki >= 32 then nb := 1; nagl := (others => '0');
      else jedynki := 0;
      end if;
    else
      nb := nb + 1;
      if nb <= 14 then nagl := nagl(12 downto 0) & linia; end if;
      if nb = 14 then
        if nagl(13 downto 12) /= "01" then bl_ramki <= bl_ramki + 1; end if;
        czyt := nagl(11 downto 10) = "10";
        nasz := nagl(9 downto 5) = "00001";
      end if;
      if nb = 15 and czyt and nasz then
        d := r(to_integer(unsigned(nagl(4 downto 0))));
        p_oe <= '1' after 100 ns; p_o <= '0' after 100 ns;
      end if;
      if nb >= 16 and nb <= 31 and czyt and nasz then p_o <= d(31 - nb) after 100 ns; end if;
      if nb >= 17 and nb <= 32 and not czyt then d := d(14 downto 0) & linia; end if;
      if nb = 32 then
        if not czyt and nasz then r(to_integer(unsigned(nagl(4 downto 0)))) := d; end if;
        p_oe <= '0' after 100 ns;
        nb := 0; jedynki := 0;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable errors : natural := 0;
    procedure op(z : std_logic; p, rr : natural; w : std_logic_vector(15 downto 0)) is
    begin
      wait until falling_edge(clk);
      start <= '1'; zapis <= z; phy <= std_logic_vector(to_unsigned(p, 5)); rej <= std_logic_vector(to_unsigned(rr, 5));
      wdane <= w;
      wait until falling_edge(clk);
      start <= '0';
      wait until gotowe = '1';
      wait for 1 ns;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    op('0', 1, 2, x"0000");
    write(l, "odczyt rejestru 2: " & to_hstring(rdane)); writeline(output, l);
    if rdane /= x"2000" then errors := errors + 1; end if;
    op('0', 1, 3, x"0000");
    write(l, "odczyt rejestru 3: " & to_hstring(rdane)); writeline(output, l);
    if rdane /= x"5CE1" then errors := errors + 1; end if;
    op('0', 1, 1, x"0000");
    write(l, "odczyt rejestru 1: " & to_hstring(rdane)); writeline(output, l);
    if rdane /= x"7849" then errors := errors + 1; end if;
    op('1', 1, 0, x"3100");
    op('0', 1, 0, x"0000");
    write(l, "zapis 3100 do rejestru 0, odczyt: " & to_hstring(rdane)); writeline(output, l);
    if rdane /= x"3100" then errors := errors + 1; end if;
    op('0', 7, 2, x"0000");
    write(l, "odczyt pod adresem PHY 7 (brak): " & to_hstring(rdane)); writeline(output, l);
    if rdane /= x"FFFF" then errors := errors + 1; end if;
    write(l, "MDC: okres min " & integer'image(min_okres / 1 ns) & " ns, bledne naglowki " & integer'image(bl_ramki));
    writeline(output, l);
    if bl_ramki /= 0 or min_okres < 400 ns then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

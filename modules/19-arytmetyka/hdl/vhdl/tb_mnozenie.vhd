-- Testbench mnożarek z 19.02 na wspólnym strumieniu danych (in_valid losowe):
--   mnoz_potok 18 × 18 ze znakiem dla LAT = 0…4, bez znaku (LAT = 2), 25 × 18 (LAT = 3),
--   mnoz_szeroki 34 × 34, mnoz_zesp z czterema i z trzema mnożeniami.
-- Wzorzec z historii wejść (numeric_std), sprawdzane też opóźnienie i liczba wyników.
-- Pierwsze 48 próbek: wartości skrajne (najmniejsza, największa, -1, 0) dla 18, 34 i 16 bitów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mnozenie is
end entity tb_mnozenie;

architecture sim of tb_mnozenie is
  constant N : positive := 3000;
  type h34_t is array (0 to N - 1) of std_logic_vector(33 downto 0);
  type h16_t is array (0 to N - 1) of std_logic_vector(15 downto 0);
  type int_t is array (0 to N - 1) of integer;
  type licz_t is array (0 to 9) of integer;
  type p36_t is array (0 to 4) of std_logic_vector(35 downto 0);

  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal in_valid : std_logic := '0';
  signal a, b     : std_logic_vector(33 downto 0) := (others => '0');
  signal ci, di   : std_logic_vector(15 downto 0) := (others => '0');
  signal ha, hb   : h34_t;
  signal hc, hd   : h16_t;
  signal t_wej    : int_t;
  signal takt     : integer := 0;
  signal nwyn     : licz_t := (others => 0);       -- liczba wyników każdej instancji
  signal nbl      : licz_t := (others => 0);       -- liczba błędów każdej instancji

  signal p_s      : p36_t;
  signal v_s      : std_logic_vector(0 to 4);
  signal p_u      : std_logic_vector(35 downto 0);
  signal p_25     : std_logic_vector(42 downto 0);
  signal p_w      : std_logic_vector(67 downto 0);
  signal pr4, pi4, pr3, pi3 : std_logic_vector(32 downto 0);
  signal v_u, v_25, v_w, v4, v3 : std_logic;

  function skrajna(k : natural; w : positive) return std_logic_vector is
    variable jed : unsigned(33 downto 0) := (others => '1');
  begin
    case k is
      when 0      => return std_logic_vector(shift_left(jed, w - 1));
      when 1      => return std_logic_vector(not shift_left(jed, w - 1));
      when 2      => return std_logic_vector(jed);
      when others => return (33 downto 0 => '0');
    end case;
  end function;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);

  g_lat : for g in 0 to 4 generate
    u : entity work.mnoz_potok generic map (WA => 18, WB => 18, ZNAK => true, LAT => g)
      port map (clk, in_valid, a(17 downto 0), b(17 downto 0), v_s(g), p_s(g));
    process (clk)
    begin
      if rising_edge(clk) and v_s(g) = '1' then
        if signed(p_s(g)) /= signed(ha(nwyn(g))(17 downto 0)) * signed(hb(nwyn(g))(17 downto 0))
           or takt - t_wej(nwyn(g)) /= g then
          nbl(g) <= nbl(g) + 1;
        end if;
        nwyn(g) <= nwyn(g) + 1;
      end if;
    end process;
  end generate;

  u_bz : entity work.mnoz_potok generic map (WA => 18, WB => 18, ZNAK => false, LAT => 2)
    port map (clk, in_valid, a(17 downto 0), b(17 downto 0), v_u, p_u);
  u_25 : entity work.mnoz_potok generic map (WA => 25, WB => 18, ZNAK => true, LAT => 3)
    port map (clk, in_valid, a(24 downto 0), b(17 downto 0), v_25, p_25);
  u_w  : entity work.mnoz_szeroki generic map (H => 17) port map (clk, in_valid, a, b, v_w, p_w);
  u_z4 : entity work.mnoz_zesp generic map (W => 16, TRZY => false)
    port map (clk, in_valid, a(15 downto 0), ci, b(15 downto 0), di, v4, pr4, pi4);
  u_z3 : entity work.mnoz_zesp generic map (W => 16, TRZY => true)
    port map (clk, in_valid, a(15 downto 0), ci, b(15 downto 0), di, v3, pr3, pi3);

  process (clk)
    variable nr : integer;
    variable er, ei : signed(32 downto 0);
  begin
    if rising_edge(clk) then
      if v_u = '1' then
        nr := nwyn(5);
        if unsigned(p_u) /= unsigned(ha(nr)(17 downto 0)) * unsigned(hb(nr)(17 downto 0)) then
          nbl(5) <= nbl(5) + 1;
        end if;
        nwyn(5) <= nr + 1;
      end if;
      if v_25 = '1' then
        nr := nwyn(6);
        if signed(p_25) /= signed(ha(nr)(24 downto 0)) * signed(hb(nr)(17 downto 0)) then
          nbl(6) <= nbl(6) + 1;
        end if;
        nwyn(6) <= nr + 1;
      end if;
      if v_w = '1' then
        nr := nwyn(7);
        if signed(p_w) /= signed(ha(nr)) * signed(hb(nr)) or takt - t_wej(nr) /= 3 then
          nbl(7) <= nbl(7) + 1;
        end if;
        nwyn(7) <= nr + 1;
      end if;
      if v4 = '1' then
        nr  := nwyn(8);
        er := resize(signed(ha(nr)(15 downto 0)) * signed(hb(nr)(15 downto 0)), 33)
              - signed(hc(nr)) * signed(hd(nr));
        ei := resize(signed(ha(nr)(15 downto 0)) * signed(hd(nr)), 33)
              + signed(hc(nr)) * signed(hb(nr)(15 downto 0));
        if v3 /= '1' or signed(pr4) /= er or signed(pi4) /= ei or signed(pr3) /= er or signed(pi3) /= ei
           or takt - t_wej(nr) /= 4 then
          nbl(8) <= nbl(8) + 1;
        end if;
        nwyn(8) <= nr + 1;
      end if;
    end if;
  end process;

  process
    variable l      : line;
    variable s1, s2 : positive := 3;
    variable r      : real;
    variable nwej, i, w, errors : integer := 0;
    variable va, vb : std_logic_vector(33 downto 0);
    variable vc, vd : std_logic_vector(15 downto 0);
    variable vv     : std_logic;

    impure function los(bity : positive) return std_logic_vector is
      variable v : std_logic_vector(bity - 1 downto 0);
    begin
      for k in v'range loop
        uniform(s1, s2, r);
        v(k) := '1' when r > 0.5 else '0';
      end loop;
      return v;
    end function;
  begin
    wait for 25 ns;
    while nwej < N - 8 loop
      wait until falling_edge(clk);
      if i < 48 then
        w  := 18 when i < 16 else 34 when i < 32 else 16;
        va := skrajna(i mod 4, w);
        vb := skrajna((i / 4) mod 4, w);
        vc := vb(15 downto 0);
        vd := va(15 downto 0);
        vv := '1';
      else
        va := los(34); vb := los(34); vc := los(16); vd := los(16);
        uniform(s1, s2, r);
        vv := '1' when r < 0.75 else '0';
      end if;
      a <= va; b <= vb; ci <= vc; di <= vd; in_valid <= vv;
      if vv = '1' then
        ha(nwej) <= va; hb(nwej) <= vb; hc(nwej) <= vc; hd(nwej) <= vd; t_wej(nwej) <= takt;
        nwej := nwej + 1;
      end if;
      i := i + 1;
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for k in 1 to 8 loop wait until falling_edge(clk); end loop;
    for k in 0 to 8 loop
      errors := errors + nbl(k);
      if nwyn(k) /= nwej then errors := errors + 1; end if;
    end loop;
    write(l, "probek " & integer'image(nwej) & "; wynikow LAT0 " & integer'image(nwyn(0)) & ", szeroki "
          & integer'image(nwyn(7)) & ", zesp " & integer'image(nwyn(8)));
    writeline(output, l);
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

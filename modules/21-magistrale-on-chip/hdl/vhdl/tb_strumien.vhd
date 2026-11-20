-- Testbench 21.01: axis_skid i axis_8na32 z losowym valid i losowym ready (przeciwciśnienie).
-- Sprawdzane: kolejność, dane, TLAST i TKEEP (model konwersji liczony z góry), reguła protokołu na wyjściu
-- (valid and not ready -> w następnym takcie valid nadal '1', dane bez zmian), przepustowość bufora.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_strumien is
end entity tb_strumien;

architecture sim of tb_strumien is
  constant N1 : positive := 1500;
  constant NB : positive := 700;
  type b_t is array (0 to NB - 1) of std_logic_vector(7 downto 0);
  type w_t is array (0 to NB - 1) of std_logic_vector(31 downto 0);
  type k_t is array (0 to NB - 1) of std_logic_vector(3 downto 0);
  type l_t is array (0 to NB - 1) of std_logic;
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal pv, pr : integer := 50;
  signal bl_s, bl_u : integer := 0;
  -- skid
  signal sd, md : std_logic_vector(7 downto 0) := x"00";
  signal sl, sv, sr, ml, mv, mr : std_logic := '0';
  signal wyst, odeb : integer := 0;
  -- 8na32
  signal bajty : b_t;
  signal ost, el : l_t;
  signal ed : w_t;
  signal ek : k_t;
  signal nslow : integer := 0;
  signal ud : std_logic_vector(7 downto 0) := x"00";
  signal ul, uv, ur, us_r, um_l, um_v : std_logic := '0';
  signal um_d : std_logic_vector(31 downto 0);
  signal um_k : std_logic_vector(3 downto 0);
  signal u_wyst, u_odeb : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_skid : entity work.axis_skid generic map (W => 8)
    port map (clk => clk, rst => rst, s_data => sd, s_last => sl, s_valid => sv, s_ready => sr,
              m_data => md, m_last => ml, m_valid => mv, m_ready => mr);
  u_konw : entity work.axis_8na32
    port map (clk => clk, rst => rst, s_data => ud, s_last => ul, s_valid => uv, s_ready => us_r,
              m_data => um_d, m_keep => um_k, m_last => um_l, m_valid => um_v, m_ready => ur);

  -- źródła i odbiorniki
  process (clk)
    variable s1, s2 : positive := 3;
    variable r : real;
  begin
    if rising_edge(clk) and rst = '0' then
      if sv = '0' or sr = '1' then
        uniform(s1, s2, r);
        if wyst < N1 and r * 100.0 < real(pv) then
          sv   <= '1';
          sd   <= std_logic_vector(to_unsigned(wyst mod 256, 8)) xor x"5A";
          sl   <= '1' when wyst mod 7 = 6 else '0';
          wyst <= wyst + 1;
        else
          sv <= '0';
        end if;
      end if;
      uniform(s1, s2, r);
      mr <= '1' when r * 100.0 < real(pr) else '0';
      if uv = '0' or us_r = '1' then
        uniform(s1, s2, r);
        if u_wyst < NB and r * 100.0 < real(pv) then
          uv     <= '1';
          ud     <= bajty(u_wyst);
          ul     <= ost(u_wyst);
          u_wyst <= u_wyst + 1;
        else
          uv <= '0';
        end if;
      end if;
      uniform(s1, s2, r);
      ur <= '1' when r * 100.0 < real(pr) else '0';
    end if;
  end process;

  -- sprawdzanie
  process (clk)
    variable stoi : boolean := false;
    variable pop  : std_logic_vector(8 downto 0);
    variable l    : line;
  begin
    if rising_edge(clk) and rst = '0' then
      if stoi and (mv = '0' or ml & md /= pop) then
        write(l, string'("skid: zmiana wyjscia przy valid and not ready")); writeline(output, l);
        bl_s <= bl_s + 1;
      end if;
      stoi := mv = '1' and mr = '0';
      pop  := ml & md;
      if mv = '1' and mr = '1' then
        if md /= (std_logic_vector(to_unsigned(odeb mod 256, 8)) xor x"5A")
           or (ml = '1') /= (odeb mod 7 = 6) then
          bl_s <= bl_s + 1;
        end if;
        odeb <= odeb + 1;
      end if;
      if um_v = '1' and ur = '1' then
        if um_d /= ed(u_odeb) or um_k /= ek(u_odeb) or um_l /= el(u_odeb) then
          if bl_u < 10 then
            write(l, "8na32: slowo " & integer'image(u_odeb)); writeline(output, l);
          end if;
          bl_u <= bl_u + 1;
        end if;
        u_odeb <= u_odeb + 1;
      end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 17;
    variable r      : real;
    variable poz, dl, n, n_takt, errors : integer := 0;
    variable w      : std_logic_vector(31 downto 0);
    variable k      : std_logic_vector(3 downto 0);
    variable b      : b_t;
    variable o      : l_t;
    variable t0     : time;
    variable l      : line;
  begin
    -- pakiety 1-13 bajtów i oczekiwane słowa
    poz := 0;
    for i in 0 to NB - 1 loop
      if poz = 0 then uniform(s1, s2, r); dl := 1 + integer(floor(r * 13.0)); end if;
      uniform(s1, s2, r);
      b(i) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
      poz := poz + 1;
      o(i) := '1' when poz = dl or i = NB - 1 else '0';
      if o(i) = '1' then poz := 0; end if;
    end loop;
    bajty <= b;
    ost   <= o;
    poz := 0; w := (others => '0'); k := "0000"; n := 0;
    for i in 0 to NB - 1 loop
      w(poz * 8 + 7 downto poz * 8) := b(i);
      k(poz) := '1';
      if poz = 3 or o(i) = '1' then
        ed(n) <= w; ek(n) <= k; el(n) <= o(i);
        n := n + 1;
        w := (others => '0'); k := "0000"; poz := 0;
      else
        poz := poz + 1;
      end if;
    end loop;
    nslow <= n;
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    wait until odeb = N1 - 200;
    wait until falling_edge(clk);
    pv <= 100;
    pr <= 100;
    wait until odeb = N1 - 190;
    t0 := now;
    wait until odeb = N1;
    n_takt := (now - t0) / 10 ns;
    if u_odeb /= n then wait until u_odeb = n; end if;
    for q in 1 to 10 loop wait until falling_edge(clk); end loop;
    write(l, "skid: " & integer'image(odeb) & " slow; przy valid = ready = 1: 190 slow w " & integer'image(n_takt)
          & " taktach");
    writeline(output, l);
    write(l, "8na32: " & integer'image(NB) & " bajtow -> " & integer'image(u_odeb) & " slow (pakiety 1-13 bajtow)");
    writeline(output, l);
    errors := bl_s + bl_u;
    if n_takt > 191 or wyst /= N1 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

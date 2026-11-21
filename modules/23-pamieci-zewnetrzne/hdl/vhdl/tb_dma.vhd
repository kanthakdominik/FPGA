-- Testbench 23.04: arbiter_rr z dwoma silnikami dma_kopia i „procesorem” (losowe zapisy i odczyty) do modelu
-- pamięci Avalon-MM (4096 słów, odczyt po 2 taktach, losowy waitrequest 20 %). Opis jak w tb_dma.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_dma is
end entity tb_dma;

architecture sim of tb_dma is
  type pam_t is array (0 to 4095) of std_logic_vector(31 downto 0);
  type m512_t is array (0 to 511) of std_logic_vector(31 downto 0);
  type m64_t is array (0 to 63) of std_logic_vector(31 downto 0);
  type l3_t is array (0 to 2) of integer;
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal p_wait : integer := 20;
  -- slave
  signal s_adr : std_logic_vector(11 downto 0);
  signal s_read, s_write : std_logic;
  signal s_wdata, rd0, rd1 : std_logic_vector(31 downto 0) := (others => '0');
  signal s_wait : std_logic := '0';
  signal rv : std_logic_vector(1 downto 0) := "00";
  signal pam : pam_t;
  signal pam_gotowa : boolean := false;
  -- mastery
  signal m_adr : std_logic_vector(35 downto 0);
  signal m_read, m_write, m_wait, m_rvalid : std_logic_vector(2 downto 0);
  signal m_wdata : std_logic_vector(95 downto 0);
  signal m_rdata : std_logic_vector(31 downto 0);
  signal start, zajety, gotowe : std_logic_vector(1 downto 0) := "00";
  signal zr0, cel0, n0, zr1, cel1, n1 : std_logic_vector(11 downto 0) := (others => '0');
  -- procesor
  signal c_adr : std_logic_vector(11 downto 0) := (others => '0');
  signal c_read, c_write : std_logic := '0';
  signal c_wdata : std_logic_vector(31 downto 0) := (others => '0');
  signal c_akt, mierz : boolean := false;
  signal c_n, c_wo, c_bl : integer := 0;
  signal licz : l3_t := (others => 0);
begin
  clk <= not clk after 5 ns when not fin else clk;

  -- pamięć
  process (clk)
    variable s1, s2 : positive := 9;
    variable r : real;
    variable p : pam_t;
    variable init : boolean := true;
  begin
    if init then
      for i in 0 to 4095 loop
        uniform(s1, s2, r); p(i)(31 downto 16) := std_logic_vector(to_unsigned(integer(floor(r * 65536.0)), 16));
        uniform(s1, s2, r); p(i)(15 downto 0) := std_logic_vector(to_unsigned(integer(floor(r * 65536.0)), 16));
      end loop;
      pam <= p;
      init := false;
      pam_gotowa <= true;
    end if;
    if rising_edge(clk) then
      uniform(s1, s2, r);
      s_wait <= '1' when r * 100.0 < real(p_wait) else '0';
      if s_write = '1' and s_wait = '0' then pam(to_integer(unsigned(s_adr))) <= s_wdata; end if;
      rv  <= rv(0) & (s_read and not s_wait);
      rd0 <= pam(to_integer(unsigned(s_adr)));
      rd1 <= rd0;
    end if;
  end process;

  u_arb : entity work.arbiter_rr generic map (N => 3, AW => 12, KOL => 8)
    port map (clk => clk, rst => rst, m_adr => m_adr, m_read => m_read, m_write => m_write, m_wdata => m_wdata,
              m_wait => m_wait, m_rvalid => m_rvalid, m_rdata => m_rdata, s_adr => s_adr, s_read => s_read,
              s_write => s_write, s_wdata => s_wdata, s_wait => s_wait, s_rvalid => rv(1), s_rdata => rd1);
  u_dma0 : entity work.dma_kopia generic map (AW => 12, GL => 8)
    port map (clk => clk, rst => rst, start => start(0), zrodlo => zr0, cel => cel0, n => n0, zajety => zajety(0),
              gotowe => gotowe(0), m_adr => m_adr(11 downto 0), m_read => m_read(0), m_write => m_write(0),
              m_wdata => m_wdata(31 downto 0), m_wait => m_wait(0), m_rvalid => m_rvalid(0), m_rdata => m_rdata);
  u_dma1 : entity work.dma_kopia generic map (AW => 12, GL => 8)
    port map (clk => clk, rst => rst, start => start(1), zrodlo => zr1, cel => cel1, n => n1, zajety => zajety(1),
              gotowe => gotowe(1), m_adr => m_adr(23 downto 12), m_read => m_read(1), m_write => m_write(1),
              m_wdata => m_wdata(63 downto 32), m_wait => m_wait(1), m_rvalid => m_rvalid(1), m_rdata => m_rdata);
  m_adr(35 downto 24)  <= c_adr;
  m_read(2)            <= c_read;
  m_write(2)           <= c_write;
  m_wdata(95 downto 64) <= c_wdata;

  -- procesor: losowe zapisy i odczyty w obszarze 3584-4095
  process (clk)
    variable s1, s2 : positive := 13;
    variable r : real;
    variable model : m512_t;
    variable ocz : m64_t;
    variable wz : integer := 0;
    variable a : integer;
    variable d : std_logic_vector(31 downto 0);
  begin
    if pam_gotowa and wz = 0 and c_n = 0 and not c_akt then
      for i in 0 to 511 loop model(i) := pam(3584 + i); end loop;
    end if;
    if rising_edge(clk) then
      if m_rvalid(2) = '1' then
        if m_rdata /= ocz(c_wo mod 64) then c_bl <= c_bl + 1; end if;
        c_wo <= c_wo + 1;
      end if;
      if (c_read = '1' or c_write = '1') and m_wait(2) = '0' then
        c_n <= c_n + 1;
        if c_read = '1' then
          ocz(wz mod 64) := model(to_integer(unsigned(c_adr)) - 3584);
          wz := wz + 1;
        end if;
        c_read  <= '0';
        c_write <= '0';
      end if;
      uniform(s1, s2, r);
      if c_akt and ((c_read = '0' and c_write = '0') or m_wait(2) = '0') and r < 0.7 then
        uniform(s1, s2, r);
        a := 3584 + integer(floor(r * 512.0));
        c_adr <= std_logic_vector(to_unsigned(a, 12));
        uniform(s1, s2, r);
        if r < 0.5 then
          uniform(s1, s2, r);
          d := std_logic_vector(to_unsigned(integer(floor(r * 65536.0)), 16)) & x"5A5A";
          model(a - 3584) := d;
          c_wdata <= d;
          c_write <= '1';
        else
          c_read <= '1';
        end if;
      end if;
      if mierz then
        for j in 0 to 2 loop
          if (m_read(j) = '1' or m_write(j) = '1') and m_wait(j) = '0' then licz(j) <= licz(j) + 1; end if;
        end loop;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable errors : integer := 0;
    variable t0, t1 : time;
    variable kopia : pam_t;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    p_wait <= 0;
    wait until falling_edge(clk);
    zr0 <= std_logic_vector(to_unsigned(0, 12)); cel0 <= std_logic_vector(to_unsigned(1024, 12));
    n0 <= std_logic_vector(to_unsigned(256, 12)); start <= "01";
    wait until falling_edge(clk);
    start <= "00";
    t0 := now;
    wait until gotowe(0) = '1';
    t1 := now;
    wait until falling_edge(clk);
    for i in 0 to 255 loop
      if pam(1024 + i) /= pam(i) then errors := errors + 1; end if;
    end loop;
    write(l, "DMA sam: 256 slow w " & integer'image((t1 - t0) / 10 ns) & " taktach (512 transferow)");
    writeline(output, l);
    p_wait <= 20;
    kopia := pam;
    wait until falling_edge(clk);
    zr0 <= std_logic_vector(to_unsigned(256, 12)); cel0 <= std_logic_vector(to_unsigned(1536, 12));
    n0 <= std_logic_vector(to_unsigned(300, 12));
    zr1 <= std_logic_vector(to_unsigned(2048, 12)); cel1 <= std_logic_vector(to_unsigned(2560, 12));
    n1 <= std_logic_vector(to_unsigned(300, 12));
    start <= "11"; c_akt <= true; mierz <= true;
    wait until falling_edge(clk);
    start <= "00";
    wait until gotowe(0) = '1' or gotowe(1) = '1';
    mierz <= false;
    write(l, "rywalizacja (do konca pierwszego DMA): transfery DMA0 " & integer'image(licz(0)) & ", DMA1 "
          & integer'image(licz(1)) & ", procesor " & integer'image(licz(2)));
    writeline(output, l);
    if licz(0) < 2 * licz(1) / 3 or licz(1) < 2 * licz(0) / 3 then errors := errors + 1; end if;
    if zajety /= "00" then wait until zajety = "00"; end if;
    c_akt <= false;
    for q in 1 to 20 loop wait until falling_edge(clk); end loop;
    for i in 0 to 299 loop
      if pam(1536 + i) /= kopia(256 + i) then errors := errors + 1; end if;
      if pam(2560 + i) /= kopia(2048 + i) then errors := errors + 1; end if;
    end loop;
    write(l, "kopie 2 x 300 slow: bledow " & integer'image(errors) & "; procesor: " & integer'image(c_n)
          & " transferow, " & integer'image(c_wo) & " odczytow, bledow odczytu " & integer'image(c_bl));
    writeline(output, l);
    if c_bl /= 0 or c_wo < 50 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

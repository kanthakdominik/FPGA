-- Testbench fp32_mnoz (19.05): wektory z fp32_mnoz.hex (gen_fp32.py) — wartości specjalne, losowe,
-- remisy przy zaokrąglaniu, granice nadmiaru i niedomiaru. Dane w każdym takcie, opóźnienie 2 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_fp32_mnoz is
end entity tb_fp32_mnoz;

architecture sim of tb_fp32_mnoz is
  constant NMAX : positive := 8192;
  type w_t is array (0 to NMAX - 1) of std_logic_vector(31 downto 0);
  type f_t is array (0 to NMAX - 1) of std_logic_vector(3 downto 0);
  type i_t is array (0 to NMAX - 1) of integer;
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal in_valid  : std_logic := '0';
  signal a, b, p   : std_logic_vector(31 downto 0) := (others => '0');
  signal out_valid, nadmiar, niedomiar : std_logic;
  signal wa, wb, wp : w_t;
  signal wf        : f_t;
  signal t_wej     : i_t;
  signal takt, k, errors, n_nan, n_inf : integer := 0;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);
  dut : entity work.fp32_mnoz port map (clk, in_valid, a, b, out_valid, p, nadmiar, niedomiar);

  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) and out_valid = '1' then
      if p /= wp(k) or (nadmiar & niedomiar) /= wf(k)(1 downto 0) or takt - t_wej(k) /= 2 then
        if errors < 10 then
          write(l, to_hstring(wa(k)) & " * " & to_hstring(wb(k)) & " = " & to_hstring(p) & ", oczekiwano "
                & to_hstring(wp(k)));
          writeline(output, l);
        end if;
        errors <= errors + 1;
      end if;
      if p = x"7FC00000" then n_nan <= n_nan + 1; end if;
      if p(30 downto 0) = 31x"7F800000" then n_inf <= n_inf + 1; end if;
      k <= k + 1;
    end if;
  end process;

  process
    file f     : text;
    variable st : file_open_status;
    variable l : line;
    variable n : integer := 0;
    variable va, vb, vp : std_logic_vector(31 downto 0);
    variable vf : std_logic_vector(3 downto 0);
  begin
    file_open(st, f, "fp32_mnoz.hex", read_mode);
    if st /= open_ok then
      write(l, string'("FAIL: brak pliku fp32_mnoz.hex")); writeline(output, l);
      std.env.finish;
    end if;
    while not endfile(f) and n < NMAX loop
      readline(f, l);
      hread(l, va); hread(l, vb); hread(l, vp); hread(l, vf);
      wa(n) <= va; wb(n) <= vb; wp(n) <= vp; wf(n) <= vf;
      n := n + 1;
    end loop;
    file_close(f);
    wait for 25 ns;
    for i in 0 to n - 1 loop
      wait until falling_edge(clk);
      a <= wa(i); b <= wb(i); in_valid <= '1'; t_wej(i) <= takt;
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for i in 1 to 4 loop wait until falling_edge(clk); end loop;
    write(l, "wektorow " & integer'image(n) & ", wynikow " & integer'image(k) & ": NaN " & integer'image(n_nan)
          & ", nieskonczonosci " & integer'image(n_inf));
    writeline(output, l);
    if errors = 0 and k = n and n >= 3000 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

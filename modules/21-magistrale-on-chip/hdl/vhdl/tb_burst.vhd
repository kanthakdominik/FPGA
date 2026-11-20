-- Testbench 21.03: axi_ram (AXI4) i avmm_burst_ram (Avalon-MM) z modelem pamięci.
--   AXI4: wypełnienie pamięci burstami INCR po 16, odczyt INCR 16 przy RREADY = 1 (przepustowość), potem
--   300 losowych transakcji zapis + odczyt: FIXED (1-4), INCR (1-16), WRAP (2, 4, 8, 16), losowe WSTRB i ID,
--   przerwy w WVALID, losowe BREADY i RREADY; adresy taktów w modelu wprost ze wzorów specyfikacji.
--   Avalon-MM: wypełnienie, potem 200 losowych burstów zapisu (z przerwami) i odczytu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_burst is
end entity tb_burst;

architecture sim of tb_burst is
  constant FIXED : std_logic_vector(1 downto 0) := "00";
  constant INCR  : std_logic_vector(1 downto 0) := "01";
  constant WRAP  : std_logic_vector(1 downto 0) := "10";
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  -- AXI4
  signal awid, arid, bid, rid : std_logic_vector(3 downto 0) := "0000";
  signal awaddr, araddr : std_logic_vector(11 downto 0) := (others => '0');
  signal awlen, arlen : std_logic_vector(7 downto 0) := (others => '0');
  signal awburst, arburst, bresp, rresp : std_logic_vector(1 downto 0) := "00";
  signal awvalid, wvalid, wlast, bready, arvalid, rready : std_logic := '0';
  signal awready, wready, bvalid, arready, rvalid, rlast : std_logic;
  signal wdata, rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrb : std_logic_vector(3 downto 0) := "0000";
  -- Avalon-MM
  signal address : std_logic_vector(9 downto 0) := (others => '0');
  signal av_read, av_write, waitrequest, readdatavalid : std_logic := '0';
  signal writedata, readdata : std_logic_vector(31 downto 0) := (others => '0');
  signal burstcount : std_logic_vector(4 downto 0) := "00000";
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_axi : entity work.axi_ram generic map (AW => 12, IDW => 4)
    port map (clk => clk, rst => rst,
              s_awid => awid, s_awaddr => awaddr, s_awlen => awlen, s_awsize => "010", s_awburst => awburst,
              s_awvalid => awvalid, s_awready => awready,
              s_wdata => wdata, s_wstrb => wstrb, s_wlast => wlast, s_wvalid => wvalid, s_wready => wready,
              s_bid => bid, s_bresp => bresp, s_bvalid => bvalid, s_bready => bready,
              s_arid => arid, s_araddr => araddr, s_arlen => arlen, s_arsize => "010", s_arburst => arburst,
              s_arvalid => arvalid, s_arready => arready,
              s_rid => rid, s_rdata => rdata, s_rresp => rresp, s_rlast => rlast, s_rvalid => rvalid, s_rready => rready);
  u_avmm : entity work.avmm_burst_ram generic map (AW => 10, BW => 5)
    port map (clk => clk, rst => rst, address => address, read => av_read, write => av_write, writedata => writedata,
              byteenable => "1111", burstcount => burstcount, waitrequest => waitrequest, readdata => readdata,
              readdatavalid => readdatavalid);

  process
    type bajty_t is array (0 to 4095) of std_logic_vector(7 downto 0);
    type slowa_t is array (0 to 1023) of std_logic_vector(31 downto 0);
    variable model  : bajty_t;
    variable mmodel : slowa_t;
    variable s1, s2 : positive := 21;
    variable r      : real;
    variable errors, pr_r, st, len, n_fix, n_incr, n_wrap : integer := 0;
    variable typ    : std_logic_vector(1 downto 0);
    variable t_ar, t_last : time;
    variable l      : line;

    impure function los(zakres : positive) return integer is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(zakres)));
    end function;
    impure function los32 return std_logic_vector is
    begin
      return std_logic_vector(to_unsigned(los(65536), 16)) & std_logic_vector(to_unsigned(los(65536), 16));
    end function;

    -- adres taktu k ze wzorów specyfikacji (rozmiar 4 bajty)
    function adres(start : integer; t : std_logic_vector(1 downto 0); ln : integer; k : integer) return integer is
      variable rozm, dol : integer;
    begin
      if t = FIXED then return start;
      elsif t = INCR then return start + 4 * k;
      else
        rozm := 4 * (ln + 1);
        dol  := start - (start mod rozm);
        return dol + ((start - dol + 4 * k) mod rozm);
      end if;
    end function;

    procedure czekaj(n : integer) is
    begin
      for q in 1 to n loop wait until falling_edge(clk); end loop;
    end procedure;

    procedure axi_zapis(start : integer; t : std_logic_vector(1 downto 0); ln : integer; id : integer; pelne : boolean) is
      variable da, c, k, przerwa, a : integer;
      variable ga, nowy : boolean;
      variable d : std_logic_vector(31 downto 0);
      variable s : std_logic_vector(3 downto 0);
    begin
      da := los(3); c := 0; ga := false; k := 0; przerwa := los(2); nowy := true;
      loop
        wait until falling_edge(clk);
        awaddr <= std_logic_vector(to_unsigned(start, 12)); awburst <= t;
        awlen <= std_logic_vector(to_unsigned(ln, 8)); awid <= std_logic_vector(to_unsigned(id, 4));
        awvalid <= '1' when not ga and c >= da else '0';
        if k <= ln and przerwa = 0 then
          if nowy then
            d := los32;
            if pelne then s := "1111"; else s := std_logic_vector(to_unsigned(los(16), 4)); end if;
            nowy := false;
          end if;
          wdata <= d; wstrb <= s; wlast <= '1' when k = ln else '0'; wvalid <= '1';
        else
          wvalid <= '0';
          if przerwa > 0 then przerwa := przerwa - 1; end if;
        end if;
        wait until rising_edge(clk);
        if awvalid = '1' and awready = '1' then ga := true; end if;
        if wvalid = '1' and wready = '1' then
          a := adres(start, t, ln, k);
          for b in 0 to 3 loop
            if s(b) = '1' then model(a + b) := d(b * 8 + 7 downto b * 8); end if;
          end loop;
          k := k + 1; przerwa := los(2); nowy := true;
        end if;
        c := c + 1;
        exit when ga and k > ln;
      end loop;
      wait until falling_edge(clk);
      awvalid <= '0'; wvalid <= '0';
      czekaj(los(3));
      bready <= '1';
      loop
        wait until rising_edge(clk);
        exit when bvalid = '1';
      end loop;
      if to_integer(unsigned(bid)) /= id or bresp /= "00" then errors := errors + 1; end if;
      wait until falling_edge(clk);
      bready <= '0';
    end procedure;

    procedure axi_odczyt(start : integer; t : std_logic_vector(1 downto 0); ln : integer; id : integer) is
      variable k, a : integer;
      variable ocz  : std_logic_vector(31 downto 0);
    begin
      czekaj(los(3));
      araddr <= std_logic_vector(to_unsigned(start, 12)); arburst <= t;
      arlen <= std_logic_vector(to_unsigned(ln, 8)); arid <= std_logic_vector(to_unsigned(id, 4)); arvalid <= '1';
      loop
        wait until rising_edge(clk);
        exit when arready = '1';
      end loop;
      t_ar := now;
      wait until falling_edge(clk);
      arvalid <= '0';
      k := 0;
      while k <= ln loop
        rready <= '1' when los(100) < pr_r else '0';
        wait until rising_edge(clk);
        if rvalid = '1' and rready = '1' then
          a := adres(start, t, ln, k);
          ocz := model(a + 3) & model(a + 2) & model(a + 1) & model(a);
          if rdata /= ocz or to_integer(unsigned(rid)) /= id or (rlast = '1') /= (k = ln) then
            if errors < 10 then
              write(l, "AXI odczyt typ " & to_string(t) & " len " & integer'image(ln) & " takt " & integer'image(k)
                    & ": " & to_hstring(rdata) & ", oczekiwano " & to_hstring(ocz));
              writeline(output, l);
            end if;
            errors := errors + 1;
          end if;
          k := k + 1;
          t_last := now;
        end if;
        wait until falling_edge(clk);
      end loop;
      rready <= '0';
    end procedure;

    procedure av_zapis(a : integer; n : integer; przerwy : boolean) is
      variable d : std_logic_vector(31 downto 0);
    begin
      for k in 0 to n - 1 loop
        if przerwy then czekaj(los(2)); end if;
        d := los32;
        address <= std_logic_vector(to_unsigned(a, 10)); burstcount <= std_logic_vector(to_unsigned(n, 5));
        writedata <= d; av_write <= '1';
        loop
          wait until rising_edge(clk);
          exit when waitrequest = '0';
        end loop;
        mmodel(a + k) := d;
        wait until falling_edge(clk);
        av_write <= '0';
      end loop;
    end procedure;

    procedure av_odczyt(a : integer; n : integer) is
      variable k : integer;
    begin
      wait until falling_edge(clk);
      address <= std_logic_vector(to_unsigned(a, 10)); burstcount <= std_logic_vector(to_unsigned(n, 5));
      av_read <= '1';
      loop
        wait until rising_edge(clk);
        exit when waitrequest = '0';
      end loop;
      wait until falling_edge(clk);
      av_read <= '0';
      k := 0;
      while k < n loop
        wait until rising_edge(clk);
        if readdatavalid = '1' then
          if readdata /= mmodel(a + k) then
            if errors < 10 then
              write(l, "Avalon: burst " & integer'image(n) & " od " & integer'image(a) & " slowo " & integer'image(k));
              writeline(output, l);
            end if;
            errors := errors + 1;
          end if;
          k := k + 1;
        end if;
      end loop;
    end procedure;
  begin
    czekaj(5);
    rst <= '0';
    for i in 0 to 63 loop axi_zapis(i * 64, INCR, 15, i mod 16, true); end loop;
    pr_r := 100;
    axi_odczyt(256, INCR, 15, 3);
    write(l, "AXI: odczyt INCR 16 slow przy RREADY = 1: " & integer'image((t_last - t_ar) / 10 ns)
          & " taktow od przyjecia AR do RLAST");
    writeline(output, l);
    if (t_last - t_ar) / 10 ns > 17 then errors := errors + 1; end if;
    pr_r := 60;
    for i in 1 to 300 loop
      typ := std_logic_vector(to_unsigned(los(3), 2));
      if typ = FIXED then
        len := los(4); st := 4 * los(1024); n_fix := n_fix + 1;
      elsif typ = INCR then
        len := los(16); st := 4 * los(1024 - len); n_incr := n_incr + 1;
      else
        len := 2 * 2 ** los(4) - 1; st := 4 * los(1024); n_wrap := n_wrap + 1;
      end if;
      axi_zapis(st, typ, len, los(16), false);
      axi_odczyt(st, typ, len, los(16));
    end loop;
    write(l, "AXI4: 300 transakcji zapis + odczyt (FIXED " & integer'image(n_fix) & ", INCR " & integer'image(n_incr)
          & ", WRAP " & integer'image(n_wrap) & "), bledow " & integer'image(errors));
    writeline(output, l);
    for i in 0 to 63 loop av_zapis(i * 16, 16, false); end loop;
    for i in 1 to 200 loop
      len := 1 + los(16);
      st  := los(1024 - len);
      av_zapis(st, len, true);
      len := 1 + los(16);
      st  := los(1024 - len);
      av_odczyt(st, len);
    end loop;
    write(l, "Avalon-MM: 200 burstow zapisu i odczytu (1-16 slow), bledow lacznie " & integer'image(errors));
    writeline(output, l);
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

-- Testbench 21.02: ta sama mapa rejestrów przez AXI4-Lite (axil_rejestry) i Avalon-MM (avmm_rejestry).
-- Master AXI4-Lite podaje AW i W z losowymi, niezależnymi opóźnieniami (także W przed AW), losowe opóźnienie
-- BREADY/RREADY. Sprawdzane: ID, maska bajtów, rejestr tylko do odczytu, W1C, irq z maską, SLVERR poza mapą,
-- 100 losowych zapisów i odczytów rejestru SKRYTKA z modelem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_rejestry is
end entity tb_rejestry;

architecture sim of tb_rejestry is
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  -- AXI4-Lite
  signal awaddr, araddr : std_logic_vector(5 downto 0) := (others => '0');
  signal awvalid, wvalid, bready, arvalid, rready : std_logic := '0';
  signal awready, wready, bvalid, arready, rvalid : std_logic;
  signal wdata, rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrb : std_logic_vector(3 downto 0) := "0000";
  signal bresp, rresp : std_logic_vector(1 downto 0);
  signal ster_a, stan_a : std_logic_vector(31 downto 0) := (others => '0');
  signal zdarz_a : std_logic_vector(7 downto 0) := x"00";
  signal irq_a : std_logic;
  -- Avalon-MM
  signal address : std_logic_vector(3 downto 0) := "0000";
  signal av_read, av_write : std_logic := '0';
  signal writedata, readdata : std_logic_vector(31 downto 0) := (others => '0');
  signal byteenable : std_logic_vector(3 downto 0) := "0000";
  signal response : std_logic_vector(1 downto 0);
  signal ster_m, stan_m : std_logic_vector(31 downto 0) := (others => '0');
  signal zdarz_m : std_logic_vector(7 downto 0) := x"00";
  signal irq_m : std_logic;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_axil : entity work.axil_rejestry
    port map (clk => clk, rst => rst, s_awaddr => awaddr, s_awvalid => awvalid, s_awready => awready,
              s_wdata => wdata, s_wstrb => wstrb, s_wvalid => wvalid, s_wready => wready,
              s_bresp => bresp, s_bvalid => bvalid, s_bready => bready,
              s_araddr => araddr, s_arvalid => arvalid, s_arready => arready,
              s_rdata => rdata, s_rresp => rresp, s_rvalid => rvalid, s_rready => rready,
              ster => ster_a, stan => stan_a, zdarz => zdarz_a, irq => irq_a);
  u_avmm : entity work.avmm_rejestry
    port map (clk => clk, rst => rst, address => address, read => av_read, write => av_write, writedata => writedata,
              byteenable => byteenable, readdata => readdata, response => response,
              ster => ster_m, stan => stan_m, zdarz => zdarz_m, irq => irq_m);

  process
    variable s1, s2 : positive := 11;
    variable r      : real;
    variable szyna, errors : integer := 0;
    variable dane, model, x, m : std_logic_vector(31 downto 0);
    variable odp    : std_logic_vector(1 downto 0);
    variable s      : std_logic_vector(3 downto 0);
    variable l      : line;

    impure function los(zakres : positive) return integer is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(zakres)));
    end function;

    procedure czekaj(n : integer) is
    begin
      for q in 1 to n loop wait until falling_edge(clk); end loop;
    end procedure;

    procedure zapis(a : std_logic_vector(5 downto 0); d : std_logic_vector(31 downto 0); st : std_logic_vector(3 downto 0)) is
      variable da, dw, c : integer;
      variable ga, gw    : boolean;
    begin
      if szyna = 0 then
        da := los(4); dw := los(4); c := 0; ga := false; gw := false;
        loop
          wait until falling_edge(clk);
          awaddr <= a; wdata <= d; wstrb <= st;
          awvalid <= '1' when not ga and c >= da else '0';
          wvalid  <= '1' when not gw and c >= dw else '0';
          wait until rising_edge(clk);
          if awvalid = '1' and awready = '1' then ga := true; end if;
          if wvalid = '1' and wready = '1' then gw := true; end if;
          c := c + 1;
          exit when ga and gw;
        end loop;
        wait until falling_edge(clk);
        awvalid <= '0'; wvalid <= '0';
        czekaj(los(3));
        bready <= '1';
        loop
          wait until rising_edge(clk);
          exit when bvalid = '1';
        end loop;
        odp := bresp;
        wait until falling_edge(clk);
        bready <= '0';
      else
        wait until falling_edge(clk);
        address <= a(5 downto 2); writedata <= d; byteenable <= st; av_write <= '1';
        wait until falling_edge(clk);
        av_write <= '0';
        odp := "00";                                            -- Avalon-MM: zapis bez odpowiedzi
      end if;
    end procedure;

    procedure odczyt(a : std_logic_vector(5 downto 0)) is
    begin
      if szyna = 0 then
        czekaj(los(4));
        araddr <= a; arvalid <= '1';
        loop
          wait until rising_edge(clk);
          exit when arready = '1';
        end loop;
        wait until falling_edge(clk);
        arvalid <= '0';
        czekaj(los(3));
        rready <= '1';
        loop
          wait until rising_edge(clk);
          exit when rvalid = '1';
        end loop;
        dane := rdata; odp := rresp;
        wait until falling_edge(clk);
        rready <= '0';
      else
        wait until falling_edge(clk);
        address <= a(5 downto 2); av_read <= '1';
        wait until falling_edge(clk);
        av_read <= '0';
        dane := readdata; odp := response;
      end if;
    end procedure;

    procedure oczekuj(a : std_logic_vector(5 downto 0); d : std_logic_vector(31 downto 0); o : std_logic_vector(1 downto 0)) is
    begin
      odczyt(a);
      if dane /= d or odp /= o then
        write(l, "szyna " & integer'image(szyna) & ": odczyt " & to_hstring(a) & " = " & to_hstring(dane) & " (odp "
              & to_string(odp) & "), oczekiwano " & to_hstring(d));
        writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;

    procedure zdarzenie(z : std_logic_vector(7 downto 0)) is
    begin
      wait until falling_edge(clk);
      if szyna = 0 then zdarz_a <= z; else zdarz_m <= z; end if;
      wait until falling_edge(clk);
      zdarz_a <= x"00"; zdarz_m <= x"00";
    end procedure;

    impure function irq return std_logic is
    begin
      if szyna = 0 then return irq_a; else return irq_m; end if;
    end function;
  begin
    czekaj(5);
    rst <= '0';
    for sz in 0 to 1 loop
      szyna := sz;
      oczekuj("000000", x"21020001", "00");
      zapis("000100", x"12345678", "1111");
      oczekuj("000100", x"12345678", "00");
      zapis("000100", x"AABBCCDD", "0101");                     -- tylko bajty 0 i 2
      oczekuj("000100", x"12BB56DD", "00");
      if (szyna = 0 and ster_a /= x"12BB56DD") or (szyna = 1 and ster_m /= x"12BB56DD") then errors := errors + 1; end if;
      zapis("000000", x"FFFFFFFF", "1111");                     -- ID tylko do odczytu
      oczekuj("000000", x"21020001", "00");
      if szyna = 0 then stan_a <= x"CAFEF00D"; else stan_m <= x"CAFEF00D"; end if;
      oczekuj("001000", x"CAFEF00D", "00");
      zdarzenie(x"05");
      oczekuj("001100", x"00000005", "00");
      if irq /= '0' then errors := errors + 1; end if;
      zapis("010000", x"00000004", "0001");                     -- maska bitu 2
      wait until falling_edge(clk);
      if irq /= '1' then
        write(l, "szyna " & integer'image(szyna) & ": brak irq"); writeline(output, l); errors := errors + 1;
      end if;
      zapis("001100", x"00000004", "0001");                     -- W1C bitu 2
      oczekuj("001100", x"00000001", "00");
      wait until falling_edge(clk);
      if irq /= '0' then errors := errors + 1; end if;
      oczekuj("100000", x"00000000", "10");                     -- poza mapą
      zapis("111100", x"00000001", "1111");
      if (szyna = 0 and odp /= "10") or (szyna = 1 and odp /= "00") then errors := errors + 1; end if;
      model := (others => '0');
      zapis("010100", x"00000000", "1111");
      for i in 1 to 100 loop
        x := std_logic_vector(to_unsigned(los(65536), 16)) & std_logic_vector(to_unsigned(los(65536), 16));
        s := std_logic_vector(to_unsigned(los(16), 4));
        for b in 0 to 3 loop m(b * 8 + 7 downto b * 8) := (others => s(b)); end loop;
        zapis("010100", x, s);
        model := (model and not m) or (x and m);
        oczekuj("010100", model, "00");
      end loop;
      if szyna = 0 then write(l, string'("szyna AXI4-Lite"));
      else write(l, string'("szyna Avalon-MM")); end if;
      write(l, ": ID, maska bajtow, RO, W1C, irq, SLVERR, 100 zapisow losowych - bledow do tej pory "
            & integer'image(errors));
      writeline(output, l);
    end loop;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

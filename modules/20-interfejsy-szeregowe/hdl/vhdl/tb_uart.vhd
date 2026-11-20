-- Testbench UART (20.01), zegar 50 MHz:
--   1. pętla uart_tx -> uart_rx, 115 200 b/s, bez parzystości / nieparzysta / parzysta, po 40 bajtów,
--      długość ramki nadajnika,
--   2. tolerancja odbiornika 8N1 500 000 b/s: model linii z szybkością odchyloną o 0…±6 % co 0,5 %,
--      20 bajtów na odchylenie (wymagane ±3,5 %),
--   3. zakłócenia: impuls 0,25 bitu w spoczynku i 1/16 bitu w środku bitu,
--   4. błąd ramki i błąd parzystości.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_uart is
end entity tb_uart;

architecture sim of tb_uart is
  constant BIT_T : time := 2000 ns;                            -- 500 000 b/s
  type wzor_t is array (0 to 2, 0 to 39) of std_logic_vector(7 downto 0);
  type licz_t is array (0 to 2) of integer;
  signal clk   : std_logic := '0';
  signal fin   : boolean := false;
  signal rst   : std_logic := '1';
  signal start, gotowy, tx, wazne, bl_r, bl_p : std_logic_vector(0 to 2) := (others => '0');
  type b3_t is array (0 to 2) of std_logic_vector(7 downto 0);
  signal bajt  : std_logic_vector(7 downto 0) := x"00";
  signal odebr : b3_t;
  signal wzor  : wzor_t;
  signal n_rx  : licz_t := (others => 0);
  signal bl_petla : integer := 0;
  -- linia -> odbiorniki 500 000 b/s
  signal linia, linia_p : std_logic := '1';
  signal w0, w2, r0, r2, p0, p2 : std_logic;
  signal d0, d2 : std_logic_vector(7 downto 0);
  signal n_w0, n_w2 : integer := 0;
  signal ost0, ost2 : std_logic_vector(7 downto 0) := x"00";
  signal ostr0, ostp2 : std_logic := '0';
  type log_t is array (0 to 4095) of std_logic;
  signal log_r0 : log_t := (others => '0');
begin
  clk <= not clk after 10 ns when not fin else clk;

  g_cfg : for g in 0 to 2 generate
    u_tx : entity work.uart_tx generic map (CLK_HZ => 50_000_000, BAUD => 115_200, PARZ => g)
      port map (clk => clk, rst => rst, start => start(g), dane => bajt, gotowy => gotowy(g), tx => tx(g));
    u_rx : entity work.uart_rx generic map (CLK_HZ => 50_000_000, BAUD => 115_200, PARZ => g)
      port map (clk => clk, rst => rst, rx => tx(g), dane => odebr(g), wazne => wazne(g), blad_ramki => bl_r(g),
                blad_parz => bl_p(g));
  end generate;

  -- sprawdzanie pętli (jeden proces dla trzech konfiguracji)
  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) then
      for g in 0 to 2 loop
        if wazne(g) = '1' then
          if odebr(g) /= wzor(g, n_rx(g)) or bl_r(g) = '1' or bl_p(g) = '1' then
            write(l, "petla PARZ=" & integer'image(g) & " bajt " & integer'image(n_rx(g))); writeline(output, l);
            bl_petla <= bl_petla + 1;
          end if;
          n_rx(g) <= n_rx(g) + 1;
        end if;
      end loop;
    end if;
  end process;

  u_rx0 : entity work.uart_rx generic map (CLK_HZ => 50_000_000, BAUD => 500_000, PARZ => 0)
    port map (clk => clk, rst => rst, rx => linia, dane => d0, wazne => w0, blad_ramki => r0, blad_parz => p0);
  u_rx2 : entity work.uart_rx generic map (CLK_HZ => 50_000_000, BAUD => 500_000, PARZ => 2)
    port map (clk => clk, rst => rst, rx => linia_p, dane => d2, wazne => w2, blad_ramki => r2, blad_parz => p2);

  process (clk)
  begin
    if rising_edge(clk) then
      if w0 = '1' then
        log_r0(n_w0) <= r0;
        n_w0  <= n_w0 + 1;
        ost0  <= d0;
        ostr0 <= r0;
      end if;
      if w2 = '1' then
        n_w2  <= n_w2 + 1;
        ost2  <= d2;
        ostp2 <= p2;
      end if;
    end if;
  end process;

  process
    variable l      : line;
    variable s1, s2 : positive := 7;
    variable r      : real;
    variable errors, k, n_ok, dmin, dmax : integer := 0;
    variable t0     : time;
    variable dl     : licz_t;
    variable b      : std_logic_vector(7 downto 0);
    variable okres  : time;

    procedure nadaj(bity : std_logic_vector; signal lin : out std_logic; okr : time) is
    begin
      for j in bity'reverse_range loop                         -- od najmłodszego
        lin <= bity(j);
        wait for okr;
      end loop;
    end procedure;
    impure function los8 return std_logic_vector is
    begin
      uniform(s1, s2, r);
      return std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
    end function;
  begin
    wait for 100 ns;
    rst <= '0';
    -- 1. pętla
    for g in 0 to 2 loop
      for i in 0 to 39 loop
        wait until falling_edge(clk);
        if i = 0 then b := x"00"; elsif i = 1 then b := x"FF"; else b := los8; end if;
        bajt <= b;
        wzor(g, i) <= b;
        start(g) <= '1';
        t0 := now;
        wait until falling_edge(clk);
        start(g) <= '0';
        wait until gotowy(g) = '1';
        dl(g) := (now - t0) / 20 ns;
      end loop;
    end loop;
    wait for 40 us;
    write(l, "petla: odebrano " & integer'image(n_rx(0)) & " / " & integer'image(n_rx(1)) & " / "
          & integer'image(n_rx(2)) & "; ramka " & integer'image(dl(0)) & ", " & integer'image(dl(1)) & ", "
          & integer'image(dl(2)) & " taktow");
    writeline(output, l);
    if n_rx(0) /= 40 or n_rx(1) /= 40 or n_rx(2) /= 40 or bl_petla /= 0 then errors := errors + 1; end if;
    if dl(0) < 4338 or dl(0) > 4344 or dl(1) < 4772 or dl(1) > 4778 or dl(2) < 4772 or dl(2) > 4778 then
      errors := errors + 1;
    end if;

    -- 2. tolerancja
    dmin := -5; dmax := -5;
    for znak in 0 to 1 loop
      for d in 0 to 12 loop                                    -- d·5 promili
        n_ok := 0;
        if znak = 0 then okres := BIT_T * (1.0 + real(d) * 0.005);
        else okres := BIT_T * (1.0 - real(d) * 0.005); end if;
        for i in 0 to 19 loop
          b := los8;
          k := n_w0;
          nadaj('1' & b & '0', linia, okres);
          wait for okres;
          if n_w0 = k + 1 and ost0 = b and ostr0 = '0' then n_ok := n_ok + 1; end if;
        end loop;
        if znak = 0 and n_ok = 20 and dmax = d * 5 - 5 then dmax := d * 5; end if;
        if znak = 1 and n_ok = 20 and dmin = d * 5 - 5 then dmin := d * 5; end if;
      end loop;
    end loop;
    write(l, "tolerancja odbiornika 8N1, 16 probek na bit: od -" & integer'image(dmin) & " do +"
          & integer'image(dmax) & " promili bez bledow");
    writeline(output, l);
    if dmin < 35 or dmax < 35 then errors := errors + 1; end if;

    -- 3. zakłócenia
    wait for 5 * BIT_T;
    k := n_w0;
    n_ok := 0;
    for i in 0 to 19 loop
      b := los8;
      linia <= '0'; wait for BIT_T / 4; linia <= '1'; wait for 2 * BIT_T;      -- impuls w spoczynku
      linia <= '0'; wait for BIT_T;                                           -- start
      for j in 0 to 7 loop
        linia <= b(j);
        if j = 3 then
          wait for BIT_T * 15 / 32; linia <= not b(j); wait for BIT_T / 16; linia <= b(j); wait for BIT_T * 15 / 32;
        else
          wait for BIT_T;
        end if;
      end loop;
      linia <= '1'; wait for 2 * BIT_T;
      if ost0 = b and ostr0 = '0' then n_ok := n_ok + 1; end if;
    end loop;
    write(l, "zaklocenia: " & integer'image(n_ok) & " / 20 bajtow poprawnych, odebranych " & integer'image(n_w0 - k));
    writeline(output, l);
    if n_ok /= 20 or n_w0 - k /= 20 then errors := errors + 1; end if;

    -- 4. błąd ramki i parzystości
    k := n_w0;
    nadaj("0" & x"A5" & "0", linia, BIT_T);                   -- bit stopu = 0
    linia <= '1'; wait for 3 * BIT_T;
    if n_w0 < k + 1 or log_r0(k) /= '1' then
      write(l, string'("brak bledu ramki")); writeline(output, l); errors := errors + 1;
    end if;
    k := n_w2;
    nadaj("1" & "0" & x"5A" & "0", linia_p, BIT_T);           -- poprawna parzystość
    linia_p <= '1'; wait for 2 * BIT_T;
    if n_w2 /= k + 1 or ostp2 = '1' or ost2 /= x"5A" then errors := errors + 1; end if;
    nadaj("1" & "1" & x"5A" & "0", linia_p, BIT_T);           -- zły bit parzystości
    linia_p <= '1'; wait for 2 * BIT_T;
    if n_w2 /= k + 2 or ostp2 /= '1' then
      write(l, string'("brak bledu parzystosci")); writeline(output, l); errors := errors + 1;
    end if;

    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

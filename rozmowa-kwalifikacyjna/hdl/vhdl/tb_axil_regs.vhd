-- Testbench zadania 10 (VHDL): zapisy z różną kolejnością kanałów AW i W, maska bajtów, opóźnione bready i rready,
-- model 4 rejestrów, potem 200 losowych operacji.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_axil_regs is
end entity;

architecture sim of tb_axil_regs is
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal awaddr  : std_logic_vector(3 downto 0) := (others => '0');
  signal awvalid : std_logic := '0';
  signal awready : std_logic;
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrb   : std_logic_vector(3 downto 0) := (others => '0');
  signal wvalid  : std_logic := '0';
  signal wready  : std_logic;
  signal bresp   : std_logic_vector(1 downto 0);
  signal bvalid  : std_logic;
  signal bready  : std_logic := '0';
  signal araddr  : std_logic_vector(3 downto 0) := (others => '0');
  signal arvalid : std_logic := '0';
  signal arready : std_logic;
  signal rdata   : std_logic_vector(31 downto 0);
  signal rresp   : std_logic_vector(1 downto 0);
  signal rvalid  : std_logic;
  signal rready  : std_logic := '0';
  signal reg0, reg1, reg2, reg3 : std_logic_vector(31 downto 0);

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.axil_regs
    port map (clk => clk, rst => rst, awaddr => awaddr, awvalid => awvalid, awready => awready, wdata => wdata,
              wstrb => wstrb, wvalid => wvalid, wready => wready, bresp => bresp, bvalid => bvalid, bready => bready,
              araddr => araddr, arvalid => arvalid, arready => arready, rdata => rdata, rresp => rresp,
              rvalid => rvalid, rready => rready, reg0 => reg0, reg1 => reg1, reg2 => reg2, reg3 => reg3);

  process
    type regs_t is array (0 to 3) of std_logic_vector(31 downto 0);
    variable model               : regs_t := (others => (others => '0'));
    variable errors, n_wr, n_rd  : natural := 0;
    variable s1, s2              : positive := 8;
    variable r                   : real;

    impure function rnd(n : positive) return natural is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(n)));
    end function;

    procedure axi_write(idx : natural; d : std_logic_vector(31 downto 0); s : std_logic_vector(3 downto 0);
                        d_aw, d_w, d_b : natural) is
      variable cyc              : natural := 0;
      variable aw_done, w_done  : boolean := false;
      variable seen, done       : boolean := false;
    begin
      awaddr <= std_logic_vector(to_unsigned(idx * 4, 4)); wdata <= d; wstrb <= s;
      while not (aw_done and w_done) loop
        wait until falling_edge(clk);
        if not aw_done and cyc >= d_aw then awvalid <= '1'; else awvalid <= '0'; end if;
        if not w_done and cyc >= d_w then wvalid <= '1'; else wvalid <= '0'; end if;
        cyc := cyc + 1;
        wait until rising_edge(clk);
        if awvalid = '1' and awready = '1' then aw_done := true; end if;
        if wvalid = '1' and wready = '1' then w_done := true; end if;
      end loop;
      wait until falling_edge(clk);
      awvalid <= '0'; wvalid <= '0';
      cyc := 0;
      while not done loop
        if cyc >= d_b then bready <= '1'; else bready <= '0'; end if;
        cyc := cyc + 1;
        wait until rising_edge(clk);
        if bvalid = '1' then seen := true;
        elsif seen then say("bvalid zniknelo bez bready"); errors := errors + 1; end if;
        if bvalid = '1' and bready = '1' then
          if bresp /= "00" then errors := errors + 1; end if;
          done := true;
        elsif cyc > 50 then
          say("brak odpowiedzi B"); errors := errors + 1; done := true;
        end if;
        wait until falling_edge(clk);
      end loop;
      bready <= '0';
      for b in 0 to 3 loop
        if s(b) = '1' then model(idx)(8 * b + 7 downto 8 * b) := d(8 * b + 7 downto 8 * b); end if;
      end loop;
      n_wr := n_wr + 1;
    end procedure;

    procedure axi_read(idx : natural; d_r : natural) is
      variable cyc  : natural := 0;
      variable done : boolean := false;
    begin
      wait until falling_edge(clk);
      araddr <= std_logic_vector(to_unsigned(idx * 4, 4)); arvalid <= '1';
      wait until rising_edge(clk);
      while arready = '0' loop wait until rising_edge(clk); end loop;
      wait until falling_edge(clk);
      arvalid <= '0';
      while not done loop
        if cyc >= d_r then rready <= '1'; else rready <= '0'; end if;
        cyc := cyc + 1;
        wait until rising_edge(clk);
        if rvalid = '1' and rready = '1' then
          if rdata /= model(idx) or rresp /= "00" then
            say("rejestr " & integer'image(idx) & ": zly odczyt"); errors := errors + 1;
          end if;
          n_rd := n_rd + 1;
          done := true;
        elsif cyc > 50 then
          say("brak odpowiedzi R"); errors := errors + 1; done := true;
        end if;
        wait until falling_edge(clk);
      end loop;
      rready <= '0';
    end procedure;

    variable v_idx : natural;
    variable v_d   : std_logic_vector(31 downto 0);
    variable v_s   : std_logic_vector(3 downto 0);
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    axi_write(0, x"11111111", "1111", 0, 3, 0);     -- AW przed W
    axi_write(1, x"22222222", "1111", 4, 0, 2);     -- W przed AW
    axi_write(2, x"33333333", "1111", 0, 0, 5);     -- razem
    axi_write(3, x"DEADBEEF", "1111", 1, 1, 0);
    axi_write(3, x"0000AA00", "0010", 0, 0, 1);     -- jeden bajt
    axi_write(0, x"FFFF0000", "1100", 2, 0, 0);
    for i in 0 to 3 loop axi_read(i, i); end loop;
    if reg3 /= x"DEADAABF" or reg0 /= x"FFFF1111" then say("zle wyjscia rejestrow"); errors := errors + 1; end if;
    for i in 0 to 199 loop
      v_idx := rnd(4);
      v_d   := std_logic_vector(to_unsigned(rnd(65536), 16)) & std_logic_vector(to_unsigned(rnd(65536), 16));
      v_s   := std_logic_vector(to_unsigned(rnd(16), 4));
      if rnd(2) = 1 then
        axi_write(v_idx, v_d, v_s, rnd(3), rnd(3), rnd(3));
      else
        axi_read(v_idx, rnd(3));
      end if;
    end loop;
    say("zapisow " & integer'image(n_wr) & ", odczytow " & integer'image(n_rd));
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;

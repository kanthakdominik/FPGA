-- Testbench axil_regs: procedury mastera AXI4-Lite z losową kolejnością AW/W, losowymi opóźnieniami
-- i wstrzymaniami BREADY/RREADY; model rejestrów w zmiennych testbencha. Sprawdzane: wartości po resecie,
-- każdy odczyt (dane i RRESP), BRESP, stabilność B i R przy wstrzymaniu, irq po każdej operacji.
-- Pokrycie: zapis i odczyt każdego adresu, SLVERR, kasowanie W1C, irq = 1, częściowy WSTRB,
-- kolejność AW przed W i W przed AW.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_axil_regs is
end entity tb_axil_regs;

architecture sim of tb_axil_regs is
  signal clk                                     : std_logic := '0';
  signal done                                    : boolean   := false;
  signal rst                                     : std_logic := '1';
  signal s_awvalid, s_wvalid, s_bready           : std_logic := '0';
  signal s_arvalid, s_rready                     : std_logic := '0';
  signal s_awaddr, s_araddr                      : std_logic_vector(4 downto 0)  := (others => '0');
  signal s_wdata                                 : std_logic_vector(31 downto 0) := (others => '0');
  signal s_wstrb                                 : std_logic_vector(3 downto 0)  := (others => '0');
  signal s_awready, s_wready, s_bvalid           : std_logic;
  signal s_arready, s_rvalid, irq                : std_logic;
  signal s_bresp, s_rresp                        : std_logic_vector(1 downto 0);
  signal s_rdata                                 : std_logic_vector(31 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.axil_regs
    port map (clk => clk, rst => rst, s_awvalid => s_awvalid, s_awready => s_awready, s_awaddr => s_awaddr,
              s_wvalid => s_wvalid, s_wready => s_wready, s_wdata => s_wdata, s_wstrb => s_wstrb,
              s_bvalid => s_bvalid, s_bready => s_bready, s_bresp => s_bresp, s_arvalid => s_arvalid,
              s_arready => s_arready, s_araddr => s_araddr, s_rvalid => s_rvalid, s_rready => s_rready,
              s_rdata => s_rdata, s_rresp => s_rresp, irq => irq);

  stim : process
    type count_t is array (0 to 7) of natural;
    -- model rejestrów
    variable m_op                       : natural range 0 to 7 := 0;
    variable m_irq_en, m_err            : std_logic := '0';
    variable m_opa, m_opb               : natural range 0 to 255 := 0;
    variable m_scratch                  : std_logic_vector(31 downto 0) := (others => '0');
    -- statystyki
    variable errors                     : natural := 0;
    variable n_wr, n_rd                 : count_t := (others => 0);
    variable n_slverr_w, n_slverr_r     : natural := 0;
    variable n_w1c, n_irq, n_part       : natural := 0;
    variable n_aw_first, n_w_first      : natural := 0;
    variable seed1, seed2               : positive := 11;
    variable idx                        : natural;
    variable d                          : std_logic_vector(31 downto 0);
    variable strb                       : std_logic_vector(3 downto 0);
    variable l                          : line;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    impure function rnd_word return std_logic_vector is
    begin
      return std_logic_vector(to_unsigned(rnd(65536), 16)) & std_logic_vector(to_unsigned(rnd(65536), 16));
    end function rnd_word;

    procedure fail(msg : string) is
    begin
      errors := errors + 1;
      if errors <= 10 then
        report msg severity warning;
      end if;
    end procedure fail;

    impure function m_result return std_logic_vector is
      variable r, c, e, z : natural := 0;
      constant SH         : natural := m_opb mod 8;
    begin
      case m_op is
        when 0 =>
          r := (m_opa + m_opb) mod 256;
          c := 1 when m_opa + m_opb > 255 else 0;
        when 1 =>
          r := (m_opa + 256 - m_opb) mod 256;
          c := 1 when m_opa < m_opb else 0;
        when 2 => r := to_integer(to_unsigned(m_opa, 8) and to_unsigned(m_opb, 8));
        when 3 => r := to_integer(to_unsigned(m_opa, 8) or to_unsigned(m_opb, 8));
        when 4 => r := to_integer(to_unsigned(m_opa, 8) xor to_unsigned(m_opb, 8));
        when 5 => r := (m_opa * 2 ** SH) mod 256;
        when 6 => r := m_opa / 2 ** SH;
        when others => e := 1;
      end case;
      z := 1 when r = 0 else 0;
      return std_logic_vector(to_unsigned(e * 4 + z * 2 + c, 24)) & std_logic_vector(to_unsigned(r, 8));
    end function m_result;

    impure function m_read(i : natural) return std_logic_vector is
    begin
      case i is
        when 0 => return x"414C5531";
        when 1 => return (31 downto 9 => '0') & m_irq_en & "00000" & std_logic_vector(to_unsigned(m_op, 3));
        when 2 => return std_logic_vector(to_unsigned(m_opa, 32));
        when 3 => return std_logic_vector(to_unsigned(m_opb, 32));
        when 4 => return m_result;
        when 5 => return (31 downto 1 => '0') & m_err;
        when 6 => return m_scratch;
        when others => return x"00000000";
      end case;
    end function m_read;

    function strb_merge(old, dd : std_logic_vector(31 downto 0); st : std_logic_vector(3 downto 0))
      return std_logic_vector is
      variable v : std_logic_vector(31 downto 0) := old;
    begin
      for i in 0 to 3 loop
        if st(i) = '1' then
          v(8 * i + 7 downto 8 * i) := dd(8 * i + 7 downto 8 * i);
        end if;
      end loop;
      return v;
    end function strb_merge;

    procedure m_write(i : natural; dd : std_logic_vector(31 downto 0); st : std_logic_vector(3 downto 0)) is
      variable v : std_logic_vector(31 downto 0);
    begin
      case i is
        when 1 =>
          v        := strb_merge(m_read(1), dd, st);
          m_op     := to_integer(unsigned(v(2 downto 0)));
          m_irq_en := v(8);
          if m_op = 7 then
            m_err := '1';
          end if;
        when 2 =>
          v     := strb_merge(m_read(2), dd, st);
          m_opa := to_integer(unsigned(v(7 downto 0)));
        when 3 =>
          v     := strb_merge(m_read(3), dd, st);
          m_opb := to_integer(unsigned(v(7 downto 0)));
        when 5 =>
          if st(0) = '1' and dd(0) = '1' then
            m_err := '0';
          end if;
        when 6 => m_scratch := strb_merge(m_scratch, dd, st);
        when others => null;
      end case;
    end procedure m_write;

    -- procedury mastera
    procedure axi_write(addr : natural; dd : std_logic_vector(31 downto 0); st : std_logic_vector(3 downto 0);
                        resp : out std_logic_vector(1 downto 0)) is
      variable mode           : natural := rnd(3);
      variable lag            : natural := 1 + rnd(3);
      variable t              : natural := 0;
      variable aw_ok, w_ok    : boolean := false;
      variable stalled, got   : boolean := false;
      variable held           : std_logic_vector(1 downto 0);
    begin
      if mode = 1 then n_aw_first := n_aw_first + 1; end if;
      if mode = 2 then n_w_first := n_w_first + 1; end if;
      while not (aw_ok and w_ok) loop
        wait until falling_edge(clk);
        s_awvalid <= '1' when not aw_ok and (mode /= 2 or t >= lag) else '0';
        s_awaddr  <= std_logic_vector(to_unsigned(addr, 5));
        s_wvalid  <= '1' when not w_ok and (mode /= 1 or t >= lag) else '0';
        s_wdata   <= dd;
        s_wstrb   <= st;
        wait for 1 ns;
        if s_awvalid = '1' and s_awready = '1' then aw_ok := true; end if;
        if s_wvalid = '1' and s_wready = '1' then w_ok := true; end if;
        t := t + 1;
      end loop;
      wait until falling_edge(clk);
      s_awvalid <= '0';
      s_wvalid  <= '0';
      while not got loop
        s_bready <= '1' when rnd(3) /= 0 else '0';
        wait for 1 ns;
        if stalled and (s_bvalid /= '1' or s_bresp /= held) then
          fail("B zmienione podczas wstrzymania");
        end if;
        if s_bvalid = '1' and s_bready = '1' then
          resp := s_bresp;
          got  := true;
        else
          stalled := s_bvalid = '1';
          held    := s_bresp;
          wait until falling_edge(clk);
        end if;
      end loop;
      wait until falling_edge(clk);
      s_bready <= '0';
    end procedure axi_write;

    procedure axi_read(addr : natural; dd : out std_logic_vector(31 downto 0);
                       resp : out std_logic_vector(1 downto 0)) is
      variable stalled, got : boolean := false;
      variable held         : std_logic_vector(33 downto 0);
    begin
      wait until falling_edge(clk);
      s_arvalid <= '1';
      s_araddr  <= std_logic_vector(to_unsigned(addr, 5));
      wait for 1 ns;
      while s_arready /= '1' loop
        wait until falling_edge(clk);
        wait for 1 ns;
      end loop;
      wait until falling_edge(clk);
      s_arvalid <= '0';
      while not got loop
        s_rready <= '1' when rnd(3) /= 0 else '0';
        wait for 1 ns;
        if stalled and (s_rvalid /= '1' or s_rresp & s_rdata /= held) then
          fail("R zmienione podczas wstrzymania");
        end if;
        if s_rvalid = '1' and s_rready = '1' then
          dd   := s_rdata;
          resp := s_rresp;
          got  := true;
        else
          stalled := s_rvalid = '1';
          held    := s_rresp & s_rdata;
          wait until falling_edge(clk);
        end if;
      end loop;
      wait until falling_edge(clk);
      s_rready <= '0';
    end procedure axi_read;

    procedure check_read(i : natural) is
      variable rd   : std_logic_vector(31 downto 0);
      variable resp : std_logic_vector(1 downto 0);
    begin
      axi_read(i * 4, rd, resp);
      n_rd(i) := n_rd(i) + 1;
      if i = 7 then n_slverr_r := n_slverr_r + 1; end if;
      if (i = 7 and resp /= "10") or (i /= 7 and resp /= "00") then
        fail("RRESP=" & to_string(resp) & " dla adresu " & integer'image(i * 4));
      end if;
      if rd /= m_read(i) then
        fail("odczyt " & integer'image(i * 4) & ": " & to_hstring(rd) & ", oczekiwano " & to_hstring(m_read(i)));
      end if;
    end procedure check_read;

    procedure do_write(i : natural; dd : std_logic_vector(31 downto 0); st : std_logic_vector(3 downto 0)) is
      variable resp : std_logic_vector(1 downto 0);
    begin
      axi_write(i * 4, dd, st, resp);
      n_wr(i) := n_wr(i) + 1;
      if i = 7 then n_slverr_w := n_slverr_w + 1; end if;
      if i = 5 and st(0) = '1' and dd(0) = '1' and m_err = '1' then n_w1c := n_w1c + 1; end if;
      if i = 6 and st /= "1111" and st /= "0000" then n_part := n_part + 1; end if;
      m_write(i, dd, st);
      if (i = 7 and resp /= "10") or (i /= 7 and resp /= "00") then
        fail("BRESP=" & to_string(resp) & " dla adresu " & integer'image(i * 4));
      end if;
    end procedure do_write;
  begin
    for k in 1 to 3 loop
      wait until falling_edge(clk);
    end loop;
    rst <= '0';
    -- 1. wartości po resecie
    for i in 0 to 7 loop
      check_read(i);
    end loop;
    -- 2. operacje losowe
    for n in 0 to 1499 loop
      idx := rnd(8);
      d   := rnd_word;
      if rnd(4) = 0 then
        strb := std_logic_vector(to_unsigned(rnd(16), 4));
      else
        strb := "1111";
      end if;
      if idx = 1 and rnd(4) /= 0 then
        d(2 downto 0) := std_logic_vector(to_unsigned(rnd(7), 3));    -- OP = 7 rzadziej
      end if;
      if rnd(2) = 1 then
        do_write(idx, d, strb);
      else
        check_read(idx);
      end if;
      if irq /= (m_err and m_irq_en) then
        fail("irq niezgodne z modelem");
      end if;
      if irq = '1' then
        n_irq := n_irq + 1;
      end if;
    end loop;

    for i in 0 to 7 loop
      if n_wr(i) = 0 or n_rd(i) = 0 then
        fail("pokrycie: adres " & integer'image(i * 4));
      end if;
    end loop;
    if n_slverr_w = 0 or n_slverr_r = 0 or n_w1c = 0 or n_irq = 0 or n_part = 0 or n_aw_first = 0 or
       n_w_first = 0 then
      fail("pokrycie: slverr " & integer'image(n_slverr_w) & "/" & integer'image(n_slverr_r) &
           " w1c " & integer'image(n_w1c) & " irq " & integer'image(n_irq) & " wstrb " & integer'image(n_part));
    end if;
    write(l, "zapisow kasujacych ERR: " & integer'image(n_w1c) & ", operacji z irq: " & integer'image(n_irq));
    writeline(output, l);
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;

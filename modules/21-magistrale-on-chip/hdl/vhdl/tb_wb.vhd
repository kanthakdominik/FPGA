-- Testbench 21.04: Wishbone B4 potokowy - master z kolejką żądań -> wb_dekoder -> wb_ram (STALL co 3. takt)
-- i wb_rejestry. Żądania jednego cyklu CYC idą bez czekania na ACK; odpowiedzi (ACK/ERR, dane) sprawdzane
-- w kolejności żądań. Sprawdzane: 64 zapisy i 64 odczyty w potoku, przepustowość przy STALL, rejestry,
-- ERR z rejestrów i z dekodera, 20 cykli z losową mieszanką.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_wb is
end entity tb_wb;

architecture sim of tb_wb is
  type b_t   is array (0 to 127) of std_logic;
  type a_t   is array (0 to 127) of std_logic_vector(9 downto 0);
  type d_t   is array (0 to 127) of std_logic_vector(31 downto 0);
  type s_t   is array (0 to 127) of std_logic_vector(3 downto 0);
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal cyc, stb, we, ack, err, stall : std_logic := '0';
  signal adr   : std_logic_vector(9 downto 0) := (others => '0');
  signal dat_w, dat_r : std_logic_vector(31 downto 0) := (others => '0');
  signal sel   : std_logic_vector(3 downto 0) := "0000";
  signal s0_stb, s0_ack, s0_stall, s1_stb, s1_ack, s1_err, s1_stall, s_cyc, s_we, irq : std_logic;
  signal s0_adr : std_logic_vector(8 downto 0);
  signal s1_adr, s_sel : std_logic_vector(3 downto 0);
  signal s0_dat, s1_dat, s_dat, ster : std_logic_vector(31 downto 0);
  -- kolejka żądań i oczekiwane odpowiedzi (wypełniane przez proces główny)
  signal q_we, o_err : b_t;
  signal q_adr : a_t;
  signal o_dat : d_t;
  signal nq, n_odp, bl_odp : integer := 0;
  signal zeruj : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_dek : entity work.wb_dekoder
    port map (clk => clk, rst => rst, m_cyc => cyc, m_stb => stb, m_we => we, m_adr => adr, m_dat_i => dat_w,
              m_sel => sel, m_dat_o => dat_r, m_ack => ack, m_err => err, m_stall => stall,
              s0_stb => s0_stb, s0_adr => s0_adr, s0_dat_o => s0_dat, s0_ack => s0_ack, s0_stall => s0_stall,
              s1_stb => s1_stb, s1_adr => s1_adr, s1_dat_o => s1_dat, s1_ack => s1_ack, s1_err => s1_err,
              s1_stall => s1_stall, s_cyc => s_cyc, s_we => s_we, s_dat_i => s_dat, s_sel => s_sel);
  u_ram : entity work.wb_ram generic map (AW => 9, CO => 3)
    port map (clk => clk, rst => rst, cyc => s_cyc, stb => s0_stb, we => s_we, adr => s0_adr, dat_i => s_dat,
              sel => s_sel, dat_o => s0_dat, ack => s0_ack, stall => s0_stall);
  u_rej : entity work.wb_rejestry
    port map (clk => clk, rst => rst, cyc => s_cyc, stb => s1_stb, we => s_we, adr => s1_adr, dat_i => s_dat,
              sel => s_sel, dat_o => s1_dat, ack => s1_ack, err => s1_err, stall => s1_stall,
              ster => ster, stan => x"00000000", zdarz => x"00", irq => irq);

  -- monitor odpowiedzi
  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) then
      if zeruj then
        n_odp <= 0;
      elsif cyc = '1' and (ack = '1' or err = '1') then
        if (ack and err) = '1' or n_odp >= nq or err /= o_err(n_odp)
           or (q_we(n_odp) = '0' and ack = '1' and dat_r /= o_dat(n_odp)) then
          if bl_odp < 10 then
            write(l, "odpowiedz " & integer'image(n_odp) & ": ack " & std_logic'image(ack) & " err "
                  & std_logic'image(err) & " dane " & to_hstring(dat_r));
            writeline(output, l);
          end if;
          bl_odp <= bl_odp + 1;
        end if;
        n_odp <= n_odp + 1;
      end if;
    end if;
  end process;

  process
    type ram_t is array (0 to 511) of std_logic_vector(31 downto 0);
    variable ram_m  : ram_t := (others => (others => '0'));
    variable skr_m  : std_logic_vector(31 downto 0) := (others => '0');
    variable s1, s2 : positive := 31;
    variable r      : real;
    variable n, errors, a : integer := 0;
    variable vwe, verr : b_t;
    variable vadr   : a_t;
    variable vdat, vod : d_t;
    variable vsel   : s_t;
    variable t0, t1 : time;
    variable l      : line;
    variable w      : std_logic;

    impure function los(zakres : positive) return integer is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(zakres)));
    end function;
    impure function los32 return std_logic_vector is
    begin
      return std_logic_vector(to_unsigned(los(65536), 16)) & std_logic_vector(to_unsigned(los(65536), 16));
    end function;
    function maskuj(st, nw : std_logic_vector(31 downto 0); s : std_logic_vector(3 downto 0)) return std_logic_vector is
      variable m : std_logic_vector(31 downto 0);
    begin
      for b in 0 to 3 loop m(b * 8 + 7 downto b * 8) := (others => s(b)); end loop;
      return (st and not m) or (nw and m);
    end function;

    procedure dodaj(wz : std_logic; ad : std_logic_vector(9 downto 0); d : std_logic_vector(31 downto 0);
                    s : std_logic_vector(3 downto 0)) is
      variable i : integer;
    begin
      vwe(n) := wz; vadr(n) := ad; vdat(n) := d; vsel(n) := s; verr(n) := '0'; vod(n) := (others => '0');
      if ad(9) = '0' then
        i := to_integer(unsigned(ad(8 downto 0)));
        if wz = '1' then ram_m(i) := maskuj(ram_m(i), d, s); end if;
        vod(n) := ram_m(i);
      elsif ad(9 downto 4) = "100000" and unsigned(ad(3 downto 0)) <= 5 then
        if ad(3 downto 0) = "0101" and wz = '1' then skr_m := maskuj(skr_m, d, s); end if;
        if ad(3 downto 0) = "0000" then vod(n) := x"21020001";
        elsif ad(3 downto 0) = "0101" then vod(n) := skr_m;
        else verr(n) := '1'; end if;
      else
        verr(n) := '1';
      end if;
      n := n + 1;
    end procedure;

    procedure cykl is
    begin
      q_we <= vwe; q_adr <= vadr; o_err <= verr; o_dat <= vod; nq <= n;
      zeruj <= true;
      wait until falling_edge(clk);
      zeruj <= false;
      cyc <= '1';
      for k in 0 to n - 1 loop
        stb <= '1'; we <= vwe(k); adr <= vadr(k); dat_w <= vdat(k); sel <= vsel(k);
        loop
          wait until rising_edge(clk);
          exit when stall = '0';
        end loop;
        if k = 0 then t0 := now; end if;
        t1 := now;
        wait until falling_edge(clk);
      end loop;
      stb <= '0';
      while n_odp < n loop wait until falling_edge(clk); end loop;
      cyc <= '0';
      wait until falling_edge(clk);
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    n := 0;
    for i in 0 to 63 loop dodaj('1', std_logic_vector(to_unsigned(i * 7, 10)), los32, "1111"); end loop;
    cykl;
    write(l, "zapis 64 slow w potoku: " & integer'image((t1 - t0) / 10 ns + 1) & " taktow (STALL co 3. takt)");
    writeline(output, l);
    if (t1 - t0) / 10 ns + 1 > 97 then errors := errors + 1; end if;
    n := 0;
    for i in 0 to 63 loop dodaj('0', std_logic_vector(to_unsigned(i * 7, 10)), x"00000000", "1111"); end loop;
    cykl;
    n := 0;
    dodaj('0', "1000000000", x"00000000", "1111");            -- ID
    dodaj('1', "1000000101", x"DEADBEEF", "1111");
    dodaj('1', "1000000101", x"00001100", "0010");
    dodaj('0', "1000000101", x"00000000", "1111");
    dodaj('0', "1000001010", x"00000000", "1111");            -- ERR z rejestrów
    dodaj('0', "1100000000", x"00000000", "1111");            -- ERR z dekodera
    dodaj('0', "0000000000", x"00000000", "1111");
    cykl;
    for rr in 1 to 20 loop
      n := 0;
      for i in 1 to 5 + los(20) loop
        case los(4) is
          when 0 => a := 16#200#;
          when 1 => a := 16#205#;
          when 2 => a := 16#210# + los(64);
          when others => a := los(512);
        end case;
        if a = 16#200# then w := '0'; else w := '1' when los(2) = 1 else '0'; end if;
        dodaj(w, std_logic_vector(to_unsigned(a, 10)), los32, std_logic_vector(to_unsigned(los(16), 4)));
      end loop;
      cykl;
    end loop;
    write(l, string'("Wishbone: zapisy i odczyty w potoku, rejestry, ERR z rejestrow i z dekodera, 20 cykli losowych"));
    writeline(output, l);
    errors := errors + bl_odp;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

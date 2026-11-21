-- Testbench 24.02: adv7513_konfig z modelem odbiornika I2C (adres 0x39): rejestracja zapisów, ACK, pomiar czasów
-- magistrali (okres i stany SCL, t_HD;STA, t_SU;STO, t_BUF). Przebiegi: seria po resecie, seria cykliczna,
-- odbiornik pod innym adresem (NACK -> blad), seria na żądanie (start).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_adv is
end entity tb_adv;

architecture sim of tb_adv is
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal start  : std_logic := '0';
  signal zajety, gotowe, blad, scl_o, sda_o : std_logic;
  signal s_sda  : std_logic := '1';
  signal scl, sda : std_logic;
  signal fin    : boolean := false;
  signal adr_modelu : std_logic_vector(6 downto 0) := "0111001";
  signal n_zap, n_start, n_stop, bl_tab : natural := 0;
  signal min_h, min_l, min_hdsta, min_susto, min_buf, min_okr : time := 1 sec;

  type tab_t is array (0 to 16) of std_logic_vector(15 downto 0);
  constant OCZ : tab_t := (x"4110", x"9803", x"9AE0", x"9C30", x"9D61", x"A2A4", x"A3A4", x"E0D0", x"F900",
                           x"1500", x"1630", x"1700", x"1846", x"AF16", x"BA60", x"D6C0", x"96F6");
begin
  clk <= not clk after 125 ns when not fin else clk;          -- 4 MHz
  scl <= scl_o;
  sda <= sda_o and s_sda;

  dut : entity work.adv7513_konfig
    generic map (F_CLK => 4000000, F_I2C => 100000, OKRES => 30000)
    port map (clk => clk, rst => rst, start => start, zajety => zajety, gotowe => gotowe, blad => blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => sda);

  -- model odbiornika
  process (scl, sda)
    variable akt, pierwsze : boolean := false;
    variable bity, nr_b : natural := 0;
    variable bajt, rej : std_logic_vector(7 downto 0) := x"00";
    variable t_scl_g, t_scl_d, t_start, t_g_pop : time := 0 ns;
    variable t_stop : time := 0 ns;
    variable byl_stop : boolean := false;
    variable zap : natural := 0;
  begin
    if rst = '0' then
      if sda'event and sda = '0' and scl = '1' then                -- START
        n_start <= n_start + 1;
        if byl_stop and now - t_stop < min_buf then min_buf <= now - t_stop; end if;
        t_start := now; akt := true; pierwsze := true; bity := 0; nr_b := 0;
      end if;
      if sda'event and sda = '1' and scl = '1' then                -- STOP
        n_stop <= n_stop + 1;
        t_stop := now; byl_stop := true;
        if now - t_scl_g < min_susto then min_susto <= now - t_scl_g; end if;
        akt := false;
      end if;
      if scl'event and scl = '1' then
        if t_scl_d > 0 ns and not pierwsze and now - t_scl_d < min_l then min_l <= now - t_scl_d; end if;
        if t_g_pop > 0 ns and now - t_g_pop < min_okr then min_okr <= now - t_g_pop; end if;
        t_g_pop := now; t_scl_g := now;
        if akt and bity < 8 then bajt := bajt(6 downto 0) & sda; bity := bity + 1; end if;
      end if;
      if scl'event and scl = '0' then
        if pierwsze then
          if now - t_start < min_hdsta then min_hdsta <= now - t_start; end if;
          pierwsze := false;
        elsif now - t_scl_g < min_h then
          min_h <= now - t_scl_g;
        end if;
        t_scl_d := now;
        if akt and bity = 8 then                                   -- po 8 bitach: decyzja o ACK
          bity := 9;
          if nr_b = 0 then
            if bajt = adr_modelu & '0' then s_sda <= '0'; else akt := false; end if;
          elsif nr_b = 1 then
            rej := bajt; s_sda <= '0';
          else
            if zap < 34 and rej & bajt /= OCZ(zap mod 17) then bl_tab <= bl_tab + 1; end if;
            zap := zap + 1;
            n_zap <= zap;
            s_sda <= '0';
          end if;
        elsif bity = 9 then                                        -- koniec taktu ACK
          s_sda <= '1'; bity := 0; nr_b := nr_b + 1;
        end if;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable t0 : time;
    variable n_przed, errors : natural := 0;
    procedure seria is
    begin
      wait until zajety = '1';
      wait until zajety = '0';
      wait for 1 ns;
    end procedure;
  begin
    wait for 1 us;
    wait until rising_edge(clk);
    rst <= '0';
    t0 := now;
    seria;
    write(l, "seria po resecie: " & integer'image(n_zap) & " zapisow, " & integer'image((now - t0) / 1 us) & " us, gotowe = "
          & std_logic'image(gotowe) & ", blad = " & std_logic'image(blad));
    writeline(output, l);
    if n_zap /= 17 or gotowe /= '1' or blad /= '0' then errors := errors + 1; end if;
    seria;
    write(l, "seria cykliczna: razem " & integer'image(n_zap) & " zapisow");
    writeline(output, l);
    if n_zap /= 34 or gotowe /= '1' or blad /= '0' then errors := errors + 1; end if;
    adr_modelu <= "0111101";
    n_przed := n_zap;
    seria;
    write(l, "odbiornik pod adresem 0x3D: zapisow " & integer'image(n_zap - n_przed) & ", gotowe = "
          & std_logic'image(gotowe) & ", blad = " & std_logic'image(blad));
    writeline(output, l);
    if n_zap /= n_przed or gotowe /= '0' or blad /= '1' then errors := errors + 1; end if;
    adr_modelu <= "0111001";
    wait until falling_edge(clk);
    start <= '1';
    wait until falling_edge(clk);
    start <= '0';
    seria;
    write(l, "seria na zadanie: zapisow " & integer'image(n_zap - n_przed) & ", gotowe = " & std_logic'image(gotowe)
          & ", blad = " & std_logic'image(blad));
    writeline(output, l);
    if n_zap - n_przed /= 17 or gotowe /= '1' or blad /= '0' then errors := errors + 1; end if;
    write(l, "START " & integer'image(n_start) & ", STOP " & integer'image(n_stop) & "; bledow w tablicy "
          & integer'image(bl_tab));
    writeline(output, l);
    write(l, "SCL: okres min " & integer'image(min_okr / 1 ns) & " ns, stan wysoki min " & integer'image(min_h / 1 ns)
          & " ns, niski min " & integer'image(min_l / 1 ns) & " ns");
    writeline(output, l);
    write(l, "t_HD;STA min " & integer'image(min_hdsta / 1 ns) & " ns, t_SU;STO min " & integer'image(min_susto / 1 ns)
          & " ns, t_BUF min " & integer'image(min_buf / 1 ns) & " ns");
    writeline(output, l);
    if bl_tab /= 0 or n_start /= n_stop then errors := errors + 1; end if;
    if min_okr < 10 us or min_h < 4 us or min_l < 4.7 us then errors := errors + 1; end if;
    if min_hdsta < 4 us or min_susto < 4 us or min_buf < 4.7 us then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

-- Testbench 25.01: i2c_zapisy z tablicą konfiguracji TLV320AIC3254 (adres 0x18) i modelem kodeka ze stronami
-- rejestrów. Sprawdza: wszystkie zapisy z ACK, przerwę po programowym resecie, rejestry stron 0 i 1, stronę końcową.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_kodek is
end entity tb_kodek;

architecture sim of tb_kodek is
  constant N : positive := 42;
  constant TAB : std_logic_vector(16 * N - 1 downto 0) :=
    x"0000" & x"0101" & x"FF01" &
    x"0B81" & x"0C82" & x"0D00" & x"0E80" & x"1281" & x"1382" & x"1480" &
    x"1B20" & x"3C08" & x"3D01" &
    x"0001" & x"0108" & x"0200" & x"7B01" & x"1425" & x"0A00" &
    x"0C08" & x"0D08" & x"0E08" & x"0F08" & x"0300" & x"0400" &
    x"1000" & x"1100" & x"1200" & x"1300" & x"093C" & x"4732" &
    x"3440" & x"3640" & x"3740" & x"3940" & x"3B0C" & x"3C0C" &
    x"0000" & x"3FD6" & x"4000" & x"51C0" & x"5200";

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal zajety, gotowe, blad, scl_o, sda_o : std_logic;
  signal s_sda : std_logic := '1';
  signal scl, sda : std_logic;
  type mem_t is array (0 to 127) of std_logic_vector(7 downto 0);
  signal mem0, mem1 : mem_t := (others => (others => 'X'));
  signal strona : std_logic_vector(7 downto 0) := x"00";
  signal n_zap : natural := 0;
  signal max_przerwa : time := 0 ns;
begin
  clk <= not clk after 40 ns when not fin else clk;
  scl <= scl_o;
  sda <= sda_o and s_sda;

  dut : entity work.i2c_zapisy
    generic map (F_CLK => 12500000, F_I2C => 100000, OKRES => 0, ADRES => "0011000", N => N, TAB => TAB)
    port map (clk => clk, rst => rst, start => '0', zajety => zajety, gotowe => gotowe, blad => blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => sda);

  process (scl, sda)
    variable akt : boolean := false;
    variable bity, nr_b : natural := 0;
    variable bajt, rej : std_logic_vector(7 downto 0) := x"00";
    variable t_stop : time := 0 ns;
    variable str : std_logic_vector(7 downto 0) := x"00";
  begin
    if rst = '0' then
      if sda'event and sda = '0' and scl = '1' then
        if t_stop > 0 ns and now - t_stop > max_przerwa then max_przerwa <= now - t_stop; end if;
        akt := true; bity := 0; nr_b := 0;
      end if;
      if sda'event and sda = '1' and scl = '1' then akt := false; t_stop := now; end if;
      if scl'event and scl = '1' and akt and bity < 8 then bajt := bajt(6 downto 0) & sda; bity := bity + 1; end if;
      if scl'event and scl = '0' then
        if akt and bity = 8 then
          bity := 9;
          if nr_b = 0 then
            if bajt = "0011000" & '0' then s_sda <= '0'; else akt := false; end if;
          elsif nr_b = 1 then
            rej := bajt; s_sda <= '0';
          else
            n_zap <= n_zap + 1;
            if rej = x"00" then str := bajt;
            elsif str = x"00" then mem0(to_integer(unsigned(rej(6 downto 0)))) <= bajt;
            else mem1(to_integer(unsigned(rej(6 downto 0)))) <= bajt;
            end if;
            strona <= str;
            s_sda <= '0';
          end if;
        elsif bity = 9 then
          s_sda <= '1'; bity := 0; nr_b := nr_b + 1;
        end if;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable errors : natural := 0;
    variable t0 : time;
    procedure spr(st : natural; r : natural; w : std_logic_vector(7 downto 0)) is
      variable v : std_logic_vector(7 downto 0);
    begin
      if st = 0 then v := mem0(r); else v := mem1(r); end if;
      if v /= w then
        write(l, "strona " & integer'image(st) & " rejestr " & integer'image(r) & " niezgodny");
        writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
  begin
    wait for 400 ns;
    rst <= '0';
    t0 := now;
    wait until zajety = '1';
    wait until zajety = '0';
    wait for 1 ns;
    write(l, "seria: " & integer'image(n_zap) & " zapisow w " & integer'image((now - t0) / 1 us) & " us, gotowe = "
          & std_logic'image(gotowe) & ", blad = " & std_logic'image(blad) & ", strona koncowa "
          & integer'image(to_integer(unsigned(strona))));
    writeline(output, l);
    write(l, "najdluzsza przerwa miedzy transakcjami (po resecie kodeka): " & integer'image(max_przerwa / 1 us) & " us");
    writeline(output, l);
    if n_zap /= N - 1 or gotowe /= '1' or blad /= '0' or strona /= x"00" then errors := errors + 1; end if;
    if max_przerwa < 1 ms then errors := errors + 1; end if;
    spr(0, 16#0B#, x"81"); spr(0, 16#0C#, x"82"); spr(0, 16#0E#, x"80"); spr(0, 16#12#, x"81");
    spr(0, 16#13#, x"82"); spr(0, 16#14#, x"80"); spr(0, 16#1B#, x"20"); spr(0, 16#3F#, x"D6");
    spr(0, 16#40#, x"00"); spr(0, 16#51#, x"C0"); spr(0, 16#52#, x"00");
    spr(1, 16#01#, x"08"); spr(1, 16#02#, x"00"); spr(1, 16#09#, x"3C"); spr(1, 16#0C#, x"08");
    spr(1, 16#0F#, x"08"); spr(1, 16#14#, x"25"); spr(1, 16#3B#, x"0C"); spr(1, 16#3C#, x"0C");
    spr(0, 16#3C#, x"08");
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

-- Testbench I²C (20.03): i2c_master (DIV = 10, SCL 1,25 MHz przy 50 MHz) z behawioralnym modelem
-- slave'a (adres 0x50, 256 rejestrów, wskaźnik z autoinkrementacją — jak pamięć EEPROM 24xx),
-- linie open-drain jako iloczyn logiczny wyjść z podciąganiem. Slave losowo rozciąga zegar
-- (trzyma SCL nisko do ok. 2 µs po zboczu opadającym). Sprawdzane:
--   zapis 32 bajtów, odczyt z powtórzonym STARTEM (ostatni bajt z NACK), brak ACK pod złym adresem,
--   minimalny czas stanu wysokiego SCL mimo rozciągania, przegrany arbitraż (drugi master ściąga SDA).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_i2c is
end entity tb_i2c;

architecture sim of tb_i2c is
  constant DIV : positive := 10;
  constant ADR : std_logic_vector(6 downto 0) := "1010000";   -- 0x50
  type mem_t is array (0 to 255) of std_logic_vector(7 downto 0);
  signal clk  : std_logic := '0';
  signal fin  : boolean := false;
  signal rst  : std_logic := '1';
  signal rozkaz : std_logic_vector(2 downto 0) := "000";
  signal wykonaj, nack_wy : std_logic := '0';
  signal wdane  : std_logic_vector(7 downto 0) := x"00";
  signal gotowy, wykonane, nack_we, utrata, m_scl_oe, m_sda_oe : std_logic;
  signal rdane  : std_logic_vector(7 downto 0);
  signal s_scl_oe, s_sda_oe, obcy_sda_oe : std_logic := '0';
  signal scl, sda : std_logic;
  signal mem      : mem_t := (others => x"EE");
  signal rozciagaj : boolean := true;
  signal n_rozc   : integer := 0;
  signal min_wys  : time := 1 ms;
  signal arb      : boolean := false;
begin
  clk <= not clk after 10 ns when not fin else clk;
  scl <= '0' when m_scl_oe = '1' or s_scl_oe = '1' else '1';                    -- podciąganie + open-drain
  sda <= '0' when m_sda_oe = '1' or s_sda_oe = '1' or obcy_sda_oe = '1' else '1';

  dut : entity work.i2c_master generic map (DIV => DIV)
    port map (clk => clk, rst => rst, rozkaz => rozkaz, wykonaj => wykonaj, wdane => wdane, nack_wy => nack_wy,
              gotowy => gotowy, wykonane => wykonane, rdane => rdane, nack_we => nack_we, utrata => utrata,
              scl_i => scl, scl_oe => m_scl_oe, sda_i => sda, sda_oe => m_sda_oe);

  -- model slave'a; tryb: 0 nieadresowany, 1 adres, 2 zapis, 3 odczyt
  slave : process
    variable tryb, n : integer := 0;
    variable bajt, ptr : std_logic_vector(7 downto 0) := x"00";
    variable rw, mack : std_logic := '0';
    variable pierwszy : boolean := false;
    variable s1, s2   : positive := 11;
    variable r        : real;
  begin
    wait on scl, sda;
    if sda'event and scl = '1' then
      if sda = '0' then                                         -- START / powtórzony START
        tryb := 1; n := 0;
      else                                                      -- STOP
        tryb := 0; s_sda_oe <= '0';
      end if;
    elsif scl'event and scl = '1' then
      if tryb = 1 or tryb = 2 then
        if n < 8 then bajt := bajt(6 downto 0) & sda; end if;
        n := n + 1;
      elsif tryb = 3 then
        if n = 8 then mack := sda; end if;                      -- ACK mastera po bajcie
        n := n + 1;
      end if;
    elsif scl'event and scl = '0' then
      if (tryb = 1 or tryb = 2) and n = 8 then                  -- po 8 bitach: ACK
        if tryb = 1 then
          if bajt(7 downto 1) = ADR then
            s_sda_oe <= '1'; rw := bajt(0);
          else
            tryb := 0;                                          -- nie nasz adres: NACK
          end if;
        else
          if pierwszy then
            ptr := bajt; pierwszy := false;
          else
            mem(to_integer(unsigned(ptr))) <= bajt;
            ptr := std_logic_vector(unsigned(ptr) + 1);
          end if;
          s_sda_oe <= '1';
        end if;
      elsif n = 9 and tryb /= 0 then                            -- koniec bitu ACK
        s_sda_oe <= '0';
        n := 0;
        if tryb = 1 then
          if rw = '1' then
            tryb := 3; s_sda_oe <= not mem(to_integer(unsigned(ptr)))(7);
          else
            tryb := 2; pierwszy := true;
          end if;
        elsif tryb = 3 then
          if mack = '0' then
            ptr := std_logic_vector(unsigned(ptr) + 1);
            s_sda_oe <= not mem(to_integer(unsigned(ptr)))(7);
          else
            tryb := 0;                                          -- NACK — koniec odczytu
          end if;
        end if;
      elsif tryb = 3 and n >= 1 and n <= 7 then
        s_sda_oe <= not mem(to_integer(unsigned(ptr)))(7 - n);  -- kolejny bit danych
      elsif tryb = 3 and n = 8 then
        s_sda_oe <= '0';                                        -- zwolnij SDA na ACK mastera
      end if;
      uniform(s1, s2, r);
      if rozciagaj and tryb /= 0 and r < 0.25 then              -- rozciąganie zegara
        s_scl_oe <= '1';
        n_rozc   <= n_rozc + 1;
        uniform(s1, s2, r);
        wait for 200 ns + integer(r * 2047.0) * 1 ns;
        s_scl_oe <= '0';
      end if;
    end if;
  end process;

  -- pomiar stanu wysokiego SCL
  process (scl)
    variable t_wys : time := 0 ns;
  begin
    if rising_edge(scl) then
      t_wys := now;
    elsif falling_edge(scl) and rst = '0' and now - t_wys < min_wys then
      min_wys <= now - t_wys;
    end if;
  end process;

  -- obcy master: wystawia 0 w bicie 6 adresu, gdy nasz nadaje 1
  process
  begin
    wait until arb;
    wait until rising_edge(scl);
    wait until falling_edge(scl);                               -- po bicie 7
    wait for 50 ns;
    obcy_sda_oe <= '1';
    wait until not arb;
    obcy_sda_oe <= '0';
    wait;
  end process;

  process
    variable l      : line;
    variable errors : integer := 0;
    variable s1, s2 : positive := 5;
    variable r      : real;
    type wzor_t is array (0 to 31) of std_logic_vector(7 downto 0);
    variable wzor   : wzor_t;
    variable nk     : std_logic;

    procedure rozk(rz : integer; d : std_logic_vector(7 downto 0); nack_b : std_logic) is
    begin
      wait until falling_edge(clk);
      if gotowy /= '1' then wait until gotowy = '1'; end if;
      wait until falling_edge(clk);
      rozkaz  <= std_logic_vector(to_unsigned(rz, 3));
      wdane   <= d;
      nack_wy <= nack_b;
      wykonaj <= '1';
      wait until falling_edge(clk);
      wykonaj <= '0';
      if wykonane /= '1' then wait until wykonane = '1'; end if;
      wait until falling_edge(clk);
    end procedure;

    procedure blad(s : string) is
    begin
      write(l, s); writeline(output, l);
      errors := errors + 1;
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for q in 1 to 20 loop wait until falling_edge(clk); end loop;

    -- zapis 32 bajtów od rejestru 0x40
    rozk(1, x"00", '0');
    rozk(3, ADR & '0', '0'); if nack_we = '1' then blad("brak ACK adresu"); end if;
    rozk(3, x"40", '0');     if nack_we = '1' then blad("brak ACK wskaznika"); end if;
    for i in 0 to 31 loop
      uniform(s1, s2, r);
      wzor(i) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
      rozk(3, wzor(i), '0'); if nack_we = '1' then blad("brak ACK danych"); end if;
    end loop;
    rozk(2, x"00", '0');
    for i in 0 to 31 loop
      if mem(16#40# + i) /= wzor(i) then blad("zapis: rejestr " & integer'image(16#40# + i)); end if;
    end loop;

    -- odczyt: wskaźnik, powtórzony START, 32 bajty
    rozk(1, x"00", '0');
    rozk(3, ADR & '0', '0');
    rozk(3, x"40", '0');
    rozk(1, x"00", '0');                                        -- Sr
    rozk(3, ADR & '1', '0'); if nack_we = '1' then blad("brak ACK adresu (odczyt)"); end if;
    for i in 0 to 31 loop
      if i = 31 then nk := '1'; else nk := '0'; end if;          -- ostatni bajt z NACK
      rozk(4, x"00", nk);
      if rdane /= wzor(i) then blad("odczyt " & integer'image(i)); end if;
    end loop;
    rozk(2, x"00", '0');

    -- zły adres
    rozk(1, x"00", '0');
    rozk(3, "1010001" & '0', '0');
    if nack_we /= '1' then blad("ACK pod zlym adresem"); end if;
    rozk(2, x"00", '0');
    if scl /= '1' or sda /= '1' then blad("magistrala nie zwolniona po STOP"); end if;

    write(l, "rozciagniec zegara: " & integer'image(n_rozc) & ", najkrotszy stan wysoki SCL "
          & integer'image(min_wys / 1 ns) & " ns (wymagane >= " & integer'image(2 * DIV * 20) & " ns)");
    writeline(output, l);
    if n_rozc < 20 or min_wys < (2 * DIV * 20 - 1) * 1 ns then errors := errors + 1; end if;

    -- arbitraż
    rozciagaj <= false;
    rozk(1, x"00", '0');
    arb <= true;
    rozk(3, x"FE", '0');
    arb <= false;
    wait for 1 ns;
    if utrata /= '1' or m_sda_oe = '1' or m_scl_oe = '1' then blad("arbitraz: brak utraty");
    else write(l, string'("arbitraz przegrany poprawnie, linie zwolnione")); writeline(output, l); end if;

    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

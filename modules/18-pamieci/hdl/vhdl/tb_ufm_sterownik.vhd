-- Testbench ufm_sterownik z modelem rdzenia On-Chip Flash (ufm_model w tym pliku): 1024 słowa (strony
-- po 64), skasowane do x"FFFFFFFF", rejestry statusu i kontrolny, waitrequest, opóźnienie odczytu, czasy
-- zapisu i kasowania, ochrona sektora, zapis jako AND. Sprawdzane: odczyt skasowanej komórki, zapis
-- i odczyt, nadpisanie bez kasowania (AND), kasowanie strony, przywrócenie ochrony, brak operacji przy
-- włączonej ochronie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ufm_model is
  generic (
    AW : positive := 10; STRONA : positive := 64; T_ZAPIS : positive := 30; T_KASUJ : positive := 200;
    SEKTOR : positive := 1
  );
  port (
    clk, rst                     : in  std_logic;
    csr_addr, csr_read, csr_write : in std_logic;
    csr_writedata                : in  std_logic_vector(31 downto 0);
    csr_readdata                 : out std_logic_vector(31 downto 0);
    data_addr                    : in  std_logic_vector(AW - 1 downto 0);
    data_read, data_write        : in  std_logic;
    data_writedata               : in  std_logic_vector(31 downto 0);
    data_burstcount              : in  std_logic_vector(3 downto 0);
    data_waitrequest             : out std_logic;
    data_readdatavalid           : out std_logic;
    data_readdata                : out std_logic_vector(31 downto 0);
    chroniony                    : out std_logic;
    bledy_ochrony                : out natural
  );
end entity ufm_model;

architecture model of ufm_model is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(31 downto 0);
  signal ctrl : std_logic_vector(31 downto 0) := (others => '1');
  signal busy : std_logic_vector(1 downto 0) := "00";
begin
  data_waitrequest <= '0' when busy = "00" else '1';
  chroniony        <= ctrl(22 + SEKTOR);

  process (clk)
    variable mem    : mem_t := (others => (others => '1'));
    variable licz   : integer := 0;
    variable adr_op : natural := 0;
    variable dane_op : std_logic_vector(31 downto 0);
    variable rs, ws, es : std_logic := '0';
    variable bledy  : natural := 0;
    variable pe     : natural;
    variable st     : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      data_readdatavalid <= '0';
      if csr_read = '1' then
        if csr_addr = '1' then
          csr_readdata <= ctrl;
        else
          st := (others => '1');
          st(9 downto 0) := "00000" & es & ws & rs & busy;
          csr_readdata <= st;
        end if;
      end if;
      if rst = '1' then
        ctrl <= (others => '1'); busy <= "00"; rs := '0'; ws := '0'; es := '0';
      else
        if csr_write = '1' and csr_addr = '1' then
          ctrl <= csr_writedata;
          pe := to_integer(unsigned(csr_writedata(19 downto 0)));
          if busy = "00" and pe < 2 ** AW then                 -- kasowanie strony
            if csr_writedata(22 + SEKTOR) = '1' then
              es := '0'; bledy := bledy + 1;
            else
              busy <= "01"; licz := T_KASUJ; adr_op := pe;
            end if;
          end if;
        end if;
        case busy is
          when "00" =>
            if data_write = '1' then
              if ctrl(22 + SEKTOR) = '1' or data_burstcount /= "0001" then
                ws := '0';
                if ctrl(22 + SEKTOR) = '1' then bledy := bledy + 1; end if;
              else
                busy <= "10"; licz := T_ZAPIS; adr_op := to_integer(unsigned(data_addr)); dane_op := data_writedata;
              end if;
            elsif data_read = '1' then
              busy <= "11"; licz := 2; adr_op := to_integer(unsigned(data_addr));
            end if;
          when "10" =>
            licz := licz - 1;
            if licz = 0 then mem(adr_op) := mem(adr_op) and dane_op; ws := '1'; busy <= "00"; end if;
          when "01" =>
            licz := licz - 1;
            if licz = 0 then
              for i in 0 to STRONA - 1 loop
                mem((adr_op / STRONA) * STRONA + i) := (others => '1');
              end loop;
              es := '1'; busy <= "00";
            end if;
          when others =>                                         -- odczyt: dane po dwóch taktach
            licz := licz - 1;
            if licz = 0 then
              data_readdata <= mem(adr_op); data_readdatavalid <= '1'; rs := '1'; busy <= "00";
            end if;
        end case;
      end if;
      bledy_ochrony <= bledy;
    end if;
  end process;
end architecture model;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ufm_sterownik is
end entity tb_ufm_sterownik;

architecture sim of tb_ufm_sterownik is
  constant AW : positive := 10;
  signal clk, rst : std_logic := '1';
  signal start : std_logic := '0';
  signal op : std_logic_vector(1 downto 0) := "00";
  signal addr : std_logic_vector(AW - 1 downto 0) := (others => '0');
  signal wdata, rdata, csr_wd, csr_rd, data_wd, data_rd : std_logic_vector(31 downto 0) := (others => '0');
  signal busy, done, ok, csr_addr, csr_read, csr_write, data_read, data_write, waitreq, rdvalid : std_logic;
  signal data_addr : std_logic_vector(AW - 1 downto 0);
  signal burst : std_logic_vector(3 downto 0);
  signal chroniony : std_logic;
  signal bledy_ochrony : natural;
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.ufm_sterownik generic map (AW => AW, SEKTOR => 1, CZEKAJ => 4)
    port map (clk => clk, rst => rst, start => start, op => op, addr => addr, wdata => wdata, busy => busy,
              done => done, ok => ok, rdata => rdata, csr_addr => csr_addr, csr_read => csr_read,
              csr_write => csr_write, csr_writedata => csr_wd, csr_readdata => csr_rd, data_addr => data_addr,
              data_read => data_read, data_write => data_write, data_writedata => data_wd,
              data_burstcount => burst, data_waitrequest => waitreq, data_readdatavalid => rdvalid,
              data_readdata => data_rd);
  flash : entity work.ufm_model generic map (AW => AW)
    port map (clk => clk, rst => rst, csr_addr => csr_addr, csr_read => csr_read, csr_write => csr_write,
              csr_writedata => csr_wd, csr_readdata => csr_rd, data_addr => data_addr, data_read => data_read,
              data_write => data_write, data_writedata => data_wd, data_burstcount => burst,
              data_waitrequest => waitreq, data_readdatavalid => rdvalid, data_readdata => data_rd,
              chroniony => chroniony, bledy_ochrony => bledy_ochrony);

  process
    variable l : line;
    variable errors : integer := 0;
    procedure polecenie(o : std_logic_vector(1 downto 0); a : natural; d : std_logic_vector(31 downto 0)) is
    begin
      wait until falling_edge(clk);
      start <= '1'; op <= o; addr <= std_logic_vector(to_unsigned(a, AW)); wdata <= d;
      wait until falling_edge(clk);
      start <= '0';
      if done /= '1' then
        wait until done = '1';
      end if;
      wait until falling_edge(clk);
      if chroniony /= '1' then
        write(l, string'("ochrona nie przywrocona")); writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
    procedure oczekuj(v : std_logic_vector(31 downto 0); opis : string) is
    begin
      if ok /= '1' or rdata /= v then
        write(l, opis & ": niezgodny odczyt"); writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
    procedure sprawdz_ok(opis : string) is
    begin
      if ok /= '1' then
        write(l, opis & ": ok = 0"); writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
  begin
    wait for 23 ns;
    rst <= '0';
    polecenie("00", 5, x"00000000");   oczekuj(x"FFFFFFFF", "odczyt skasowanej");
    polecenie("01", 5, x"12345678");   sprawdz_ok("zapis");
    polecenie("01", 100, x"CAFE0001");
    polecenie("00", 5, x"00000000");   oczekuj(x"12345678", "odczyt po zapisie");
    polecenie("01", 5, x"FFFF0000");
    polecenie("00", 5, x"00000000");   oczekuj(x"12340000", "nadpisanie bez kasowania (AND)");
    polecenie("10", 7, x"00000000");   sprawdz_ok("kasowanie");
    polecenie("00", 5, x"00000000");   oczekuj(x"FFFFFFFF", "po kasowaniu strony");
    polecenie("00", 100, x"00000000"); oczekuj(x"CAFE0001", "inna strona nietknieta");
    polecenie("01", 5, x"000000A5");
    polecenie("00", 5, x"00000000");   oczekuj(x"000000A5", "zapis po kasowaniu");
    if bledy_ochrony /= 0 then
      write(l, string'("operacje przy wlaczonej ochronie")); writeline(output, l);
      errors := errors + 1;
    end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

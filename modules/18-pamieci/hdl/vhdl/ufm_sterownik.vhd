-- Sterownik pamięci flash użytkownika MAX 10 (18.05) - strona "master" dla rdzenia On-Chip Flash IP
-- (Avalon-MM csr i data, tryb równoległy, burstcount = 1). op = 0 - odczyt, 1 - zapis (program; flash
-- zmienia tylko bity 1 -> 0), 2 - kasowanie strony zawierającej addr. Zapis i kasowanie: zdjęcie ochrony
-- sektora SEKTOR, operacja, odpytywanie statusu do busy = "00", sprawdzenie ws/es, przywrócenie ochrony.
-- Status (adres 0): [1:0] busy, [2] rs, [3] ws, [4] es. Kontrola (adres 1): [19:0] adres strony,
-- [22:20] sektor do skasowania ("111" - brak), [27:23] ochrona zapisu sektorów 1..5 ('1' = chroniony).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ufm_sterownik is
  generic (
    AW     : positive := 17;
    SEKTOR : positive := 1;
    CZEKAJ : natural  := 4
  );
  port (
    clk                : in  std_logic;
    rst                : in  std_logic;
    start              : in  std_logic;
    op                 : in  std_logic_vector(1 downto 0);
    addr               : in  std_logic_vector(AW - 1 downto 0);
    wdata              : in  std_logic_vector(31 downto 0);
    busy               : out std_logic;
    done               : out std_logic;
    ok                 : out std_logic;
    rdata              : out std_logic_vector(31 downto 0);
    csr_addr           : out std_logic;
    csr_read           : out std_logic;
    csr_write          : out std_logic;
    csr_writedata      : out std_logic_vector(31 downto 0);
    csr_readdata       : in  std_logic_vector(31 downto 0);
    data_addr          : out std_logic_vector(AW - 1 downto 0);
    data_read          : out std_logic;
    data_write         : out std_logic;
    data_writedata     : out std_logic_vector(31 downto 0);
    data_burstcount    : out std_logic_vector(3 downto 0);
    data_waitrequest   : in  std_logic;
    data_readdatavalid : in  std_logic;
    data_readdata      : in  std_logic_vector(31 downto 0)
  );
end entity ufm_sterownik;

architecture rtl of ufm_sterownik is
  type stan_t is (S_IDLE, S_RD, S_RD_CZEKAJ, S_ODBLOKUJ, S_ZAPIS_REQ, S_ZAPIS, S_KASUJ, S_START,
                  S_STATUS, S_STATUS_W, S_STATUS_D, S_ZABLOKUJ, S_KONIEC);
  constant CTRL_CHRONIONY : std_logic_vector(31 downto 0) := (others => '1');

  function maska_odblokowania return std_logic_vector is
    variable v : std_logic_vector(31 downto 0) := (others => '1');
  begin
    v(22 + SEKTOR) := '0';
    return v;
  end function;
  constant CTRL_ODBLOK : std_logic_vector(31 downto 0) := maska_odblokowania;

  signal stan    : stan_t := S_IDLE;
  signal op_r    : std_logic_vector(1 downto 0) := "00";
  signal licz    : natural range 0 to CZEKAJ := 0;
  signal adr_r   : std_logic_vector(AW - 1 downto 0) := (others => '0');
begin
  busy            <= '0' when stan = S_IDLE else '1';
  data_burstcount <= "0001";
  data_addr       <= adr_r;

  process (clk)
  begin
    if rising_edge(clk) then
      done      <= '0';
      csr_read  <= '0';
      csr_write <= '0';
      if rst = '1' then
        stan       <= S_IDLE;
        ok         <= '0';
        data_read  <= '0';
        data_write <= '0';
        csr_addr   <= '0';
      else
        case stan is
          when S_IDLE =>
            if start = '1' then
              op_r           <= op;
              adr_r          <= addr;
              data_writedata <= wdata;
              ok             <= '0';
              if op = "00" then
                data_read <= '1';
                stan      <= S_RD;
              else
                stan <= S_ODBLOKUJ;
              end if;
            end if;
          when S_RD =>                                 -- żądanie trwa, dopóki rdzeń trzyma waitrequest
            if data_waitrequest = '0' then
              data_read <= '0';
              stan      <= S_RD_CZEKAJ;
            end if;
          when S_RD_CZEKAJ =>
            if data_readdatavalid = '1' then
              rdata <= data_readdata;
              ok    <= '1';
              stan  <= S_KONIEC;
            end if;
          when S_ODBLOKUJ =>                           -- zdjęcie ochrony zapisu sektora
            csr_addr      <= '1';
            csr_write     <= '1';
            csr_writedata <= CTRL_ODBLOK;
            if op_r = "01" then
              stan <= S_ZAPIS_REQ;
            else
              stan <= S_KASUJ;
            end if;
          when S_ZAPIS_REQ =>                          -- zapis danych takt po zdjęciu ochrony
            data_write <= '1';
            stan       <= S_ZAPIS;
          when S_ZAPIS =>
            if data_waitrequest = '0' then
              data_write <= '0';
              licz       <= CZEKAJ;
              stan       <= S_START;
            end if;
          when S_KASUJ =>                              -- adres strony w polu pe, sektor "111" = brak
            csr_addr      <= '1';
            csr_write     <= '1';
            csr_writedata <= CTRL_ODBLOK(31 downto 20) & std_logic_vector(resize(unsigned(adr_r), 20));
            licz          <= CZEKAJ;
            stan          <= S_START;
          when S_START =>                              -- rdzeń potrzebuje chwili, zanim pokaże busy
            if licz = 0 then
              stan <= S_STATUS;
            else
              licz <= licz - 1;
            end if;
          when S_STATUS =>
            csr_addr <= '0';
            csr_read <= '1';
            stan     <= S_STATUS_W;
          when S_STATUS_W =>
            stan <= S_STATUS_D;
          when S_STATUS_D =>
            if csr_readdata(1 downto 0) /= "00" then
              stan <= S_STATUS;                        -- wciąż zajęty
            else
              if op_r = "01" then
                ok <= csr_readdata(3);
              else
                ok <= csr_readdata(4);
              end if;
              stan <= S_ZABLOKUJ;
            end if;
          when S_ZABLOKUJ =>                           -- przywrócenie ochrony
            csr_addr      <= '1';
            csr_write     <= '1';
            csr_writedata <= CTRL_CHRONIONY;
            stan          <= S_KONIEC;
          when S_KONIEC =>
            done <= '1';
            stan <= S_IDLE;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;

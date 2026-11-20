-- I²C master z interfejsem rozkazów (20.03): 1 START (także powtórzony), 2 STOP, 3 ZAPIS bajtu z odczytem
-- ACK, 4 ODCZYT bajtu z ACK/NACK. Linie open-drain (*_oe = '1' ściąga do zera). Bit: 4 fazy po DIV taktów,
-- zmiana SDA w połowie stanu niskiego SCL, próbkowanie w połowie wysokiego; rozciąganie zegara — czas
-- stanu wysokiego liczony od chwili, gdy SCL naprawdę jest wysoki; arbitraż — utrata, gdy nadawane 1, a odczytane 0.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master is
  generic (DIV : positive := 125);
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    rozkaz   : in  std_logic_vector(2 downto 0);
    wykonaj  : in  std_logic;
    wdane    : in  std_logic_vector(7 downto 0);
    nack_wy  : in  std_logic;
    gotowy   : out std_logic;
    wykonane : out std_logic := '0';
    rdane    : out std_logic_vector(7 downto 0);
    nack_we  : out std_logic;
    utrata   : out std_logic := '0';
    scl_i    : in  std_logic;
    scl_oe   : out std_logic := '0';
    sda_i    : in  std_logic;
    sda_oe   : out std_logic := '0'
  );
end entity i2c_master;

architecture rtl of i2c_master is
  constant K_START  : natural := 1;
  constant K_STOP   : natural := 2;
  constant K_ZAPIS  : natural := 3;
  constant K_ODCZYT : natural := 4;
  signal s_scl, s_sda : std_logic_vector(1 downto 0) := "11";
  attribute altera_attribute : string;
  attribute altera_attribute of s_scl, s_sda : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  signal kom       : natural range 0 to 4 := 0;
  signal faza      : natural range 0 to 3 := 0;
  signal t         : natural range 0 to DIV - 1 := 0;
  signal czeka_scl : boolean := false;
  signal nbit      : natural range 0 to 8 := 0;
  signal sr        : std_logic_vector(7 downto 0) := (others => '0');
  signal nack_r    : std_logic := '0';
  signal sda_oe_r  : std_logic := '0';
  signal bit_wy    : std_logic;
begin
  s_scl  <= s_scl(0) & scl_i when rising_edge(clk);
  s_sda  <= s_sda(0) & sda_i when rising_edge(clk);
  gotowy <= '1' when kom = 0 else '0';
  sda_oe <= sda_oe_r;

  -- stan SDA w bicie nbit rozkazu ZAPIS/ODCZYT: '1' — zwolnij
  bit_wy <= '1'    when kom = K_ZAPIS and nbit = 8 else
            sr(7)  when kom = K_ZAPIS else
            nack_r when nbit = 8 else
            '1';

  process (clk)
  begin
    if rising_edge(clk) then
      wykonane <= '0';
      if rst = '1' then
        kom      <= 0;
        scl_oe   <= '0';
        sda_oe_r <= '0';
        utrata   <= '0';
      elsif kom = 0 then
        if wykonaj = '1' and unsigned(rozkaz) /= 0 then
          kom       <= to_integer(unsigned(rozkaz));
          faza      <= 0;
          t         <= DIV - 1;
          czeka_scl <= false;
          nbit      <= 0;
          sr        <= wdane;
          nack_r    <= nack_wy;
          if to_integer(unsigned(rozkaz)) = K_START then
            sda_oe_r <= '0';
          elsif to_integer(unsigned(rozkaz)) = K_STOP then
            sda_oe_r <= '1';
          end if;
        end if;
      elsif czeka_scl then
        if s_scl(1) = '1' then czeka_scl <= false; end if;     -- SCL naprawdę wysoki
      elsif t /= 0 then
        t <= t - 1;
      else
        t    <= DIV - 1;
        faza <= (faza + 1) mod 4;
        case faza is
          when 0 =>
            if kom = K_START or kom = K_STOP then
              scl_oe    <= '0';
              czeka_scl <= true;
            else
              sda_oe_r <= not bit_wy;                           -- zmiana SDA w środku stanu niskiego SCL
            end if;
          when 1 =>
            if kom = K_START then
              sda_oe_r <= '1';                                  -- warunek START
            elsif kom = K_STOP then
              sda_oe_r <= '0';                                  -- warunek STOP
            else
              scl_oe    <= '0';
              czeka_scl <= true;
            end if;
          when 2 =>
            if kom = K_START then
              scl_oe <= '1';
            elsif kom = K_ZAPIS or kom = K_ODCZYT then
              if nbit = 8 then
                if kom = K_ZAPIS then nack_we <= s_sda(1); end if;
              else
                if kom = K_ODCZYT then sr <= sr(6 downto 0) & s_sda(1); end if;
                if kom = K_ZAPIS and sda_oe_r = '0' and s_sda(1) = '0' then
                  utrata   <= '1';                              -- nadawaliśmy 1, a na linii 0
                  scl_oe   <= '0';
                  sda_oe_r <= '0';
                  kom      <= 0;
                  wykonane <= '1';
                end if;
              end if;
            end if;
          when others =>
            if kom = K_START or kom = K_STOP then
              kom      <= 0;
              wykonane <= '1';
            else
              scl_oe <= '1';                                    -- SCL w dół
              if nbit = 8 then
                if kom = K_ODCZYT then rdane <= sr; end if;
                kom      <= 0;
                wykonane <= '1';
              else
                nbit <= nbit + 1;
                if kom = K_ZAPIS then sr <= sr(6 downto 0) & '0'; end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;

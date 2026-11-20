-- Sterownik akcelerometru LIS2DH12 przez SPI tryb 3 (20.05): rozruch (CZEKAJ taktów), WHO_AM_I (0x0F,
-- oczekiwane 0x33), CTRL_REG1 = 0x57 (100 Hz, osie XYZ), CTRL_REG4 = 0x88 (BDU, HR, ±2 g), potem co OKRES
-- taktów odczyt 6 bajtów od OUT_X_L (0x28) z autoinkrementacją (pierwszy bajt 0xE8: odczyt | MS | 0x28).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity akcel_lis2dh12 is
  generic (
    DIV    : positive := 13;
    CZEKAJ : positive := 250_000;
    OKRES  : positive := 2_500_000
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    sclk     : out std_logic;
    mosi     : out std_logic;
    miso     : in  std_logic;
    cs_n     : out std_logic;
    x, y, z  : out std_logic_vector(15 downto 0) := (others => '0');
    nowe     : out std_logic := '0';
    who_am_i : out std_logic_vector(7 downto 0) := (others => '0');
    id_ok    : out std_logic
  );
end entity akcel_lis2dh12;

architecture rtl of akcel_lis2dh12 is
  type etap_t is (E_ROZRUCH, E_ID, E_CTRL1, E_CTRL4, E_CZEKA, E_XYZ);
  signal etap     : etap_t := E_ROZRUCH;
  signal start, dalej, zajety, gotowe : std_logic := '0';
  signal tx, rx   : std_logic_vector(7 downto 0) := (others => '0');
  signal nb       : natural range 0 to 7 := 0;
  signal w_toku   : boolean := false;
  signal licz     : natural range 0 to maximum(CZEKAJ, OKRES) := 0;
  signal dane     : std_logic_vector(47 downto 0) := (others => '0');
  signal who      : std_logic_vector(7 downto 0) := (others => '0');

  function bajt(e : etap_t; n : natural) return std_logic_vector is
  begin
    case e is
      when E_ID    => if n = 0 then return x"8F"; else return x"00"; end if;   -- odczyt 0x0F
      when E_CTRL1 => if n = 0 then return x"20"; else return x"57"; end if;
      when E_CTRL4 => if n = 0 then return x"23"; else return x"88"; end if;
      when others  => if n = 0 then return x"E8"; else return x"00"; end if;   -- odczyt, MS, 0x28
    end case;
  end function;
begin
  u_spi : entity work.spi_master
    generic map (N => 8, DIV => DIV)
    port map (clk => clk, rst => rst, cpol => '1', cpha => '1', start => start, dalej => dalej,
              tx_dane => tx, rx_dane => rx, zajety => zajety, gotowe => gotowe, sclk => sclk, mosi => mosi,
              miso => miso, cs_n => cs_n);

  who_am_i <= who;
  id_ok    <= '1' when who = x"33" else '0';

  process (clk)
    variable dlugosc : natural range 2 to 7;
    variable pelne   : std_logic_vector(47 downto 0);
  begin
    if rising_edge(clk) then
      start <= '0';
      nowe  <= '0';
      dlugosc := 7 when etap = E_XYZ else 2;
      if rst = '1' then
        etap   <= E_ROZRUCH;
        licz   <= 0;
        w_toku <= false;
      elsif etap = E_ROZRUCH or etap = E_CZEKA then
        if (etap = E_ROZRUCH and licz = CZEKAJ) or (etap = E_CZEKA and licz = OKRES) then
          licz <= 0;
          etap <= E_ID when etap = E_ROZRUCH else E_XYZ;
        else
          licz <= licz + 1;
        end if;
      elsif not w_toku then                                    -- pierwszy bajt transakcji
        if zajety = '0' then
          tx     <= bajt(etap, 0);
          dalej  <= '1';
          start  <= '1';
          nb     <= 0;
          w_toku <= true;
        end if;
      elsif gotowe = '1' then
        pelne := rx & dane(47 downto 8);                       -- po 6 bajtach: ZH ZL YH YL XH XL
        if nb /= 0 then dane <= pelne; end if;
        if nb = dlugosc - 1 then
          w_toku <= false;
          case etap is
            when E_ID    => who <= rx; etap <= E_CTRL1;
            when E_CTRL1 => etap <= E_CTRL4;
            when E_CTRL4 => etap <= E_CZEKA;
            when others  =>
              x    <= pelne(15 downto 0);
              y    <= pelne(31 downto 16);
              z    <= pelne(47 downto 32);
              nowe <= '1';
              etap <= E_CZEKA;
          end case;
        else
          tx    <= bajt(etap, nb + 1);
          dalej <= '1' when nb + 1 /= dlugosc - 1 else '0';    -- ostatni bajt zwalnia CS
          start <= '1';
          nb    <= nb + 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

-- DECA — dwa obrazy konfiguracji MAX 10 i przełączanie z logiki (29.02), VHDL. Generic OBRAZ (0 — „fabryczny”,
-- 1 — „aplikacja”), KEY(1) — przełączenie na drugi obraz przez system_dual (Dual Configuration IP z Platform
-- Designer), SW(0) — CRC poprawne, SW(1) — zerowanie licznika nadzorującego, LED(6) — numer obrazu,
-- LED(7) — odmowa. Komponent system_dual w GHDL pozostaje niepowiązany (sprawdzana jest składnia).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  generic (OBRAZ : natural range 0 to 1 := 0);
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component system_dual is
    port (
      clk_clk                    : in  std_logic;
      reset_reset_n              : in  std_logic;
      dual_boot_avalon_address   : in  std_logic_vector(2 downto 0);
      dual_boot_avalon_read      : in  std_logic;
      dual_boot_avalon_writedata : in  std_logic_vector(31 downto 0);
      dual_boot_avalon_write     : in  std_logic;
      dual_boot_avalon_readdata  : out std_logic_vector(31 downto 0)
    );
  end component;

  signal clk         : std_logic;
  signal rs          : std_logic_vector(1 downto 0) := "11";
  signal rst, rst_n  : std_logic;
  signal licz_1ms    : natural range 0 to 49999 := 0;
  signal k1          : std_logic_vector(1 downto 0) := "11";
  signal start       : std_logic := '0';
  signal sw1, sw2    : std_logic_vector(1 downto 0) := "00";
  signal t           : unsigned(25 downto 0) := (others => '0');
  signal pies        : std_logic;
  signal av_address  : std_logic_vector(2 downto 0);
  signal av_write, av_read, zajety, odmowa, wyzwolono : std_logic;
  signal av_writedata, av_readdata : std_logic_vector(31 downto 0);
  signal odm         : unsigned(26 downto 0) := (others => '0');
  signal wzor        : std_logic_vector(5 downto 0);
  signal sel_obraz   : std_logic;
  signal b7, b6      : std_logic;
  signal niski       : std_logic_vector(5 downto 0);
begin
  clk   <= MAX10_CLK1_50;
  rst   <= rs(1);
  rst_n <= not rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      rs    <= rs(0) & not KEY(0);
      start <= '0';
      sw1   <= SW;
      sw2   <= sw1;
      if licz_1ms = 49999 then licz_1ms <= 0; else licz_1ms <= licz_1ms + 1; end if;
      if licz_1ms = 0 then
        k1 <= k1(0) & KEY(1);
        if k1(0) = '0' and k1(1) = '1' then start <= '1'; end if;
      end if;
      t <= t + 1;
      if odmowa = '1' then
        odm <= to_unsigned(100_000_000, 27);
      elsif odm /= 0 then
        odm <= odm - 1;
      end if;
    end if;
  end process;

  pies      <= '1' when sw2(1) = '1' and t(24 downto 0) = 0 else '0';
  sel_obraz <= '1' when OBRAZ = 0 else '0';

  u_akt : entity work.aktualizacja generic map (CZAS => 600)
    port map (clk => clk, rst => rst, start => start, obraz => sel_obraz, obraz_ok => sw2(0), pies => pies,
              av_address => av_address, av_write => av_write, av_writedata => av_writedata, av_read => av_read,
              zajety => zajety, odmowa => odmowa, wyzwolono => wyzwolono);

  u_sys : system_dual port map (
    clk_clk => clk, reset_reset_n => rst_n, dual_boot_avalon_address => av_address,
    dual_boot_avalon_read => av_read, dual_boot_avalon_writedata => av_writedata,
    dual_boot_avalon_write => av_write, dual_boot_avalon_readdata => av_readdata);

  wzor  <= (5 downto 1 => '0', 0 => t(25)) when OBRAZ = 0
           else std_logic_vector(shift_left(to_unsigned(1, 6), to_integer(t(25 downto 23)) mod 6));
  b7    <= '1' when odm /= 0 and t(21) = '1' else '0';
  b6    <= '1' when OBRAZ /= 0 else '0';
  niski <= (others => '1') when zajety = '1' else wzor;
  LED   <= not (b7 & b6 & niski);
end architecture rtl;

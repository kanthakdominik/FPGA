-- Rdzeń mapy rejestrów niezależny od magistrali (21.02):
--   0x00 ID RO, 0x04 STER RW (maska bajtów), 0x08 STAN RO, 0x0C PRZER W1C (8 bitów, ustawiane przez zdarz),
--   0x10 MASKA RW (8 bitów, irq = or(PRZER and MASKA)), 0x14 SKRYTKA RW; reszta - błąd.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rejestry_rdzen is
  generic (ID : std_logic_vector(31 downto 0) := x"21020001");
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    zap      : in  std_logic;
    zap_adr  : in  std_logic_vector(3 downto 0);
    zap_dane : in  std_logic_vector(31 downto 0);
    zap_str  : in  std_logic_vector(3 downto 0);
    zap_blad : out std_logic;
    odc_adr  : in  std_logic_vector(3 downto 0);
    odc_dane : out std_logic_vector(31 downto 0);
    odc_blad : out std_logic;
    ster     : out std_logic_vector(31 downto 0);
    stan     : in  std_logic_vector(31 downto 0);
    zdarz    : in  std_logic_vector(7 downto 0);
    irq      : out std_logic
  );
end entity rejestry_rdzen;

architecture rtl of rejestry_rdzen is
  signal ster_r, skrytka : std_logic_vector(31 downto 0) := (others => '0');
  signal przer, maska    : std_logic_vector(7 downto 0) := (others => '0');
  signal m               : std_logic_vector(31 downto 0);
begin
  g_m : for b in 0 to 3 generate
    m(b * 8 + 7 downto b * 8) <= (others => zap_str(b));
  end generate;

  ster     <= ster_r;
  zap_blad <= '1' when unsigned(zap_adr) > 5 else '0';
  odc_blad <= '1' when unsigned(odc_adr) > 5 else '0';
  irq      <= or (przer and maska);

  with to_integer(unsigned(odc_adr)) select odc_dane <=
    ID                     when 0,
    ster_r                 when 1,
    stan                   when 2,
    x"000000" & przer      when 3,
    x"000000" & maska      when 4,
    skrytka                when 5,
    (others => '0')        when others;

  process (clk)
    variable kas : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ster_r  <= (others => '0');
        przer   <= (others => '0');
        maska   <= (others => '0');
        skrytka <= (others => '0');
      else
        kas := (others => '0');
        if zap = '1' and unsigned(zap_adr) = 3 and zap_str(0) = '1' then kas := zap_dane(7 downto 0); end if;
        przer <= (przer and not kas) or zdarz;              -- zdarzenie w takcie kasowania wygrywa
        if zap = '1' then
          case to_integer(unsigned(zap_adr)) is
            when 1 => ster_r <= (ster_r and not m) or (zap_dane and m);
            when 4 => if zap_str(0) = '1' then maska <= zap_dane(7 downto 0); end if;
            when 5 => skrytka <= (skrytka and not m) or (zap_dane and m);
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

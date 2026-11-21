-- Kontroler karty SD w trybie SPI (23.05): inicjalizacja (≥ 74 takty, CMD0, CMD8, CMD55 + ACMD41, CMD58,
-- CMD16 dla SDSC) przy SCLK ≤ 400 kHz i odczyt bloku 512 B (CMD17, token 0xFE, CRC16). CRC7 dla każdego
-- rozkazu. Tryb SPI 0, MSB pierwszy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_spi is
  generic (
    DIV_WOLNY  : positive := 63;
    DIV_SZYBKI : positive := 2;
    PROBY      : positive := 2000
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    odczyt     : in  std_logic;
    blok       : in  std_logic_vector(31 downto 0);
    gotowy     : out std_logic := '0';
    sdhc       : out std_logic := '0';
    blad       : out std_logic := '0';
    kod_bledu  : out std_logic_vector(3 downto 0) := "0000";
    dane       : out std_logic_vector(7 downto 0);
    dane_wazne : out std_logic := '0';
    koniec     : out std_logic := '0';
    crc_ok     : out std_logic := '0';
    sclk       : out std_logic := '0';
    mosi       : out std_logic := '1';
    cs_n       : out std_logic := '1';
    miso       : in  std_logic
  );
end entity sd_spi;

architecture rtl of sd_spi is
  -- silnik bajtowy
  signal b_start, b_done, b_akt, szybko, sc : std_logic := '0';
  signal b_tx, b_rx, b_sr : std_logic_vector(7 downto 0) := (others => '1');
  signal b_n : natural range 0 to 7 := 0;
  signal b_t : natural range 0 to 127 := 0;

  function crc7(d : std_logic_vector(39 downto 0)) return std_logic_vector is
    variable c : std_logic_vector(6 downto 0) := (others => '0');
    variable fb : std_logic;
  begin
    for i in 39 downto 0 loop
      fb := d(i) xor c(6);
      c  := c(5 downto 0) & '0';
      if fb = '1' then c := c xor "0001001"; end if;
    end loop;
    return c;
  end function;

  function crc16(c0 : std_logic_vector(15 downto 0); d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable c : std_logic_vector(15 downto 0) := c0;
    variable fb : std_logic;
  begin
    for i in 7 downto 0 loop
      fb := d(i) xor c(15);
      c  := c(14 downto 0) & '0';
      if fb = '1' then c := c xor x"1021"; end if;
    end loop;
    return c;
  end function;

  type p_t is (P_ROZRUCH, P_WYSLIJ, P_R1, P_EXT, P_PRZERWA, P_GOTOWY, P_TOKEN, P_DANE, P_CRC, P_BLAD);
  type k_t is (K_CMD0, K_CMD8, K_CMD55, K_ACMD41, K_CMD58, K_CMD16, K_CMD17);
  signal p     : p_t := P_ROZRUCH;
  signal krok  : k_t := K_CMD0;
  signal ramka : std_logic_vector(47 downto 0) := (others => '1');
  signal idx   : natural range 0 to 6 := 0;
  signal r1    : std_logic_vector(7 downto 0) := x"FF";
  signal ext   : std_logic_vector(31 downto 0) := (others => '0');
  signal licz  : natural range 0 to 2047 := 0;
  signal proby_l : natural range 0 to 65535 := 0;
  signal crc_obl : std_logic_vector(15 downto 0) := (others => '0');
  signal crc_hi  : std_logic_vector(7 downto 0) := (others => '0');
  signal czeka, hc, got : std_logic := '0';

  function nr(k : k_t) return std_logic_vector is
  begin
    case k is
      when K_CMD0   => return std_logic_vector(to_unsigned(0, 6));
      when K_CMD8   => return std_logic_vector(to_unsigned(8, 6));
      when K_CMD55  => return std_logic_vector(to_unsigned(55, 6));
      when K_ACMD41 => return std_logic_vector(to_unsigned(41, 6));
      when K_CMD58  => return std_logic_vector(to_unsigned(58, 6));
      when K_CMD16  => return std_logic_vector(to_unsigned(16, 6));
      when K_CMD17  => return std_logic_vector(to_unsigned(17, 6));
    end case;
  end function;
begin
  sclk   <= sc;
  sdhc   <= hc;
  gotowy <= got;

  -- silnik bajtowy (tryb 0)
  process (clk)
    variable dz : natural range 0 to 127;
  begin
    if rising_edge(clk) then
      b_done <= '0';
      if szybko = '1' then dz := DIV_SZYBKI - 1; else dz := DIV_WOLNY - 1; end if;
      if rst = '1' then
        b_akt <= '0';
        sc    <= '0';
        mosi  <= '1';
      elsif b_akt = '0' then
        if b_start = '1' then
          b_akt <= '1';
          b_sr  <= b_tx;
          mosi  <= b_tx(7);
          b_n   <= 0;
          b_t   <= dz;
        end if;
      elsif b_t /= 0 then
        b_t <= b_t - 1;
      else
        b_t <= dz;
        sc  <= not sc;
        if sc = '0' then
          b_rx <= b_rx(6 downto 0) & miso;                     -- narastające: próbka
        else
          b_sr <= b_sr(6 downto 0) & '1';                      -- opadające: następny bit
          mosi <= b_sr(6);
          if b_n = 7 then
            b_akt  <= '0';
            b_done <= '1';
            mosi   <= '1';
          else
            b_n <= b_n + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- sekwencer
  process (clk)
    procedure rozkaz(k : k_t) is
      variable arg : std_logic_vector(31 downto 0);
      variable ra  : std_logic_vector(39 downto 0);
    begin
      case k is
        when K_CMD8   => arg := x"000001AA";
        when K_ACMD41 => arg := x"40000000";                   -- HCS
        when K_CMD16  => arg := std_logic_vector(to_unsigned(512, 32));
        when K_CMD17  => if hc = '1' then arg := blok; else arg := blok(22 downto 0) & "000000000"; end if;
        when others   => arg := (others => '0');
      end case;
      ra    := "01" & nr(k) & arg;
      ramka <= ra & crc7(ra) & '1';
      krok  <= k;
      idx   <= 0;
      p     <= P_WYSLIJ;
    end procedure;
    procedure bajt(b : std_logic_vector(7 downto 0)) is
    begin
      b_tx    <= b;
      b_start <= '1';
      czeka   <= '1';
    end procedure;
    procedure blad_ust(kod : natural) is
    begin
      blad      <= '1';
      kod_bledu <= std_logic_vector(to_unsigned(kod, 4));
      cs_n      <= '1';
      p         <= P_BLAD;
    end procedure;
  begin
    if rising_edge(clk) then
      b_start    <= '0';
      dane_wazne <= '0';
      koniec     <= '0';
      if rst = '1' then
        p         <= P_ROZRUCH;
        cs_n      <= '1';
        szybko    <= '0';
        got       <= '0';
        hc        <= '0';
        blad      <= '0';
        kod_bledu <= "0000";
        crc_ok    <= '0';
        czeka     <= '0';
        licz      <= 0;
        proby_l   <= 0;
      elsif czeka = '1' then
        if b_done = '1' then czeka <= '0'; end if;
      else
        case p is
          when P_ROZRUCH =>                                    -- 10 bajtów 0xFF z CS = '1'
            if licz = 10 then
              licz <= 0;
              rozkaz(K_CMD0);
            else
              licz <= licz + 1;
              bajt(x"FF");
            end if;
          when P_WYSLIJ =>
            cs_n <= '0';
            if idx = 6 then
              idx  <= 0;
              licz <= 0;
              p    <= P_R1;
              bajt(x"FF");
            else
              idx <= idx + 1;
              bajt(ramka(47 - idx * 8 downto 40 - idx * 8));
            end if;
          when P_R1 =>
            if b_rx(7) = '0' then
              r1  <= b_rx;
              idx <= 0;
              if krok = K_CMD8 or krok = K_CMD58 then
                p <= P_EXT;
                bajt(x"FF");
              elsif krok = K_CMD17 then
                if b_rx /= x"00" then
                  blad_ust(7);
                else
                  licz <= 0;
                  p    <= P_TOKEN;
                  bajt(x"FF");
                end if;
              else
                p    <= P_PRZERWA;
                cs_n <= '1';
                bajt(x"FF");
              end if;
            elsif licz = 9 then
              blad_ust(1);
            else
              licz <= licz + 1;
              bajt(x"FF");
            end if;
          when P_EXT =>
            ext <= ext(23 downto 0) & b_rx;
            if idx = 3 then
              p    <= P_PRZERWA;
              cs_n <= '1';
            else
              idx <= idx + 1;
            end if;
            bajt(x"FF");
          when P_PRZERWA =>
            case krok is
              when K_CMD0 =>
                if r1 = x"01" then rozkaz(K_CMD8);
                elsif proby_l = 10 then blad_ust(2);
                else proby_l <= proby_l + 1; rozkaz(K_CMD0); end if;
              when K_CMD8 =>
                if r1 = x"01" and ext(11 downto 0) = x"1AA" then proby_l <= 0; rozkaz(K_CMD55);
                else blad_ust(3); end if;
              when K_CMD55 =>
                if r1 = x"01" or r1 = x"00" then rozkaz(K_ACMD41); else blad_ust(4); end if;
              when K_ACMD41 =>
                if r1 = x"00" then rozkaz(K_CMD58);
                elsif r1 = x"01" and proby_l /= PROBY then proby_l <= proby_l + 1; rozkaz(K_CMD55);
                else blad_ust(5); end if;
              when K_CMD58 =>
                if r1 = x"00" and ext(31) = '1' then
                  hc <= ext(30);
                  if ext(30) = '1' then szybko <= '1'; got <= '1'; p <= P_GOTOWY;
                  else rozkaz(K_CMD16); end if;
                else
                  blad_ust(6);
                end if;
              when K_CMD16 =>
                if r1 = x"00" then szybko <= '1'; got <= '1'; p <= P_GOTOWY; else blad_ust(6); end if;
              when K_CMD17 =>
                got    <= '1';
                koniec <= '1';
                p      <= P_GOTOWY;
            end case;
          when P_GOTOWY =>
            if odczyt = '1' then
              got    <= '0';
              crc_ok <= '0';
              rozkaz(K_CMD17);
            end if;
          when P_TOKEN =>
            if b_rx = x"FE" then
              licz    <= 0;
              crc_obl <= (others => '0');
              p       <= P_DANE;
              bajt(x"FF");
            elsif b_rx /= x"FF" or licz = PROBY then
              blad_ust(8);
            else
              licz <= licz + 1;
              bajt(x"FF");
            end if;
          when P_DANE =>
            dane       <= b_rx;
            dane_wazne <= '1';
            crc_obl    <= crc16(crc_obl, b_rx);
            licz       <= licz + 1;
            if licz = 511 then
              idx <= 0;
              p   <= P_CRC;
            end if;
            bajt(x"FF");
          when P_CRC =>
            if idx = 0 then
              crc_hi <= b_rx;
              idx    <= 1;
            else
              crc_ok <= '1' when crc_hi & b_rx = crc_obl else '0';
              cs_n   <= '1';
              p      <= P_PRZERWA;
            end if;
            bajt(x"FF");
          when P_BLAD =>
            null;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;

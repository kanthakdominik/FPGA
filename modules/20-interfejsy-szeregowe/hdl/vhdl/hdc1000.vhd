-- Odczyt czujnika HDC1000 przez I²C (20.05): konfiguracja 0x02 = 0x1000 (temperatura i wilgotność jednym
-- wyzwoleniem), pętla: wskaźnik 0x00 (wyzwolenie), odczekanie CZEKAJ, odczyt 4 bajtów (ostatni z NACK),
-- co OKRES taktów. NACK na adres (pomiar trwa) — STOP i ponowienie po CZEKAJ/4.
-- T = surowe·165/2^16 − 40 °C, RH = surowe·100/2^16 %.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdc1000 is
  generic (
    ADR    : std_logic_vector(6 downto 0) := "1000000";
    DIV    : positive := 125;
    CZEKAJ : positive := 1_000_000;
    OKRES  : positive := 25_000_000
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    scl_i     : in  std_logic;
    scl_oe    : out std_logic;
    sda_i     : in  std_logic;
    sda_oe    : out std_logic;
    temp_sur  : out std_logic_vector(15 downto 0) := (others => '0');
    wilg_sur  : out std_logic_vector(15 downto 0) := (others => '0');
    temp_c    : out std_logic_vector(8 downto 0);
    wilg_proc : out std_logic_vector(6 downto 0);
    nowe      : out std_logic := '0';
    nacki     : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity hdc1000;

architecture rtl of hdc1000 is
  constant K_START  : std_logic_vector(2 downto 0) := "001";
  constant K_STOP   : std_logic_vector(2 downto 0) := "010";
  constant K_ZAPIS  : std_logic_vector(2 downto 0) := "011";
  constant K_ODCZYT : std_logic_vector(2 downto 0) := "100";
  type stan_t is (S_KONF, S_WYZW, S_CZEKA, S_ODCZ);

  signal rozkaz   : std_logic_vector(2 downto 0) := "000";
  signal wykonaj, nack_wy, gotowy, wykonane, nack_we : std_logic := '0';
  signal wdane, rdane : std_logic_vector(7 downto 0) := (others => '0');
  signal stan, nast   : stan_t := S_KONF;
  signal k        : natural range 0 to 7 := 0;
  signal w_toku, przerwij : boolean := false;
  signal licz, czekaj_do : natural range 0 to maximum(CZEKAJ, OKRES) := 0;
  signal bajty    : std_logic_vector(31 downto 0) := (others => '0');
  signal t_r, w_r : unsigned(15 downto 0) := (others => '0');
  signal nk       : unsigned(7 downto 0) := (others => '0');

  -- rozkaz nr k sekwencji: {rozkaz, dane, nack_wy}
  function krok(s : stan_t; n : natural) return std_logic_vector is
  begin
    case s is
      when S_KONF =>
        case n is
          when 0 => return K_START & x"00" & '0';
          when 1 => return K_ZAPIS & ADR & '0' & '0';
          when 2 => return K_ZAPIS & x"02" & '0';               -- wskaźnik: konfiguracja
          when 3 => return K_ZAPIS & x"10" & '0';               -- MODE = 1
          when 4 => return K_ZAPIS & x"00" & '0';
          when others => return K_STOP & x"00" & '0';
        end case;
      when S_WYZW =>
        case n is
          when 0 => return K_START & x"00" & '0';
          when 1 => return K_ZAPIS & ADR & '0' & '0';
          when 2 => return K_ZAPIS & x"00" & '0';               -- wskaźnik 0x00: wyzwolenie pomiaru
          when others => return K_STOP & x"00" & '0';
        end case;
      when others =>
        case n is
          when 0 => return K_START & x"00" & '0';
          when 1 => return K_ZAPIS & ADR & '1' & '0';
          when 2 | 3 | 4 => return K_ODCZYT & x"00" & '0';
          when 5 => return K_ODCZYT & x"00" & '1';              -- ostatni bajt: NACK
          when others => return K_STOP & x"00" & '0';
        end case;
    end case;
  end function;

  function ostatni(s : stan_t) return natural is
  begin
    case s is
      when S_KONF => return 5;
      when S_WYZW => return 3;
      when others => return 6;
    end case;
  end function;
begin
  u_i2c : entity work.i2c_master
    generic map (DIV => DIV)
    port map (clk => clk, rst => rst, rozkaz => rozkaz, wykonaj => wykonaj, wdane => wdane, nack_wy => nack_wy,
              gotowy => gotowy, wykonane => wykonane, rdane => rdane, nack_we => nack_we, utrata => open,
              scl_i => scl_i, scl_oe => scl_oe, sda_i => sda_i, sda_oe => sda_oe);

  temp_sur  <= std_logic_vector(t_r);
  wilg_sur  <= std_logic_vector(w_r);
  nacki     <= std_logic_vector(nk);
  temp_c    <= std_logic_vector(resize((t_r * 165) / 65536, 9) - 40);
  wilg_proc <= std_logic_vector(resize((w_r * 100) / 65536, 7));

  process (clk)
    variable r : std_logic_vector(11 downto 0);
  begin
    if rising_edge(clk) then
      wykonaj <= '0';
      nowe    <= '0';
      r := krok(stan, k);
      if rst = '1' then
        stan   <= S_KONF;
        k      <= 0;
        w_toku <= false;
        licz   <= 0;
        nk     <= (others => '0');
      elsif stan = S_CZEKA then
        if licz >= czekaj_do then
          licz <= 0;
          stan <= nast;
          k    <= 0;
        else
          licz <= licz + 1;
        end if;
      elsif not w_toku then
        if gotowy = '1' then
          rozkaz  <= K_STOP when przerwij else r(11 downto 9);
          wdane   <= r(8 downto 1);
          nack_wy <= r(0);
          wykonaj <= '1';
          w_toku  <= true;
        end if;
      elsif wykonane = '1' then
        w_toku <= false;
        if rozkaz = K_ODCZYT then bajty <= bajty(23 downto 0) & rdane; end if;
        if rozkaz = K_ZAPIS and nack_we = '1' then              -- brak potwierdzenia: STOP i ponowienie
          przerwij <= true;
          if nk /= 255 then nk <= nk + 1; end if;
        elsif przerwij or k = ostatni(stan) then               -- koniec sekwencji
          przerwij <= false;
          stan     <= S_CZEKA;
          licz     <= 0;
          if przerwij then
            czekaj_do <= CZEKAJ / 4;
            nast      <= stan;
          elsif stan = S_KONF then
            czekaj_do <= 0;
            nast      <= S_WYZW;
          elsif stan = S_WYZW then
            czekaj_do <= CZEKAJ;
            nast      <= S_ODCZ;
          else
            t_r       <= unsigned(bajty(31 downto 16));
            w_r       <= unsigned(bajty(15 downto 0));
            nowe      <= '1';
            czekaj_do <= OKRES;
            nast      <= S_WYZW;
          end if;
        else
          k <= k + 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

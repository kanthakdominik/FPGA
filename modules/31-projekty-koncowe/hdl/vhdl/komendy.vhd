-- Interpreter komend tekstowych z UART (31.01): ?, Thhmmss, S, P, R, L, W (litery bez rozróżniania wielkości),
-- odpowiedzi do 12 znaków w rejestrze przesuwnym, wysyłane przez uart_tx. Jak w wersjach Verilog i SV.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity komendy is
  port (
    clk, rst   : in  std_logic;
    rx_dane    : in  std_logic_vector(7 downto 0);
    rx_wazne   : in  std_logic;
    czas       : in  std_logic_vector(23 downto 0);
    stoper     : in  std_logic_vector(23 downto 0);
    ustaw      : out std_logic := '0';
    ustaw_czas : out std_logic_vector(23 downto 0) := (others => '0');
    st_start, st_stop, st_zeruj, st_okr : out std_logic := '0';
    tx_start   : out std_logic := '0';
    tx_dane    : out std_logic_vector(7 downto 0) := (others => '0');
    tx_gotowy  : in  std_logic;
    pominieto  : out std_logic := '0'
  );
end entity komendy;

architecture rtl of komendy is
  constant CR : std_logic_vector(7 downto 0) := x"0D";
  constant LF : std_logic_vector(7 downto 0) := x"0A";

  function z(c : character) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(character'pos(c), 8));
  end function;
  function cyf(d : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    return x"3" & d;
  end function;

  constant T_OK  : std_logic_vector(95 downto 0) := z('O') & z('K') & CR & LF & x"0000000000000000";
  constant T_ERR : std_logic_vector(95 downto 0) := z('E') & z('R') & z('R') & CR & LF & x"00000000000000";

  signal bufor   : std_logic_vector(95 downto 0) := (others => '0');
  signal ile     : natural range 0 to 12 := 0;
  signal czekaj  : std_logic := '0';
  signal txs     : std_logic := '0';
  signal w_cyfr  : std_logic := '0';
  signal nc      : natural range 0 to 5 := 0;
  signal cyfry   : std_logic_vector(19 downto 0) := (others => '0');
  signal pom     : std_logic := '0';
begin
  tx_start  <= txs;
  pominieto <= pom;

  process (clk)
    variable duza  : std_logic_vector(7 downto 0);
    variable nowe  : std_logic_vector(23 downto 0);
    variable cyfra, zakres : boolean;
    variable odp   : std_logic_vector(95 downto 0);
    variable n_odp : natural range 0 to 12;
  begin
    if rising_edge(clk) then
      ustaw <= '0'; st_start <= '0'; st_stop <= '0'; st_zeruj <= '0'; st_okr <= '0';
      txs <= '0';
      n_odp := 0;
      odp := (others => '0');
      if rst = '1' then
        ile <= 0; czekaj <= '0'; w_cyfr <= '0'; nc <= 0; pom <= '0';
      else
        czekaj <= txs;
        if ile /= 0 and tx_gotowy = '1' and txs = '0' and czekaj = '0' then
          tx_dane <= bufor(95 downto 88);
          txs     <= '1';
          bufor   <= bufor(87 downto 0) & x"00";
          ile     <= ile - 1;
        end if;
        if rx_wazne = '1' then
          if unsigned(rx_dane) >= character'pos('a') and unsigned(rx_dane) <= character'pos('z') then
            duza := rx_dane and x"DF";
          else
            duza := rx_dane;
          end if;
          cyfra := unsigned(rx_dane) >= character'pos('0') and unsigned(rx_dane) <= character'pos('9');
          nowe := cyfry(19 downto 0) & rx_dane(3 downto 0);
          zakres := (unsigned(nowe(23 downto 20)) < 2 or
                     (unsigned(nowe(23 downto 20)) = 2 and unsigned(nowe(19 downto 16)) <= 3)) and
                    unsigned(nowe(15 downto 12)) <= 5 and unsigned(nowe(7 downto 4)) <= 5;
          if w_cyfr = '1' then
            if not cyfra then
              w_cyfr <= '0';
              odp := T_ERR; n_odp := 5;
            else
              cyfry <= nowe(19 downto 0);
              if nc = 5 then
                w_cyfr <= '0';
                if zakres then
                  ustaw <= '1'; ustaw_czas <= nowe;
                  odp := T_OK; n_odp := 4;
                else
                  odp := T_ERR; n_odp := 5;
                end if;
              else
                nc <= nc + 1;
              end if;
            end if;
          elsif duza = z('T') then
            w_cyfr <= '1'; nc <= 0;
          elsif duza = z('?') then
            odp := cyf(czas(23 downto 20)) & cyf(czas(19 downto 16)) & z(':') & cyf(czas(15 downto 12)) &
                   cyf(czas(11 downto 8)) & z(':') & cyf(czas(7 downto 4)) & cyf(czas(3 downto 0)) & CR & LF & x"0000";
            n_odp := 10;
          elsif duza = z('S') then
            st_start <= '1'; odp := T_OK; n_odp := 4;
          elsif duza = z('P') then
            st_stop <= '1'; odp := T_OK; n_odp := 4;
          elsif duza = z('R') then
            st_zeruj <= '1'; odp := T_OK; n_odp := 4;
          elsif duza = z('L') then
            st_okr <= '1';
            odp := z('L') & z(' ') & cyf(stoper(23 downto 20)) & cyf(stoper(19 downto 16)) & z(':') &
                   cyf(stoper(15 downto 12)) & cyf(stoper(11 downto 8)) & z('.') & cyf(stoper(7 downto 4)) &
                   cyf(stoper(3 downto 0)) & CR & LF;
            n_odp := 12;
          elsif duza = z('W') then
            odp := cyf(stoper(23 downto 20)) & cyf(stoper(19 downto 16)) & z(':') & cyf(stoper(15 downto 12)) &
                   cyf(stoper(11 downto 8)) & z('.') & cyf(stoper(7 downto 4)) & cyf(stoper(3 downto 0)) & CR & LF &
                   x"0000";
            n_odp := 10;
          elsif duza = z(' ') or duza = CR or duza = LF then
            null;
          else
            odp := T_ERR; n_odp := 5;
          end if;
          if n_odp /= 0 then
            if ile /= 0 then
              pom <= '1';
            else
              bufor <= odp;
              ile <= n_odp;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

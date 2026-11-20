-- Testbench 20.06: adc_sekwencer z modelem rdzenia „ADC Control Core Only” (przyjęcie rozkazu impulsem
-- command_ready, odpowiedź po czasie przetwarzania KONW taktów, bez przeciwciśnienia), adc_srednia
-- i tsd_temperatura.
--   sekwencer: kanały 1, 3, 17 na zmianę; każda odpowiedź trafia do właściwego pola wyników,
--              kolejność kanałów w rozkazach zgodna z listą, 300 konwersji,
--   srednia:   K = 6 na kanale 1 (próbki 1000 + 0…7) — wynik 1000…1007,
--   tsd:       punkty z tabeli UG (3798 -> −40, 3677 -> 25, 3595 -> 60, 3431 -> 125, 3690 -> 20),
--              kody spoza tabeli i monotoniczność dla wszystkich kodów 3300…3999.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_adc is
end entity tb_adc;

architecture sim of tb_adc is
  constant KONW : positive := 20;
  type lista_t is array (0 to 2) of integer;
  constant LISTA : lista_t := (1, 3, 17);
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal c_valid, c_sop, c_eop, nowy : std_logic;
  signal c_kanal, kanal : std_logic_vector(4 downto 0);
  signal dane    : std_logic_vector(11 downto 0);
  signal wyniki  : std_logic_vector(35 downto 0);
  signal c_ready, r_valid : std_logic := '0';
  signal r_kanal : std_logic_vector(4 downto 0) := (others => '0');
  signal r_dane  : std_logic_vector(11 downto 0) := (others => '0');
  signal n_rozk, n_odp, n_sr, bl_rozk, bl_sr : integer := 0;
  signal s_we, s_wazne : std_logic;
  signal srednia : std_logic_vector(11 downto 0);
  signal kod     : std_logic_vector(11 downto 0) := (others => '0');
  signal tc      : std_logic_vector(7 downto 0);

  function probka(k : integer; n : integer) return std_logic_vector is
  begin
    case k is
      when 1 => return std_logic_vector(to_unsigned(1000 + n mod 8, 12));   -- „szum” 0…7
      when 3 => return std_logic_vector(to_unsigned(2500, 12));
      when others => return std_logic_vector(to_unsigned(3677, 12));         -- termodioda: 25 °C
    end case;
  end function;
begin
  clk <= not clk after 10 ns when not fin else clk;

  dut : entity work.adc_sekwencer
    generic map (LICZBA => 3, KANALY => std_logic_vector(to_unsigned(17 * 1024 + 3 * 32 + 1, 40)))
    port map (clk => clk, rst => rst, wlacz => '1', command_valid => c_valid, command_channel => c_kanal,
              command_startofpacket => c_sop, command_endofpacket => c_eop, command_ready => c_ready,
              response_valid => r_valid, response_channel => r_kanal, response_data => r_dane, wyniki => wyniki,
              nowy => nowy, kanal => kanal, dane => dane);

  -- model rdzenia: przyjmuje rozkaz (ready przez takt), po KONW taktach odpowiedź, potem kolejny rozkaz
  process (clk)
    variable t, n_konw : integer := 0;
    variable zajety    : boolean := false;
    variable kan_konw  : integer := 0;
  begin
    if rising_edge(clk) then
      c_ready <= '0';
      r_valid <= '0';
      if rst = '0' then
        if not zajety and c_valid = '1' and c_ready = '0' then
          c_ready  <= '1';                                      -- przyjęcie w tym takcie (valid && ready)
          kan_konw := to_integer(unsigned(c_kanal));
          zajety   := true;
          t        := KONW;
        elsif zajety then
          if t = 0 then
            r_valid <= '1';
            r_kanal <= std_logic_vector(to_unsigned(kan_konw, 5));
            r_dane  <= probka(kan_konw, n_konw);
            n_konw  := n_konw + 1;
            zajety  := false;
          else
            t := t - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- kolejność rozkazów, liczba odpowiedzi
  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) then
      if c_valid = '1' and c_ready = '1' then
        if to_integer(unsigned(c_kanal)) /= LISTA(n_rozk mod 3) then
          if bl_rozk < 10 then
            write(l, "rozkaz " & integer'image(n_rozk) & ": kanal " & integer'image(to_integer(unsigned(c_kanal)))
                  & ", oczekiwano " & integer'image(LISTA(n_rozk mod 3)));
            writeline(output, l);
          end if;
          bl_rozk <= bl_rozk + 1;
        end if;
        n_rozk <= n_rozk + 1;
      end if;
      if nowy = '1' then n_odp <= n_odp + 1; end if;
    end if;
  end process;

  -- średnia z kanału 1
  s_we <= '1' when nowy = '1' and kanal = "00001" else '0';
  u_sr : entity work.adc_srednia generic map (W => 12, K => 6)
    port map (clk => clk, rst => rst, wazne => s_we, dane => dane, wyj_wazne => s_wazne, srednia => srednia);
  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) and s_wazne = '1' then
      n_sr <= n_sr + 1;
      if unsigned(srednia) < 1000 or unsigned(srednia) > 1007 then
        write(l, "srednia " & integer'image(to_integer(unsigned(srednia)))); writeline(output, l);
        bl_sr <= bl_sr + 1;
      end if;
    end if;
  end process;

  -- termodioda
  u_tsd : entity work.tsd_temperatura port map (clk => clk, kod => kod, temp_c => tc);

  process
    variable l      : line;
    variable errors : integer := 0;
    variable poprz  : integer;

    procedure sprawdz_tsd(k : integer; oczek : integer) is
    begin
      wait until falling_edge(clk);
      kod <= std_logic_vector(to_unsigned(k, 12));
      wait until falling_edge(clk);
      if to_integer(signed(tc)) /= oczek then
        write(l, "TSD kod " & integer'image(k) & ": " & integer'image(to_integer(signed(tc))) & " C, oczekiwano "
              & integer'image(oczek));
        writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    wait until n_odp = 300;
    wait until falling_edge(clk);
    write(l, "sekwencer: " & integer'image(n_rozk) & " rozkazow, " & integer'image(n_odp) & " odpowiedzi; wyniki: kanal 1 = "
          & integer'image(to_integer(unsigned(wyniki(11 downto 0)))) & ", kanal 3 = "
          & integer'image(to_integer(unsigned(wyniki(23 downto 12)))) & ", kanal 17 = "
          & integer'image(to_integer(unsigned(wyniki(35 downto 24)))) & "; srednich " & integer'image(n_sr));
    writeline(output, l);
    if unsigned(wyniki(11 downto 0)) < 1000 or unsigned(wyniki(11 downto 0)) > 1007
       or unsigned(wyniki(23 downto 12)) /= 2500 or unsigned(wyniki(35 downto 24)) /= 3677 or n_sr < 1 then
      errors := errors + 1;
    end if;
    errors := errors + bl_rozk + bl_sr;

    sprawdz_tsd(3798, -40);
    sprawdz_tsd(3677, 25);
    sprawdz_tsd(3595, 60);
    sprawdz_tsd(3431, 125);
    sprawdz_tsd(3690, 20);                                      -- między 19 °C (3695) a 20 °C (3688)
    sprawdz_tsd(3200, 125);
    sprawdz_tsd(4000, -40);
    poprz := 200;
    for i in 3300 to 3999 loop                                  -- temperatura nierosnąca ze wzrostem kodu
      wait until falling_edge(clk);
      kod <= std_logic_vector(to_unsigned(i, 12));
      wait until falling_edge(clk);
      if to_integer(signed(tc)) > poprz then
        write(l, "TSD niemonotoniczna przy kodzie " & integer'image(i)); writeline(output, l);
        errors := errors + 1;
      end if;
      poprz := to_integer(signed(tc));
    end loop;

    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;

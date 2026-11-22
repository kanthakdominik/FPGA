-- Projekt 2 (31.02): oscyloskop — zrzut (domena ADC), ram_2z (dwa zegary), takt_wideo + ekran_osc (domena
-- piksela), przekazanie zrzutu przełącznikami z synchronizatorami. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oscyloskop is
  generic (
    AW : positive := 9; PRZED : positive := 64; AUTO : positive := 4096; X0 : positive := 64; Y0 : positive := 112;
    H_AKT : positive := 640; H_FP : positive := 16; H_SYNC : positive := 96; H_BP : positive := 48;
    V_AKT : positive := 480; V_FP : positive := 10; V_SYNC : positive := 2; V_BP : positive := 33
  );
  port (
    clk_a, rst_a : in  std_logic;
    we           : in  std_logic;
    probka       : in  std_logic_vector(11 downto 0);
    poziom       : in  std_logic_vector(11 downto 0);
    dziel        : in  unsigned(7 downto 0);
    tryb_auto    : in  std_logic;
    wyzwolony    : out std_logic;
    clk_v, rst_v : in  std_logic;
    rgb          : out std_logic_vector(23 downto 0);
    hs, vs, de   : out std_logic;
    nr_zrzutu    : out unsigned(15 downto 0)
  );
end entity oscyloskop;

architecture rtl of oscyloskop is
  signal ram_we, bank_gotowy, gotowy_t, potw_t : std_logic;
  signal ram_wadr, ram_radr : unsigned(AW downto 0);
  signal ram_wdane, ram_rdane : std_logic_vector(7 downto 0);
  signal poczatek : unsigned(AW - 1 downto 0);
  signal poz_s1, poz_s2 : std_logic_vector(11 downto 0) := (others => '0');
  signal t_hs, t_vs, t_de, t_nowa : std_logic;
  signal tx, ty : unsigned(11 downto 0);

  attribute altera_attribute : string;
  attribute altera_attribute of poz_s1 : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  u_zrzut : entity work.zrzut generic map (AW => AW, PRZED => PRZED, AUTO => AUTO)
    port map (clk => clk_a, rst => rst_a, we => we, probka => probka, poziom => poziom, dziel => dziel,
              tryb_auto => tryb_auto, ram_we => ram_we, ram_adr => ram_wadr, ram_dane => ram_wdane,
              bank_gotowy => bank_gotowy, poczatek => poczatek, wyzwolony => wyzwolony, gotowy_t => gotowy_t,
              potw_t => potw_t, zajety => open);
  u_ram : entity work.ram_2z generic map (AW => AW + 1, DW => 8)
    port map (clk_a => clk_a, we => ram_we, wadr => ram_wadr, wdane => ram_wdane, clk_b => clk_v,
              radr => ram_radr, rdane => ram_rdane);
  process (clk_v) begin if rising_edge(clk_v) then poz_s1 <= poziom; poz_s2 <= poz_s1; end if; end process;
  u_takt : entity work.takt_wideo
    generic map (H_AKT => H_AKT, H_FP => H_FP, H_SYNC => H_SYNC, H_BP => H_BP, V_AKT => V_AKT, V_FP => V_FP,
                 V_SYNC => V_SYNC, V_BP => V_BP)
    port map (clk => clk_v, rst => rst_v, hs => t_hs, vs => t_vs, de => t_de, x => tx, y => ty, nowa_ramka => t_nowa);
  u_ekran : entity work.ekran_osc generic map (AW => AW, PRZED => PRZED, X0 => X0, Y0 => Y0)
    port map (clk => clk_v, rst => rst_v, hs_we => t_hs, vs_we => t_vs, de_we => t_de, x => tx, y => ty,
              nowa_ramka => t_nowa, poziom => poz_s2, gotowy_t => gotowy_t, bank_gotowy => bank_gotowy,
              poczatek => poczatek, potw_t => potw_t, ram_adr => ram_radr, ram_dane => ram_rdane, rgb => rgb,
              hs => hs, vs => vs, de => de, nr_zrzutu => nr_zrzutu);
end architecture rtl;

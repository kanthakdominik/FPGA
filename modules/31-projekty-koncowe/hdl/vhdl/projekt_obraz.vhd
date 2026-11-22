-- Projekt 5 (31.05): takt_wideo -> wzor_bayer -> isp. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity projekt_obraz is
  generic (
    H_AKT : positive := 640; H_FP : positive := 16; H_SYNC : positive := 96; H_BP : positive := 48;
    V_AKT : positive := 480; V_FP : positive := 10; V_SYNC : positive := 2; V_BP : positive := 33;
    PROG  : natural := 96
  );
  port (
    clk, rst   : in  std_logic;
    tryb       : in  unsigned(2 downto 0);
    ruch       : in  std_logic;
    de, hs, vs : out std_logic;
    rgb        : out std_logic_vector(23 downto 0);
    suma_y     : out unsigned(31 downto 0)
  );
end entity projekt_obraz;

architecture rtl of projekt_obraz is
  signal t_hs, t_vs, t_de, t_nowa, b_de, b_hs, b_vs : std_logic;
  signal tx, ty : unsigned(11 downto 0);
  signal raw : std_logic_vector(7 downto 0);
begin
  u_takt : entity work.takt_wideo
    generic map (H_AKT => H_AKT, H_FP => H_FP, H_SYNC => H_SYNC, H_BP => H_BP, V_AKT => V_AKT, V_FP => V_FP,
                 V_SYNC => V_SYNC, V_BP => V_BP)
    port map (clk => clk, rst => rst, hs => t_hs, vs => t_vs, de => t_de, x => tx, y => ty, nowa_ramka => t_nowa);
  u_wzor : entity work.wzor_bayer generic map (W => H_AKT, H => V_AKT)
    port map (clk => clk, rst => rst, ruch => ruch, de => t_de, hs => t_hs, vs => t_vs, x => tx, y => ty,
              nowa_ramka => t_nowa, o_de => b_de, o_hs => b_hs, o_vs => b_vs, raw => raw);
  u_isp : entity work.isp generic map (L => H_AKT + H_FP + H_SYNC + H_BP, PROG => PROG)
    port map (clk => clk, tryb => tryb, de => b_de, hs => b_hs, vs => b_vs, raw => raw, o_de => de, o_hs => hs,
              o_vs => vs, rgb => rgb, suma_y => suma_y);
end architecture rtl;

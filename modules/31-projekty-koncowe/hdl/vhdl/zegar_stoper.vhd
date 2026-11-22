-- Zegar doby i stoper w kodzie BCD (31.01): takt setnych sekundy z dzielnika CS_DZIEL.
-- zegar hh:mm:ss (ustaw — nowa wartość, setne zerowane), stoper mm:ss.cc ze startem, stopem, zerowaniem
-- i okrążeniem. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zegar_stoper is
  generic (CS_DZIEL : positive := 500_000);
  port (
    clk, rst   : in  std_logic;
    ustaw      : in  std_logic;
    ustaw_czas : in  std_logic_vector(23 downto 0);
    st_start, st_stop, st_zeruj, st_okr : in std_logic;
    czas       : out std_logic_vector(23 downto 0);
    stoper     : out std_logic_vector(23 downto 0);
    okr        : out std_logic_vector(23 downto 0);
    biegnie    : out std_logic;
    tik_cs     : out std_logic
  );
end entity zegar_stoper;

architecture rtl of zegar_stoper is
  signal dz   : natural range 0 to CS_DZIEL - 1 := 0;
  signal tik  : std_logic;
  signal cs_z : natural range 0 to 99 := 0;
  signal cz, st, ok : std_logic_vector(23 downto 0) := (others => '0');
  signal bieg : std_logic := '0';

  -- dwie cyfry BCD + 1 z ograniczeniem; wynik: przeniesienie & nowa wartość
  function inc2(v : std_logic_vector(7 downto 0); maks : std_logic_vector(7 downto 0)) return std_logic_vector is
  begin
    if v = maks then
      return '1' & x"00";
    elsif v(3 downto 0) = x"9" then
      return '0' & std_logic_vector(unsigned(v(7 downto 4)) + 1) & x"0";
    else
      return '0' & v(7 downto 4) & std_logic_vector(unsigned(v(3 downto 0)) + 1);
    end if;
  end function;
begin
  tik <= '1' when dz = CS_DZIEL - 1 else '0';
  tik_cs <= tik;
  czas <= cz; stoper <= st; okr <= ok; biegnie <= bieg;

  process (clk)
    variable z_s, z_m, z_h, s_c, s_s, s_m : std_logic_vector(8 downto 0);
  begin
    if rising_edge(clk) then
      z_s := inc2(cz(7 downto 0), x"59");
      z_m := inc2(cz(15 downto 8), x"59");
      z_h := inc2(cz(23 downto 16), x"23");
      s_c := inc2(st(7 downto 0), x"99");
      s_s := inc2(st(15 downto 8), x"59");
      s_m := inc2(st(23 downto 16), x"99");
      if rst = '1' then
        dz <= 0; cs_z <= 0; cz <= (others => '0'); st <= (others => '0'); ok <= (others => '0'); bieg <= '0';
      else
        if tik = '1' then dz <= 0; else dz <= dz + 1; end if;
        if ustaw = '1' then
          cz <= ustaw_czas;
          cs_z <= 0;
        elsif tik = '1' then
          if cs_z = 99 then
            cs_z <= 0;
            cz(7 downto 0) <= z_s(7 downto 0);
            if z_s(8) = '1' then
              cz(15 downto 8) <= z_m(7 downto 0);
              if z_m(8) = '1' then cz(23 downto 16) <= z_h(7 downto 0); end if;
            end if;
          else
            cs_z <= cs_z + 1;
          end if;
        end if;
        if st_zeruj = '1' then
          st <= (others => '0'); ok <= (others => '0'); bieg <= '0';
        else
          if st_start = '1' then bieg <= '1'; end if;
          if st_stop = '1' then bieg <= '0'; end if;
          if st_okr = '1' then ok <= st; end if;
          if bieg = '1' and tik = '1' then
            st(7 downto 0) <= s_c(7 downto 0);
            if s_c(8) = '1' then
              st(15 downto 8) <= s_s(7 downto 0);
              if s_s(8) = '1' then st(23 downto 16) <= s_m(7 downto 0); end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;

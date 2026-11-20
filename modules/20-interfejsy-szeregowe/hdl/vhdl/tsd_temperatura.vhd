-- Przeliczenie kodu termodiody (kanał 17 ADC MAX 10) na stopnie C (20.06): tablica 512 słów, adres = kod - 3431.
-- Tablica liczona przy elaboracji z tabeli kodów z MAX 10 ADC User Guide (683596, kod dla każdej
-- temperatury od -40 do 125) — ta sama reguła co w gen_tsd.py: temperatura o najbliższym kodzie
-- (przy remisie niższa). Bez plików: ten sam kod syntetyzuje się w Quartusie (wersje Verilog i SV czytają
-- tsd_temp.hex przez $readmemh). Kody spoza tablicy: 125 (poniżej) albo -40 (powyżej). Odczyt synchroniczny.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tsd_temperatura is
  port (
    clk    : in  std_logic;
    kod    : in  std_logic_vector(11 downto 0);
    temp_c : out std_logic_vector(7 downto 0)                    -- U2, stopnie C
  );
end entity tsd_temperatura;

architecture rtl of tsd_temperatura is
  constant KOD0 : natural := 3431;
  type kody_t is array (-40 to 125) of natural;
  constant UG : kody_t := (
    3798, 3796, 3795, 3793, 3792, 3790, 3788, 3786, 3785, 3782, 3781, 3780,
    3779, 3777, 3775, 3773, 3771, 3770, 3768, 3766, 3765, 3764, 3762, 3759,
    3756, 3754, 3752, 3751, 3750, 3748, 3746, 3744, 3742, 3740, 3738, 3736,
    3733, 3732, 3731, 3730, 3727, 3725, 3721, 3720, 3719, 3717, 3715, 3713,
    3711, 3709, 3707, 3704, 3703, 3702, 3700, 3699, 3698, 3697, 3696, 3695,
    3688, 3684, 3682, 3680, 3678, 3677, 3676, 3673, 3670, 3667, 3666, 3664,
    3662, 3660, 3658, 3656, 3654, 3651, 3648, 3645, 3643, 3642, 3641, 3640,
    3638, 3636, 3634, 3632, 3630, 3628, 3625, 3622, 3619, 3616, 3613, 3610,
    3607, 3604, 3601, 3598, 3595, 3594, 3593, 3592, 3591, 3590, 3589, 3585,
    3582, 3579, 3576, 3573, 3570, 3567, 3564, 3561, 3558, 3555, 3552, 3551,
    3550, 3549, 3548, 3547, 3546, 3542, 3538, 3534, 3530, 3526, 3525, 3524,
    3522, 3519, 3516, 3513, 3510, 3507, 3504, 3501, 3500, 3498, 3496, 3494,
    3492, 3490, 3489, 3486, 3483, 3480, 3477, 3474, 3471, 3468, 3465, 3461,
    3460, 3459, 3456, 3451, 3450, 3449, 3445, 3440, 3432, 3431);
  type tab_t is array (0 to 511) of std_logic_vector(7 downto 0);

  function oblicz return tab_t is
    variable t        : tab_t;
    variable kod_i, najl, odl, best : integer;
  begin
    for a in tab_t'range loop
      kod_i := KOD0 + a;
      if kod_i >= UG(-40) then
        best := -40;
      elsif kod_i <= UG(125) then
        best := 125;
      else
        najl := integer'high;
        best := 0;
        for st in kody_t'range loop                              -- od najniższej: remis zostaje przy niższej
          odl := abs (UG(st) - kod_i);
          if odl < najl then
            najl := odl;
            best := st;
          end if;
        end loop;
      end if;
      t(a) := std_logic_vector(to_signed(best, 8));
    end loop;
    return t;
  end function;

  constant TAB : tab_t := oblicz;
begin
  process (clk)
    variable k : integer;
  begin
    if rising_edge(clk) then
      k := to_integer(unsigned(kod)) - KOD0;
      if k < 0 then
        temp_c <= std_logic_vector(to_signed(125, 8));
      elsif k > 511 then
        temp_c <= std_logic_vector(to_signed(-40, 8));
      else
        temp_c <= TAB(k);
      end if;
    end if;
  end process;
end architecture rtl;

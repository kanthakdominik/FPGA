-- Funkcje pomocnicze do parametryzacji: logarytm dwójkowy z zaokrągleniem w górę i test potęgi dwójki.
-- Liczone na liczbach całkowitych (bez math_real), więc wynik jest dokładny także dla potęg dwójki.
package rtl_pkg is
  function clog2(n : positive) return natural;     -- najmniejsze k, dla którego 2**k >= n
  function is_pow2(n : positive) return boolean;
end package rtl_pkg;

package body rtl_pkg is
  function clog2(n : positive) return natural is
    variable k : natural  := 0;
    variable p : positive := 1;
  begin
    while p < n loop
      p := p * 2;
      k := k + 1;
    end loop;
    return k;
  end function clog2;

  function is_pow2(n : positive) return boolean is
  begin
    return 2 ** clog2(n) = n;
  end function is_pow2;
end package body rtl_pkg;

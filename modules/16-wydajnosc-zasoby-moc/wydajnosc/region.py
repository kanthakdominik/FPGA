# Skrypt nextpnr (--pre-place) dla 16.05: przypisuje komórki instancji u_a i u_b do prostokątnych
# regionów (odpowiednik LogicLock w Quartusie i Pblock w Vivado). Tryb ze zmiennej REGION:
#   blisko — oba regiony obok siebie w środku układu, daleko — na przeciwnych krańcach.
import os

tryb = os.environ.get("REGION", "blisko")
try:
    X, Y = ctx.getGridDimX(), ctx.getGridDimY()
except AttributeError:
    # starsze/inne wiązania Pythona: rozmiar siatki z położeń wszystkich elementów (bel)
    X = Y = 0
    for bel in ctx.getBels():
        loc = ctx.getBelLocation(bel)
        X, Y = max(X, loc.x + 1), max(Y, loc.y + 1)
s = 12                                  # bok regionu w kafelkach
if tryb == "daleko":
    ra = (2, 2, 2 + s, 2 + s)
    rb = (X - 3 - s, Y - 3 - s, X - 3, Y - 3)
else:
    cx, cy = X // 2, Y // 2
    ra = (cx - s, cy - s // 2, cx - 1, cy + s // 2)
    rb = (cx, cy - s // 2, cx + s - 1, cy + s // 2)
ctx.createRectangularRegion("reg_a", *ra)
ctx.createRectangularRegion("reg_b", *rb)
na = nb = 0
for nazwa, komorka in ctx.cells:
    if nazwa.startswith("u_a."):
        ctx.constrainCellToRegion(nazwa, "reg_a")
        na += 1
    elif nazwa.startswith("u_b."):
        ctx.constrainCellToRegion(nazwa, "reg_b")
        nb += 1
print(f"REGIONY {tryb}: siatka {X}x{Y}, reg_a {ra} ({na} komorek), reg_b {rb} ({nb} komorek)")

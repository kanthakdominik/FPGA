# Amaranth (28.06): symulacja w Pythonie, eksport do Veriloga i test wygenerowanego kodu w Icarusie.
#   pip install -r requirements.txt && make
all:
	python3 fir_amaranth.py
	iverilog -g2005 -o tb_fir_amaranth.vvp tb_fir_amaranth.v fir_amaranth.v
	vvp -n tb_fir_amaranth.vvp

clean:
	rm -f fir_amaranth.v tb_fir_amaranth.vvp

.PHONY: all clean

# Symulacja C jąder HLS (28.x) zwykłym g++: dyrektywy #pragma HLS są pomijane, sprawdzana jest funkcja.
# Ten sam kod i testbenche wchodzą do Vitis HLS (vitis_hls.tcl: csim, csynth, cosim) albo Bambu.
CXX      ?= g++
CXXFLAGS := -O2 -std=c++17 -Wall -Wextra -Werror -Wno-unknown-pragmas -Wno-unused-label
TESTY    := tb_fir tb_histogram tb_macierz tb_mlp

test: $(TESTY)
	@for t in $(TESTY); do echo "== $$t"; ./$$t || exit 1; done

tb_fir: tb_fir.cpp fir.cpp fir.h wektory.h
	$(CXX) $(CXXFLAGS) -o $@ tb_fir.cpp fir.cpp
tb_histogram: tb_histogram.cpp histogram.cpp histogram.h
	$(CXX) $(CXXFLAGS) -o $@ tb_histogram.cpp histogram.cpp
tb_macierz: tb_macierz.cpp macierz.cpp macierz.h
	$(CXX) $(CXXFLAGS) -o $@ tb_macierz.cpp macierz.cpp
tb_mlp: tb_mlp.cpp mlp.cpp mlp.h mlp_wagi.h wektory.h
	$(CXX) $(CXXFLAGS) -o $@ tb_mlp.cpp mlp.cpp

clean:
	rm -f $(TESTY)

.PHONY: test clean

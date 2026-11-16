# Wspólne reguły make dla projektów płytki DECA.
#
# Makefile w katalogu projektu (np. modules/00-srodowisko-pracy/deca/blink/Makefile):
#   PROJEKT := blink
#   include ../../../../plytka-deca/deca.mk
#
# Użycie:
#   make                     # utworzenie projektu i pełna kompilacja (domyślnie Verilog)
#   make JEZYK=vhdl          # to samo dla VHDL (albo sv)
#   make sram                # wgranie .sof przez JTAG (ulotne)
#   make flash               # wgranie .pof do wewnętrznej pamięci flash (trwałe)
#   make czas                # analiza czasowa i sprawdzenie zapasu we wszystkich modelach
#   make czysc               # usunięcie wszystkich plików generowanych
#
# Zmienne: JEZYK (verilog | vhdl | sv), UKLAD (np. 10M50DAF484C6G), KABEL (numer z jtagconfig).

DECA_KATALOG := $(dir $(lastword $(MAKEFILE_LIST)))

JEZYK  ?= verilog
UKLAD  ?= 10M50DAF484C6GES
KABEL  ?= 1
QSH    ?= quartus_sh
QSTA   ?= quartus_sta
QPGM   ?= quartus_pgm

ifndef PROJEKT
$(error Ustaw PROJEKT przed dołączeniem deca.mk)
endif

ROZSZ_verilog := v
ROZSZ_vhdl    := vhd
ROZSZ_sv      := sv
ROZSZ := $(ROZSZ_$(JEZYK))
ifeq ($(ROZSZ),)
$(error Nieznany JEZYK=$(JEZYK); dozwolone: verilog, vhdl, sv)
endif

SOF    := output_files/$(PROJEKT).sof
POF    := output_files/$(PROJEKT).pof
ZNACZNIK := .projekt-$(JEZYK)
ZRODLA := $(wildcard deca_top.$(ROZSZ) *.sdc ../../hdl/$(JEZYK)/*.$(ROZSZ))

.PHONY: all projekt kompilacja sram flash czas czysc

all: kompilacja

# Projekt Quartusa jest tworzony od nowa przy zmianie języka albo skryptu.
projekt: $(ZNACZNIK)

$(ZNACZNIK): utworz_projekt.tcl
	rm -f .projekt-*
	$(QSH) -t utworz_projekt.tcl $(JEZYK) $(UKLAD)
	touch $@

kompilacja: $(SOF)

$(SOF): $(ZNACZNIK) $(ZRODLA)
	$(QSH) --flow compile $(PROJEKT)

$(POF): $(SOF)

sram: $(SOF)
	$(QPGM) -c $(KABEL) -m jtag -o "p;$(SOF)"

flash: $(POF)
	$(QPGM) -c $(KABEL) -m jtag -o "p;$(POF)"

czas: $(SOF)
	$(QSTA) -t $(DECA_KATALOG)sprawdz_czasy.tcl $(PROJEKT)

czysc:
	rm -rf db incremental_db output_files qdb tmp-clearbox greybox_tmp .qsys_edit \
	       $(PROJEKT).qpf $(PROJEKT).qsf $(PROJEKT).qws .projekt-* *.rpt *.summary *.smsg *.done *.jdi *.pin *.sld

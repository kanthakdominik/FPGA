# Skrypt System Console (21.06): odczyt i zapis rejestrów przez JTAG to Avalon Master Bridge.
#   system-console --script=konsola.tcl      (płytka zaprogramowana plikiem rejestry.sof)
# Adresy bajtowe: ID 0x00, STER 0x04, STAN 0x08, PRZER 0x0C, MASKA 0x10, SKRYTKA 0x14.
set m [lindex [get_service_paths master] 0]
open_service master $m

puts "ID      = [master_read_32 $m 0x00 1]   (oczekiwane 0x21020001)"
puts "STAN    = [master_read_32 $m 0x08 1]   (bity 3:0 = SW1 SW0 KEY1 KEY0)"

master_write_32 $m 0x04 0x0000002A
puts "STER    = [master_read_32 $m 0x04 1]   (diody LED[6:0] = 0101010)"

master_write_32 $m 0x14 0xDEADBEEF
puts "SKRYTKA = [master_read_32 $m 0x14 1]"

puts "Nacisnij KEY1 i Enter..."
gets stdin
puts "PRZER   = [master_read_32 $m 0x0C 1]   (bit 0 = 1 po nacisnieciu)"
master_write_32 $m 0x10 0x00000001
puts "MASKA = 1: LED7 (irq) powinna swiecic. Enter skasuje PRZER (W1C)..."
gets stdin
master_write_32 $m 0x0C 0x00000001
puts "PRZER   = [master_read_32 $m 0x0C 1]   (0 - LED7 gasnie)"

close_service master $m

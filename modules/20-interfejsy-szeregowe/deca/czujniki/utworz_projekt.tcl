# Tworzy projekt Quartusa "czujniki" dla płytki DECA (moduł 20, 20.02/20.03/20.05): akcelerometr LIS2DH12
# (SPI), czujnik temperatury LM71 (SPI 3-przewodowe), czujnik wilgotności HDC1000 (I²C) i telemetria UART
# na GPIO0_D[0]. Linie I²C dostają dodatkowo słabe podciąganie w układzie.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile czujniki
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt czujniki $tu {spi_master i2c_master uart_tx akcel_lis2dh12 temp_lm71 hdc1000} \
    {MAX10_CLK1_50 przyciski przelaczniki diody akcelerometr czujnik_temperatury czujnik_wilgotnosci GPIO0_D[0]}

project_open czujniki
foreach s {RH_TEMP_I2C_SCL RH_TEMP_I2C_SDA} {
    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to $s
}
project_close

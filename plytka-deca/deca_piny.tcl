# Przypisania pinów płytki Arrow DECA (MAX 10 10M50DAF484) dla Quartusa.
# Źródło: DECA User Manual (Terasic, 2017), tabele 3-2..3-21, sprawdzone z LiteX i schematem płytki.
# Opis: plytka-deca/piny.md
#
# Użycie w skrypcie projektu (quartus_sh -t):
#   source deca_piny.tcl
#   deca_ustawienia_ukladu                      ;# rodzina, układ, banki I/O, konfiguracja
#   deca_pin MAX10_CLK1_50                      ;# pojedynczy sygnał
#   deca_grupa diody                            ;# cała grupa sygnałów
#
# Pamięć DDR3 i kamera MIPI nie są tu opisane — przypisania generują ich rdzenie IP (moduły 23 i 24).

package require ::quartus::project

# nazwa sygnału -> {pin standard grupa}
set ::DECA_PINY [dict create]
# --- Zegary
dict set ::DECA_PINY {MAX10_CLK1_50} [list PIN_M8 {2.5 V} zegary]
dict set ::DECA_PINY {MAX10_CLK2_50} [list PIN_P11 {3.3-V LVTTL} zegary]
dict set ::DECA_PINY {DDR3_CLK_50} [list PIN_N15 {1.5 V} zegary]
dict set ::DECA_PINY {ADC_CLK_10} [list PIN_M9 {2.5 V} zegary]
# --- Przyciski
dict set ::DECA_PINY {KEY[0]} [list PIN_H21 {1.5 V SCHMITT TRIGGER} przyciski]
dict set ::DECA_PINY {KEY[1]} [list PIN_H22 {1.5 V SCHMITT TRIGGER} przyciski]
# --- Przełączniki suwakowe
dict set ::DECA_PINY {SW[0]} [list PIN_J21 {1.5 V SCHMITT TRIGGER} przelaczniki]
dict set ::DECA_PINY {SW[1]} [list PIN_J22 {1.5 V SCHMITT TRIGGER} przelaczniki]
# --- Diody LED
dict set ::DECA_PINY {LED[0]} [list PIN_C7 {1.2 V} diody]
dict set ::DECA_PINY {LED[1]} [list PIN_C8 {1.2 V} diody]
dict set ::DECA_PINY {LED[2]} [list PIN_A6 {1.2 V} diody]
dict set ::DECA_PINY {LED[3]} [list PIN_B7 {1.2 V} diody]
dict set ::DECA_PINY {LED[4]} [list PIN_C4 {1.2 V} diody]
dict set ::DECA_PINY {LED[5]} [list PIN_A5 {1.2 V} diody]
dict set ::DECA_PINY {LED[6]} [list PIN_B4 {1.2 V} diody]
dict set ::DECA_PINY {LED[7]} [list PIN_C5 {1.2 V} diody]
# --- Przyciski pojemnościowe CapSense (I²C)
dict set ::DECA_PINY {CAP_SENSE_I2C_SCL} [list PIN_AB2 {3.3-V LVTTL} capsense]
dict set ::DECA_PINY {CAP_SENSE_I2C_SCA} [list PIN_AB3 {3.3-V LVTTL} capsense]
# --- Monitor zasilania (I²C)
dict set ::DECA_PINY {PMONITOR_I2C_SCL} [list PIN_Y3 {3.3-V LVTTL} monitor_zasilania]
dict set ::DECA_PINY {PMONITOR_I2C_SDA} [list PIN_Y1 {3.3-V LVTTL} monitor_zasilania]
dict set ::DECA_PINY {PMONITOR_ALERT} [list PIN_Y4 {3.3-V LVTTL} monitor_zasilania]
# --- Złącza rozszerzeń P8 i P9
dict set ::DECA_PINY {GPIO0_D[0]} [list PIN_W18 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[1]} [list PIN_Y18 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[2]} [list PIN_Y19 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[3]} [list PIN_AA17 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[4]} [list PIN_AA20 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[5]} [list PIN_AA19 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[6]} [list PIN_AB21 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[7]} [list PIN_AB20 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[8]} [list PIN_AB19 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[9]} [list PIN_Y16 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[10]} [list PIN_V16 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[11]} [list PIN_AB18 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[12]} [list PIN_V15 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[13]} [list PIN_W17 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[14]} [list PIN_AB17 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[15]} [list PIN_AA16 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[16]} [list PIN_AB16 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[17]} [list PIN_W16 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[18]} [list PIN_AB15 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[19]} [list PIN_W15 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[20]} [list PIN_Y14 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[21]} [list PIN_AA15 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[22]} [list PIN_AB14 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[23]} [list PIN_AA14 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[24]} [list PIN_AB13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[25]} [list PIN_AA13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[26]} [list PIN_AB12 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[27]} [list PIN_AA12 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[28]} [list PIN_AB11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[29]} [list PIN_AA11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[30]} [list PIN_AB10 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[31]} [list PIN_Y13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[32]} [list PIN_Y11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[33]} [list PIN_W13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[34]} [list PIN_W12 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[35]} [list PIN_W11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[36]} [list PIN_V12 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[37]} [list PIN_V11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[38]} [list PIN_V13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[39]} [list PIN_V14 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[40]} [list PIN_Y17 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[41]} [list PIN_W14 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[42]} [list PIN_U15 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO0_D[43]} [list PIN_R13 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[0]} [list PIN_Y5 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[1]} [list PIN_Y6 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[2]} [list PIN_W6 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[3]} [list PIN_W7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[4]} [list PIN_W8 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[5]} [list PIN_V8 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[6]} [list PIN_AB8 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[7]} [list PIN_V7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[8]} [list PIN_R11 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[9]} [list PIN_AB7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[10]} [list PIN_AB6 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[11]} [list PIN_AA7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[12]} [list PIN_AA6 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[13]} [list PIN_Y7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[14]} [list PIN_V10 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[15]} [list PIN_U7 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[16]} [list PIN_W9 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[17]} [list PIN_W5 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[18]} [list PIN_R9 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[19]} [list PIN_W4 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[20]} [list PIN_P9 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[21]} [list PIN_V17 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {GPIO1_D[22]} [list PIN_W3 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {SYS_RESET_n} [list PIN_AA2 {3.3-V LVTTL} zlacza]
dict set ::DECA_PINY {PWR_BUT} [list PIN_U6 {3.3-V LVTTL} zlacza]
# --- Kodek audio TLV320AIC3254
dict set ::DECA_PINY {AUDIO_MCLK} [list PIN_P14 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_BCLK} [list PIN_R14 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_WCLK} [list PIN_R15 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_DIN_MFP1} [list PIN_P15 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_DOUT_MFP2} [list PIN_P18 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_SCLK_MFP3} [list PIN_P19 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_SCL_SS_n} [list PIN_P20 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_SDA_MOSI} [list PIN_P21 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_MISO_MFP4} [list PIN_N21 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_SPI_SELECT} [list PIN_N22 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_RESET_n} [list PIN_M21 {1.5 V} audio]
dict set ::DECA_PINY {AUDIO_GPIO_MFP5} [list PIN_M22 {1.5 V} audio]
# --- Pamięć QSPI flash
dict set ::DECA_PINY {FLASH_DATA[0]} [list PIN_P12 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_DATA[1]} [list PIN_V4 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_DATA[2]} [list PIN_V5 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_DATA[3]} [list PIN_P10 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_DCLK} [list PIN_R12 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_NCSO} [list PIN_R10 {3.3-V LVTTL} qspi]
dict set ::DECA_PINY {FLASH_RESET_n} [list PIN_W10 {3.3-V LVTTL} qspi]
# --- Ethernet 10/100 (PHY)
dict set ::DECA_PINY {NET_TX_EN} [list PIN_P3 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_TX_CLK} [list PIN_T5 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_TXD[0]} [list PIN_U2 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_TXD[1]} [list PIN_W1 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_TXD[2]} [list PIN_N9 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_TXD[3]} [list PIN_W2 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RX_DV} [list PIN_P4 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RX_ER} [list PIN_V1 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RXD[0]} [list PIN_U5 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RXD[1]} [list PIN_U4 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RXD[2]} [list PIN_R7 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RXD[3]} [list PIN_P8 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RX_CLK} [list PIN_T6 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_RESET_n} [list PIN_R3 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_MDIO} [list PIN_N8 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_MDC} [list PIN_R5 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_COL} [list PIN_R4 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_CRS} [list PIN_P5 {2.5 V} ethernet]
dict set ::DECA_PINY {NET_PCF_EN} [list PIN_V9 {3.3-V LVTTL} ethernet]
# --- Nadajnik HDMI ADV7513
dict set ::DECA_PINY {HDMI_TX_D[0]} [list PIN_C18 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[1]} [list PIN_D17 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[2]} [list PIN_C17 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[3]} [list PIN_C19 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[4]} [list PIN_D14 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[5]} [list PIN_B19 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[6]} [list PIN_D13 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[7]} [list PIN_A19 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[8]} [list PIN_C14 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[9]} [list PIN_A17 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[10]} [list PIN_B16 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[11]} [list PIN_C15 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[12]} [list PIN_A14 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[13]} [list PIN_A15 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[14]} [list PIN_A12 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[15]} [list PIN_A16 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[16]} [list PIN_A13 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[17]} [list PIN_C16 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[18]} [list PIN_C12 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[19]} [list PIN_B17 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[20]} [list PIN_B12 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[21]} [list PIN_B14 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[22]} [list PIN_A18 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_D[23]} [list PIN_C13 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_CLK} [list PIN_A20 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_DE} [list PIN_C9 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_HS} [list PIN_B11 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_VS} [list PIN_C11 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_TX_INT} [list PIN_B10 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2C_SCL} [list PIN_C10 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2C_SDA} [list PIN_B15 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_MCLK} [list PIN_A7 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_LRCLK} [list PIN_A10 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_SCLK} [list PIN_D12 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2S[0]} [list PIN_A9 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2S[1]} [list PIN_A11 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2S[2]} [list PIN_A8 {1.8 V} hdmi]
dict set ::DECA_PINY {HDMI_I2S[3]} [list PIN_B8 {1.8 V} hdmi]
# --- USB 2.0 OTG (PHY ULPI)
dict set ::DECA_PINY {USB_DATA[0]} [list PIN_E12 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[1]} [list PIN_E13 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[2]} [list PIN_H13 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[3]} [list PIN_E14 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[4]} [list PIN_H14 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[5]} [list PIN_D15 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[6]} [list PIN_E15 {1.8 V} usb]
dict set ::DECA_PINY {USB_DATA[7]} [list PIN_F15 {1.8 V} usb]
dict set ::DECA_PINY {USB_NXT} [list PIN_H12 {1.8 V} usb]
dict set ::DECA_PINY {USB_DIR} [list PIN_J13 {1.8 V} usb]
dict set ::DECA_PINY {USB_STP} [list PIN_J12 {1.8 V} usb]
dict set ::DECA_PINY {USB_CS} [list PIN_J11 {1.8 V} usb]
dict set ::DECA_PINY {USB_RESET_n} [list PIN_E16 {1.8 V} usb]
dict set ::DECA_PINY {USB_CLKIN} [list PIN_H11 {1.2 V} usb]
dict set ::DECA_PINY {USB_FAULT_n} [list PIN_D8 {1.2 V} usb]
# --- Czujnik zbliżeniowy i światła Si1143
dict set ::DECA_PINY {LIGHT_I2C_SCL} [list PIN_Y8 {3.3-V LVTTL} czujnik_swiatla]
dict set ::DECA_PINY {LIGHT_I2C_SDA} [list PIN_AA8 {3.3-V LVTTL} czujnik_swiatla]
dict set ::DECA_PINY {LIGHT_INT} [list PIN_AA9 {3.3-V LVTTL} czujnik_swiatla]
# --- Czujnik wilgotności i temperatury HDC1000
dict set ::DECA_PINY {RH_TEMP_I2C_SCL} [list PIN_Y10 {3.3-V LVTTL} czujnik_wilgotnosci]
dict set ::DECA_PINY {RH_TEMP_I2C_SDA} [list PIN_AA10 {3.3-V LVTTL} czujnik_wilgotnosci]
dict set ::DECA_PINY {RH_TEMP_DRDY_n} [list PIN_AB9 {3.3-V LVTTL} czujnik_wilgotnosci]
# --- Czujnik temperatury
dict set ::DECA_PINY {TEMP_SC} [list PIN_AA1 {3.3-V LVTTL} czujnik_temperatury]
dict set ::DECA_PINY {TEMP_SIO} [list PIN_Y2 {3.3-V LVTTL} czujnik_temperatury]
dict set ::DECA_PINY {TEMP_CS_n} [list PIN_AB4 {3.3-V LVTTL} czujnik_temperatury]
# --- Akcelerometr
dict set ::DECA_PINY {G_SENSOR_SDI} [list PIN_C6 {1.2 V} akcelerometr]
dict set ::DECA_PINY {G_SENSOR_SDO} [list PIN_D5 {1.2 V} akcelerometr]
dict set ::DECA_PINY {G_SENSOR_CS_n} [list PIN_E9 {1.2 V} akcelerometr]
dict set ::DECA_PINY {G_SENSOR_SCLK} [list PIN_B5 {1.2 V} akcelerometr]
dict set ::DECA_PINY {G_SENSOR_INT1} [list PIN_E8 {1.2 V} akcelerometr]
dict set ::DECA_PINY {G_SENSOR_INT2} [list PIN_D7 {1.2 V} akcelerometr]
# --- Gniazdo microSD
dict set ::DECA_PINY {SD_CLK} [list PIN_T20 {1.5 V} microsd]
dict set ::DECA_PINY {SD_FB_CLK} [list PIN_R22 {1.5 V} microsd]
dict set ::DECA_PINY {SD_CMD} [list PIN_T21 {1.5 V} microsd]
dict set ::DECA_PINY {SD_CMD_DIR} [list PIN_U22 {1.5 V} microsd]
dict set ::DECA_PINY {SD_D0_DIR} [list PIN_T22 {1.5 V} microsd]
dict set ::DECA_PINY {SD_D123_DIR} [list PIN_U21 {1.5 V} microsd]
dict set ::DECA_PINY {SD_SEL} [list PIN_P13 {3.3-V LVTTL} microsd]
dict set ::DECA_PINY {SD_DAT[0]} [list PIN_R18 {1.5 V} microsd]
dict set ::DECA_PINY {SD_DAT[1]} [list PIN_T18 {1.5 V} microsd]
dict set ::DECA_PINY {SD_DAT[2]} [list PIN_T19 {1.5 V} microsd]
dict set ::DECA_PINY {SD_DAT[3]} [list PIN_R20 {1.5 V} microsd]

# Ustawienia układu i płytki. Wczesne płytki DECA mają układ w wersji inżynierskiej (ES) — sprawdź napis na układzie.
proc deca_ustawienia_ukladu {{uklad 10M50DAF484C6GES}} {
    set_global_assignment -name FAMILY "MAX 10"
    set_global_assignment -name DEVICE $uklad
    set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
    set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
    # napięcia banków I/O na płytce DECA
    foreach {bank v} {1A 2.5V 1B 2.5V 2 2.5V 3 3.3V 4 3.3V 5 1.5V 6 1.5V 7 1.8V 8 1.2V} {
        set_global_assignment -name IOBANK_VCCIO $v -section_id $bank
    }
    # konfiguracja z wewnętrznej pamięci flash, piny konfiguracyjne jako zwykłe I/O
    set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"
    set_global_assignment -name USE_CONFIGURATION_DEVICE OFF
    set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
    set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF
    set_global_assignment -name FORCE_CONFIGURATION_VCCIO ON
    set_global_assignment -name AUTO_RESTART_CONFIGURATION OFF
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
}

# Przypisanie jednego sygnału (nazwa jak w instrukcji płytki, np. LED[0], KEY[1], MAX10_CLK1_50).
proc deca_pin {sygnal} {
    if {![dict exists $::DECA_PINY $sygnal]} {
        error "deca_pin: nieznany sygnał $sygnal (zobacz plytka-deca/piny.md)"
    }
    lassign [dict get $::DECA_PINY $sygnal] pin standard
    set_location_assignment $pin -to $sygnal
    set_instance_assignment -name IO_STANDARD $standard -to $sygnal
}

# Przypisanie całej grupy: zegary, przyciski, przelaczniki, diody, capsense, monitor_zasilania, zlacza, audio, qspi, ethernet, hdmi, usb, czujnik_swiatla, czujnik_wilgotnosci, czujnik_temperatury, akcelerometr, microsd
proc deca_grupa {grupa} {
    set n 0
    dict for {sygnal opis} $::DECA_PINY {
        if {[lindex $opis 2] eq $grupa} { deca_pin $sygnal; incr n }
    }
    if {$n == 0} { error "deca_grupa: nieznana grupa $grupa" }
}

# Piny płytki DECA

[← płytka DECA](README.md)

Pełne przypisanie sygnałów płytki do wyprowadzeń układu MAX 10, przepisane z *DECA User Manual* (Terasic, 2017, tabele 3-2 do 3-21) i sprawdzone z opisem płytki w LiteX (`litex_boards/platforms/terasic_deca.py`), szablonem DECAfpga i schematem płytki. Pięć wierszy uszkodzonych w instrukcji (brak nazwy albo standardu) uzupełniono ze schematu — są oznaczone ✱.

Kolumna **Standard w Quartusie** to dokładna wartość do `set_instance_assignment -name IO_STANDARD`. Te same dane są w [deca_piny.tcl](deca_piny.tcl).

## Banki I/O i napięcia

| Bank | VCCIO | Co jest podłączone |
|------|-------|--------------------|
| 1A, 1B, 2 | 2,5 V | zegary `MAX10_CLK1_50` i `ADC_CLK_10`, Ethernet, MIPI (część), wejścia ADC |
| 3, 4 | 3,3 V | złącza P8 i P9, czujniki, QSPI, CapSense, `MAX10_CLK2_50` |
| 5, 6 | 1,5 V | DDR3, przyciski, przełączniki, kodek audio, microSD |
| 7 | 1,8 V | nadajnik HDMI, USB ULPI |
| 8 | 1,2 V | diody LED, akcelerometr, linie LP kamery MIPI |

⚠️ Standard I/O sygnału musi pasować do napięcia banku. Quartus odrzuci np. `3.3-V LVTTL` na diodzie w banku 8 (1,2 V).

## Zegary

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `MAX10_CLK1_50` | M8 | 2.5 V | 50 MHz clock input |
| `MAX10_CLK2_50` | P11 | 3.3-V LVTTL | 50 MHz clock input |
| `DDR3_CLK_50` | N15 | 1.5 V | 50 MHz clock input |
| `ADC_CLK_10` | M9 | 2.5 V | 10 MHz clock input |

## Przyciski

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `KEY[0]` | H21 | 1.5 V SCHMITT TRIGGER | Push-button[0] |
| `KEY[1]` | H22 | 1.5 V SCHMITT TRIGGER | Push-button[1] |

## Przełączniki suwakowe

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `SW[0]` | J21 | 1.5 V SCHMITT TRIGGER | Slide Switch[0] |
| `SW[1]` | J22 | 1.5 V SCHMITT TRIGGER | Slide Switch[1] |

## Diody LED

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `LED[0]` | C7 | 1.2 V | LED [0] |
| `LED[1]` | C8 | 1.2 V | LED [1] |
| `LED[2]` | A6 | 1.2 V | LED [2] |
| `LED[3]` | B7 | 1.2 V | LED [3] |
| `LED[4]` | C4 | 1.2 V | LED [4] |
| `LED[5]` | A5 | 1.2 V | LED [5] |
| `LED[6]` | B4 | 1.2 V | LED [6] |
| `LED[7]` | C5 | 1.2 V | LED [7] |

## Przyciski pojemnościowe CapSense (I²C)

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `CAP_SENSE_I2C_SCL` | AB2 | 3.3-V LVTTL | CapSense SCL |
| `CAP_SENSE_I2C_SCA` | AB3 | 3.3-V LVTTL | CapSense SDA |

## Monitor zasilania (I²C)

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `PMONITOR_I2C_SCL` | Y3 | 3.3-V LVTTL | Power Monitor SCL |
| `PMONITOR_I2C_SDA` | Y1 | 3.3-V LVTTL | Power Monitor SDA |
| `PMONITOR_ALERT` | Y4 | 3.3-V LVTTL | Power Monitor ALERT |

## Złącza rozszerzeń P8 i P9

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `GPIO0_D[0]` | W18 | 3.3-V LVTTL | P8 GPIO0_D0] |
| `GPIO0_D[1]` | Y18 | 3.3-V LVTTL | P8 GPIO0_D1] |
| `GPIO0_D[2]` | Y19 | 3.3-V LVTTL | P8 GPIO0_D2] |
| `GPIO0_D[3]` | AA17 | 3.3-V LVTTL | P8 GPIO0_D3] |
| `GPIO0_D[4]` | AA20 | 3.3-V LVTTL | P8 GPIO0_D4] |
| `GPIO0_D[5]` | AA19 | 3.3-V LVTTL | P8 GPIO0_D5] |
| `GPIO0_D[6]` | AB21 | 3.3-V LVTTL | P8 GPIO0_D6] |
| `GPIO0_D[7]` | AB20 | 3.3-V LVTTL | P8 GPIO0_D7] |
| `GPIO0_D[8]` | AB19 | 3.3-V LVTTL | P8 GPIO0_D8] |
| `GPIO0_D[9]` | Y16 | 3.3-V LVTTL | P8 GPIO0_D9] |
| `GPIO0_D[10]` | V16 | 3.3-V LVTTL | P8 GPIO0_D10] |
| `GPIO0_D[11]` | AB18 | 3.3-V LVTTL | P8 GPIO0_D11] |
| `GPIO0_D[12]` | V15 | 3.3-V LVTTL | P8 GPIO0_D12] |
| `GPIO0_D[13]` | W17 | 3.3-V LVTTL | P8 GPIO0_D13] |
| `GPIO0_D[14]` | AB17 | 3.3-V LVTTL | P8 GPIO0_D14] |
| `GPIO0_D[15]` | AA16 | 3.3-V LVTTL | P8 GPIO0_D15] |
| `GPIO0_D[16]` | AB16 | 3.3-V LVTTL | P8 GPIO0_D16] |
| `GPIO0_D[17]` | W16 | 3.3-V LVTTL | P8 GPIO0_D17] |
| `GPIO0_D[18]` | AB15 | 3.3-V LVTTL | P8 GPIO0_D18] |
| `GPIO0_D[19]` | W15 | 3.3-V LVTTL | P8 GPIO0_D19] |
| `GPIO0_D[20]` | Y14 | 3.3-V LVTTL | P8 GPIO0_D20] |
| `GPIO0_D[21]` | AA15 | 3.3-V LVTTL | P8 GPIO0_D21] |
| `GPIO0_D[22]` | AB14 | 3.3-V LVTTL | P8 GPIO0_D22] |
| `GPIO0_D[23]` | AA14 | 3.3-V LVTTL | P8 GPIO0_D23] |
| `GPIO0_D[24]` | AB13 | 3.3-V LVTTL | P8 GPIO0_D24] |
| `GPIO0_D[25]` | AA13 | 3.3-V LVTTL | P8 GPIO0_D25] |
| `GPIO0_D[26]` | AB12 | 3.3-V LVTTL | P8 GPIO0_D26] |
| `GPIO0_D[27]` | AA12 | 3.3-V LVTTL | P8 GPIO0_D27] |
| `GPIO0_D[28]` | AB11 | 3.3-V LVTTL | P8 GPIO0_D28] |
| `GPIO0_D[29]` | AA11 | 3.3-V LVTTL | P8 GPIO0_D29] |
| `GPIO0_D[30]` | AB10 | 3.3-V LVTTL | P8 GPIO0_D30] |
| `GPIO0_D[31]` | Y13 | 3.3-V LVTTL | P8 GPIO0_D31] |
| `GPIO0_D[32]` | Y11 | 3.3-V LVTTL | P8 GPIO0_D32] |
| `GPIO0_D[33]` | W13 | 3.3-V LVTTL | P8 GPIO0_D33] |
| `GPIO0_D[34]` | W12 | 3.3-V LVTTL | P8 GPIO0_D34] |
| `GPIO0_D[35]` | W11 | 3.3-V LVTTL | P8 GPIO0_D35] |
| `GPIO0_D[36]` | V12 | 3.3-V LVTTL | P8 GPIO0_D36] |
| `GPIO0_D[37]` | V11 | 3.3-V LVTTL | P8 GPIO0_D37] |
| `GPIO0_D[38]` | V13 | 3.3-V LVTTL | P8 GPIO0_D38] |
| `GPIO0_D[39]` | V14 | 3.3-V LVTTL | P8 GPIO0_D39] |
| `GPIO0_D[40]` | Y17 | 3.3-V LVTTL | P8 GPIO0_D40] |
| `GPIO0_D[41]` | W14 | 3.3-V LVTTL | P8 GPIO0_D41] |
| `GPIO0_D[42]` | U15 | 3.3-V LVTTL | P8 GPIO0_D42] |
| `GPIO0_D[43]` | R13 | 3.3-V LVTTL | P8 GPIO0_D43] |
| `GPIO1_D[0]` | Y5 | 3.3-V LVTTL | GPIO (P9) Connection 1[0] |
| `GPIO1_D[1]` | Y6 | 3.3-V LVTTL | GPIO (P9) Connection 1[1] |
| `GPIO1_D[2]` | W6 | 3.3-V LVTTL | GPIO (P9) Connection 1[2] |
| `GPIO1_D[3]` | W7 | 3.3-V LVTTL | GPIO (P9) Connection 1[3] |
| `GPIO1_D[4]` | W8 | 3.3-V LVTTL | GPIO (P9) Connection 1[4] |
| `GPIO1_D[5]` | V8 | 3.3-V LVTTL | GPIO (P9) Connection 1[5] |
| `GPIO1_D[6]` | AB8 | 3.3-V LVTTL | GPIO (P9) Connection 1[6] |
| `GPIO1_D[7]` | V7 | 3.3-V LVTTL | GPIO (P9) Connection 1[7] |
| `GPIO1_D[8]` | R11 | 3.3-V LVTTL | GPIO (P9) Connection 1[8] |
| `GPIO1_D[9]` | AB7 | 3.3-V LVTTL | GPIO (P9) Connection 1[9] |
| `GPIO1_D[10]` | AB6 | 3.3-V LVTTL | GPIO (P9) Connection 1[10] |
| `GPIO1_D[11]` | AA7 | 3.3-V LVTTL | GPIO (P9) Connection 1[11] |
| `GPIO1_D[12]` | AA6 | 3.3-V LVTTL | GPIO (P9) Connection 1[12] |
| `GPIO1_D[13]` | Y7 | 3.3-V LVTTL | GPIO (P9) Connection 1[13] |
| `GPIO1_D[14]` | V10 | 3.3-V LVTTL | GPIO (P9) Connection 1[14] |
| `GPIO1_D[15]` | U7 | 3.3-V LVTTL | GPIO (P9) Connection 1[15] |
| `GPIO1_D[16]` | W9 | 3.3-V LVTTL | GPIO (P9) Connection 1[16] |
| `GPIO1_D[17]` | W5 | 3.3-V LVTTL | GPIO (P9) Connection 1[17] |
| `GPIO1_D[18]` | R9 | 3.3-V LVTTL | GPIO (P9) Connection 1[18] |
| `GPIO1_D[19]` | W4 | 3.3-V LVTTL | GPIO (P9) Connection 1[19] |
| `GPIO1_D[20]` | P9 | 3.3-V LVTTL | GPIO (P9) Connection 1[20] |
| `GPIO1_D[21]` | V17 | 3.3-V LVTTL | GPIO (P9) Connection 1[21] |
| `GPIO1_D[22]` | W3 | 3.3-V LVTTL | GPIO (P9) Connection 1[22] |
| `SYS_RESET_n` ✱ | AA2 | 3.3-V LVTTL | P9 SYS_RESET_n |
| `PWR_BUT` | U6 | 3.3-V LVTTL | GPIO (P9) Connection PWR_BUT |
| `ADC1IN1` | F5 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [1] |
| `ADC1IN2` | F4 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [2] |
| `ADC1IN3` | J8 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [3] |
| `ADC1IN4` | J9 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [4] |
| `ADC1IN5` | J4 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [5] |
| `ADC1IN6` | H3 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [6] |
| `ADC1IN7` | K5 | — (wejście analogowe ADC) | GPIO (P9) ADC1 Analog Input [7] |

## Kodek audio TLV320AIC3254

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `AUDIO_MCLK` | P14 | 1.5 V | Master output Clock |
| `AUDIO_BCLK` | R14 | 1.5 V | Audio serial data bus (primary) bit clock |
| `AUDIO_WCLK` | R15 | 1.5 V | Audio serial data bus (primary) word clock |
| `AUDIO_DIN_MFP1` ✱ | P15 | 1.5 V | Audio serial data bus data output |
| `AUDIO_DOUT_MFP2` | P18 | 1.5 V | Audio serial data bus data input/general purpose input |
| `AUDIO_SCLK_MFP3` | P19 | 1.5 V | SPI serial Clock/headphone-detect output |
| `AUDIO_SCL_SS_n` | P20 | 1.5 V | I2C Clock/SPI interface mode chip-select signal |
| `AUDIO_SDA_MOSI` | P21 | 1.5 V | I2C Data/SPI interface mode serial data output |
| `AUDIO_MISO_MFP4` | N21 | 1.5 V | Serial data input/General purpose input |
| `AUDIO_SPI_SELECT` | N22 | 1.5 V | Control mode select pin |
| `AUDIO_RESET_n` | M21 | 1.5 V | Reset signal |
| `AUDIO_GPIO_MFP5` | M22 | 1.5 V | General Purpose digital IO/CLKOUT input |

## Pamięć DDR3

_Tych pinów nie ma w `deca_piny.tcl` — przypisania generuje rdzeń IP (kontroler DDR3 UniPHY, odbiornik MIPI) w modułach 23 i 24._

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `DDR3_A[0]` | E21 | SSTL-15 CLASS I | DDR3 Address[0] |
| `DDR3_A[1]` | V20 | SSTL-15 CLASS I | DDR3 Address[1] |
| `DDR3_A[2]` | V21 | SSTL-15 CLASS I | DDR3 Address[2] |
| `DDR3_A[3]` | C20 | SSTL-15 CLASS I | DDR3 Address[3] |
| `DDR3_A[4]` | Y21 | SSTL-15 CLASS I | DDR3 Address[4] |
| `DDR3_A[5]` | J14 | SSTL-15 CLASS I | DDR3 Address[5] |
| `DDR3_A[6]` | V18 | SSTL-15 CLASS I | DDR3 Address[6] |
| `DDR3_A[7]` | U20 | SSTL-15 CLASS I | DDR3 Address[7] |
| `DDR3_A[8]` | Y20 | SSTL-15 CLASS I | DDR3 Address[8] |
| `DDR3_A[9]` | W22 | SSTL-15 CLASS I | DDR3 Address[9] |
| `DDR3_A[10]` | C22 | SSTL-15 CLASS I | DDR3 Address[10] |
| `DDR3_A[11]` | Y22 | SSTL-15 CLASS I | DDR3 Address[11] |
| `DDR3_A[12]` | N18 | SSTL-15 CLASS I | DDR3 Address[12] |
| `DDR3_A[13]` | V22 | SSTL-15 CLASS I | DDR3 Address[13] |
| `DDR3_A[14]` | W20 | SSTL-15 CLASS I | DDR3 Address[14] |
| `DDR3_BA[0]` | D19 | SSTL-15 CLASS I | DDR3 Bank Address[0] |
| `DDR3_BA[1]` | W19 | SSTL-15 CLASS I | DDR3 Bank Address[1] |
| `DDR3_BA[2]` | F19 | SSTL-15 CLASS I | DDR3 Bank Address[2] |
| `DDR3_CAS_n` | E20 | SSTL-15 CLASS I | DDR3 Column Address Strobe |
| `DDR3_CKE` | B22 | SSTL-15 CLASS I | Clock Enable pin for DDR3 |
| `DDR3_CK_n` ✱ | E18 | DIFFERENTIAL 1.5-V SSTL CLASS I | Clock n for DDR3 |
| `DDR3_CK_p` ✱ | D18 | DIFFERENTIAL 1.5-V SSTL CLASS I | Clock p for DDR3 |
| `DDR3_CS_n` | F22 | SSTL-15 CLASS I | DDR3 Chip Select |
| `DDR3_DM[0]` | N19 | SSTL-15 CLASS I | DDR3 Data Mask[0] |
| `DDR3_DM[1]` | J15 | SSTL-15 CLASS I | DDR3 Data Mask[1] |
| `DDR3_DQ[0]` | L20 | SSTL-15 CLASS I | DDR3 Data[0] |
| `DDR3_DQ[1]` | L19 | SSTL-15 CLASS I | DDR3 Data[1] |
| `DDR3_DQ[2]` | L18 | SSTL-15 CLASS I | DDR3 Data[2] |
| `DDR3_DQ[3]` | M15 | SSTL-15 CLASS I | DDR3 Data[3] |
| `DDR3_DQ[4]` | M18 | SSTL-15 CLASS I | DDR3 Data[4] |
| `DDR3_DQ[5]` | M14 | SSTL-15 CLASS I | DDR3 Data[5] |
| `DDR3_DQ[6]` | M20 | SSTL-15 CLASS I | DDR3 Data[6] |
| `DDR3_DQ[7]` | N20 | SSTL-15 CLASS I | DDR3 Data[7] |
| `DDR3_DQ[8]` | K19 | SSTL-15 CLASS I | DDR3 Data[8] |
| `DDR3_DQ[9]` | K18 | SSTL-15 CLASS I | DDR3 Data[9] |
| `DDR3_DQ[10]` | J18 | SSTL-15 CLASS I | DDR3 Data[10] |
| `DDR3_DQ[11]` | K20 | SSTL-15 CLASS I | DDR3 Data[11] |
| `DDR3_DQ[12]` | H18 | SSTL-15 CLASS I | DDR3 Data[12] |
| `DDR3_DQ[13]` | J20 | SSTL-15 CLASS I | DDR3 Data[13] |
| `DDR3_DQ[14]` | H20 | SSTL-15 CLASS I | DDR3 Data[14] |
| `DDR3_DQ[15]` | H19 | SSTL-15 CLASS I | DDR3 Data[15] |
| `DDR3_DQS_n[0]` | L15 | DIFFERENTIAL 1.5-V SSTL CLASS I | DDR3 Data Strobe n[0] |
| `DDR3_DQS_n[1]` | K15 | DIFFERENTIAL 1.5-V SSTL CLASS I | DDR3 Data Strobe n[1] |
| `DDR3_DQS_p[0]` | L14 | DIFFERENTIAL 1.5-V SSTL CLASS I | DDR3 Data Strobe p[0] |
| `DDR3_DQS_p[1]` | K14 | DIFFERENTIAL 1.5-V SSTL CLASS I | DDR3 Data Strobe p[1] |
| `DDR3_ODT` | G22 | SSTL-15 CLASS I | DDR3 On-die Termination |
| `DDR3_RAS_n` | D22 | SSTL-15 CLASS I | DDR3 Row Address Strobe |
| `DDR3_RESET_n` | U19 | SSTL-15 CLASS I | DDR3 Reset |
| `DDR3_WE_n` | E22 | SSTL-15 CLASS I | DDR3 Write Enable |

## Pamięć QSPI flash

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `FLASH_DATA[0]` | P12 | 3.3-V LVTTL | FLASH Data[0] |
| `FLASH_DATA[1]` | V4 | 3.3-V LVTTL | FLASH Data[1] |
| `FLASH_DATA[2]` | V5 | 3.3-V LVTTL | FLASH Data[2] |
| `FLASH_DATA[3]` | P10 | 3.3-V LVTTL | FLASH Data[3] |
| `FLASH_DCLK` | R12 | 3.3-V LVTTL | FLASH Data Clock |
| `FLASH_NCSO` | R10 | 3.3-V LVTTL | FLASH Chip Enable |
| `FLASH_RESET_n` | W10 | 3.3-V LVTTL | FLASH Chip Reset |

## Ethernet 10/100 (PHY)

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `NET_TX_EN` | P3 | 2.5 V | GMII and MII transmit enable |
| `NET_TX_CLK` | T5 | 2.5 V | MII transmit clock |
| `NET_TXD[0]` | U2 | 2.5 V | MII transmit data[0] |
| `NET_TXD[1]` | W1 | 2.5 V | MII transmit data[1] |
| `NET_TXD[2]` | N9 | 2.5 V | MII transmit data[2] |
| `NET_TXD[3]` | W2 | 2.5 V | MII transmit data[3] |
| `NET_RX_DV` | P4 | 2.5 V | GMII and MII receive data valid |
| `NET_RX_ER` | V1 | 2.5 V | GMII and MII receive data valid |
| `NET_RXD[0]` | U5 | 2.5 V | GMII and MII receive data[0] |
| `NET_RXD[1]` | U4 | 2.5 V | GMII and MII receive data[1] |
| `NET_RXD[2]` | R7 | 2.5 V | GMII and MII receive data[2] |
| `NET_RXD[3]` | P8 | 2.5 V | GMII and MII receive data[3] |
| `NET_RX_CLK` | T6 | 2.5 V | GMII and MII receive clock |
| `NET_RESET_n` | R3 | 2.5 V | Hardware Reset Signal |
| `NET_MDIO` | N8 | 2.5 V | Management Data |
| `NET_MDC` | R5 | 2.5 V | Management Data Clock Reference |
| `NET_COL` | R4 | 2.5 V | Interrupt Open Drain Output |
| `NET_CRS` | P5 | 2.5 V | GMII Transmit Clock |
| `NET_PCF_EN` | V9 | 3.3-V LVTTL | PHY control frame enable |

## Nadajnik HDMI ADV7513

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `HDMI_TX_D[0]` | C18 | 1.8 V | Video Data bus |
| `HDMI_TX_D[1]` | D17 | 1.8 V | Video Data bus |
| `HDMI_TX_D[2]` | C17 | 1.8 V | Video Data bus |
| `HDMI_TX_D[3]` | C19 | 1.8 V | Video Data bus |
| `HDMI_TX_D[4]` | D14 | 1.8 V | Video Data bus |
| `HDMI_TX_D[5]` | B19 | 1.8 V | Video Data bus |
| `HDMI_TX_D[6]` | D13 | 1.8 V | Video Data bus |
| `HDMI_TX_D[7]` | A19 | 1.8 V | Video Data bus |
| `HDMI_TX_D[8]` | C14 | 1.8 V | Video Data bus |
| `HDMI_TX_D[9]` | A17 | 1.8 V | Video Data bus |
| `HDMI_TX_D[10]` | B16 | 1.8 V | Video Data bus |
| `HDMI_TX_D[11]` | C15 | 1.8 V | Video Data bus |
| `HDMI_TX_D[12]` | A14 | 1.8 V | Video Data bus |
| `HDMI_TX_D[13]` | A15 | 1.8 V | Video Data bus |
| `HDMI_TX_D[14]` | A12 | 1.8 V | Video Data bus |
| `HDMI_TX_D[15]` | A16 | 1.8 V | Video Data bus |
| `HDMI_TX_D[16]` | A13 | 1.8 V | Video Data bus |
| `HDMI_TX_D[17]` | C16 | 1.8 V | Video Data bus |
| `HDMI_TX_D[18]` | C12 | 1.8 V | Video Data bus |
| `HDMI_TX_D[19]` | B17 | 1.8 V | Video Data bus |
| `HDMI_TX_D[20]` | B12 | 1.8 V | Video Data bus |
| `HDMI_TX_D[21]` | B14 | 1.8 V | Video Data bus |
| `HDMI_TX_D[22]` | A18 | 1.8 V | Video Data bus |
| `HDMI_TX_D[23]` | C13 | 1.8 V | Video Data bus |
| `HDMI_TX_CLK` | A20 | 1.8 V | Video Clock |
| `HDMI_TX_DE` ✱ | C9 | 1.8 V | Data enable |
| `HDMI_TX_HS` | B11 | 1.8 V | Horizontal Synchronization |
| `HDMI_TX_VS` | C11 | 1.8 V | Vertical Synchronization |
| `HDMI_TX_INT` | B10 | 1.8 V | Interrupt Signal |
| `HDMI_I2C_SCL` | C10 | 1.8 V | I2C Clock |
| `HDMI_I2C_SDA` | B15 | 1.8 V | I2C Data |
| `HDMI_MCLK` | A7 | 1.8 V | Audio Reference Clock Input |
| `HDMI_LRCLK` | A10 | 1.8 V | Left/Right Channel Signal Input |
| `HDMI_SCLK` | D12 | 1.8 V | I2S Audio Clock Input |
| `HDMI_I2S[0]` | A9 | 1.8 V | I2C Channel 0 Audio Data Input |
| `HDMI_I2S[1]` | A11 | 1.8 V | I2C Channel 1 Audio Data Input |
| `HDMI_I2S[2]` | A8 | 1.8 V | I2C Channel 2 Audio Data Input |
| `HDMI_I2S[3]` | B8 | 1.8 V | I2C Channel 3 Audio Data Input |

## USB 2.0 OTG (PHY ULPI)

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `USB_DATA[0]` | E12 | 1.8 V | ULPI DATA input/output signal 0 |
| `USB_DATA[1]` | E13 | 1.8 V | ULPI DATA input/output signal 1 |
| `USB_DATA[2]` | H13 | 1.8 V | ULPI DATA input/output signal 2 |
| `USB_DATA[3]` | E14 | 1.8 V | ULPI DATA input/output signal 3 |
| `USB_DATA[4]` | H14 | 1.8 V | ULPI DATA input/output signal 4 |
| `USB_DATA[5]` | D15 | 1.8 V | ULPI DATA input/output signal 5 |
| `USB_DATA[6]` | E15 | 1.8 V | ULPI DATA input/output signal 6 |
| `USB_DATA[7]` | F15 | 1.8 V | ULPI DATA input/output signal 7 |
| `USB_NXT` | H12 | 1.8 V | ULPI NXT output signal |
| `USB_DIR` | J13 | 1.8 V | ULPI DIR output signal |
| `USB_STP` | J12 | 1.8 V | ULPI STP input signal |
| `USB_CS` | J11 | 1.8 V | Active-high chip select pin |
| `USB_RESET_n` | E16 | 1.8 V | Reset pin used to reset all digital registers |
| `USB_CLKIN` | H11 | 1.2 V | ULPI 60 MHz output clock |
| `USB_FAULT_n` | D8 | 1.2 V | Fault input from USB power switch |

## Złącze kamery MIPI CSI-2

_Tych pinów nie ma w `deca_piny.tcl` — przypisania generuje rdzeń IP (kontroler DDR3 UniPHY, odbiornik MIPI) w modułach 23 i 24._

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `MIPI_MD_p[0]` | R2 | 2.5 V | HS Differential MIPI Serial 0 Data Lane(positive) |
| `MIPI_MD_n[0]` | R1 | 2.5 V | HS Differential MIPI Serial 0 Data Lane(negative) |
| `MIPI_MD_p[1]` | N1 | 2.5 V | HS Differential MIPI Serial 1 Data Lane(positive) |
| `MIPI_MD_n[1]` | P1 | 2.5 V | HS Differential MIPI Serial 1 Data Lane(negative) |
| `MIPI_MD_p[2]` | T2 | 2.5 V | HS Differential MIPI Serial 2 Data Lane(negative) |
| `MIPI_MD_n[2]` | T1 | 2.5 V | HS Differential MIPI Serial 2 Data Lane(negative) |
| `MIPI_MD_p[3]` | N2 | 2.5 V | HS Differential MIPI Serial 3 Data Lane(negative) |
| `MIPI_MD_n[3]` | N3 | 2.5 V | HS Differential MIPI Serial 3 Data Lane(negative) |
| `MIPI_MC_p` | N5 | 2.5 V | HS Differential MIPI Serial Clock/Strobe (positive) |
| `MIPI_MC_n` | N4 | 2.5 V | HS Differential MIPI Serial Clock/Strobe (negative) |
| `MIPI_LP_MD_p[0]` | A4 | 1.2 V | LP single-ended MIPI Data Lane 0 signal dp0 |
| `MIPI_LP_MD_n[0]` | A3 | 1.2 V | LP single-ended MIPI Data Lane 0 signal dn0 |
| `MIPI_LP_MD_p[1]` | C3 | 1.2 V | LP single-ended MIPI Data Lane 1 signal dp1 |
| `MIPI_LP_MD_n[1]` | C2 | 1.2 V | LP single-ended MIPI Data Lane 1 signal dn1 |
| `MIPI_LP_MD_p[2]` | B1 | 1.2 V | LP single-ended MIPI Data Lane 2 signal dp2 |
| `MIPI_LP_MD_n[2]` | B2 | 1.2 V | LP single-ended MIPI Data Lane 2 signal dn2 |
| `MIPI_LP_MD_p[3]` | B3 | 1.2 V | LP single-ended MIPI Data Lane 3 signal dp3 |
| `MIPI_LP_MD_n[3]` | A2 | 1.2 V | LP single-ended MIPI Data Lane 3 signal dn3 |
| `MIPI_LP_MC_p` | E11 | 1.2 V | LP single-ended MIPI Clock signal cp |
| `MIPI_LP_MC_n` | E10 | 1.2 V | LP single-ended MIPI Clock signal cn |
| `MIPI_RESET_n` | T3 | 2.5 V | Master output Reset signal for MIPI camera/sensor |
| `MIPI_MCLK` | U3 | 2.5 V | Master output Clock |
| `MIPI_WP` | U1 | 2.5 V | Master output EEPROM Write Protect |
| `MIPI_CORE_EN` | V3 | 2.5 V | Master output core Enable |
| `MIPI_I2C_SCL` | M1 | 2.5 V | Master output I2C Clock |
| `MIPI_I2C_SDA` | M2 | 2.5 V | I2C Data |

## Czujnik zbliżeniowy i światła Si1143

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `LIGHT_I2C_SCL` | Y8 | 3.3-V LVTTL | I2C Clock for Si1143 Sensor |
| `LIGHT_I2C_SDA` | AA8 | 3.3-V LVTTL | I2C Data for Si1143 Sensor |
| `LIGHT_INT` | AA9 | 3.3-V LVTTL | Interrupt input from Si1143 Sensor |

## Czujnik wilgotności i temperatury HDC1000

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `RH_TEMP_I2C_SCL` | Y10 | 3.3-V LVTTL | I2C Clock for HDC1000 Sensor |
| `RH_TEMP_I2C_SDA` | AA10 | 3.3-V LVTTL | I2C Data for HDC1000 Sensor |
| `RH_TEMP_DRDY_n` | AB9 | 3.3-V LVTTL | Data ready input from HDC1000 Sensor |

## Czujnik temperatury

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `TEMP_SC` | AA1 | 3.3-V LVTTL | FPGA output clock to sensor |
| `TEMP_SIO` | Y2 | 3.3-V LVTTL | Bi-direction data line |
| `TEMP_CS_n` | AB4 | 3.3-V LVTTL | FPGA output chip secetc |

## Akcelerometr

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `G_SENSOR_SDI` ✱ | C6 | 1.2 V | SPI serial data input / I2C SDA |
| `G_SENSOR_SDO` | D5 | 1.2 V | SPI serial data output/I2C less |
| `G_SENSOR_CS_n` | E9 | 1.2 V | SPI enable, I2C/SPI mode selection: 1: |
| `G_SENSOR_SCLK` | B5 | 1.2 V | I2C serial clock/SPI serial port clock |
| `G_SENSOR_INT1` | E8 | 1.2 V | Interrupt pin 1 |
| `G_SENSOR_INT2` | D7 | 1.2 V | Interrupt pin 2 |

## Gniazdo microSD

| Sygnał | Pin | Standard w Quartusie | Opis |
|--------|-----|----------------------|------|
| `SD_CLK` | T20 | 1.5 V | FPGA output SD Clock |
| `SD_FB_CLK` | R22 | 1.5 V | Clock feedback to FPGA for |
| `SD_CMD` | T21 | 1.5 V | Command bit connected to FPGA |
| `SD_CMD_DIR` | U22 | 1.5 V | Direction control for command bit |
| `SD_D0_DIR` | T22 | 1.5 V | Direction control for DAT0A/DAT0B |
| `SD_D123_DIR` | U21 | 1.5 V | Direction control for DAT1A/B, DAT2A/B, |
| `SD_SEL` | P13 | 3.3-V LVTTL | FPGA output SD card VCCIO select |
| `SD_DAT[0]` | R18 | 1.5 V | Data bit 0 connected to FPGA |
| `SD_DAT[1]` | T18 | 1.5 V | Data bit 1 connected to FPGA |
| `SD_DAT[2]` | T19 | 1.5 V | Data bit 2 connected to FPGA |
| `SD_DAT[3]` | R20 | 1.5 V | Data bit 3 connected to FPGA |

## Uwagi

- **Diody LED świecą przy stanie niskim** — instrukcja: wysoki poziom gasi diodę, niski zapala.
- **Przyciski `KEY` dają 0 po wciśnięciu.** Mają sprzętowy przerzutnik Schmitta, ale nie zastępuje on synchronizacji z zegarem w logice.
- **Przełączniki `SW`:** pozycja w dół (do krawędzi płytki) daje 0, w górę — 1.
- Wejścia `ADC1IN1`–`ADC1IN7` to piny dwufunkcyjne; jako wejścia analogowe obsługuje je rdzeń ADC MAX 10 (moduł 20).

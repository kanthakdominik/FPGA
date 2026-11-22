/* Program Nios V (31.04): wypełnia bufor wzorem (numer pakietu + licznik bajtów), wysyła 1000 datagramów po
 * 1024 B na 192.168.1.100:5006 (MAC docelowy rozgłoszeniowy — bez ARP) i wypisuje wynik przez JTAG UART.
 * Odbiór na komputerze: skrypt z modułu 25 (deca/udp/odbior_udp.py) albo
 *   python3 -c "import socket;s=socket.socket(2,2);s.bind(('',5006));print(len(s.recv(2048)))"
 * Adres bazowy: UDP_BASE z system.h (BSP); bufor: tablica w pamięci wewnętrznej albo w DDR3 (README.md). */
#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "udp_dma.h"

#define DLUGOSC 1024u
#define PAKIETOW 1000u

static uint32_t bufor[DLUGOSC / 4];

static uint32_t ip(uint8_t a, uint8_t b, uint8_t c, uint8_t d)
{
    return ((uint32_t)a << 24) | ((uint32_t)b << 16) | ((uint32_t)c << 8) | d;
}

int main(void)
{
    static const uint8_t mac_fpga[6] = {0x02, 0x00, 0x00, 0x00, 0x00, 0x01};
    static const uint8_t mac_rozgl[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    udp_dma_t u;
    uint8_t *b = (uint8_t *)bufor;

    udp_dma_init(&u, UDP_BASE, mac_fpga, ip(192, 168, 1, 200), 5005);
    udp_dma_cel(&u, mac_rozgl, ip(192, 168, 1, 100), 5006);
    printf("udp_dma: %u datagramow po %u B\n", (unsigned)PAKIETOW, (unsigned)DLUGOSC);
    for (uint32_t n = 0; n < PAKIETOW; n++) {
        b[0] = (uint8_t)(n >> 24); b[1] = (uint8_t)(n >> 16); b[2] = (uint8_t)(n >> 8); b[3] = (uint8_t)n;
        for (uint32_t i = 4; i < DLUGOSC; i++) b[i] = (uint8_t)(n + i);
        if (udp_dma_wyslij(&u, bufor, DLUGOSC) != 0) {
            printf("blad: peryferium zajete\n");
            return 1;
        }
        udp_dma_czekaj(&u);
    }
    printf("wyslano %lu ramek\n", (unsigned long)udp_dma_pakiety(&u));
    return 0;
}

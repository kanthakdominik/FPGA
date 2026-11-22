/* Sterownik peryferium udp_dma (31.04). Bez HAL: dostęp przez wskaźnik volatile do rejestrów 32-bitowych
 * (adres bazowy z system.h BSP), więc kod działa na Nios V i kompiluje się na komputerze do testu składni. */
#include "udp_dma.h"

static uint32_t mac_h(const uint8_t m[6]) { return ((uint32_t)m[0] << 8) | m[1]; }
static uint32_t mac_l(const uint8_t m[6])
{
    return ((uint32_t)m[2] << 24) | ((uint32_t)m[3] << 16) | ((uint32_t)m[4] << 8) | m[5];
}

void udp_dma_init(udp_dma_t *u, uintptr_t baza, const uint8_t mac_zr[6], uint32_t ip_zr, uint16_t port_zr)
{
    u->baza = (volatile uint32_t *)baza;
    u->baza[UDP_DMA_MAC_ZR_H] = mac_h(mac_zr);
    u->baza[UDP_DMA_MAC_ZR_L] = mac_l(mac_zr);
    u->baza[UDP_DMA_IP_ZR] = ip_zr;
    u->baza[UDP_DMA_PORTY] = ((uint32_t)port_zr << 16) | (u->baza[UDP_DMA_PORTY] & 0xFFFFu);
    u->baza[UDP_DMA_STATUS] = UDP_DMA_STATUS_KONIEC;
}

void udp_dma_cel(udp_dma_t *u, const uint8_t mac_cel[6], uint32_t ip_cel, uint16_t port_cel)
{
    u->baza[UDP_DMA_MAC_CEL_H] = mac_h(mac_cel);
    u->baza[UDP_DMA_MAC_CEL_L] = mac_l(mac_cel);
    u->baza[UDP_DMA_IP_CEL] = ip_cel;
    u->baza[UDP_DMA_PORTY] = (u->baza[UDP_DMA_PORTY] & 0xFFFF0000u) | port_cel;
}

int udp_dma_zajety(const udp_dma_t *u) { return (u->baza[UDP_DMA_STATUS] & UDP_DMA_STATUS_ZAJETY) != 0; }

int udp_dma_wyslij(udp_dma_t *u, const void *bufor, uint32_t dlugosc)
{
    uintptr_t a = (uintptr_t)bufor;
    if (dlugosc == 0 || dlugosc > UDP_DMA_MAKS_DANYCH || (a & 3u) != 0 || udp_dma_zajety(u))
        return -1;
    u->baza[UDP_DMA_ADRES] = (uint32_t)a;
    u->baza[UDP_DMA_DLUGOSC] = dlugosc;
    u->baza[UDP_DMA_STER] = UDP_DMA_STER_START;   /* przerwanie wyłączone: sterownik odpytuje */
    return 0;
}

void udp_dma_czekaj(udp_dma_t *u)
{
    while ((u->baza[UDP_DMA_STATUS] & UDP_DMA_STATUS_KONIEC) == 0) {
    }
    u->baza[UDP_DMA_STATUS] = UDP_DMA_STATUS_KONIEC;
}

uint32_t udp_dma_pakiety(const udp_dma_t *u) { return u->baza[UDP_DMA_PAKIETY]; }

/* Sterownik peryferium udp_dma (31.04): mapa rejestrów zgodna z hdl/verilog/udp_dma.v. */
#ifndef UDP_DMA_H
#define UDP_DMA_H

#include <stdint.h>

#define UDP_DMA_STER     0u   /* bit 0 START (impuls), bit 1 PRZ */
#define UDP_DMA_STATUS   1u   /* bit 0 ZAJETY, bit 1 KONIEC (W1C) */
#define UDP_DMA_ADRES    2u
#define UDP_DMA_DLUGOSC  3u
#define UDP_DMA_IP_ZR    4u
#define UDP_DMA_IP_CEL   5u
#define UDP_DMA_PORTY    6u
#define UDP_DMA_MAC_ZR_H 7u
#define UDP_DMA_MAC_ZR_L 8u
#define UDP_DMA_MAC_CEL_H 9u
#define UDP_DMA_MAC_CEL_L 10u
#define UDP_DMA_PAKIETY  11u

#define UDP_DMA_STER_START   (1u << 0)
#define UDP_DMA_STER_PRZ     (1u << 1)
#define UDP_DMA_STATUS_ZAJETY (1u << 0)
#define UDP_DMA_STATUS_KONIEC (1u << 1)
#define UDP_DMA_MAKS_DANYCH  1472u

typedef struct {
    volatile uint32_t *baza;
} udp_dma_t;

void udp_dma_init(udp_dma_t *u, uintptr_t baza, const uint8_t mac_zr[6], uint32_t ip_zr, uint16_t port_zr);
void udp_dma_cel(udp_dma_t *u, const uint8_t mac_cel[6], uint32_t ip_cel, uint16_t port_cel);
/* Bufor wyrównany do 4 B, w pamięci widocznej dla mastera udp_dma; dlugosc 1..1472. Zwraca 0 albo -1. */
int udp_dma_wyslij(udp_dma_t *u, const void *bufor, uint32_t dlugosc);
int udp_dma_zajety(const udp_dma_t *u);
void udp_dma_czekaj(udp_dma_t *u);   /* odpytywanie KONIEC, potem kasowanie */
uint32_t udp_dma_pakiety(const udp_dma_t *u);

#endif

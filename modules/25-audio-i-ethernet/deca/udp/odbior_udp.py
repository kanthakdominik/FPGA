#!/usr/bin/env python3
"""Odbiór strumienia UDP z płytki DECA (moduł 25, 25.05).

Płytka nadaje datagramy 1024 B na port 5006: numer pakietu (4 B, big-endian) i bajty (numer + i) mod 256.
Skrypt najpierw wysyła jeden pakiet do FPGA (192.168.1.200:5005) — system zapyta wtedy płytkę przez ARP,
a ta nauczy się adresu komputera i przejdzie z adresu rozgłoszeniowego na nasz. Potem przez zadany czas
odbiera datagramy i sprawdza: ciągłość numerów (zgubione, poza kolejnością), zawartość, przepływność.

Komputer musi mieć adres z sieci 192.168.1.0/24 (np. 192.168.1.100) na interfejsie połączonym z płytką.
Użycie: python3 odbior_udp.py [--fpga 192.168.1.200] [--port 5006] [--czas 10]
"""
import argparse
import socket
import struct
import time


def main():
    a = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    a.add_argument("--fpga", default="192.168.1.200")
    a.add_argument("--port", type=int, default=5006)
    a.add_argument("--czas", type=float, default=10.0, help="czas pomiaru [s]")
    arg = a.parse_args()

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 8 * 1024 * 1024)
    s.bind(("", arg.port))
    s.settimeout(1.0)
    s.sendto(b"start", (arg.fpga, 5005))          # wywołuje ARP: płytka uczy się adresu komputera

    pakiety = bajty = zgubione = wstecz = zle_dane = 0
    ostatni = None
    t0 = time.monotonic()
    while time.monotonic() - t0 < arg.czas:
        try:
            d, nadawca = s.recvfrom(2048)
        except socket.timeout:
            print("brak danych (sprawdź SW[1], kabel i adres IP komputera)")
            continue
        if len(d) < 4:
            continue
        nr = struct.unpack(">I", d[:4])[0]
        oczekiwane = bytes((nr + i) & 0xFF for i in range(4, len(d)))
        if d[4:] != oczekiwane:
            zle_dane += 1
        if ostatni is not None:
            if nr > ostatni + 1:
                zgubione += nr - ostatni - 1
            elif nr <= ostatni:
                wstecz += 1
        ostatni = nr
        pakiety += 1
        bajty += len(d)
    t = time.monotonic() - t0
    print(f"pakietów {pakiety}, danych {bajty} B w {t:.1f} s: {8 * bajty / t / 1e6:.1f} Mb/s")
    print(f"zgubionych {zgubione}, poza kolejnością {wstecz}, z błędną zawartością {zle_dane}")


if __name__ == "__main__":
    main()

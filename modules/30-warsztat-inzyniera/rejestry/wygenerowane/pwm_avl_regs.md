# Mapa rejestrów `pwm_avl`

> WYGENEROWANE przez narzedzia/rejestry.py z rejestry/pwm_avl.json — nie edytuj ręcznie.

Peryferium PWM ze slave'em Avalon-MM (moduł 27, 27.03). Wersja opisu 1.0.0, słowa 32-bitowe, 2 bity adresu (słowa), przesunięcia w bajtach dla procesora.

| Słowo | Bajt | Rejestr | Bity | Pole | Dostęp | Reset | Opis |
|------:|-----:|---------|------|------|--------|------:|------|
| 0 | 0x0 | STER | 1 | PRZ | RW | 0 | zezwolenie na przerwanie |
|  |  |  | 0 | WL | RW | 0 | włączenie generatora |
| 1 | 0x4 | OKRES | 31:0 | WARTOSC | RW | 0 | liczba taktów okresu |
| 2 | 0x8 | WYPELN | 31:0 | WARTOSC | RW | 0 | liczba taktów stanu wysokiego |
| 3 | 0xC | STATUS | 1 | WYJSCIE | RO | 0 | bieżący stan wyjścia PWM |
|  |  |  | 0 | KONIEC | W1C | 0 | koniec okresu, zapis 1 kasuje |

Bity niewymienione są zarezerwowane: zapis ignorowany, odczyt 0. W1C — zapis 1 kasuje bit, zapis 0 nic nie zmienia.

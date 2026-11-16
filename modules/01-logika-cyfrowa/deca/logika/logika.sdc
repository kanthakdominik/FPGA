# Projekt bez zegara: same ścieżki kombinacyjne od przełączników i przycisków do diod.
# Człowiek nie zauważy opóźnienia rzędu nanosekund, więc wyłączamy analizę tych ścieżek
# (bez tego Timing Analyzer zgłosi je jako nieograniczone — "unconstrained").
set_false_path -from [get_ports {SW[*] KEY[*]}] -to [get_ports {LED[*]}]

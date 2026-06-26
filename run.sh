#!/usr/bin/env bash
# build_and_run.sh - Build, run and log with timestamp

set -euo pipefail

# Compiler/Wrapper vor dem Build setzen
export FPM_FC="mpifort"

# Zeitstempel für Dateinamen: YYYYMMDD_HHMMSS
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="build_${TIMESTAMP}.log"


# Voller Pfad zur Logdatei
LOGPATH="output/.logs/${LOGFILE}"

# Löche bin Dateien, wichtig für umschalten von single_file auf multiple_files, sonst werden die alten bin Dateien nicht überschrieben
rm -f output/*.bin

# Alle folgenden Ausgaben in die Logdatei schreiben und gleichzeitig auf der Konsole anzeigen
exec > >(tee -a "$LOGPATH") 2>&1

echo "=== Build gestartet: $(date '+%Y-%m-%d %H:%M:%S') ==="

# Build mit fpm (Verbose)
fpm build -V

# Run mit mpirun
fpm run --runner "mpirun -np 4"

# Plotten
python3 plot.py

# Bild öffnen im Hintergrund
xdg-open output/mandelbrot_150.png &

echo "=== Fertig: $(date '+%Y-%m-%d %H:%M:%S') ==="

# Symbolischen Link auf die neueste Logdatei aktualisieren
# damit für tail -f logs/build.log immer die aktuelle Logdatei angezeigt wird
ln -sf "$(realpath "$LOGPATH")" "output/.logs/build.log"
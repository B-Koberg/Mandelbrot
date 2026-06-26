import numpy as np
from PIL import Image
import matplotlib.cm as cm
import gc
import os
import time
from datetime import datetime
import glob

def now_hms():
    return datetime.now().strftime("%H:%M:%S")

start_time = time.time()
print(f"({now_hms()}) Starte Plot-Erstellung...")

# --- Suche alle Rank-Dateien ---
files = sorted(glob.glob("output/mandelbrot_output_*.bin"))
if not files:
    raise FileNotFoundError("Keine Dateien gefunden: output/mandelbrot_output_*.bin")

print(f"({now_hms()}) Gefundene Dateien: {len(files)}")

# --- Header-Definition ---
header_count = 4
header_dtype = np.float64
header_bytes = header_count * header_dtype().nbytes
data_dtype = np.int32

def read_file_info(fname):
    with open(fname, "rb") as f:
        header = np.fromfile(f, dtype=header_dtype, count=header_count)
    nx_hdr = int(header[0])
    maybe_ny = int(header[1])
    local_ny = int(header[2])
    max_iter = int(header[3])
    filesize = os.path.getsize(fname)
    data_bytes = filesize - header_bytes
    if data_bytes < 0:
        raise ValueError(f"Datei {fname} zu klein für Header")
    bytes_per_elem = np.dtype(data_dtype).itemsize
    n_elems = data_bytes // bytes_per_elem
    if n_elems % nx_hdr != 0:
        raise ValueError(f"Datei {fname}: Datenlänge {n_elems} ist kein Vielfaches von nx={nx_hdr}")
    return {
        "fname": fname,
        "nx": nx_hdr,
        "maybe_ny": maybe_ny,
        "local_ny": int(header[2]),
        "max_iter": max_iter,
        "local_ny": local_ny,
        "filesize": filesize
    }

infos = [read_file_info(f) for f in files]

# Konsistenzprüfungen
nx_values = {info["nx"] for info in infos}
if len(nx_values) != 1:
    raise ValueError(f"Unterschiedliche nx in Dateien: {nx_values}")
nx = nx_values.pop()
ny = sum(info["local_ny"] for info in infos)
max_iter_values = {info["max_iter"] for info in infos}
if len(max_iter_values) != 1:
    print("Warnung: unterschiedliche max_iter in Dateien, nehme erstes")
max_iter = infos[0]["max_iter"]

print(f"({now_hms()}) nx={nx}, ny={ny}, max_iter={max_iter}")
print(f"({now_hms()}) Baue globales Array aus {len(infos)} Blöcken...")

# Allokation globales Array (Fortran-Order)
global_arr = np.empty((nx, ny), dtype=data_dtype, order='F')

col_start = 0
for info in infos:
    fname = info["fname"]
    local_ny = info["local_ny"]
    print(f"({now_hms()}) Lese {fname}: local_ny={local_ny}, cols {col_start}:{col_start+local_ny}")
    with open(fname, "rb") as f:
        f.seek(header_bytes)
        data = np.fromfile(f, dtype=data_dtype, count=nx * local_ny)
    block = data.reshape((nx, local_ny), order='F')
    global_arr[:, col_start:col_start+local_ny] = block
    col_start += local_ny
    del data, block
    gc.collect()

# arr_view[y,x]
arr_view = global_arr.reshape((nx, ny), order='F').T

# --- Verwende feste globale Min/Max: 0 und max_iter ---
gmin = 0
gmax = max_iter
# Vermeide Division durch 0
use_log = (gmax > gmin)

possible_block_h = [ny / i for i in [0.0625, 0.125, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 35]]
min_block_h_idx = np.argmin([abs(bh - 1000) for bh in possible_block_h])
block_h = int(round(possible_block_h[min_block_h_idx])) + 1

print(f"({now_hms()}) Erstelle Bild mit Pixelreihen im Arbeitsspeicher {block_h} von {ny} Pixelreihen insgesamt...")
img = Image.new("RGB", (nx, ny))

for y0 in range(0, ny, block_h):
    y1 = min(y0 + block_h, ny)
    block = arr_view[y0:y1, :].astype(np.int32)
    # Maske für Punkte, die max_iter erreicht haben (gehören vermutlich zum Set)
    mask_max = (block == max_iter)

    if not use_log:
        norm = np.zeros_like(block, dtype=np.float32)
    else:
        block_f = block.astype(np.float32)
        numer = block_f - float(gmin) + 1.0
        denom = float(gmax) - float(gmin) + 1.0  # = max_iter + 1
        # numer >= 1, denom > 0
        norm = np.log(numer) / np.log(denom)
        # setze max_iter-Pixel auf 0 (schwarz)
        norm[mask_max] = 0.0

    rgb_block = (cm.inferno(norm)[:, :, :3] * 255).astype('uint8')
    # explizit max_iter-Pixel schwarz setzen (falls inferno(0) nicht exakt schwarz)
    rgb_block[mask_max, :] = 0
    img.paste(Image.fromarray(rgb_block), (0, y0))

    # aufräumen
    del block, norm, rgb_block, mask_max
    try:
        del block_f
    except NameError:
        pass
    gc.collect()
    print(f"({now_hms()}) Progress {y1}/{ny} Pixelreihen verarbeitet...")

print(f"({now_hms()}) Bild erstellt, speichere und lösche temporäre Daten...")
img.save(f"output/mandelbrot_{max_iter}.png")
del img, arr_view, global_arr, infos, files
gc.collect()
print(f"({now_hms()}) Fertig: output/mandelbrot_{max_iter}.png gespeichert und RAM freigegeben.")

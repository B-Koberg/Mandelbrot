import numpy as np
from PIL import Image
import matplotlib.cm as cm
import gc
import os
import time
from datetime import datetime

def now_hms():
    return datetime.now().strftime("%H:%M:%S")

start_time = time.time()
print(f"({now_hms()}) Starte Plot-Erstellung...")

print(f"({now_hms()}) Lese Header und Daten...")
fn = "mandelbrot_output.bin"
with open(fn, "rb") as f:
    header = np.fromfile(f, dtype=np.float64, count=7)
nx, ny = int(header[0]), int(header[1])
max_iter = int(header[2])
header_bytes = 7 * 8  # 7 float64

mm = np.memmap(fn, dtype=np.int32, mode='r', offset=header_bytes, shape=(nx * ny,))
arr_view = mm.reshape((nx, ny), order='F').T  # arr[y,x]


possible_block_h = [ny / i for i in [0.0625, 0.125, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 35]]
min_block_h_idx = np.argmin([abs(bh - 1000) for bh in possible_block_h])
block_h = round(possible_block_h[min_block_h_idx]) + 1

print(f"({now_hms()}) Erstelle Bild mit Pixelreihen im Arbeitsspeicher {block_h} von {ny} Pixelreihen insgesamt...")
img = Image.new("RGB", (nx, ny))

for y0 in range(0, ny, block_h):
    y1 = min(y0 + block_h, ny)
    block = arr_view[y0:y1, :]
    bmin, bmax = block.min(), block.max()
    if bmax == bmin:
        norm = np.zeros_like(block, dtype=np.float32)
    else:
        #norm = (block - bmin) / (bmax - bmin)
        norm = np.log(block - bmin + 1) / np.log(bmax - bmin + 1)
        
    rgb_block = (cm.inferno(norm)[:, :, :3] * 255).astype('uint8')
    img.paste(Image.fromarray(rgb_block), (0, y0))
    del block, norm, rgb_block
    gc.collect()
    
    print (f"({now_hms()}) Progress {y1}/{ny} Pixelreihen verarbeitet...")

print(f"({now_hms()}) Bild erstellt, speichere und lösche temporäre Daten...")
img.save(f"mandelbrot_{max_iter}.png")
del img, arr_view, mm, header
gc.collect()
print(f"({now_hms()}) Fertig: mandelbrot_maxiter.png gespeichert und RAM freigegeben.")


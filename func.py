# func.py
from datetime import datetime
import os
import gc
import glob
import numpy as np
from PIL import Image
import matplotlib.cm as cm

HEADER_COUNT = 4
HEADER_DTYPE = np.float64
DATA_DTYPE = np.int32
HEADER_BYTES = HEADER_COUNT * HEADER_DTYPE().nbytes

def now_hms() -> str:
    return datetime.now().strftime("%H:%M:%S")

def find_input_files(pattern: str = "output/mandelbrot_output_*.bin"):
    files = sorted(glob.glob(pattern))
    if not files:
        raise FileNotFoundError(f"Keine Dateien gefunden: {pattern}")
    return files

def read_file_info(fname: str):
    with open(fname, "rb") as f:
        header = np.fromfile(f, dtype=HEADER_DTYPE, count=HEADER_COUNT)
    nx_hdr = int(header[0])
    maybe_ny = int(header[1])
    local_ny = int(header[2])
    max_iter = int(header[3])
    filesize = os.path.getsize(fname)
    data_bytes = filesize - HEADER_BYTES
    if data_bytes < 0:
        raise ValueError(f"Datei {fname} zu klein für Header")
    bytes_per_elem = np.dtype(DATA_DTYPE).itemsize
    n_elems = data_bytes // bytes_per_elem
    if n_elems % nx_hdr != 0:
        raise ValueError(f"Datei {fname}: Datenlänge {n_elems} ist kein Vielfaches von nx={nx_hdr}")
    return {
        "fname": fname,
        "nx": nx_hdr,
        "maybe_ny": maybe_ny,
        "local_ny": local_ny,
        "max_iter": max_iter,
        "filesize": filesize
    }

def read_all_infos(files):
    return [read_file_info(f) for f in files]

def build_global_array(infos):
    nx_values = {info["nx"] for info in infos}
    if len(nx_values) != 1:
        raise ValueError(f"Unterschiedliche nx in Dateien: {nx_values}")
    nx = nx_values.pop()
    ny = sum(info["local_ny"] for info in infos)
    max_iter_values = {info["max_iter"] for info in infos}
    if len(max_iter_values) != 1:
        print(f"({now_hms()}) Warnung: unterschiedliche max_iter in Dateien, nehme erstes")
    max_iter = infos[0]["max_iter"]

    print(f"({now_hms()}) Baue globales Array aus {len(infos)} Blöcken...")
    global_arr = np.empty((nx, ny), dtype=DATA_DTYPE, order="F")

    col_start = 0
    for info in infos:
        fname = info["fname"]
        local_ny = info["local_ny"]
        print(f"({now_hms()}) Lese {fname}: local_ny={local_ny}, cols {col_start}:{col_start+local_ny}")
        with open(fname, "rb") as f:
            f.seek(HEADER_BYTES)
            data = np.fromfile(f, dtype=DATA_DTYPE, count=nx * local_ny)
        block = data.reshape((nx, local_ny), order="F")
        global_arr[:, col_start:col_start + local_ny] = block
        col_start += local_ny
        del data, block
        gc.collect()

    return global_arr, nx, ny, max_iter

def compute_block_height(ny: int, target: int = 1000) -> int:
    possible_block_h = [ny / i for i in [0.0625, 0.125, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 35]]
    min_idx = int(np.argmin([abs(bh - target) for bh in possible_block_h]))
    block_h = int(round(possible_block_h[min_idx])) + 1
    return max(1, block_h)

def create_image_from_array(global_arr, nx, ny, max_iter, out_path):
    arr_view = global_arr.reshape((nx, ny), order="F").T

    gmin = 0
    gmax = max_iter
    use_log = (gmax > gmin)

    block_h = compute_block_height(ny)
    print(f"({now_hms()}) Erstelle Bild mit Pixelreihen im Arbeitsspeicher {block_h} von {ny} Pixelreihen insgesamt...")
    img = Image.new("RGB", (nx, ny))

    for y0 in range(0, ny, block_h):
        y1 = min(y0 + block_h, ny)
        block = arr_view[y0:y1, :].astype(np.int32)
        mask_max = (block == max_iter)

        if not use_log:
            norm = np.zeros_like(block, dtype=np.float32)
        else:
            block_f = block.astype(np.float32)
            numer = block_f - float(gmin) + 1.0
            denom = float(gmax) - float(gmin) + 1.0
            norm = np.log(numer) / np.log(denom)
            norm[mask_max] = 0.0

        rgb_block = (cm.inferno(norm)[:, :, :3] * 255).astype("uint8")
        rgb_block[mask_max, :] = 0
        img.paste(Image.fromarray(rgb_block), (0, y0))

        del block, norm, rgb_block, mask_max
        try:
            del block_f
        except NameError:
            pass
        gc.collect()
        print(f"({now_hms()}) Progress {y1}/{ny} Pixelreihen verarbeitet...")

    print(f"({now_hms()}) Bild erstellt, speichere: {out_path}")
    img.save(out_path)
    del img, arr_view, global_arr
    gc.collect()


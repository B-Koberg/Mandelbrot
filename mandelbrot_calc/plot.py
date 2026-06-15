import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np
from PIL import Image
import sys


with open("mandelbrot_output.txt", "r") as f:
    # Erste Zeile lesen
    first_line = f.readline().strip()

# Erste Zeile in Zahlen umwandeln
args = np.fromstring(first_line, sep=' ')

nx, ny, max_iter, x_min, x_max, y_min, y_max = args

# Rest der Datei laden
data = np.loadtxt("mandelbrot_output.txt", skiprows=1)

print(args, data.shape)


# Normieren
norm = (data - data.min()) / (data.max() - data.min())

# Colormap anwenden (liefert RGBA)
colored = cm.inferno(norm)

# Alpha entfernen
rgb = (colored[:, :, :3] * 255).astype(np.uint8)

img = Image.fromarray(rgb, mode="RGB")
img.save("mandelbrot_color.png")



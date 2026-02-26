from PIL import Image
import numpy as np

# ------------------------
# 1️⃣ Parameters
# ------------------------
WIDTH = 2
HEIGHT = 2
hex_file = "4x4_output.hex"
bmp_file = "reconstructed.bmp"

# ------------------------
# 2️⃣ Read pixel values from .hex
# ------------------------
pixels = []

with open(hex_file, "r") as f:
    for line in f:
        line = line.strip()
        if line:  # skip empty lines
            # Parse hex value (assume one byte per line)
            pixels.append(int(line, 16))

# Ensure we have exactly WIDTH*HEIGHT pixels
if len(pixels) != WIDTH * HEIGHT:
    raise ValueError(f"Expected {WIDTH*HEIGHT} pixels, got {len(pixels)}")

# Convert to NumPy array with shape (HEIGHT, WIDTH)
img_array = np.array(pixels, dtype=np.uint8).reshape((HEIGHT, WIDTH))

# ------------------------
# 3️⃣ Save as BMP
# ------------------------
img = Image.fromarray(img_array, mode='L')
img.save(bmp_file)
print(f"Reconstructed image saved as {bmp_file}")

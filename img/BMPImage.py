from PIL import Image
import numpy as np

# ------------------------
# 1️⃣ Create nxn grayscale image with central division
# ------------------------
WIDTH = 16
HEIGHT = 16

img = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

# Previous loop (commented out)
#for y in range(HEIGHT):
#     for x in range(WIDTH):
#         img[y, x] = x * 20   # changes only across columns

# Hard-coded Sobel Gx test matrix

img = np.array([
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0,   0,   0],
    [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
    [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
    [  0,   0,   0,   0,   0,   0,   0,   0,   0, 255, 255,   0,   0,   0,   0,   0],
], dtype=np.uint8)



# Save BMP for viewing
Image.fromarray(img, mode='L').save("input.bmp")
print("Saved input.bmp")

# ------------------------
# 2️⃣ Save pixel values to .hex file in 4-byte format
# ------------------------
pixel_file = "4x4_input.hex"

with open(pixel_file, "w") as f:
    for y in range(HEIGHT):
        for x in range(WIDTH):
            f.write(f"{img[y, x]:02x} 00 00 00\n")

print(f"Saved pixels to {pixel_file}")

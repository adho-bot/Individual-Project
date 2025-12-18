from PIL import Image
import numpy as np

# ------------------------
# 1️⃣ Create 8x8 grayscale image with central division
# ------------------------
WIDTH = 8
HEIGHT = 8
DIV_VALUE = 90

img = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

for y in range(HEIGHT):
    for x in range(WIDTH):
        if x < WIDTH // 2:
            img[y, x] = 0          # left half
        else:
            img[y, x] = DIV_VALUE  # right half (~90)

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

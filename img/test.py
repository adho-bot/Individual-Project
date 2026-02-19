from PIL import Image
import matplotlib.pyplot as plt

in_path = "/home/gary/Individual_Project/img/lena_gray.bmp"
out_path = "/home/gary/Individual_Project/img/4x4_input.hex"

# Load and force 8-bit grayscale
img = Image.open(in_path).convert("L")
w, h = img.size

#Parameters
WIDTH = 32
HEIGHT = 32
if w < WIDTH or h < HEIGHT:
    raise ValueError(f"Image too small: {w}x{h}")

# --- Center crop to 32x32 ---
left   = (w - HEIGHT) // 2
top    = (h - HEIGHT) // 2
right  = left + HEIGHT
bottom = top + HEIGHT

img_32 = img.crop((left, top, right, bottom))

# --- Display result ---
plt.imshow(img_32, cmap="gray")
plt.title("Center-cropped 32×32 image")
plt.axis("off")
plt.show()

# --- Convert to raw bytes ---
data = img_32.tobytes()  # 1024 bytes

# --- Write hex output (pixel in MSB, zero-padded to 32 bits) ---
with open(out_path, "w", newline="\n") as f:
    for b in data:
        f.write(f"{b:02x} 00\n")

print(f"Wrote {len(data)} bytes to {out_path}")

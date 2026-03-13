# from PIL import Image
import matplotlib.pyplot as plt

# in_path = "/home/gary/Individual_Project/img/lena_gray.bmp"  # Commented out
hex_path = "/home/gary/CNN_PROJECT/weights_16x16/test_images/test_5_label1.hex"   # Your .hex file
out_path = "/home/gary/Individual_Project_System/System_Top/src/imagedata.h"

WIDTH = 16
HEIGHT = 16

# Read .hex file
with open(hex_path, "r") as f:
    # Assumes one value per line or comma-separated
    content = f.read().replace(",", " ").split()
    data = [int(x, 16) for x in content]

if len(data) < WIDTH * HEIGHT:
    raise ValueError(f"Hex file has too few pixels: {len(data)}")

# Take only the first WIDTH*HEIGHT pixels
data = data[:WIDTH*HEIGHT]

# Convert to 2D for visualization
import numpy as np
img_array = np.array(data, dtype=np.uint8).reshape((HEIGHT, WIDTH))

# Show image
plt.imshow(img_array, cmap="gray")
plt.title("16x16 image from hex")
plt.axis("off")
plt.show()

# Write to C header
with open(out_path, "w") as f:
    f.write("#ifndef IMAGE_DATA_H\n")
    f.write("#define IMAGE_DATA_H\n\n")

    f.write(f"#define IMG_WIDTH {WIDTH}\n")
    f.write(f"#define IMG_HEIGHT {HEIGHT}\n\n")

    f.write("static const unsigned int image_data[] = {\n")

    for i, p in enumerate(data):
        f.write(f"0x{p:08x},")
        if (i+1) % 8 == 0:
            f.write("\n")

    f.write("\n};\n\n#endif\n")

print(f"Generated {out_path}")
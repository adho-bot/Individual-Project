import serial
import numpy as np
import matplotlib.pyplot as plt

WIDTH = 16
HEIGHT = 16

ser = serial.Serial("/dev/ttyUSB1",115200)

data = []
record = False

while True:
    line = ser.readline().decode().strip()

    if line == "BEGIN_IMAGE":
        record = True
        continue

    if line == "END_IMAGE":
        break

    if record:
        data.append(int(line,16))

img = np.array(data).reshape(HEIGHT,WIDTH)

plt.imshow(img,cmap="gray")
plt.title("FPGA Sobel Output")
plt.axis("off")
plt.show()
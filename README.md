# Bit-serial Array Processor

## Introduction

This repository contains the RTL code for the Bit-Serial Array Processor, an FPGA-based accelerator for image processing workloads. Alongside the processor core it provides verification testbenches, files for testing the different workloads, and a CNN implementation.

The main testbench in this module computes the Sobel edge detection algorithm through bit-serial shift operations, demonstrating how the array can be driven to perform a real image processing task.

<img width="585" height="483" alt="image" src="https://github.com/user-attachments/assets/2650eedd-098a-467f-bb30-47ddf75b1fa0" />

Array Diagram Overview

## Demo





<img width="585" height="317" alt="image" src="https://github.com/user-attachments/assets/590034af-cda9-4918-82ec-76c8307d5ace" /> 

Sobel edge detection example

## Repository Layout

* `/rtl` – SystemVerilog RTL for the processing element array and control path.
* `/sim` – Testbenches and simulation artifacts.
* `/scripts` – Python-based Sobel reference model and RTL result checker.
* `/img` – Input/output image and hex conversion utilities.
* `/vitis` – Vitis software used to drive the AXI-connected accelerator.
* `/ip` – Packaged IP blocks and wrappers.
* `/syn` – FPGA constraint files.
* `/cnn` – 16x16 image/test data and software helpers.
* `/report` – Project report artifacts.

## User Installation Instructions

These instructions assume you are starting from scratch with no prior tools installed.

1. **Download Vivado.** Go to the [AMD/Xilinx downloads page](https://www.xilinx.com/support/download.html)
2. **Run the installer.** Launch the installer and sign in with (or create) an AMD account when prompted.
3. **Select Vitis.** On the edition selection screen, choose the option that installs **Vitis** alongside Vivado, so you have the software development tools needed to drive the accelerator.
4. **Select the Zynq device family.** When choosing devices/families to install, make sure the **Zynq** checkmark is ticked, as the target board is Zynq-based.
5. **Complete installation.** Accept the licence agreements, choose an install location, and let the installer finish.
6. **Install the PYNQ-Z2 board files.** Download the PYNQ-Z2 board files and copy them into your Vivado board files directory (typically `<Vivado_install>/data/boards/board_files/`) so the PYNQ-Z2 board appears as a target in Vivado.

## How to Run the Code

These steps assume no prior knowledge of the project.

To run the **full workflow**, go to the **`Individual_Project_System`** repository to access the supporting system hardware for the current array processor. The CNN code that runs on the PYNQ-Z2 FPGA can also be found there.

### Running the Demo

The project includes a GUI demo with panels for both Sobel edge detection and MNIST.

1. **Open the `img` folder.** From the repository root, run:
   ```bash
   cd img
   code .
   ```
2. **Activate the virtual environment:**
   ```bash
   source venv/bin/activate
   ```
3. **Launch the demo GUI:**
   ```bash
   python3 -u PROJECT_DEMO.py
   ```
   This opens a GUI with panels for both Sobel and MNIST.
4. **Run the Sobel verification.** In Vivado, run the verification testbench `KernelTest_tb.sv` and wait for it to complete.
5. **View the output.** Once the testbench has finished, click the **Show Result** button in the GUI to see the Sobel output.

**Note:** To change the test image, edit the path in the config section in `PROJECT_DEMO.py` to the path of your test image
   ```python
    "lena_path":        "/home/gary/Individual_Project/img/lena_gray.bmp",
   ```

### What this project does

This is an array processor that can run image processing workloads. The main testbench in this module computes the **Sobel edge detection** algorithm through bit-serial shift operations.

## More Technical Details

The processor is a bit-serial array: data is processed one bit at a time through the processing element array, with the control path coordinating the shift operations across elements.

The demonstration workload implements **Sobel edge detection**, which convolves the image with two 3x3 kernels to approximate the horizontal and vertical intensity gradients:

```
        | -1  0  +1 |              | +1  +2  +1 |
  Gx =  | -2  0  +2 |        Gy =  |  0   0   0 |
        | -1  0  +1 |              | -1  -2  -1 |
```

The gradient magnitude at each pixel is then computed (commonly as `|G| = sqrt(Gx^2 + Gy^2)`, or approximated by `|G| = |Gx| + |Gy|`), and these operations are mapped onto the bit-serial shift-and-add datapath of the array. A Python reference model in `/scripts` computes the expected result so the RTL output can be checked against it.

*Add any further equations or implementation details specific to your design here.*

## Known Issues / Future Improvements

Not much for now.

# Individual-Project

Hardware/software co-design project for Sobel edge detection on a custom SIMD array processor.

## Repository layout

- `/rtl` – SystemVerilog RTL for the processing element array and control path.
- `/sim` – Testbenches and simulation artifacts.
- `/scripts` – Python-based Sobel reference model and RTL result checker.
- `/img` – Input/output image and hex conversion utilities.
- `/vitis` – Vitis software used to drive the AXI-connected accelerator.
- `/ip` – Packaged IP blocks and wrappers.
- `/syn` – FPGA constraint files.
- `/cnn` – 16x16 image/test data and software helpers.
- `/report` – Project report artifacts.

## What this project does

1. Loads image pixels into the SIMD array.
2. Executes Sobel `Gx` and `Gy` instruction sequences.
3. Computes `|Gx| + |Gy|`, applies right-shift scaling, and stores results.
4. Verifies RTL output against a Python reference model.

## Prerequisites

- Linux environment
- Python 3.10+
- `numpy` (`pip install numpy`)
- One supported HDL simulator:
  - XSIM (Vivado)
  - Questa/ModelSim
  - Icarus Verilog (`iverilog` + `vvp`)

## Quick start

Set your repo root once:

```bash
export PROJECT_DIR=/absolute/path/to/Individual-Project
```

### 1) Configure project path in Makefile

`Makefile.sobel` contains a machine-specific `PROJECT_DIR` value.

Update it to your local repository path, for example:

- `PROJECT_DIR := /absolute/path/to/Individual-Project`

### 2) Generate golden output

```bash
cd ${PROJECT_DIR}
make -f Makefile.sobel golden
```

### 3) Run RTL simulation

```bash
cd ${PROJECT_DIR}
make -f Makefile.sobel sim SIMULATOR=iverilog
```

Replace `iverilog` with `xsim` or `questa` as needed.

### 4) Compare outputs

```bash
cd ${PROJECT_DIR}
make -f Makefile.sobel compare
```

## Useful commands

```bash
cd ${PROJECT_DIR}
make -f Makefile.sobel help
make -f Makefile.sobel clean
```

## Python verifier usage

Main script: `/scripts/sobel_verify.py`

```bash
python3 ${PROJECT_DIR}/scripts/sobel_verify.py --self-test
python3 ${PROJECT_DIR}/scripts/sobel_verify.py --input ${PROJECT_DIR}/img/4x4_input.hex --rows 4 --cols 4
python3 ${PROJECT_DIR}/scripts/sobel_verify.py --input ${PROJECT_DIR}/img/4x4_input.hex --rtl-output ${PROJECT_DIR}/sim/actual_output.hex --rows 4 --cols 4
```

## Notes

- Some folders include local virtual environments (`venv`). They are not required if you use your own Python environment.
- The repository includes editor swap files (e.g. `.swp`) and generated simulation outputs.

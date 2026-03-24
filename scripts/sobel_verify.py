#!/usr/bin/env python3
"""
Automated Sobel Edge Detection Verifier
========================================
Self-contained: includes the SIMD array reference model, instruction assembler,
and Sobel pipeline verification. No external imports beyond numpy.

Usage:
    # Generate expected output from an input image:
    python3 sobel_verify.py --input /home/gary/Individual_Project/img/4x4_input.hex --rows 32 --cols 32

    # Compare RTL output against expected:
    python3 sobel_verify.py --input 4x4_input.hex --rtl-output 4x4_output.hex --rows 32 --cols 32

    # Generate a test image and run:
    python3 sobel_verify.py --generate-test gradient --rows 8 --cols 8

    # Run self-tests:
    python3 sobel_verify.py --self-test
"""

import argparse
import sys
import os
import numpy as np
from enum import IntEnum
from typing import Optional


###############################################################################
#                       REFERENCE MODEL                                       #
###############################################################################

class ALUOp(IntEnum):
    ADD    = 0b000
    SUB    = 0b001
    XOR    = 0b010
    OR     = 0b011
    AND    = 0b100
    MSBTST = 0b101
    SRA    = 0b110

class InstrType(IntEnum):
    LOAD      = 0b00
    R_TYPE    = 0b01
    STORE     = 0b10
    NEWS_TYPE = 0b11

class NewsDir(IntEnum):
    NORTH = 0b00
    EAST  = 0b01
    WEST  = 0b10
    SOUTH = 0b11


class PE:
    def __init__(self, row, col, data_width=16, reg_depth=8):
        self.row = row
        self.col = col
        self.data_width = data_width
        self.reg_depth = reg_depth
        self.mask = (1 << data_width) - 1
        self.regs = [0] * reg_depth

    def read_reg(self, addr):
        return self.regs[addr] & self.mask

    def write_reg(self, addr, value):
        if addr != 0:
            self.regs[addr] = value & self.mask

    def alu_op(self, opcode, a, b):
        w = self.data_width
        mask = self.mask
        if opcode == ALUOp.ADD:
            return (a + b) & mask
        elif opcode == ALUOp.SUB:
            return (a - b) & mask
        elif opcode == ALUOp.XOR:
            return (a ^ b) & mask
        elif opcode == ALUOp.OR:
            return (a | b) & mask
        elif opcode == ALUOp.AND:
            return (a & b) & mask
        elif opcode == ALUOp.MSBTST:
            msb = (b >> (w - 1)) & 1
            msb_mask = mask if msb else 0
            return (a ^ msb_mask) & mask
        elif opcode == ALUOp.SRA:
            return a
        return 0


class SIMDArray:
    def __init__(self, rows=2, cols=2, data_width=16, reg_depth=8):
        self.rows = rows
        self.cols = cols
        self.data_width = data_width
        self.reg_depth = reg_depth
        self.mask = (1 << data_width) - 1
        self.pe = [[PE(r, c, data_width, reg_depth)
                     for c in range(cols)] for r in range(rows)]

    def get_neighbor(self, row, col, direction, rs2_addr):
        """
        NEWS neighbor wiring from Array_Main.sv:
          north[r][c] = news[r+1][c]
          south[r][c] = news[r-1][c]
          west[r][c]  = news[r][c+1]
          east[r][c]  = news[r][c-1]
        Boundary = 0.
        """
        nr, nc = row, col
        if direction == NewsDir.NORTH:
            nr = row + 1
        elif direction == NewsDir.SOUTH:
            nr = row - 1
        elif direction == NewsDir.WEST:
            nc = col + 1
        elif direction == NewsDir.EAST:
            nc = col - 1

        if 0 <= nr < self.rows and 0 <= nc < self.cols:
            return self.pe[nr][nc].read_reg(rs2_addr)
        return 0

    def dump_regs(self):
        lines = []
        for r in range(self.rows):
            for c in range(self.cols):
                pe = self.pe[r][c]
                regs = [f"r{i}={pe.read_reg(i):04x}" for i in range(self.reg_depth)]
                lines.append(f"  PE[{r},{c}]: {' '.join(regs)}")
        return "\n".join(lines)


###############################################################################
#                       SOBEL PIPELINE (mirrors KernelTest_tb.sv)             #
###############################################################################

def signed16(v, W=16):
    return v - (1 << W) if v >= (1 << (W - 1)) else v

def to_u16(v):
    return v & 0xFFFF


def run_sobel_pipeline(arr, verbose=False):
    """
    Execute the EXACT same instruction sequence as KernelTest_tb.sv.
    After this, register r6 in each PE holds (|Gx| + |Gy|) >> 2.
    Assumes r1 in every PE is already loaded with pixel data.
    """
    rows, cols = arr.rows, arr.cols
    W = arr.data_width
    MASK = arr.mask

    if verbose:
        print("--- Gx computation ---")

    # ====== Gx ======
    # r2 = r1 + NORTH(r1)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(1)
            n = arr.get_neighbor(r, c, NewsDir.NORTH, 1)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r2 = r2 + SOUTH(r2)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(2)
            n = arr.get_neighbor(r, c, NewsDir.SOUTH, 2)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r3 = EAST(r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.EAST, 2)
            arr.pe[r][c].write_reg(3, to_u16(n))

    # r4 = WEST(r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.WEST, 2)
            arr.pe[r][c].write_reg(4, to_u16(n))

    # r5 = r3 - r4  => Gx
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(3)
            b = arr.pe[r][c].read_reg(4)
            arr.pe[r][c].write_reg(5, to_u16(a - b))

    if verbose:
        print("--- Gy computation ---")

    # ====== Gy ======
    # r2 = r1 + EAST(r1)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(1)
            n = arr.get_neighbor(r, c, NewsDir.EAST, 1)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r2 = r2 + WEST(r2)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(2)
            n = arr.get_neighbor(r, c, NewsDir.WEST, 2)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r3 = NORTH(r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.NORTH, 2)
            arr.pe[r][c].write_reg(3, to_u16(n))

    # r4 = SOUTH(r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.SOUTH, 2)
            arr.pe[r][c].write_reg(4, to_u16(n))

    # r6 = r3 - r4  => Gy
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(3)
            b = arr.pe[r][c].read_reg(4)
            arr.pe[r][c].write_reg(6, to_u16(a - b))

    if verbose:
        print("--- Magnitude: |Gx| + |Gy| ---")

    # ====== |Gx| ======
    # r3 = getmsb(r5)   =>  MSBTST: r3 = r0 XOR sign_replicated(r5)
    for r in range(rows):
        for c in range(cols):
            val = arr.pe[r][c].read_reg(5)
            msb = (val >> (W - 1)) & 1
            arr.pe[r][c].write_reg(3, MASK if msb else 0)

    # r4 = r5 XOR r3
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(5)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(4, (a ^ b) & MASK)

    # r5 = r4 - r3   => |Gx|
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(4)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(5, to_u16(a - b))

    # ====== |Gy| ======
    # r3 = getmsb(r6)
    for r in range(rows):
        for c in range(cols):
            val = arr.pe[r][c].read_reg(6)
            msb = (val >> (W - 1)) & 1
            arr.pe[r][c].write_reg(3, MASK if msb else 0)

    # r4 = r6 XOR r3
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(6)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(4, (a ^ b) & MASK)

    # r6 = r4 - r3   => |Gy|
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(4)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(6, to_u16(a - b))

    # ====== |Gx| + |Gy| ======
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(5)
            b = arr.pe[r][c].read_reg(6)
            arr.pe[r][c].write_reg(6, to_u16(a + b))

    # ====== SRA >> 2 ======
    for r in range(rows):
        for c in range(cols):
            val = signed16(arr.pe[r][c].read_reg(6))
            shifted = val >> 2
            arr.pe[r][c].write_reg(6, to_u16(shifted))

    if verbose:
        print("--- Pipeline complete ---")


###############################################################################
#                       FILE I/O                                              #
###############################################################################

def load_hex_image(filename, num_pixels):
    values = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('//') or line.startswith('#'):
                continue
            token = line.split()[0]
            values.append(int(token, 16))
    if len(values) < num_pixels:
        print(f"WARNING: hex file has {len(values)} values but expected {num_pixels}")
        values.extend([0] * (num_pixels - len(values)))
    return values[:num_pixels]


def write_hex_output(filename, values):
    with open(filename, 'w') as f:
        for v in values:
            f.write(f"{v & 0xFFFF:02x}\n")


###############################################################################
#                       COMPARISON                                            #
###############################################################################

def compare_outputs(expected, actual, rows, cols, mask=0xFFFF):
    mismatches = 0
    total = min(len(expected), len(actual))

    for i in range(total):
        exp = expected[i] & mask
        act = actual[i] & mask
        if exp != act:
            r = i // cols
            c = i % cols
            mismatches += 1
            if mismatches <= 20:
                print(f"  MISMATCH @ pixel[{r},{c}] (addr {i}): "
                      f"expected=0x{exp:04x} ({exp:5d}), "
                      f"got=0x{act:04x} ({act:5d}), "
                      f"diff={act - exp:+d}")

    if mismatches > 20:
        print(f"  ... and {mismatches - 20} more mismatches")

    if mismatches == 0:
        print(f"\n  PASS: ALL {total} PIXELS MATCH")
        return True
    else:
        print(f"\n  FAIL: {mismatches}/{total} pixels mismatched")
        return False


###############################################################################
#                       TEST IMAGE GENERATORS                                 #
###############################################################################

def generate_gradient_image(rows, cols):
    return [(r * 8 + c * 8) & 0xFF for r in range(rows) for c in range(cols)]

def generate_checkerboard(rows, cols, block_size=4):
    pixels = []
    for r in range(rows):
        for c in range(cols):
            block = ((r // block_size) + (c // block_size)) % 2
            pixels.append(200 if block else 50)
    return pixels

def generate_single_edge(rows, cols):
    return [0 if c < cols // 2 else 200 for r in range(rows) for c in range(cols)]


###############################################################################
#                       ASCII GRID DISPLAY                                    #
###############################################################################

def print_pixel_grid(values, rows, cols, title="", max_display=16):
    display_r = min(rows, max_display)
    display_c = min(cols, max_display)
    if title:
        print(f"\n{title} ({display_r}x{display_c} shown of {rows}x{cols}):")
    print("     " + " ".join(f"{c:4d}" for c in range(display_c)))
    print("    +" + "-----" * display_c)
    for r in range(display_r):
        row_vals = []
        for c in range(display_c):
            v = values[r * cols + c]
            if v >= 0x8000:
                row_vals.append(f"{v - 0x10000:4d}")
            else:
                row_vals.append(f"{v:4d}")
        print(f"{r:3d} | " + " ".join(row_vals))
    if rows > max_display or cols > max_display:
        print(f"    ... ({rows - display_r} more rows, {cols - display_c} more cols)")


###############################################################################
#                       VERIFICATION RUNNER                                   #
###############################################################################

def run_verification(input_pixels, rows, cols, rtl_output_file=None, verbose=False):
    assert len(input_pixels) >= rows * cols, \
        f"Need {rows*cols} pixels, got {len(input_pixels)}"

    arr = SIMDArray(rows=rows, cols=cols, data_width=16, reg_depth=8)

    for r in range(rows):
        for c in range(cols):
            pixel = input_pixels[r * cols + c]
            arr.pe[r][c].write_reg(1, pixel & 0xFFFF)

    if verbose:
        print(f"Loaded {rows}x{cols} = {rows*cols} pixels into r1")

    run_sobel_pipeline(arr, verbose=verbose)

    expected_output = []
    for r in range(rows):
        for c in range(cols):
            expected_output.append(arr.pe[r][c].read_reg(6))

    vals = np.array(expected_output, dtype=np.int16)
    print(f"\nExpected output statistics:")
    print(f"  Range: [{vals.min()}, {vals.max()}]")
    print(f"  Mean:  {vals.mean():.1f}")
    non_zero = np.count_nonzero(vals)
    print(f"  Non-zero pixels: {non_zero}/{len(vals)} ({100*non_zero/len(vals):.1f}%)")

    if rtl_output_file:
        print(f"\nComparing against RTL output: {rtl_output_file}")
        actual = load_hex_image(rtl_output_file, rows * cols)
        return compare_outputs(expected_output, actual, rows, cols)
    else:
        out_file = "expected_sobel_output.hex"
        write_hex_output(out_file, expected_output)
        print(f"\nWrote expected output to {out_file}")
        print("Run your RTL sim, then re-run with --rtl-output to compare.")
        return True


###############################################################################
#                       SELF-TEST                                             #
###############################################################################

def test_abs_trick():
    print("Testing abs() trick (MSBTST + XOR + SUB)...")
    W = 16
    MASK = 0xFFFF
    test_values = [0, 1, -1, 127, -128, 255, -256, 32767, -32768, -1000, 1000]
    all_pass = True
    for sv in test_values:
        x = sv & MASK
        msb = (x >> 15) & 1
        sign_mask = MASK if msb else 0
        xored = (x ^ sign_mask) & MASK
        result = (xored - sign_mask) & MASK
        expected = abs(sv) & MASK
        if result != expected:
            print(f"  FAIL: abs({sv}) = 0x{result:04x}, expected 0x{expected:04x}")
            all_pass = False
    print(f"  {'PASS' if all_pass else 'FAIL'}: abs trick verification")
    return all_pass


###############################################################################
#                       MAIN                                                  #
###############################################################################

def main():
    parser = argparse.ArgumentParser(
        description="Automated Sobel verification for SIMD array processor",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 sobel_verify.py --self-test
  python3 sobel_verify.py --input img/4x4_input.hex --rows 32 --cols 32
  python3 sobel_verify.py --input img/4x4_input.hex --rtl-output img/4x4_output.hex --rows 32 --cols 32
  python3 sobel_verify.py --generate-test gradient --rows 8 --cols 8 --show-grid
        """)

    parser.add_argument("--input", help="Input hex image file")
    parser.add_argument("--rtl-output", help="RTL simulation output hex to compare")
    parser.add_argument("--rows", type=int, default=32)
    parser.add_argument("--cols", type=int, default=32)
    parser.add_argument("--generate-test", choices=["gradient", "checkerboard", "edge"])
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--show-grid", action="store_true")
    parser.add_argument("--self-test", action="store_true")

    args = parser.parse_args()

    print("=" * 60)
    print("  Sobel Edge Detection - Automated Verification")
    print("=" * 60)

    if args.self_test:
        test_abs_trick()
        print("\nEnd-to-end self-test (4x4 gradient):")
        pixels = generate_gradient_image(4, 4)
        run_verification(pixels, 4, 4, verbose=True)
        if args.show_grid:
            arr = SIMDArray(rows=4, cols=4, data_width=16, reg_depth=8)
            for r in range(4):
                for c in range(4):
                    arr.pe[r][c].write_reg(1, pixels[r*4+c])
            run_sobel_pipeline(arr)
            out = [arr.pe[r][c].read_reg(6) for r in range(4) for c in range(4)]
            print_pixel_grid(pixels, 4, 4, "Input")
            print_pixel_grid(out, 4, 4, "Output (Sobel)")
        return

    if args.generate_test:
        generators = {
            "gradient": generate_gradient_image,
            "checkerboard": lambda r, c: generate_checkerboard(r, c),
            "edge": generate_single_edge,
        }
        pixels = generators[args.generate_test](args.rows, args.cols)
        hex_file = f"test_{args.generate_test}_{args.rows}x{args.cols}.hex"
        write_hex_output(hex_file, pixels)
        print(f"Generated {args.generate_test} image: {hex_file}")
        if args.show_grid:
            print_pixel_grid(pixels, args.rows, args.cols, "Generated input")
    elif args.input:
        pixels = load_hex_image(args.input, args.rows * args.cols)
        print(f"Loaded {len(pixels)} pixels from {args.input}")
        if args.show_grid:
            print_pixel_grid(pixels, args.rows, args.cols, "Input image")
    else:
        parser.print_help()
        print("\nError: specify --input, --generate-test, or --self-test")
        sys.exit(1)

    passed = run_verification(
        pixels, args.rows, args.cols,
        rtl_output_file=args.rtl_output,
        verbose=args.verbose
    )

    if args.show_grid and not args.rtl_output:
        expected = load_hex_image("expected_sobel_output.hex", args.rows * args.cols)
        print_pixel_grid(expected, args.rows, args.cols, "Expected Sobel output")

    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
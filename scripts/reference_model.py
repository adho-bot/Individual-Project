#!/usr/bin/env python3
"""
Automated Sobel Edge Detection Verifier
========================================
Mirrors the EXACT instruction sequence in KernelTest_tb.sv using
the Python reference model, then compares against RTL output.

Usage:
    # Generate expected output from an input image:
    python3 sobel_verify.py --input 4x4_input.hex --rows 32 --cols 32

    # Compare RTL output against expected:
    python3 sobel_verify.py --input 4x4_input.hex --rtl-output 4x4_output.hex --rows 32 --cols 32

    # Generate a test image and run:
    python3 sobel_verify.py --generate-test --rows 8 --cols 8

What this replaces:
    Instead of opening a waveform viewer and manually checking values,
    this script tells you PASS/FAIL per pixel and shows you exactly
    where mismatches are.
"""

import argparse
import sys
import os
import numpy as np

# Import reference model
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from reference_model import SIMDArray, ALUOp, NewsDir


# ─────────────────────────────────────────────
# Sobel Pipeline (mirrors KernelTest_tb.sv)
# ─────────────────────────────────────────────
def run_sobel_pipeline(arr: SIMDArray, verbose: bool = False) -> None:
    """
    Execute the EXACT same instruction sequence as KernelTest_tb.sv
    on the reference model. After this, register r6 in each PE holds
    the Sobel edge magnitude (|Gx| + |Gy|) >> 2.
    
    This function assumes r1 in every PE is already loaded with pixel data.
    """
    rows, cols = arr.rows, arr.cols
    W = arr.data_width
    MASK = arr.mask

    def signed16(v):
        """Interpret 16-bit unsigned as signed."""
        return v - (1 << W) if v >= (1 << (W - 1)) else v

    def to_u16(v):
        """Convert signed to 16-bit unsigned."""
        return v & MASK

    if verbose:
        print("─── Gx computation ───")

    # ====================================================
    #                        Gx
    # ====================================================
    # r2 = r1 + NORTH(r1)   — add_north(r2, r1, r1)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(1)
            n = arr.get_neighbor(r, c, NewsDir.NORTH, 1)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r2 = r2 + SOUTH(r2)   — add_south(r2, r2, r2)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(2)
            n = arr.get_neighbor(r, c, NewsDir.SOUTH, 2)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r3 = EAST(r2)          — mov_east(r3, r2)  [rs1=0, so 0 + east_neighbor]
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.EAST, 2)
            arr.pe[r][c].write_reg(3, to_u16(n))

    # r4 = WEST(r2)          — mov_west(r4, r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.WEST, 2)
            arr.pe[r][c].write_reg(4, to_u16(n))

    # r5 = r3 - r4           — sub(r5, r3, r4)  => Gx
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(3)
            b = arr.pe[r][c].read_reg(4)
            arr.pe[r][c].write_reg(5, to_u16(a - b))

    if verbose:
        print("─── Gy computation ───")

    # ====================================================
    #                        Gy
    # ====================================================
    # r2 = r1 + EAST(r1)    — add_east(r2, r1, r1)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(1)
            n = arr.get_neighbor(r, c, NewsDir.EAST, 1)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r2 = r2 + WEST(r2)    — add_west(r2, r2, r2)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(2)
            n = arr.get_neighbor(r, c, NewsDir.WEST, 2)
            arr.pe[r][c].write_reg(2, to_u16(a + n))

    # r3 = NORTH(r2)         — mov_north(r3, r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.NORTH, 2)
            arr.pe[r][c].write_reg(3, to_u16(n))

    # r4 = SOUTH(r2)         — mov_south(r4, r2)
    for r in range(rows):
        for c in range(cols):
            n = arr.get_neighbor(r, c, NewsDir.SOUTH, 2)
            arr.pe[r][c].write_reg(4, to_u16(n))

    # r6 = r3 - r4           — sub(r6, r3, r4)  => Gy
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(3)
            b = arr.pe[r][c].read_reg(4)
            arr.pe[r][c].write_reg(6, to_u16(a - b))

    if verbose:
        print("─── Magnitude: |Gx| + |Gy| ───")

    # ====================================================
    #                   |Gx| computation
    # ====================================================
    # r3 = getmsb(r5)       — MSBTST: r3 = r0 XOR (MSB_of_r5 replicated) = 0 or 0xFFFF
    for r in range(rows):
        for c in range(cols):
            val = arr.pe[r][c].read_reg(5)
            msb = (val >> (W - 1)) & 1
            arr.pe[r][c].write_reg(3, MASK if msb else 0)

    # r4 = r5 XOR r3        — xorr(r4, r5, r3)  => conditional complement
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(5)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(4, (a ^ b) & MASK)

    # r5 = r4 - r3          — sub(r5, r4, r3)   => add 1 if was negative (two's comp abs)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(4)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(5, to_u16(a - b))

    # ====================================================
    #                   |Gy| computation
    # ====================================================
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

    # r6 = r4 - r3
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(4)
            b = arr.pe[r][c].read_reg(3)
            arr.pe[r][c].write_reg(6, to_u16(a - b))

    # ====================================================
    #                  |Gx| + |Gy|
    # ====================================================
    # r6 = r5 + r6          — add(r6, r5, r6)
    for r in range(rows):
        for c in range(cols):
            a = arr.pe[r][c].read_reg(5)
            b = arr.pe[r][c].read_reg(6)
            arr.pe[r][c].write_reg(6, to_u16(a + b))

    # ====================================================
    #                  Shift right by 2
    # ====================================================
    # r6 = r6 >> 2  (arithmetic)  — sra(r6, r6, 2)
    for r in range(rows):
        for c in range(cols):
            val = signed16(arr.pe[r][c].read_reg(6))
            shifted = val >> 2
            arr.pe[r][c].write_reg(6, to_u16(shifted))

    if verbose:
        print("─── Pipeline complete ───")


# ─────────────────────────────────────────────
# File I/O
# ─────────────────────────────────────────────
def load_hex_image(filename: str, num_pixels: int) -> list[int]:
    """Load a hex file (one value per line) into a list of ints."""
    values = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('//') or line.startswith('#'):
                continue
            # Handle possible inline comments
            token = line.split()[0]
            values.append(int(token, 16))
    if len(values) < num_pixels:
        print(f"WARNING: hex file has {len(values)} values but expected {num_pixels}")
        values.extend([0] * (num_pixels - len(values)))
    return values[:num_pixels]


def write_hex_output(filename: str, values: list[int]):
    """Write values as hex, one per line."""
    with open(filename, 'w') as f:
        for v in values:
            f.write(f"{v & 0xFFFF:02x}\n")


# ─────────────────────────────────────────────
# Comparison
# ─────────────────────────────────────────────
def compare_outputs(expected: list[int], actual: list[int],
                    rows: int, cols: int, mask: int = 0xFFFF) -> bool:
    """
    Compare expected vs actual pixel-by-pixel.
    Returns True if all match.
    """
    mismatches = 0
    total = min(len(expected), len(actual))

    for i in range(total):
        exp = expected[i] & mask
        act = actual[i] & mask
        if exp != act:
            r = i // cols
            c = i % cols
            mismatches += 1
            if mismatches <= 20:  # Only print first 20 mismatches
                print(f"  MISMATCH @ pixel[{r},{c}] (addr {i}): "
                      f"expected=0x{exp:04x} ({exp:5d}), "
                      f"got=0x{act:04x} ({act:5d}), "
                      f"diff={act - exp:+d}")

    if mismatches > 20:
        print(f"  ... and {mismatches - 20} more mismatches")

    if mismatches == 0:
        print(f"\n  ✓ ALL {total} PIXELS MATCH — PASS")
        return True
    else:
        print(f"\n  ✗ {mismatches}/{total} pixels mismatched — FAIL")
        return False


# ─────────────────────────────────────────────
# Generate test images
# ─────────────────────────────────────────────
def generate_gradient_image(rows: int, cols: int) -> list[int]:
    """Generate a simple gradient test image (values 0-255)."""
    pixels = []
    for r in range(rows):
        for c in range(cols):
            pixels.append((r * 8 + c * 8) & 0xFF)
    return pixels


def generate_checkerboard(rows: int, cols: int, block_size: int = 4) -> list[int]:
    """Generate a checkerboard pattern."""
    pixels = []
    for r in range(rows):
        for c in range(cols):
            block = ((r // block_size) + (c // block_size)) % 2
            pixels.append(200 if block else 50)
    return pixels


def generate_single_edge(rows: int, cols: int) -> list[int]:
    """Generate an image with a single vertical edge in the middle."""
    pixels = []
    for r in range(rows):
        for c in range(cols):
            pixels.append(0 if c < cols // 2 else 200)
    return pixels


# ─────────────────────────────────────────────
# Main runner
# ─────────────────────────────────────────────
def run_verification(input_pixels: list[int], rows: int, cols: int,
                     rtl_output_file: str = None, verbose: bool = False) -> bool:
    """
    Full verification flow:
      1. Load pixels into reference model
      2. Run Sobel pipeline
      3. Extract expected outputs
      4. Compare against RTL output (if provided)
    """
    assert len(input_pixels) >= rows * cols, \
        f"Need {rows*cols} pixels, got {len(input_pixels)}"

    # Create array model matching your RTL parameters
    arr = SIMDArray(rows=rows, cols=cols, data_width=16, reg_depth=8)

    # Load pixels into r1 of each PE (same as the TB's load loop)
    for r in range(rows):
        for c in range(cols):
            pixel = input_pixels[r * cols + c]
            arr.pe[r][c].write_reg(1, pixel & 0xFFFF)

    if verbose:
        print(f"Loaded {rows}x{cols} = {rows*cols} pixels into r1")

    # Run the Sobel pipeline
    run_sobel_pipeline(arr, verbose=verbose)

    # Extract results from r6 (matches the TB's store loop)
    expected_output = []
    for r in range(rows):
        for c in range(cols):
            val = arr.pe[r][c].read_reg(6)
            expected_output.append(val)

    # Print some statistics
    vals = np.array(expected_output, dtype=np.int16)
    print(f"\nExpected output statistics:")
    print(f"  Range: [{vals.min()}, {vals.max()}]")
    print(f"  Mean:  {vals.mean():.1f}")
    non_zero = np.count_nonzero(vals)
    print(f"  Non-zero pixels: {non_zero}/{len(vals)} ({100*non_zero/len(vals):.1f}%)")

    # Compare against RTL output
    if rtl_output_file:
        print(f"\nComparing against RTL output: {rtl_output_file}")
        actual = load_hex_image(rtl_output_file, rows * cols)
        return compare_outputs(expected_output, actual, rows, cols)
    else:
        # Just write the expected output
        out_file = "expected_sobel_output.hex"
        write_hex_output(out_file, expected_output)
        print(f"\nWrote expected output to {out_file}")
        print("Run your RTL simulation, then re-run with --rtl-output to compare.")
        return True


# ─────────────────────────────────────────────
# Pixel grid visualizer (ASCII art)
# ─────────────────────────────────────────────
def print_pixel_grid(values: list[int], rows: int, cols: int,
                     title: str = "", max_display: int = 16):
    """Print a small pixel grid as ASCII for quick visual check."""
    display_r = min(rows, max_display)
    display_c = min(cols, max_display)

    if title:
        print(f"\n{title} ({display_r}x{display_c} shown of {rows}x{cols}):")

    # Header
    print("     " + " ".join(f"{c:4d}" for c in range(display_c)))
    print("    +" + "-----" * display_c)

    for r in range(display_r):
        row_vals = []
        for c in range(display_c):
            v = values[r * cols + c]
            # Show as signed if MSB is set
            if v >= 0x8000:
                row_vals.append(f"{v - 0x10000:4d}")
            else:
                row_vals.append(f"{v:4d}")
        print(f"{r:3d} | " + " ".join(row_vals))

    if rows > max_display or cols > max_display:
        print(f"    ... ({rows - display_r} more rows, {cols - display_c} more cols)")


# ─────────────────────────────────────────────
# Self-test: verify the abs trick
# ─────────────────────────────────────────────
def test_abs_trick():
    """
    Verify that the MSBTST + XOR + SUB sequence correctly computes
    absolute value in 16-bit two's complement. This is what the RTL
    uses instead of a dedicated abs instruction.
    
    The trick:  |x| = (x ^ sign_mask) - sign_mask
      where sign_mask = 0xFFFF if x < 0, else 0x0000
    """
    print("Testing abs() trick (MSBTST + XOR + SUB)...")
    W = 16
    MASK = 0xFFFF

    test_values = [0, 1, -1, 127, -128, 255, -256, 32767, -32768, -1000, 1000]
    all_pass = True

    for sv in test_values:
        x = sv & MASK  # unsigned representation

        # Step 1: MSBTST on r0 (=0) with rs2=x  =>  0 XOR sign_mask
        msb = (x >> 15) & 1
        sign_mask = MASK if msb else 0

        # Step 2: XOR x with sign_mask
        xored = (x ^ sign_mask) & MASK

        # Step 3: SUB xored - sign_mask
        result = (xored - sign_mask) & MASK

        # Expected: abs(sv) in unsigned 16-bit
        expected = abs(sv) & MASK

        if result != expected:
            print(f"  FAIL: abs({sv}) = 0x{result:04x}, expected 0x{expected:04x}")
            all_pass = False

    print(f"  {'PASS' if all_pass else 'FAIL'}: abs trick verification")
    return all_pass


# ─────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Automated Sobel edge detection verification for SIMD array",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Just generate expected output from input hex:
  python3 sobel_verify.py --input img/4x4_input.hex --rows 32 --cols 32

  # Compare RTL output against expected:
  python3 sobel_verify.py --input img/4x4_input.hex --rtl-output img/4x4_output.hex --rows 32 --cols 32

  # Generate a test image, compute expected, write hex files:
  python3 sobel_verify.py --generate-test gradient --rows 8 --cols 8

  # Run self-tests:
  python3 sobel_verify.py --self-test
        """)

    parser.add_argument("--input", help="Input hex image file")
    parser.add_argument("--rtl-output", help="RTL simulation output hex file to compare against")
    parser.add_argument("--rows", type=int, default=32, help="Array row count (default: 32)")
    parser.add_argument("--cols", type=int, default=32, help="Array column count (default: 32)")
    parser.add_argument("--generate-test", choices=["gradient", "checkerboard", "edge"],
                        help="Generate a test image instead of loading one")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--show-grid", action="store_true", help="Print pixel grids")
    parser.add_argument("--self-test", action="store_true", help="Run internal self-tests")

    args = parser.parse_args()

    print("=" * 60)
    print("  Sobel Edge Detection — Automated Verification")
    print("=" * 60)

    if args.self_test:
        test_abs_trick()
        # Quick end-to-end: 4x4 gradient
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

    # Load or generate input pixels
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
        print("\nError: specify --input or --generate-test")
        sys.exit(1)

    # Run verification
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
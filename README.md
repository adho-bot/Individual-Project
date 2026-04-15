# Individual Project Repository (EEEN30330)

This repository contains software and hardware design artefacts produced for the Individual 3rd Year Project (EEEN30330).

## Version-Controlled Repository Link (for Final Report Appendix)

Include this link in the appendix of the Final Report (Section 9.5 requirement):

- Repository: https://github.com/adho-bot/Individual-Project

> Note: A repository link is required for software-development projects.

## Repository Structure

Main directories and files required to run/evaluate the software artefacts:

- `rtl/` – SystemVerilog design sources (processing elements, control, top-level modules).
- `sim/` – Simulation testbenches and generated/expected output files.
- `scripts/` – Python verification script (`sobel_verify.py`) and related utilities.
- `img/` – Input/output image and hex data generation/handling scripts and assets.
- `cnn/` – C sources and data headers used for instruction/data preparation.
- `ip/` – Packaged IP blocks and wrappers.
- `vitis/` – Vitis-side C integration files.
- `syn/` – Synthesis constraint file(s), including board constraints.
- `report/` – Project report source artefact(s).
- `Makefile.sobel` – Sobel verification flow automation (golden generation + simulation).

## Running / Evaluating the Work

From repository root:

- Show available workflow targets:
  - `make -f Makefile.sobel help`
- Standard flow:
  - `make -f Makefile.sobel golden`
  - `make -f Makefile.sobel sim`
  - `make -f Makefile.sobel compare`

If needed, adjust path configuration in `Makefile.sobel` (`PROJECT_DIR`) to match your local checkout path.

## Third-Party / Reused Code Declaration

Any imported, reused, or third-party code must be clearly identified and referenced in the final submission.

- Python packages under local virtual-environment folders (e.g., `img/venv/`, `scripts/venv/`) are third-party dependencies and are not original project code.
- Any additional external code included in this repository should be documented with source and license details.

## Academic Integrity

All submitted software artefacts remain the student’s responsibility and must comply with academic integrity requirements.

## Optional Supporting Material in Report Appendices

Where helpful, appendices may include supplementary material referenced from the main report, such as:

- extended derivations/proofs,
- supplementary experiment/simulation results,
- additional figures/tables,
- detailed algorithm or parameter listings.

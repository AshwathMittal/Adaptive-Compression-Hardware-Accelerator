"""Print every generated adaptive-compression vector for a video walkthrough."""

from __future__ import annotations

import argparse
from pathlib import Path

from compression_model import (
    Format,
    choose_format,
    decode,
    encode,
    format_costs,
    tile_to_matrix,
    unpack_tile,
)


DEFAULT_VECTOR_DIR = (
    Path(__file__).resolve().parent
    / "verilog"
    / "rtl"
    / "HardwareAccelerator"
    / "generated_vectors"
)


def format_name(format_: Format) -> str:
    return format_.name


def read_lines(vector_dir: Path, filename: str) -> list[str]:
    path = vector_dir / filename
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {path}. Run 'python3 generate_vectors.py --count 256' first."
        )
    return [line.strip() for line in path.read_text(encoding="ascii").splitlines()]


def print_matrix(tile: tuple[int, ...], indent: str = "      ") -> None:
    for row in tile_to_matrix(tile):
        print(indent + "[" + " ".join(f"{value:02x}" for value in row) + "]")


def print_vector(index: int, tile: tuple[int, ...]) -> tuple[Format, int, int]:
    costs = format_costs(tile)
    selected = choose_format(tile)
    encoded = {format_: encode(tile, format_) for format_ in Format}
    selected_encoded = encoded[selected]
    reconstructed = decode(selected_encoded)
    if reconstructed != tile:
        raise AssertionError(f"vector {index} did not round-trip")

    print("\n" + "=" * 60)
    print(f"VECTOR {index:03d} | non-zero={sum(value != 0 for value in tile):02d}"
          f" | zero={sum(value == 0 for value in tile):02d}")
    print("  INPUT 4x4 TILE:")
    print_matrix(tile)
    print("  COST COMPARISON (bits):")
    for format_ in Format:
        candidate = encoded[format_]
        print(f"    {format_name(format_):6s} = {costs[format_]:3d} bits  "
              f"payload={candidate.bit_length}'h{candidate.bits:x}")
    saved = costs[Format.RAW] - selected_encoded.bit_length
    percent = saved * 100 // costs[Format.RAW]
    print(f"  DECISION: {format_name(selected):6s} ({selected_encoded.bit_length} bits, "
          f"saved {saved} bits / {percent}%)")
    print(f"  FINAL COMPRESSED STREAM: {selected_encoded.bit_length}'h"
          f"{selected_encoded.bits:x}")
    print("  DECOMPRESSED OUTPUT:")
    print_matrix(reconstructed)
    print("  ROUND-TRIP: PASS")
    return selected, selected_encoded.bit_length, costs[Format.RAW]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vector-dir", type=Path, default=DEFAULT_VECTOR_DIR)
    parser.add_argument(
        "--limit",
        type=int,
        help="Print only the first N vectors; default is every generated vector.",
    )
    args = parser.parse_args()

    tile_lines = read_lines(args.vector_dir, "tiles.mem")
    expected_lines = read_lines(args.vector_dir, "expected.mem")
    if len(tile_lines) != len(expected_lines):
        raise ValueError("tiles.mem and expected.mem contain different vector counts")
    count = len(tile_lines) if args.limit is None else min(args.limit, len(tile_lines))
    if count < 1:
        raise ValueError("--limit must be at least 1")

    selected_counts = {format_: 0 for format_ in Format}
    selected_bits = 0
    raw_bits = 0
    for index in range(count):
        tile = unpack_tile(int(tile_lines[index], 16))
        expected = int(expected_lines[index], 16)
        expected_costs = {
            Format.RAW: expected & 0xFF,
            Format.BITMAP: (expected >> 8) & 0xFF,
            Format.RLE: (expected >> 16) & 0xFF,
        }
        expected_format = Format((expected >> 24) & 0x3)
        if format_costs(tile) != expected_costs or choose_format(tile) != expected_format:
            raise AssertionError(f"vector {index} does not match expected.mem")

        selected, selected_length, raw_length = print_vector(index, tile)
        selected_counts[selected] += 1
        selected_bits += selected_length
        raw_bits += raw_length

    saved_bits = raw_bits - selected_bits
    print("\n" + "=" * 60)
    print(f"SUMMARY: {count} vector(s) validated and decompressed successfully")
    for format_ in Format:
        print(f"  {format_name(format_):6s}: {selected_counts[format_]:3d} selections")
    print(f"  RAW baseline: {raw_bits} bits")
    print(f"  ADAPTIVE total: {selected_bits} bits")
    print(f"  TOTAL SAVED: {saved_bits} bits ({saved_bits * 100 // raw_bits}%)")


if __name__ == "__main__":
    main()
"""Generate deterministic software-oracle vectors for the RTL testbench."""

from __future__ import annotations

import argparse
import random
from pathlib import Path

from compression_model import (
    Format,
    encode_bitmap,
    encode_raw,
    encode_rle,
    format_costs,
    pack_tile,
    choose_format,
)


def make_tile(rng: random.Random, nonzero_count: int, pattern: str) -> tuple[int, ...]:
    values = [0] * 16
    if pattern == "random":
        positions = rng.sample(range(16), nonzero_count)
    elif pattern == "clustered":
        start = rng.randrange(17 - nonzero_count) if nonzero_count else 0
        positions = range(start, start + nonzero_count)
    elif pattern == "alternating":
        order = list(range(0, 16, 2)) + list(range(1, 16, 2))
        positions = order[:nonzero_count]
    else:
        raise ValueError(f"unknown pattern: {pattern}")
    for position in positions:
        values[position] = rng.randint(1, 255)
    return tuple(values)


def generate(count: int, seed: int) -> list[tuple[int, ...]]:
    rng = random.Random(seed)
    vectors: list[tuple[int, ...]] = []
    patterns = ("random", "clustered", "alternating")
    # Guarantee every possible nonzero count before filling randomly.
    for nonzero_count in range(17):
        vectors.append(make_tile(rng, nonzero_count, patterns[nonzero_count % 3]))
    while len(vectors) < count:
        vectors.append(make_tile(rng, rng.randrange(17), rng.choice(patterns)))
    return vectors[:count]


def write_vectors(output_dir: Path, vectors: list[tuple[int, ...]]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    files = {
        "tiles.mem": [],
        "expected.mem": [],
        "raw.mem": [],
        "bitmap.mem": [],
        "rle.mem": [],
    }
    for tile in vectors:
        costs = format_costs(tile)
        expected = (
            (int(choose_format(tile)) << 24)
            | (costs[Format.RLE] << 16)
            | (costs[Format.BITMAP] << 8)
            | costs[Format.RAW]
        )
        files["tiles.mem"].append(f"{pack_tile(tile):032x}")
        files["expected.mem"].append(f"{expected:07x}")
        files["raw.mem"].append(encode_raw(tile).hex())
        files["bitmap.mem"].append(encode_bitmap(tile).hex())
        files["rle.mem"].append(encode_rle(tile).hex())

    for filename, lines in files.items():
        (output_dir / filename).write_text("\n".join(lines) + "\n", encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=256)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parent
        / "verilog"
        / "rtl"
        / "HardwareAccelerator"
        / "generated_vectors",
    )
    args = parser.parse_args()
    if args.count < 17:
        parser.error("--count must be at least 17 to cover every nonzero count")
    vectors = generate(args.count, args.seed)
    write_vectors(args.output_dir, vectors)
    print(f"Wrote {len(vectors)} vectors to {args.output_dir}")


if __name__ == "__main__":
    main()

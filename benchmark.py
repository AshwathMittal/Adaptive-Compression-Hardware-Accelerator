"""Benchmark fixed-format compression against the adaptive selector."""

from __future__ import annotations

import argparse
import csv
import random
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

from compression_model import Format, choose_format, decode, encode, format_costs
from generate_vectors import make_tile


def run(samples_per_density: int, seed: int) -> list[dict[str, object]]:
    rng = random.Random(seed)
    rows: list[dict[str, object]] = []
    for pattern in ("random", "clustered", "alternating"):
        for nonzero_count in range(17):
            for sample in range(samples_per_density):
                tile = make_tile(rng, nonzero_count, pattern)
                costs = format_costs(tile)
                selected = choose_format(tile)
                encoded = encode(tile, selected)
                if decode(encoded) != tile:
                    raise AssertionError("software round-trip failed")
                rows.append(
                    {
                        "pattern": pattern,
                        "nonzero_count": nonzero_count,
                        "density": nonzero_count / 16,
                        "sample": sample,
                        "raw_bits": costs[Format.RAW],
                        "bitmap_bits": costs[Format.BITMAP],
                        "rle_bits": costs[Format.RLE],
                        "adaptive_bits": encoded.bit_length,
                        "selected_format": selected.name,
                        "savings_vs_raw_percent":
                            100 * (costs[Format.RAW] - encoded.bit_length) / costs[Format.RAW],
                    }
                )
    return rows


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    groups: dict[tuple[str, int], list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        groups[(str(row["pattern"]), int(row["nonzero_count"]))].append(row)
    summary: list[dict[str, object]] = []
    for (pattern, count), group in sorted(groups.items()):
        selections = Counter(str(row["selected_format"]) for row in group)
        summary.append(
            {
                "pattern": pattern,
                "nonzero_count": count,
                "density": count / 16,
                "raw_bits": group[0]["raw_bits"],
                "bitmap_bits": group[0]["bitmap_bits"],
                "rle_bits": group[0]["rle_bits"],
                "adaptive_bits": group[0]["adaptive_bits"],
                "adaptive_savings_percent": group[0]["savings_vs_raw_percent"],
                "raw_selections": selections["RAW"],
                "bitmap_selections": selections["BITMAP"],
                "rle_selections": selections["RLE"],
            }
        )
    return summary


def create_plots(output_dir: Path, summary: list[dict[str, object]]) -> None:
    # Current hardware costs depend only on nonzero count, so one curve per
    # method is sufficient; all three pattern families overlap exactly.
    base = [row for row in summary if row["pattern"] == "random"]
    x = [100 * float(row["density"]) for row in base]
    fig, ax = plt.subplots(figsize=(8, 5))
    for key, label in (
        ("raw_bits", "RAW only"),
        ("bitmap_bits", "Bitmap only"),
        ("rle_bits", "RLE only"),
        ("adaptive_bits", "Adaptive"),
    ):
        ax.plot(x, [float(row[key]) for row in base], marker="o", label=label)
    ax.set(xlabel="Nonzero density (%)", ylabel="Transferred bits per tile")
    ax.set_title("Compression cost versus 4x4 tile density")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(output_dir / "compression_by_density.png", dpi=180)
    plt.close(fig)

    counts = {
        format_.name: sum(int(row[f"{format_.name.lower()}_selections"]) for row in summary)
        for format_ in Format
    }
    fig, ax = plt.subplots(figsize=(6, 4))
    labels = [format_.name for format_ in Format]
    ax.bar(labels, [counts[label] for label in labels], color=["#315a7d", "#3f8f83", "#d9824b"])
    ax.set(ylabel="Test tiles selected", title="Adaptive format choices")
    fig.tight_layout()
    fig.savefig(output_dir / "adaptive_format_choices.png", dpi=180)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--samples-per-density", type=int, default=100)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--output-dir", type=Path, default=Path("benchmark_results"))
    args = parser.parse_args()
    if args.samples_per_density <= 0:
        parser.error("--samples-per-density must be positive")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rows = run(args.samples_per_density, args.seed)
    summary = summarize(rows)
    write_csv(args.output_dir / "tile_results.csv", rows)
    write_csv(args.output_dir / "summary.csv", summary)
    create_plots(args.output_dir, summary)

    total_raw = sum(int(row["raw_bits"]) for row in rows)
    total_adaptive = sum(int(row["adaptive_bits"]) for row in rows)
    savings = 100 * (total_raw - total_adaptive) / total_raw
    print(f"Tested {len(rows)} tiles; all software round-trips passed.")
    print(f"Adaptive savings versus tagged RAW: {savings:.2f}%")
    print(f"Results written to {args.output_dir}")


if __name__ == "__main__":
    main()

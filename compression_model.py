"""Bit-accurate software model for the 4x4 adaptive compressor RTL.

Bit 0 is the least-significant bit.  Element 0 of a tile is therefore stored
in the lowest element-sized field, matching ``tile_in[0]`` in SystemVerilog.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
from typing import Iterable, Sequence


DATA_W = 8
TILE_ELEMS = 16
TAG_W = 2
BITMAP_HEADER_W = TILE_ELEMS
RLE_COUNT_W = 4
RLE_RUN_W = 4


class Format(IntEnum):
    RAW = 0b00
    BITMAP = 0b01
    RLE = 0b10


@dataclass(frozen=True)
class EncodedTile:
    format: Format
    bits: int
    bit_length: int

    def hex(self, output_bits: int = 200) -> str:
        if self.bits >= (1 << output_bits):
            raise ValueError(f"encoded value does not fit in {output_bits} bits")
        return f"{self.bits:0{(output_bits + 3) // 4}x}"


def validate_tile(tile: Sequence[int]) -> tuple[int, ...]:
    values = tuple(int(value) for value in tile)
    if len(values) != TILE_ELEMS:
        raise ValueError(f"a tile must contain exactly {TILE_ELEMS} values")
    maximum = (1 << DATA_W) - 1
    if any(value < 0 or value > maximum for value in values):
        raise ValueError(f"tile values must be unsigned {DATA_W}-bit integers")
    return values


def pack_tile(tile: Sequence[int]) -> int:
    values = validate_tile(tile)
    return sum(value << (DATA_W * index) for index, value in enumerate(values))


def unpack_tile(packed: int) -> tuple[int, ...]:
    if packed < 0 or packed >= (1 << (DATA_W * TILE_ELEMS)):
        raise ValueError("packed tile does not fit in 128 bits")
    mask = (1 << DATA_W) - 1
    return tuple((packed >> (DATA_W * index)) & mask for index in range(TILE_ELEMS))


def format_costs(tile_or_nonzero_count: Sequence[int] | int) -> dict[Format, int]:
    if isinstance(tile_or_nonzero_count, int):
        nonzero_count = tile_or_nonzero_count
    else:
        nonzero_count = sum(value != 0 for value in validate_tile(tile_or_nonzero_count))
    if not 0 <= nonzero_count <= TILE_ELEMS:
        raise ValueError("nonzero count must be between 0 and 16")
    return {
        Format.RAW: TAG_W + TILE_ELEMS * DATA_W,
        Format.BITMAP: TAG_W + BITMAP_HEADER_W + nonzero_count * DATA_W,
        Format.RLE: TAG_W + RLE_COUNT_W + nonzero_count * (RLE_RUN_W + DATA_W),
    }


def choose_format(tile_or_nonzero_count: Sequence[int] | int) -> Format:
    """Match RTL tie-breaking: RAW first, then Bitmap, then RLE."""
    costs = format_costs(tile_or_nonzero_count)
    return min((Format.RAW, Format.BITMAP, Format.RLE), key=costs.__getitem__)


def encode_raw(tile: Sequence[int]) -> EncodedTile:
    values = validate_tile(tile)
    bits = int(Format.RAW) | (pack_tile(values) << TAG_W)
    return EncodedTile(Format.RAW, bits, format_costs(values)[Format.RAW])


def encode_bitmap(tile: Sequence[int]) -> EncodedTile:
    values = validate_tile(tile)
    bitmap = sum((value != 0) << index for index, value in enumerate(values))
    bits = int(Format.BITMAP) | (bitmap << TAG_W)
    shift = TAG_W + BITMAP_HEADER_W
    for value in values:
        if value:
            bits |= value << shift
            shift += DATA_W
    return EncodedTile(Format.BITMAP, bits, shift)


def encode_rle(tile: Sequence[int]) -> EncodedTile:
    values = validate_tile(tile)
    nonzero_count = sum(value != 0 for value in values)
    # The RTL truncates 16 to 0 in its 4-bit header.  The bit_length remains
    # authoritative, allowing a decoder to distinguish this from an all-zero
    # tile (6 bits).  Adaptive selection never chooses RLE for a dense tile.
    bits = int(Format.RLE) | ((nonzero_count & 0xF) << TAG_W)
    shift = TAG_W + RLE_COUNT_W
    zero_run = 0
    for value in values:
        if value == 0:
            zero_run += 1
            continue
        token = (zero_run << DATA_W) | value
        bits |= token << shift
        shift += RLE_RUN_W + DATA_W
        zero_run = 0
    return EncodedTile(Format.RLE, bits, shift)


def encode(tile: Sequence[int], format_: Format) -> EncodedTile:
    encoders = {
        Format.RAW: encode_raw,
        Format.BITMAP: encode_bitmap,
        Format.RLE: encode_rle,
    }
    return encoders[Format(format_)](tile)


def adaptive_encode(tile: Sequence[int]) -> EncodedTile:
    return encode(tile, choose_format(tile))


def decode(encoded: EncodedTile) -> tuple[int, ...]:
    if (encoded.bits & 0b11) != int(encoded.format):
        raise ValueError("format tag does not match EncodedTile.format")

    if encoded.format == Format.RAW:
        return unpack_tile(encoded.bits >> TAG_W)

    if encoded.format == Format.BITMAP:
        bitmap = (encoded.bits >> TAG_W) & ((1 << TILE_ELEMS) - 1)
        values = [0] * TILE_ELEMS
        shift = TAG_W + BITMAP_HEADER_W
        for index in range(TILE_ELEMS):
            if (bitmap >> index) & 1:
                values[index] = (encoded.bits >> shift) & 0xFF
                shift += DATA_W
        if shift != encoded.bit_length:
            raise ValueError("bitmap length is inconsistent with its occupancy map")
        return tuple(values)

    if encoded.format == Format.RLE:
        payload_bits = encoded.bit_length - TAG_W - RLE_COUNT_W
        token_w = RLE_RUN_W + DATA_W
        if payload_bits < 0 or payload_bits % token_w:
            raise ValueError("invalid RLE bit length")
        token_count = payload_bits // token_w
        header_count = (encoded.bits >> TAG_W) & 0xF
        if header_count != (token_count & 0xF):
            raise ValueError("RLE token count header is inconsistent with its length")

        values = [0] * TILE_ELEMS
        cursor = 0
        shift = TAG_W + RLE_COUNT_W
        for _ in range(token_count):
            token = (encoded.bits >> shift) & ((1 << token_w) - 1)
            zero_run = token >> DATA_W
            value = token & 0xFF
            cursor += zero_run
            if cursor >= TILE_ELEMS or value == 0:
                raise ValueError("invalid RLE token")
            values[cursor] = value
            cursor += 1
            shift += token_w
        return tuple(values)

    raise ValueError(f"unsupported format tag: {encoded.format}")


def matrix_to_tile(rows: Iterable[Iterable[int]]) -> tuple[int, ...]:
    flattened = tuple(value for row in rows for value in row)
    return validate_tile(flattened)


def tile_to_matrix(tile: Sequence[int]) -> tuple[tuple[int, ...], ...]:
    values = validate_tile(tile)
    return tuple(tuple(values[row * 4 : row * 4 + 4]) for row in range(4))

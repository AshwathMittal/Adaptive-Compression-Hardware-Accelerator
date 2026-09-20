import random
import unittest

from compression_model import (
    EncodedTile,
    Format,
    adaptive_encode,
    choose_format,
    decode,
    encode,
    format_costs,
    pack_tile,
    unpack_tile,
)


def tile_with_nonzeros(count: int) -> tuple[int, ...]:
    return tuple(index + 1 if index < count else 0 for index in range(16))


class CompressionModelTests(unittest.TestCase):
    def test_known_sparse_example(self) -> None:
        tile = (5, 0, 0, 0, 0, 0, 0, 2) + (0,) * 8
        costs = format_costs(tile)
        self.assertEqual(costs, {Format.RAW: 130, Format.BITMAP: 34, Format.RLE: 30})
        self.assertEqual(choose_format(tile), Format.RLE)

    def test_selector_boundaries_and_ties(self) -> None:
        expected = {
            0: Format.RLE,
            1: Format.RLE,
            2: Format.RLE,
            3: Format.BITMAP,
            13: Format.BITMAP,
            14: Format.RAW,
            15: Format.RAW,
            16: Format.RAW,
        }
        for count, format_ in expected.items():
            with self.subTest(nonzero_count=count):
                self.assertEqual(choose_format(tile_with_nonzeros(count)), format_)

    def test_pack_order(self) -> None:
        tile = tuple(range(16))
        self.assertEqual(pack_tile(tile) & 0xFFFF, 0x0100)
        self.assertEqual(unpack_tile(pack_tile(tile)), tile)

    def test_every_encoder_round_trips_random_tiles(self) -> None:
        rng = random.Random(2026)
        for _ in range(1000):
            tile = tuple(0 if rng.random() < 0.6 else rng.randint(1, 255) for _ in range(16))
            for format_ in Format:
                self.assertEqual(decode(encode(tile, format_)), tile)
            self.assertEqual(decode(adaptive_encode(tile)), tile)

    def test_dense_rle_header_wrap_is_unambiguous_with_length(self) -> None:
        tile = tile_with_nonzeros(16)
        encoded = encode(tile, Format.RLE)
        self.assertEqual((encoded.bits >> 2) & 0xF, 0)
        self.assertEqual(encoded.bit_length, 198)
        self.assertEqual(decode(encoded), tile)

    def test_bad_tag_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "format tag"):
            decode(EncodedTile(Format.RAW, 0b01, 130))


if __name__ == "__main__":
    unittest.main()

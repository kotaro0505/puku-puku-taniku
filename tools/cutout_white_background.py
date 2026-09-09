"""Create an RGBA cutout from a subject photographed on a clean white background.

Only the border-connected near-white area is removed. Enclosed highlights stay opaque,
which is important for glass and jelly-like catalog artwork.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def cutout(source: Path, destination: Path) -> None:
    rgb = np.asarray(Image.open(source).convert("RGB"), dtype=np.uint8)
    distance = (255 - rgb.astype(np.int16)).max(axis=2)

    # The JPEG background is almost pure white. Flooding only the near-white band
    # prevents pale highlights inside the succulent from turning into holes.
    # copy() makes the array-backed image writable for Pillow's in-place flood fill.
    flood_source = Image.fromarray(np.where(distance < 46, 255, 0).astype(np.uint8), "L").copy()
    ImageDraw.floodfill(flood_source, (0, 0), 128, thresh=0)
    exterior = np.asarray(flood_source) == 128

    alpha = np.full(distance.shape, 255, dtype=np.uint8)
    edge_alpha = np.clip((distance.astype(np.float32) - 6.0) / 40.0 * 255.0, 0.0, 255.0)
    alpha[exterior] = edge_alpha[exterior].astype(np.uint8)

    rgba = np.dstack((rgb, alpha))
    destination.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(destination, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    cutout(args.source, args.destination)


if __name__ == "__main__":
    main()

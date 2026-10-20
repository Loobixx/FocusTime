#!/usr/bin/env python3
"""Convert frame_N...gif files into sequential N+1.png files."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow is required. Install it with: python -m pip install Pillow", file=sys.stderr)
    raise SystemExit(1)


FRAME_PATTERN = re.compile(r"^frame_(\d+).*\.gif$", re.IGNORECASE)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert frame_00_delay-0.2s.gif files to 1.png, 2.png, etc."
    )
    parser.add_argument("source", type=Path, help="Folder containing the frame GIF files")
    parser.add_argument(
        "destination",
        type=Path,
        nargs="?",
        help="Output folder (defaults to a 'png_frames' folder inside source)",
    )
    args = parser.parse_args()

    source = args.source
    destination = args.destination or source / "png_frames"
    if not source.is_dir():
        parser.error(f"Source folder does not exist: {source}")

    frames: list[tuple[int, Path]] = []
    for path in source.iterdir():
        match = FRAME_PATTERN.match(path.name)
        if path.is_file() and match:
            frames.append((int(match.group(1)), path))
    frames.sort(key=lambda item: item[0])

    if not frames:
        parser.error(f"No files matching frame_*.gif found in: {source}")

    indices = [index for index, _ in frames]
    if len(indices) != len(set(indices)):
        parser.error("More than one GIF has the same frame number.")

    destination.mkdir(parents=True, exist_ok=True)
    for frame_number, path in frames:
        output_path = destination / f"{frame_number}.png"
        with Image.open(path) as image:
            # The files in the screenshot are individual GIF frames. If a GIF
            # contains multiple frames, use its first frame.
            image.seek(0)
            image.convert("RGBA").save(output_path, format="PNG")
        print(f"{path.name} -> {output_path.name}")

    print(f"Converted {len(frames)} frames into: {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

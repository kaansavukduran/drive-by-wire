"""Wrap a PNG (up to 256x256) into a single-image .ico for the NSIS installer.

  python3 packaging/png_to_ico.py assets/icon.png build/DriveByWire.ico

Windows Vista and later read PNG-compressed ICO entries directly, so no image
library is needed. The game .exe gets its icon from export_presets.cfg instead.
"""
import struct
import sys
from pathlib import Path

source, target = (Path(arg) for arg in sys.argv[1:3])
png = source.read_bytes()
if png[:8] != b"\x89PNG\r\n\x1a\n":
    raise SystemExit(f"{source} is not a PNG")
width, height = struct.unpack(">II", png[16:24])
if width > 256 or height > 256:
    raise SystemExit(f"{source} is {width}x{height}; ICO entries are at most 256x256")
header = struct.pack("<HHH", 0, 1, 1)
entry = struct.pack("<BBBBHHII", width % 256, height % 256, 0, 0, 1, 32, len(png), 6 + 16)
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(header + entry + png)
print(f"{target}: {width}x{height} PNG icon")

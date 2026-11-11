"""Dev helper: crop frames from a sheet and enlarge them for inspection.
usage: python3 peek.py sheet.png fw fh out.png scale idx [idx...] [--bg r,g,b]"""
import sys
from PIL import Image

args = sys.argv[1:]
bg = (59, 56, 73, 255)
if "--bg" in args:
    i = args.index("--bg")
    bg = tuple(int(v) for v in args[i + 1].split(",")) + (255,)
    del args[i:i + 2]
path, fw, fh, out, scale = args[0], int(args[1]), int(args[2]), args[3], int(args[4])
idx = [int(a) for a in args[5:]]
im = Image.open(path).convert("RGBA")
cols = im.width // fw
canvas = Image.new("RGBA", (len(idx) * (fw + 2), fh), bg)
for k, n in enumerate(idx):
    fr = im.crop(((n % cols) * fw, (n // cols) * fh, (n % cols) * fw + fw, (n // cols) * fh + fh))
    canvas.alpha_composite(fr, (k * (fw + 2), 0))
canvas.resize((canvas.width * scale, canvas.height * scale), Image.NEAREST).save(out)

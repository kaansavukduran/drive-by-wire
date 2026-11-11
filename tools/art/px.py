"""Tiny deterministic pixel-art toolkit shared by every generator.

No anti-aliasing anywhere: every primitive tests pixel centres and writes a
single palette colour. Images are RGBA with alpha 0 or 255 (glow layers are
explicitly registered via GLOW_OK).
"""
import hashlib
import json
import math
import os

from PIL import Image

import pal
from pal import P, INK, CLEAR

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "assets")
PREVIEW = os.path.join(ROOT, "tools", "art", "preview")

# --------------------------------------------------------------------------
# registry (filled by generators, written by build.py)
MANIFEST = {"sheets": {}, "images": {}}
PROVENANCE = {"files": {}}
GLOW_OK = set()          # asset relpaths allowed to hold partial alpha


def new(w, h, fill=CLEAR):
    return Image.new("RGBA", (w, h), fill)


def put(img, x, y, c):
    if c is None:
        return
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((int(x), int(y)), c)


def get(img, x, y):
    if 0 <= x < img.width and 0 <= y < img.height:
        return img.getpixel((x, y))
    return CLEAR


def rect(img, x0, y0, x1, y1, c):
    """Filled rect, inclusive corners."""
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            put(img, x, y, c)


def frame_rect(img, x0, y0, x1, y1, c):
    for x in range(x0, x1 + 1):
        put(img, x, y0, c)
        put(img, x, y1, c)
    for y in range(y0, y1 + 1):
        put(img, x0, y, c)
        put(img, x1, y, c)


def line(img, x0, y0, x1, y1, c):
    x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        put(img, x0, y0, c)
        if x0 == x1 and y0 == y1:
            return
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def ellipse(img, cx, cy, rx, ry, c, ring=None):
    """Filled ellipse by pixel-centre test. cx,cy may be .5 for even sizes."""
    if rx <= 0 or ry <= 0:
        return
    for y in range(int(math.floor(cy - ry)) - 1, int(math.ceil(cy + ry)) + 2):
        for x in range(int(math.floor(cx - rx)) - 1, int(math.ceil(cx + rx)) + 2):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1.0:
                if ring is not None and d > (1 - ring) ** 2:
                    put(img, x, y, c)
                elif ring is None:
                    put(img, x, y, c)


def circle(img, cx, cy, r, c):
    ellipse(img, cx, cy, r, r, c)


def blit(dst, src, x, y, mask_color=None):
    """Copy opaque pixels of src onto dst at (x,y)."""
    x, y = int(x), int(y)
    sp = src.load()
    for j in range(src.height):
        for i in range(src.width):
            c = sp[i, j]
            if c[3] > 0:
                put(dst, x + i, y + j, mask_color or c)


def under(dst, src, x, y):
    """Copy src pixels only where dst is transparent."""
    x, y = int(x), int(y)
    sp = src.load()
    for j in range(src.height):
        for i in range(src.width):
            c = sp[i, j]
            if c[3] > 0 and get(dst, x + i, y + j)[3] == 0:
                put(dst, x + i, y + j, c)


def outline(img, c=INK, diag=False, only_outside=True):
    """Add a 1-px outline around opaque pixels (into transparent pixels)."""
    w, h = img.size
    src = img.copy()
    sp = src.load()
    ip = img.load()
    nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diag:
        nb += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
    for y in range(h):
        for x in range(w):
            if sp[x, y][3] == 0:
                for dx, dy in nb:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < w and 0 <= yy < h and sp[xx, yy][3] > 0:
                        ip[x, y] = c
                        break
    return img


def inner_edge(img, c=INK):
    """Recolour opaque pixels that touch transparency (outline drawn inside)."""
    w, h = img.size
    src = img.copy()
    sp = src.load()
    ip = img.load()
    for y in range(h):
        for x in range(w):
            if sp[x, y][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < w and 0 <= yy < h) or sp[xx, yy][3] == 0:
                    ip[x, y] = c
                    break
    return img


def remap(img, fn):
    """Return a copy with every opaque pixel passed through fn(c)->c."""
    out = img.copy()
    p = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = p[x, y]
            if c[3] > 0:
                p[x, y] = fn(c)
    return out


def silhouette(img, c):
    return remap(img, lambda _c: c)


def shifted(img, dx, dy):
    out = new(img.width, img.height)
    out.paste(img, (dx, dy))
    return out


def flip_h(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def flip_v(img):
    return img.transpose(Image.FLIP_TOP_BOTTOM)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dith(x, y, level):
    """Ordered dither test: True with density level in [0,1]."""
    return (BAYER4[y % 4][x % 4] + 0.5) / 16.0 < level


def hash01(*args):
    """Deterministic pseudo-random in [0,1) from integer args."""
    h = hashlib.blake2b(repr(args).encode(), digest_size=8).digest()
    return int.from_bytes(h, "big") / 2 ** 64


def render(w, h, shapes, cx, cy, angle=0.0, sx=1.0, sy=1.0):
    """Rasterise local-space shapes. shapes = list of (inside(lx,ly), colour(lx,ly)),
    later shapes win. Pixel (x,y) centre is transformed into local space by the
    inverse of rotate(angle)+scale+translate(cx,cy)."""
    img = new(w, h)
    p = img.load()
    ca, sa = math.cos(angle), math.sin(angle)
    for y in range(h):
        for x in range(w):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            lx = (ca * dx + sa * dy) / sx
            ly = (-sa * dx + ca * dy) / sy
            col = None
            for inside, colour in shapes:
                if inside(lx, ly):
                    cc = colour(lx, ly) if callable(colour) else colour
                    if cc is not None:
                        col = cc
            if col is not None:
                p[x, y] = col
    return img


def clean_orphans(img, min_n=1):
    """Remove opaque pixels with <= min_n-1 opaque 4-neighbours (stray pixels)."""
    w, h = img.size
    src = img.copy().load()
    p = img.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                continue
            n = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and src[xx, yy][3] > 0:
                    n += 1
            if n < min_n:
                p[x, y] = CLEAR
    return img


# --------------------------------------------------------------------------
# sheets

def make_sheet(frames, cols):
    fw, fh = frames[0].size
    rows = (len(frames) + cols - 1) // cols
    sheet = new(fw * cols, fh * rows)
    for i, f in enumerate(frames):
        assert f.size == (fw, fh), (f.size, fw, fh)
        sheet.paste(f, ((i % cols) * fw, (i // cols) * fh))
    return sheet, rows


def anim(frames, fps, loop=True, **extra):
    d = {"frames": list(frames), "fps": fps, "loop": loop}
    d.update(extra)
    return d


class SheetBuilder:
    """Collects named animations (lists of frames) into one grid sheet,
    one animation per row (wrapping when longer than cols)."""

    def __init__(self, fw, fh, cols):
        self.fw, self.fh, self.cols = fw, fh, cols
        self.frames = []
        self.anims = {}

    def row_start(self):
        # pad to start of a new row
        while len(self.frames) % self.cols:
            self.frames.append(new(self.fw, self.fh))

    def add(self, name, frames, fps, loop=True, order=None, newrow=True, **extra):
        if newrow:
            self.row_start()
        base = len(self.frames)
        for f in frames:
            assert f.size == (self.fw, self.fh), (name, f.size)
            self.frames.append(f)
        idx = list(range(base, base + len(frames)))
        seq = [idx[i] for i in order] if order else idx
        self.anims[name] = anim(seq, fps, loop, **extra)
        return idx

    def alias(self, name, frame_ids, fps, loop=True, **extra):
        self.anims[name] = anim(frame_ids, fps, loop, **extra)

    def build(self):
        self.row_start()
        sheet, rows = make_sheet(self.frames, self.cols)
        return sheet, rows


def save(img, rel, script, glow=False):
    path = os.path.join(ASSETS, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, format="PNG", optimize=False, compress_level=9)
    if glow:
        GLOW_OK.add(rel)
    PROVENANCE["files"].setdefault("assets/" + rel, {})
    PROVENANCE["files"]["assets/" + rel].update(
        {"generated_by": "tools/art/" + script, "method": "procedural"})
    return path


def register_sheet(key, rel, sheet, fw, fh, cols, rows, anims, anchor, collision=None,
                   script="", **extra):
    save(sheet, rel, script)
    d = {
        "path": "assets/" + rel,
        "size": [sheet.width, sheet.height],
        "frame_width": fw,
        "frame_height": fh,
        "columns": cols,
        "rows": rows,
        "animations": anims,
        "anchor": list(anchor),
    }
    if collision:
        d["collision"] = collision
    d.update(extra)
    MANIFEST["sheets"][key] = d
    return d


def register_image(key, rel, img, script="", **extra):
    save(img, rel, script, glow=extra.pop("glow", False))
    d = {"path": "assets/" + rel, "size": [img.width, img.height]}
    d.update(extra)
    MANIFEST["images"][key] = d
    return d


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def preview(img, name, scale=4, bg=None):
    os.makedirs(PREVIEW, exist_ok=True)
    out = img
    if bg is not None:
        b = Image.new("RGBA", img.size, bg)
        b.alpha_composite(img)
        out = b
    out = out.resize((img.width * scale, img.height * scale), Image.NEAREST)
    out.save(os.path.join(PREVIEW, name))

"""Owner's cast, derived from the owner's canonical sheets in aion_endless_run:
garage standing sprites (idle loop) and 48x48 HUD/garage portraits.

Method: crop each frame by its registered rect (CANONICAL-PROVENANCE.json), align on the
registered eye-stabilised origin, box-downscale (alpha-weighted), threshold alpha at
50%, palette-clean to a per-character subset of the master palette, add the 1-px ink
outline, remove orphan pixels.
"""
import json
import os

from PIL import Image

import px
from pal import P, INK, nearest

SCRIPT = "gen_characters.py"
SRC = "/home/user/kaansavukduran/aion_endless_run/assets"
REPO = "github: kaansavukduran/aion_endless_run (assets/)"


def sub(*names):
    out = []
    for n in names:
        if n in P:
            out.append(P[n])
        else:
            i = 0
            while f"{n}{i}" in P:
                out.append(P[f"{n}{i}"])
                i += 1
    return out


CAST = {
    "aion": {"atlas": "canonical-aion", "height": 44, "idle": [0, 1, 4, 2],
             "pal": sub("pk", "bl", "cy", "cr", "g1", "g2", "g3", "g4", "g6", "g8", "g9", "g10", "g11"),
             "label": "Aion (driver / player)"},
    "omer": {"atlas": "canonical-owl", "height": 54, "idle": [0, 1, 4, 3],
             "pal": sub("br", "o", "cr", "g1", "g2", "g3", "g11", "pk3", "r4"),
             "label": "Baykus Omer (garage mechanic)"},
    "wolf": {"atlas": "canonical-wolf", "height": 54, "idle": [0, 1, 4, 2],
             "pal": sub("mv", "cr", "cy", "pk", "pu", "g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8", "g9", "g11"),
             "label": "Accursed Wise Wolf (rival cameo)"},
    "sheep": {"atlas": "canonical-sheep", "height": 54, "idle": [0, 1, 3, 2],
              "pal": sub("cr", "pk", "br", "o", "g1", "g2", "g8", "g9", "g10", "g11"),
              "label": "Blessed Ignorant Sheep (cameo)"},
}

_prov = None


def prov():
    global _prov
    if _prov is None:
        with open(os.path.join(SRC, "CANONICAL-PROVENANCE.json")) as f:
            _prov = json.load(f)
    return _prov


def downscale(crop, scale):
    """Alpha-weighted box downscale; returns RGBA with hard alpha."""
    w = max(1, round(crop.width * scale))
    h = max(1, round(crop.height * scale))
    pre = crop.convert("RGBa").resize((w, h), Image.BOX).convert("RGBA")
    a = crop.getchannel("A").resize((w, h), Image.BOX)
    out = px.new(w, h)
    pp, ap, op = pre.load(), a.load(), out.load()
    for y in range(h):
        for x in range(w):
            if ap[x, y] >= 140:
                op[x, y] = pp[x, y][:3] + (255,)
    return out


def clean(img, palette):
    out = px.remap(img, lambda c: nearest(c, palette))
    px.clean_orphans(out, 1)
    # dark source outlines become our ink
    out = px.remap(out, lambda c: INK if sum(c[:3]) < 150 else c)
    px.outline(out, INK)
    return out


def frame_images(key, row=0, frames=None, height=None, box=None):
    """Downscaled, registered frames of one atlas row.
    box (fractions of bounds) crops a sub-region (e.g. the head for portraits)."""
    c = CAST[key]
    a = prov()["atlases"][c["atlas"]]
    sheet = Image.open(os.path.join(SRC, c["atlas"] + ".png")).convert("RGBA")
    fr = a["frames"][row]
    idx = frames if frames is not None else list(range(len(fr)))
    b0 = fr[0]["bounds"]
    bh = b0[3] - b0[1]
    scale = (height or c["height"]) / bh
    out = []
    for i in idx:
        f = fr[i]
        x, y, w, h = f["rect"]
        crop = sheet.crop((x, y, x + w, y + h))
        ox, oy = f["origin"]
        # registered placement: origin -> fixed point
        img = downscale(crop, scale)
        out.append((img, ox * scale, oy * scale, f))
    return out, scale, a


def standing(key, fw=72, fh=64):
    c = CAST[key]
    imgs, scale, a = frame_images(key, frames=c["idle"])
    frames = []
    for img, ox, oy, f in imgs:
        canvas = px.new(fw, fh)
        # origin is near the feet; put it at (fw/2, fh-3)
        foot = f["bounds"][3] * scale
        canvas.paste(img, (round(fw / 2 - ox), round(fh - 3 - foot)), img)
        frames.append(clean(canvas, c["pal"]))
    return frames, scale


def portrait(key, frame_ids, size=48):
    c = CAST[key]
    a = prov()["atlases"][c["atlas"]]
    sheet = Image.open(os.path.join(SRC, c["atlas"] + ".png")).convert("RGBA")
    fr = a["frames"][0]
    out = []
    b0 = fr[0]["bounds"]
    head_h = (b0[3] - b0[1]) * 0.8
    scale = (size - 4) / head_h
    for i in frame_ids:
        f = fr[i]
        x, y, w, h = f["rect"]
        ex, ey = f["eye"]
        crop = sheet.crop((x, y, x + w, y + h))
        img = downscale(crop, scale)
        canvas = px.new(size, size)
        # centre the face: eye landmark at (0.62*size, 0.5*size) (eye is the right/front eye)
        canvas.paste(img, (round(size * 0.58 - ex * scale), round(size * 0.5 - ey * scale)), img)
        out.append(clean(canvas, c["pal"]))
    return out, scale


def build():
    srcs = {}
    for key, c in CAST.items():
        path = os.path.join(SRC, c["atlas"] + ".png")
        srcs[key] = {"file": "aion_endless_run/assets/" + c["atlas"] + ".png",
                     "sha256": px.sha256(path), "row": 0, "frames": c["idle"]}
    sb = px.SheetBuilder(72, 64, 4)
    for key in CAST:
        frames, _ = standing(key)
        ids = sb.add(key + "_idle", frames, 4)
        sb.alias(key + "_idle", [ids[0]] * 3 + [ids[1]] * 2 + [ids[0]] * 2 + [ids[2], ids[3], ids[2]], 6)
    sheet, rows = sb.build()
    px.register_sheet("characters", "characters/characters_standing.png", sheet, 72, 64, sb.cols,
                      rows, sb.anims, anchor=(36, 61), script=SCRIPT,
                      cast={k: c["label"] for k, c in CAST.items()},
                      notes="Garage standing sprites, one character per row (aion, omer, wolf, "
                            "sheep), facing right. anchor = feet. Flip horizontally to face left.")
    sb = px.SheetBuilder(48, 48, 3)
    for key in CAST:
        fids = {"aion": [0, 2, 4], "omer": [0, 3, 1], "wolf": [0, 4, 1], "sheep": [0, 3, 1]}[key]
        frames, _ = portrait(key, fids)
        ids = sb.add(key + "_portrait", frames, 4)
        sb.alias(key + "_portrait", [ids[0]] * 8 + [ids[1]], 4)
        sb.alias(key + "_portrait_alt", [ids[2]], 1, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("portraits", "characters/portraits.png", sheet, 48, 48, sb.cols, rows,
                      sb.anims, anchor=(0, 0), script=SCRIPT,
                      notes="48x48 HUD/garage/dialogue portraits, transparent background. "
                            "Row per character (aion, omer, wolf, sheep): col 0 neutral, "
                            "col 1 blink/wink, col 2 alternate expression.")
    for rel in ("characters/characters_standing.png", "characters/portraits.png"):
        px.PROVENANCE["files"]["assets/" + rel].update({
            "method": "derived",
            "derived_from": srcs,
            "source_repo": REPO,
            "source_registration": "aion_endless_run/assets/CANONICAL-PROVENANCE.json "
                                   "(sha256 %s)" % px.sha256(os.path.join(SRC, "CANONICAL-PROVENANCE.json")),
            "process": __doc__.strip(),
            "rights": "Owner's original characters (Aion, Accursed Wise Wolf, Blessed "
                      "Ignorant Sheep, Baykus Omer); used with the owner's permission.",
        })


if __name__ == "__main__":
    build()

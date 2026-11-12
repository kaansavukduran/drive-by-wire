"""Fonts: verifies (and if missing, fetches) the OFL fonts in assets/fonts and records
provenance. Pixel art is not generated here; this only checks Turkish coverage.

  PixelifySans.ttf  - pixel-style UI/body font (variable wght), OFL 1.1
  VT323.ttf         - terminal font for the command box, OFL 1.1
  Lexend.ttf        - fallback (copied from aion_endless_run), OFL 1.1
"""
import hashlib
import os
import urllib.request

import px

SCRIPT = "gen_fonts.py"
TURKISH = "çğıİöşüÇĞÖŞÜ"
GF = "https://raw.githubusercontent.com/google/fonts/main/ofl/"
FONTS = {
    "PixelifySans.ttf": {
        "url": GF + "pixelifysans/PixelifySans%5Bwght%5D.ttf",
        "license": "PIXELIFYSANS-OFL.txt", "license_url": GF + "pixelifysans/OFL.txt",
        "sha256": "9ba86cd010a4de309d263ceff8e8044092c9db7efda869620cb9ff1c4389e8a5",
        "role": "pixel UI font (HUD, dialogue, buttons)",
        "copyright": "Copyright 2021 The Pixelify Sans Project Authors (github.com/eifetx/Pixelify-Sans)"},
    "VT323.ttf": {
        "url": GF + "vt323/VT323-Regular.ttf",
        "license": "VT323-OFL.txt", "license_url": GF + "vt323/OFL.txt",
        "sha256": "cf4de751ada78ceac033dbe16a687742939995b77bc2a052ae17a4957958594d",
        "role": "terminal font (command box)",
        "copyright": "Copyright 2011 The VT323 Project Authors (peter.hull@oikoi.com)"},
    "Lexend.ttf": {
        "url": None, "license": "LEXEND-OFL.txt", "sha256": None,
        "role": "fallback vector font",
        "copyright": "The Lexend Project Authors; copied from aion_endless_run/assets/Lexend.ttf"},
}


def build():
    from fontTools.ttLib import TTFont
    d = os.path.join(px.ASSETS, "fonts")
    os.makedirs(d, exist_ok=True)
    info = {}
    for name, f in FONTS.items():
        path = os.path.join(d, name)
        if not os.path.exists(path) and f["url"]:
            urllib.request.urlretrieve(f["url"], path)
            urllib.request.urlretrieve(f["license_url"], os.path.join(d, f["license"]))
        sha = px.sha256(path)
        if f["sha256"] and sha != f["sha256"]:
            raise SystemExit(f"{name}: sha256 mismatch {sha}")
        cmap = TTFont(path).getBestCmap()
        missing = [c for c in TURKISH if ord(c) not in cmap]
        if missing:
            raise SystemExit(f"{name}: missing Turkish glyphs {missing}")
        assert os.path.exists(os.path.join(d, f["license"])), f["license"]
        px.PROVENANCE["files"]["assets/fonts/" + name] = {
            "method": "third-party font (unmodified)", "source": f["url"] or "aion_endless_run",
            "license": "SIL Open Font License 1.1 (assets/fonts/%s)" % f["license"],
            "copyright": f["copyright"], "turkish_glyphs_verified": TURKISH,
            "glyph_count": len(cmap), "verified_by": "tools/art/" + SCRIPT}
        info[name.split(".")[0]] = {"path": "assets/fonts/" + name, "role": f["role"],
                                    "license": "assets/fonts/" + f["license"]}
    px.MANIFEST["extra"] = {"fonts": info}


if __name__ == "__main__":
    build()

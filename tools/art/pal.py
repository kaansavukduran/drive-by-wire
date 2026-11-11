"""Drive-By Wire master palette. Defined ONCE here; every generator imports it.

64 colours arranged as ramps (dark -> light). Every opaque pixel written to
assets/ must be one of these colours (build.py audits this).
"""

def _h(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


RAMPS = {
    # cool purple-greys: outlines, asphalt, metal, smoke
    "g": ["#0e0b16", "#1b1626", "#262132", "#322c41", "#403952", "#514864",
          "#665c7a", "#807693", "#9d94ae", "#bdb5cb", "#ddd7e6", "#f6f2fa"],
    # rust / brown / tan: wrecks, wood, pickup body, garage warmth
    "br": ["#2e1a1a", "#4a2a24", "#6e3c2c", "#9a5434", "#c4743f", "#e09a5c", "#f4c48c"],
    # reds: tail lights, rammer, danger
    "r": ["#3a0f1e", "#6a1a2c", "#a8203a", "#e83b4a", "#ff7a6a"],
    # fire / lamp: orange -> pale yellow
    "o": ["#b3401f", "#f06a1e", "#ff9b2e", "#ffd04a", "#fff3a8"],
    # toxic green
    "gr": ["#12261c", "#1d4a2c", "#2f7d3a", "#5cc046", "#b4f25a"],
    # neon cyan (MOMO's colour)
    "cy": ["#0b2a36", "#134e60", "#1f8aa0", "#35c8e0", "#9af6ff"],
    # mint (MOMO's car body)
    "mn": ["#163a3a", "#22645c", "#34a08a", "#5ed6b0", "#b6f7dc"],
    # blue (glass, Aion's gill tips, night)
    "bl": ["#141a3e", "#23307a", "#3a5cc8", "#6a9cf0", "#b0d4ff"],
    # magenta / purple neon
    "pu": ["#2a1238", "#4e1f62", "#8a3196", "#d052c8", "#ff9ef0"],
    # pink (Aion's skin)
    "pk": ["#6e2a4a", "#b2507a", "#e47e9e", "#f8aec2", "#ffdbe4"],
    # mauve fur (Wolf)
    "mv": ["#3c2c48", "#5c4668", "#826a8e"],
    # cream (sheep wool, wolf chest, owl belly)
    "cr": ["#e9c4a6", "#f8e2cc"],
}

P = {}
for _name, _hexes in RAMPS.items():
    for _i, _hx in enumerate(_hexes):
        P[f"{_name}{_i}"] = _h(_hx)

INK = P["g0"]          # universal 1-px outline colour
INK2 = P["g1"]
WHITE = P["g11"]
CLEAR = (0, 0, 0, 0)

ALL = list(dict.fromkeys(P.values()))  # ordered, unique
ALL_RGB = {c[:3] for c in ALL}
assert len(ALL) == 64, len(ALL)


def ramp(name):
    return [P[f"{name}{i}"] for i in range(len(RAMPS[name]))]


def ramp_of(c):
    """(ramp name, index) for a palette colour, or None."""
    for name, hexes in RAMPS.items():
        for i, hx in enumerate(hexes):
            if _h(hx)[:3] == c[:3]:
                return name, i
    return None


def shift(c, d):
    """Move a palette colour d steps along its own ramp (clamped)."""
    if c[3] == 0:
        return c
    ri = ramp_of(c)
    if ri is None:
        return c
    name, i = ri
    j = max(0, min(len(RAMPS[name]) - 1, i + d))
    return P[f"{name}{j}"]


# Warm light: what a colour becomes when lit by the garage lamp.
def _warm_table():
    t = {}
    for c in ALL:
        name, i = ramp_of(c)
        if name == "g":
            # grey picks up warmth: grey -> brown/tan
            m = {0: "br0", 1: "br1", 2: "br1", 3: "br2", 4: "br2", 5: "br3", 6: "br3",
                 7: "br4", 8: "br5", 9: "br6", 10: "cr1", 11: "o4"}
            t[c[:3]] = P[m[i]]
        else:
            t[c[:3]] = shift(c, 1)
    return t


WARM = _warm_table()


def warm(c):
    if c[3] == 0:
        return c
    return WARM.get(c[:3], c)


def darken(c, d=1):
    return shift(c, -d)


def nearest(rgb, subset=None):
    """Nearest palette colour (weighted RGB distance) - used when palette-cleaning
    derived art."""
    best, bd = None, 1e18
    r, g, b = rgb[:3]
    for c in (subset or ALL):
        dr, dg, db = r - c[0], g - c[1], b - c[2]
        rm = (r + c[0]) / 2
        d = (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db
        if d < bd:
            bd, best = d, c
    return best

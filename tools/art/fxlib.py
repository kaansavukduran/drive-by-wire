"""Procedural effect frames: fireballs, smoke, sparks. Deterministic (seeded hashes)."""
import math

import px
from pal import P

FIRE = [P["r1"], P["o0"], P["o1"], P["o2"], P["o3"], P["o4"], P["g11"]]
SMOKE_DARK = [P["g1"], P["g2"], P["g3"], P["g4"]]
SMOKE_LIGHT = [P["g4"], P["g5"], P["g6"], P["g7"], P["g8"]]


def _blobs(seed, n, spread):
    out = []
    for i in range(n):
        a = px.hash01(seed, i, "a") * math.tau
        d = px.hash01(seed, i, "d") ** 0.7 * spread
        r = 0.55 + 0.6 * px.hash01(seed, i, "r")
        out.append((math.cos(a) * d, math.sin(a) * d, r))
    return out


def fireball(size, t, n_frames, seed=1, max_r=None, cx=None, cy=None, smoke_dark=True):
    """One explosion frame. t in [0, n_frames). Returns RGBA size x size."""
    img = px.new(size, size)
    cx = size / 2 if cx is None else cx
    cy = size / 2 if cy is None else cy
    max_r = max_r or size * 0.42
    u = t / max(1, n_frames - 1)              # 0..1
    grow = min(1.0, 0.25 + 1.6 * u) if u < 0.5 else 1.0
    R = max_r * grow
    blobs = _blobs(seed, 9, 0.55)
    heat_scale = max(0.0, 1.25 - 1.5 * u)       # fire cools over time
    smoke = u > 0.35
    dissolve = max(0.0, (u - 0.55) / 0.45)      # 0..1 in last part
    rise = u * u * max_r * 0.35                 # smoke drifts up
    for y in range(size):
        for x in range(size):
            best = 0.0
            for bx, by, br in blobs:
                bxx = cx + bx * R
                byy = cy + by * R - (rise if smoke else 0)
                rr = br * R * (1.0 + 0.25 * u)
                d = math.hypot(x + 0.5 - bxx, y + 0.5 - byy) / max(rr, 0.01)
                v = 1.0 - d
                if v > best:
                    best = v
            if best <= 0:
                continue
            nz = px.hash01(seed, x, y, "n")
            if dissolve > 0 and nz < dissolve * 1.15 - best * 0.6:
                continue
            heat = best * heat_scale + (nz - 0.5) * 0.12
            if not smoke or heat > 0.35:
                if heat > 0.80:
                    c = FIRE[6]
                elif heat > 0.62:
                    c = FIRE[5]
                elif heat > 0.46:
                    c = FIRE[4]
                elif heat > 0.32:
                    c = FIRE[3]
                elif heat > 0.18:
                    c = FIRE[2]
                elif heat > 0.07:
                    c = FIRE[1]
                else:
                    c = FIRE[0]
            else:
                ramp = SMOKE_DARK if smoke_dark else SMOKE_LIGHT
                # lighter towards upper-left of each puff (fake light)
                k = best + (0.15 if (x - cx) + (y - cy) < 0 else -0.05)
                idx = 0 if k < 0.2 else 1 if k < 0.42 else 2 if k < 0.65 else 3
                c = ramp[min(idx, len(ramp) - 1)]
            px.put(img, x, y, c)
    # debris chunks
    if 0.1 < u < 0.9:
        for i in range(7):
            a = px.hash01(seed, i, "deb") * math.tau
            dist = (0.3 + 0.9 * u) * max_r * (0.8 + 0.5 * px.hash01(seed, i, "v"))
            dx, dy = cx + math.cos(a) * dist, cy + math.sin(a) * dist
            col = P["g1"] if i % 2 else P["g2"]
            px.rect(img, int(dx), int(dy), int(dx) + 1, int(dy) + (1 if i % 3 else 0), col)
            if u < 0.5:
                px.put(img, int(dx), int(dy), P["o2"])
    return img


def explosion_frames(size, n, seed=1, max_r=None, smoke_dark=True):
    return [fireball(size, t, n, seed, max_r, smoke_dark=smoke_dark) for t in range(n)]


def smoke_puff(size, t, n, seed=3, dark=False):
    img = px.new(size, size)
    u = t / max(1, n - 1)
    ramp = SMOKE_DARK if dark else SMOKE_LIGHT
    blobs = _blobs(seed, 4, 0.5)
    R = size * (0.18 + 0.22 * u)
    cx, cy = size / 2, size / 2 + size * 0.1 - u * size * 0.15
    for y in range(size):
        for x in range(size):
            best = 0
            for bx, by, br in blobs:
                d = math.hypot(x + 0.5 - (cx + bx * R), y + 0.5 - (cy + by * R)) / (br * R)
                best = max(best, 1 - d)
            if best <= 0:
                continue
            nz = px.hash01(seed, x, y)
            if u > 0.45 and nz < (u - 0.45) * 1.9 - best * 0.4:
                continue
            k = best + (0.2 if (x - cx) + (y - cy) < 0 else 0)
            idx = 0 if k < 0.25 else 1 if k < 0.5 else 2 if k < 0.75 else 3
            px.put(img, x, y, ramp[min(idx + (1 if not dark else 0), len(ramp) - 1)])
    return img


def sparks(size, t, n, seed=5, cols=None):
    img = px.new(size, size)
    cols = cols or [P["g11"], P["o4"], P["o3"], P["o2"]]
    u = t / max(1, n - 1)
    c = size / 2
    for i in range(7):
        a = px.hash01(seed, i) * math.tau
        sp = 0.6 + 0.6 * px.hash01(seed, i, "s")
        d0 = (u * 0.75) * c * sp + 1
        ln = max(1, int((1 - u) * 4 * sp))
        col = cols[min(len(cols) - 1, int(u * len(cols)))]
        for k in range(ln):
            d = d0 + k
            px.put(img, int(c + math.cos(a) * d), int(c + math.sin(a) * d), col)
    if t == 0:
        px.rect(img, int(c) - 1, int(c) - 1, int(c), int(c), cols[0])
        for dx, dy in ((-2, 0), (1, 0), (0, -2), (0, 1)):
            px.put(img, int(c) + dx - (1 if dx > 0 else 0) + (1 if dx > 0 else 0), int(c) + dy, cols[1])
    return img

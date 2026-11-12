"""Projectiles, mine, dropped obstacles, pickups, explosions, smoke, sparks, streaks."""
import math

import fxlib
import px
import sdf
from pal import P, INK

SCRIPT = "gen_fx.py"


def fr(w, h):
    return px.new(w, h)


# ---------------------------------------------------------------- projectiles
def player_bullet(f):
    im = fr(16, 16)
    # cyan plasma bolt travelling up: bright head, tapering tail
    tail = 5 + f
    for k in range(tail):
        c = P["cy4"] if k < 2 else P["cy3"] if k < 4 else P["cy2"]
        px.put(im, 7, 5 + k, c)
        if k < 4:
            px.put(im, 8, 5 + k, c)
    px.rect(im, 7, 3, 8, 5, P["g11"])
    px.put(im, 6, 4, P["cy3"])
    px.put(im, 9, 4, P["cy3"])
    if f == 1:
        px.put(im, 7, 2, P["cy4"])
        px.put(im, 8, 2, P["cy4"])
    return im


def enemy_bullet(f):
    im = fr(16, 16)
    r = 3.0 if f == 0 else 2.6
    px.ellipse(im, 8, 8, r + 0.8, r + 0.8, P["r2"])
    px.ellipse(im, 8, 8, r, r, P["o2"] if f == 0 else P["r3"])
    px.ellipse(im, 8, 8, r - 1.2, r - 1.2, P["o4"])
    px.put(im, 7, 7, P["g11"])
    px.outline(im, INK)
    return im


def build_projectiles():
    sb = px.SheetBuilder(16, 16, 4)
    sb.add("player_bullet", [player_bullet(f) for f in range(2)], 16)
    sb.add("enemy_bullet", [enemy_bullet(f) for f in range(2)], 10)
    sheet, rows = sb.build()
    px.register_sheet("projectiles", "sprites/projectiles.png", sheet, 16, 16, sb.cols, rows,
                      sb.anims, anchor=(8, 8), script=SCRIPT,
                      collision={"x": 6, "y": 3, "w": 4, "h": 8},
                      collision_enemy_bullet={"x": 5, "y": 5, "w": 6, "h": 6},
                      notes="player_bullet points up (rotate node for other directions); "
                            "enemy_bullet is round.")
    return sheet


# ---------------------------------------------------------------- mine
def mine(state, blink):
    im = fr(16, 16)
    body = sdf.circle(8, 8, 5.2)

    def col(x, y):
        l = sdf.lit(body, x, y)
        if (x - 8) ** 2 + (y - 8) ** 2 < 2.2 ** 2:
            if state == 0:
                return P["g3"]
            return P["r4"] if blink else P["r1"]
        return P["g7"] if l > 0.4 else P["g3"] if l < -0.3 else P["g5"]
    m = px.render(16, 16, [(sdf.inside(body), col)], 0, 0)
    # four prongs
    for dx, dy in ((0, -7), (0, 6), (-7, 0), (6, 0)):
        px.rect(m, 8 + dx, 8 + dy, 8 + dx + (1 if dx == 0 else 0), 8 + dy + (1 if dy == 0 else 0),
                P["o3"] if state else P["g6"])
    px.outline(m, INK)
    if state and blink:
        px.put(m, 7, 7, P["g11"])
    if state == 1:   # arming: rotating tick
        px.put(m, 8 + (1 if blink else -1), 4, P["o4"])
    return m


def build_mine():
    sb = px.SheetBuilder(16, 16, 4)
    sb.add("idle", [mine(0, False)], 1)
    sb.add("arming", [mine(1, False), mine(1, True)], 6)
    sb.add("armed", [mine(2, True), mine(2, False)], 4)
    sheet, rows = sb.build()
    px.register_sheet("mine", "sprites/mine.png", sheet, 16, 16, sb.cols, rows, sb.anims,
                      anchor=(8, 8), script=SCRIPT, collision={"x": 3, "y": 3, "w": 10, "h": 10},
                      notes="Player's rear mine. On trigger spawn explosion_small.")
    return sheet


# ---------------------------------------------------------------- obstacles (24x24)
def crate(t=-1):
    """t=-1 intact; 0..4 breaking."""
    im = fr(24, 24)
    if t < 0:
        px.rect(im, 4, 5, 19, 20, P["br4"])
        px.rect(im, 4, 5, 19, 6, P["br5"])
        px.rect(im, 18, 5, 19, 20, P["br3"])
        px.rect(im, 4, 19, 19, 20, P["br3"])
        for y in (9, 13, 17):
            px.rect(im, 5, y, 17, y, P["br3"])
        px.frame_rect(im, 5, 6, 18, 19, P["br2"])
        px.line(im, 6, 7, 17, 18, P["br2"])
        px.put(im, 6, 7, P["g8"]); px.put(im, 17, 7, P["g8"])
        px.put(im, 6, 18, P["g8"]); px.put(im, 17, 18, P["g8"])
        px.outline(im, INK)
        return im
    # planks flying outward
    for i in range(6):
        a = i / 6 * math.tau + 0.4
        d = 2 + t * 2.4
        cx, cy = 12 + math.cos(a) * d, 12 + math.sin(a) * d
        horiz = i % 2 == 0
        L = max(1, 4 - t // 2)
        if horiz:
            px.rect(im, cx - L, cy, cx + L, cy + 1, P["br4"])
            px.rect(im, cx - L, cy + 1, cx + L, cy + 1, P["br2"])
        else:
            px.rect(im, cx, cy - L, cx + 1, cy + L, P["br4"])
            px.rect(im, cx + 1, cy - L, cx + 1, cy + L, P["br2"])
    if t < 2:
        px.blit(im, fxlib.sparks(24, t + 1, 5, seed=7, cols=[P['br6'], P['br5'], P['br4'], P['br3']]), 0, 0)
    if t < 4:
        px.outline(im, INK)
    else:
        im = px.remap(im, lambda c: P["br2"] if c != INK else c)
    return im


def barrel(t=-1, drip=0):
    im = fr(24, 24)
    if t < 0:
        body = sdf.circle(12, 12, 7.2)

        def col(x, y):
            d = math.hypot(x - 12, y - 12)
            l = sdf.lit(body, x, y)
            if d < 2.0:
                return P["g1"]                         # bung hole
            if abs(d - 4.6) < 0.6:
                return P["gr1"]                        # rim ring
            return P["gr4"] if l > 0.45 and d > 5 else P["gr2"] if l < -0.3 else P["gr3"]
        im = px.render(24, 24, [(sdf.inside(body), col)], 0, 0)
        # hazard trefoil-ish mark
        for a in (0, 2.09, 4.19):
            px.put(im, int(12 + math.cos(a - 1.57) * 3.2), int(12 + math.sin(a - 1.57) * 3.2), P["o3"])
        px.outline(im, INK)
        # toxic drip puddle growing/shrinking
        px.ellipse(im, 18.5, 20.5, 2 + drip, 1.2 + drip * 0.4, P["gr3"])
        px.put(im, 18, 20, P["gr4"])
        return im
    # burst: green splash + metal shards
    r = 3 + t * 2.2
    for y in range(24):
        for x in range(24):
            d = math.hypot(x + 0.5 - 12, (y + 0.5 - 12) * 1.15)
            if d < r and px.hash01("spl", x, y, t) > t * 0.18:
                c = P["gr4"] if d < r * 0.4 else P["gr3"] if d < r * 0.8 else P["gr2"]
                if t >= 3 and px.dith(x, y, 0.5):
                    continue
                px.put(im, x, y, c)
    for i in range(5):
        a = i * 1.25 + 0.3
        d = 3 + t * 3
        px.rect(im, 12 + math.cos(a) * d, 12 + math.sin(a) * d,
                12 + math.cos(a) * d + 1, 12 + math.sin(a) * d, P["gr1"])
    if t < 2:
        px.outline(im, INK)
    return im


def spikes(t=-1, glint=0):
    """Tyre-spike strip lying across a lane."""
    im = fr(24, 24)
    k = 1 if t < 0 else 0
    if t < 0:
        px.rect(im, 1, 12, 22, 14, P["g3"])
        px.rect(im, 1, 12, 22, 12, P["g5"])
        for i, x in enumerate(range(2, 22, 4)):
            px.put(im, x, 9, P["g10"])
            px.rect(im, x, 10, x + 1, 11, P["g8"])
            px.put(im, x + 1, 9, P["g7"])
            px.put(im, x + 1, 15, P["g7"])
            px.rect(im, x, 15, x + 1, 16, P["g6"])
            if i == glint:
                px.put(im, x, 8, P["g11"])
                px.put(im, x - 1, 9, P["g11"])
        px.outline(im, INK)
        return im
    # break: strip snaps, pieces scatter
    for i in range(5):
        dx = (i - 2) * (2 + t * 1.6)
        dy = (t * 1.5) * (1 if i % 2 else -1)
        x = 10 + dx
        px.rect(im, x, 12 + dy, x + 3, 13 + dy, P["g5"] if t < 3 else P["g3"])
        px.put(im, x + 1, 11 + dy, P["g9"])
    if t == 0:
        px.blit(im, fxlib.sparks(24, 0, 4, seed=3), 0, 0)
    px.outline(im, INK)
    return im


def build_obstacles():
    sb = px.SheetBuilder(24, 24, 6)
    sb.add("crate_idle", [crate()], 1)
    sb.add("crate_break", [crate(t) for t in range(5)], 14, loop=False)
    sb.add("barrel_idle", [barrel(drip=0), barrel(drip=1)], 3)
    sb.add("barrel_break", [barrel(t) for t in range(5)], 14, loop=False)
    sb.add("spikes_idle", [spikes(glint=0), spikes(glint=3)], 3)
    sb.add("spikes_break", [spikes(t) for t in range(4)], 14, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("obstacles", "sprites/obstacles.png", sheet, 24, 24, sb.cols, rows,
                      sb.anims, anchor=(12, 12), script=SCRIPT,
                      collision={"x": 4, "y": 4, "w": 16, "h": 16},
                      collision_spikes={"x": 1, "y": 9, "w": 22, "h": 8},
                      notes="Dropped by the truck. ~16x16 objects centred in 24x24 frames. "
                            "Barrel is a toxic drum seen from above.")
    return sheet


# ---------------------------------------------------------------- pickups
def energy(f):
    im = fr(16, 16)
    bob = [0, -1, -1, 0][f]
    # battery cell with lightning bolt
    px.rect(im, 4, 3 + bob, 11, 13 + bob, P["cy2"])
    px.rect(im, 4, 3 + bob, 5, 13 + bob, P["cy3"])
    px.rect(im, 10, 3 + bob, 11, 13 + bob, P["cy1"])
    px.rect(im, 6, 1 + bob, 9, 2 + bob, P["g7"])
    bolt = [(8, 4), (7, 5), (7, 6), (6, 7), (7, 7), (8, 7), (9, 7), (8, 8), (8, 9), (7, 10), (7, 11)]
    for x, y in bolt:
        px.put(im, x, y + bob, P["o4"] if f != 2 else P["g11"])
    px.outline(im, INK)
    if f == 2:
        px.put(im, 13, 2, P["cy4"]); px.put(im, 2, 12, P["cy4"])
    if f == 3:
        px.put(im, 14, 5, P["cy3"]); px.put(im, 1, 9, P["cy3"])
    return im


def parts(f):
    im = fr(16, 16)
    ang = f * math.pi / 8   # gear turns 1/4 tooth per frame
    gear = lambda x, y: (math.hypot(x - 8, y - 8) < 5.3 + (1.3 if math.cos(6 * (math.atan2(y - 8, x - 8) - ang)) > 0.2 else 0))

    def col(x, y):
        d = math.hypot(x - 8, y - 8)
        if d < 1.8:
            return None
        if d < 3.0:
            return P["g5"]
        return P["o3"] if (x - 8) + (y - 8) < -2 else P["o2"] if d < 5.5 else P["o1"]
    im = px.render(16, 16, [(gear, col)], 0, 0)
    px.outline(im, INK)
    if f == 0:
        px.put(im, 4, 4, P["g11"])
    return im


def build_pickups():
    sb = px.SheetBuilder(16, 16, 4)
    sb.add("energy", [energy(f) for f in range(4)], 8)
    sb.add("parts", [parts(f) for f in range(4)], 8)
    sheet, rows = sb.build()
    px.register_sheet("pickups", "sprites/pickups.png", sheet, 16, 16, sb.cols, rows, sb.anims,
                      anchor=(8, 8), script=SCRIPT, collision={"x": 2, "y": 2, "w": 12, "h": 12},
                      notes="energy = cyan battery (MOMO food), parts = brass gear (repairs).")
    return sheet


# ---------------------------------------------------------------- effects
def near_miss(f):
    im = fr(16, 48)
    L = [18, 40, 34, 22][f]
    y0 = [20, 4, 6, 18][f]
    for k in range(L):
        u = k / max(1, L - 1)
        if f == 3 and px.dith(7, y0 + k, 0.5):
            continue
        c = P["g11"] if u < 0.2 else P["cy4"] if u < 0.6 else P["cy3"]
        px.put(im, 7, y0 + k, c)
        if u < 0.5 and f in (1, 2):
            px.put(im, 8, y0 + k, P["cy3"])
    return im


def speed_line(f):
    im = fr(8, 64)
    L = [24, 48, 56, 40][f]
    y0 = [40, 12, 0, 0][f]
    for k in range(L):
        if f == 3 and k % 2:
            continue
        px.put(im, 3, y0 + k, P["g9"] if k < L // 3 else P["g7"])
    return im


def build_fx():
    sb = px.SheetBuilder(64, 64, 10)
    sb.add("explode", fxlib.explosion_frames(64, 10, seed=77), 14, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("explosion", "fx/explosion.png", sheet, 64, 64, sb.cols, rows, sb.anims,
                      anchor=(32, 32), script=SCRIPT)
    sb = px.SheetBuilder(32, 32, 8)
    sb.add("explode", fxlib.explosion_frames(32, 8, seed=88), 16, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("explosion_small", "fx/explosion_small.png", sheet, 32, 32, sb.cols, rows,
                      sb.anims, anchor=(16, 16), script=SCRIPT)
    sb = px.SheetBuilder(16, 16, 6)
    sb.add("puff", [fxlib.smoke_puff(16, t, 6, seed=5) for t in range(6)], 12, loop=False)
    sb.add("puff_dark", [fxlib.smoke_puff(16, t, 6, seed=6, dark=True) for t in range(6)], 12,
           loop=False)
    sb.add("sparks", [fxlib.sparks(16, t, 5, seed=9) for t in range(5)], 20, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("smoke_sparks", "fx/smoke_sparks.png", sheet, 16, 16, sb.cols, rows,
                      sb.anims, anchor=(8, 8), script=SCRIPT)
    sb = px.SheetBuilder(16, 48, 4)
    sb.add("streak", [near_miss(f) for f in range(4)], 16, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("near_miss", "fx/near_miss.png", sheet, 16, 48, sb.cols, rows, sb.anims,
                      anchor=(8, 24), script=SCRIPT,
                      notes="Place beside the player on the side the enemy passed.")
    sb = px.SheetBuilder(8, 64, 4)
    sb.add("line", [speed_line(f) for f in range(4)], 20, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("speed_lines", "fx/speed_lines.png", sheet, 8, 64, sb.cols, rows,
                      sb.anims, anchor=(4, 0), script=SCRIPT,
                      notes="Spawn several at random x along the screen edges while boosting; "
                            "move them down fast.")


def build():
    sheets = [build_projectiles(), build_mine(), build_obstacles(), build_pickups()]
    build_fx()
    return sheets


if __name__ == "__main__":
    build()

"""MOMO's car (player): top-down, facing up. Frame grid 48x80, car centred at (24,40)."""
import math

import fxlib
import px
from pal import P, INK

SCRIPT = "gen_player.py"
FW, FH = 48, 80
CX, CY = 24, 40


import sdf

NOSE, TAIL = -28.0, 28.0
_core = sdf.rbox(0, 0, 11.6, 28, 7.0)
_ff = sdf.mirror_x(sdf.ellipse(8.8, -16, 4.8, 8.2))
_rf = sdf.mirror_x(sdf.ellipse(9.0, 15.5, 5.4, 9.0))
BODY = sdf.smooth_union(2.0, _core, _ff, _rf)
WHEELS = sdf.mirror_x(sdf.union(sdf.rbox(13.4, -16, 2.6, 5.6, 1.2),
                                 sdf.rbox(13.9, 15.5, 2.8, 6.0, 1.2)))
CANOPY = sdf.ellipse(0, -1.0, 8.0, 9.6)
CANOPY_RIM = sdf.ellipse(0, -1.0, 9.2, 10.8)
SPOILER = sdf.rbox(0, 21.6, 12.4, 1.4, 0.6)
MN = [P["mn0"], P["mn1"], P["mn2"], P["mn3"], P["mn4"]]
_body_shade = sdf.shader(BODY, MN, 2, rim=2.4, hi=0.3, lo=-0.3)


def in_body(x, y):
    return BODY(x, y) < 0


def body_col(x, y):
    d = BODY(x, y)
    if y < NOSE + 1.8:
        return P["g9"] if x < 0 else P["g7"]           # chrome nose bumper
    if y > TAIL - 1.5:
        return P["g6"] if x < 0 else P["g5"]           # rear bumper
    if d > -1.6 and sdf.lit(BODY, x, y) > 0.75 and abs(y) > 8:
        return P["mn4"]                                # specular on fender tops
    if abs(x) < 1.6 and -19.5 > y > -27:
        return P["cr1"] if x < 0 else P["cr0"]         # cream racing stripe
    if abs(x) < 1.6 and -12.0 > y > -19.5:
        return P["cr1"] if x < 0 else P["cr0"]
    return _body_shade(x, y)


def wheel_col(phase):
    def f(x, y):
        tread = int(math.floor(y + phase)) % 3 == 0
        if abs(x) > 15.0:
            return P["g4"] if tread else P["g6"]
        return P["g3"] if tread else P["g5"]
    return f


def canopy_col(x, y):
    d = (x / 8.0) ** 2 + ((y + 1.0) / 9.6) ** 2
    if 3.0 < x - 0.6 * (y - 4.0) < 4.4 and y > 1.0 and d < 0.8:
        return P["bl3"]                                # reflection streak (lower right)
    if d > 0.7:
        return P["bl0"] if x + 0.5 * y > -1 else P["bl1"]
    return P["bl1"] if x + y * 0.35 < 2.5 else P["bl0"]


def canopy_rim_col(x, y):
    l = sdf.lit(CANOPY_RIM, x, y)
    return P["g10"] if l > 0.4 else P["g6"] if l < -0.3 else P["g8"]


def vents(x, y):
    return abs(x) < 5.5 and 10.5 < y < 18 and int(math.floor(y)) % 2 == 1


def headlight(x, y):
    return math.hypot(abs(x) - 7.2, y + 23.4) < 2.1


def headlight_col(x, y):
    return P["g11"] if (abs(x) - 7.2) + (y + 23.4) < -1.2 else \
        P["o4"] if (abs(x) - 7.2) + (y + 23.4) < 0.9 else P["o3"]


def eye_ring(x, y):
    return math.hypot(x, y + 21.0) < 3.3


def eye_iris(x, y):
    return math.hypot(x, y + 21.0) < 2.2


def taillight(x, y):
    return 5.5 < abs(x) < 10.5 and 25.0 < y < 26.8


def mirror(x, y):
    return ((abs(x) - 11.4) / 1.9) ** 2 + ((y + 8.2) / 1.1) ** 2 < 1


def spoiler_col(x, y):
    if abs(x) > 11.0:
        return P["mn1"]
    return P["cr1"] if y < 21.4 else P["cr0"]


def _aion_stamp():
    """Aion seen through the canopy: pink round head, dot eyes, three gill fronds
    per side with light-blue tips, white lab-coat shoulders. 15x11 px."""
    m = {}
    for j in range(11):
        for i in range(15):
            d = math.hypot(i + 0.5 - 7.5, j + 0.5 - 5.0)
            if d < 4.6:
                c = P["pk3"]
                if d > 3.7:
                    c = P["pk2"]
                if (i - 7.5) + (j - 5) < -4.0 and d < 3.8:
                    c = P["pk4"]
                m[(i, j)] = c
    for side in (0, 1):
        def mx(i):
            return i if side == 0 else 14 - i
        for pts in (((3, 2), (2, 1), (1, 0)), ((2, 5), (1, 5), (0, 4)), ((3, 7), (2, 8), (1, 9))):
            for k, (i, j) in enumerate(pts):
                m[(mx(i), j)] = P["bl4"] if k == len(pts) - 1 else P["pk2"]
        m[(mx(5), 5)] = P["g0"]              # eyes
        m[(mx(6), 7)] = P["pk1"]             # blush
    m[(7, 7)] = P["pk0"]                     # mouth
    for i in range(4, 11):
        m[(i, 10)] = P["g10"] if i in (5, 9) else P["g9"]
    m[(7, 10)] = P["cy3"]                    # badge
    return m


AION = _aion_stamp()


def car_shapes(phase=0, brake=False, eye="normal", damaged=0):
    s = [
        (sdf.inside(WHEELS), wheel_col(phase)),
        (mirror, lambda x, y: P["mn1"] if x > 0 else P["mn3"]),
        (in_body, body_col),
        (vents, P["mn1"]),
        (sdf.inside(SPOILER), spoiler_col),
        (sdf.inside(CANOPY_RIM), canopy_rim_col),
        (sdf.inside(CANOPY), canopy_col),
        (headlight, headlight_col),
        (eye_ring, P["g1"]),
        (eye_iris, (lambda x, y: P["g11"] if (-1.2 < x < 0 and -22.2 < y < -21.0) else P["cy4"] if (x + y + 21.0 < -0.6) else P["cy3"])
         if eye == "normal" else (lambda x, y: P["r3"]) if eye == "red" else
         (lambda x, y: P["cy2"] if abs(y + 21.0) < 0.6 else P["g1"])),
        (taillight, (lambda x, y: P["r4"] if abs(x) < 8 else P["r3"]) if brake
         else (lambda x, y: P["r2"] if abs(x) < 8 else P["r1"])),
    ]
    if damaged:
        def dent(x, y):
            for (dx, dy, r) in ((7, -17, 2.2), (-9, 14, 2.0), (5, 19, 1.5), (-4, -25.0, 1.4)):
                if (x - dx) ** 2 + (y - dy) ** 2 < r * r and in_body(x, y):
                    return True
            return False
        s.append((dent, lambda x, y: P["g2"] if (int(x * 3 + y * 7) % 3) else P["g3"]))
        if damaged > 1:
            def scorch(x, y):
                return in_body(x, y) and CANOPY_RIM(x, y) > 0 and \
                    px.hash01("scorch", int(x * 2), int(y * 2)) < 0.22
            s.append((scorch, P["g1"]))
            s.append((lambda x, y: CANOPY(x, y) < 0 and abs(x - 2 - 0.5 * (y + 1)) < 0.5,
                      P["g10"]))   # cracked glass
    return s


def aion_shape():
    """Aion's head+gills as a local-space shape so it rotates with the car."""
    def inside(x, y):
        return (int(math.floor(x + 7.5)), int(math.floor(y + 9.0))) in AION

    def col(x, y):
        return AION[(int(math.floor(x + 7.5)), int(math.floor(y + 9.0)))]
    return inside, col


def draw_car(phase=0, angle=0.0, dx=0, dy=0, brake=False, eye="normal", damaged=0):
    shapes = car_shapes(phase, brake, eye, damaged)
    # Aion sits inside the canopy (insert before the cracked-glass overlays)
    k = 7
    shapes.insert(k, aion_shape())
    img = px.render(FW, FH, shapes, CX + dx, CY + dy, angle)
    px.outline(img, INK)
    return img


def drop_shadow(img, dx=2, dy=2, c=None):
    """Opaque drop shadow (down-right, light from upper-left) under the sprite."""
    sh = px.silhouette(px.shifted(img, dx, dy), c or P["g1"])
    px.under(img, sh, 0, 0)
    return img


def exhaust(img, frame, dy=0, heat=True):
    """Twin exhaust tips + heat shimmer under the tail."""
    for sx in (-5, 4):
        x = CX + sx
        y = CY + 28 + dy
        px.rect(img, x, y, x + 1, y, P["g4"])
        px.put(img, x, y + 1, INK)
        px.put(img, x + 1, y + 1, INK)
        if heat:
            # shimmer: 2 pixels drifting downwards over 4 frames
            k = frame % 4
            px.put(img, x + (k % 2), y + 2 + k, P["g7"] if k < 2 else P["g6"])
            if k in (1, 2):
                px.put(img, x + 1 - (k % 2), y + 4 + k, P["g6"])


def flame(img, frame, length, dy=0):
    """Cyan plasma boost flames from both exhausts."""
    wob = [0, 2, -1, 1][frame % 4]
    for i, sx in enumerate((-5, 4)):
        x0 = CX + sx
        y0 = CY + 29 + dy
        L = length + (wob if i == 0 else -wob)
        for k in range(L):
            u = k / max(1, L - 1)
            w = 1 if u > 0.55 else 2
            for j in range(-1, w + 1):
                xx = x0 + j
                edge = j in (-1, w)
                if edge:
                    if u < 0.75:
                        px.put(img, xx, y0 + k, P["cy2"])
                    continue
                c = P["g11"] if u < 0.25 else P["cy4"] if u < 0.55 else P["cy3"]
                px.put(img, xx, y0 + k, c)
        # spark tail
        px.put(img, x0 + (frame % 2), y0 + L + 1, P["cy3"])
        if frame % 2 == 0:
            px.put(img, x0 + 1 - (frame // 2) % 2, y0 + L + 3, P["cy2"])


def muzzle(img, size, dy=0):
    """Muzzle flashes at the twin nose guns."""
    for sx in (-6, 5):
        x = CX + sx
        y = CY - 30 + dy
        if size >= 3:
            px.rect(img, x, y - 4, x + 1, y, P["o4"])
            px.rect(img, x - 1, y - 2, x + 2, y - 1, P["o3"])
            px.put(img, x, y - 6, P["o3"])
            px.put(img, x + 1, y - 5, P["g11"])
            px.put(img, x - 2, y - 1, P["o2"])
            px.put(img, x + 3, y - 1, P["o2"])
            px.rect(img, x, y - 3, x + 1, y - 2, P["g11"])
        elif size == 2:
            px.rect(img, x, y - 2, x + 1, y, P["o3"])
            px.put(img, x, y - 1, P["g11"])
            px.put(img, x + 1, y - 3, P["o2"])
        elif size == 1:
            px.put(img, x, y, P["o2"])
            px.put(img, x + 1, y - 1, P["o2"])


def guns(img, dy=0):
    for sx in (-6, 5):
        x = CX + sx
        y = CY - 29 + dy
        px.rect(img, x, y, x + 1, y + 1, P["g5"])
        px.put(img, x, y - 1, INK)
        px.put(img, x + 1, y - 1, INK)


def base_frame(frame=0, angle=0.0, dy=0, brake=False, eye="normal", damaged=0, heat=True,
               shadow=True):
    img = draw_car(phase=frame, angle=angle, dy=dy, brake=brake, eye=eye, damaged=damaged)
    if angle == 0:
        guns(img, dy)
    if shadow:
        drop_shadow(img)
    if angle == 0:
        exhaust(img, frame, dy, heat)
    return img


def smoke_overlay(img, frame, heavy=False):
    """Smoke puffs leaving the bonnet and trailing backwards (down-screen)."""
    ramp = [P["g1"], P["g2"], P["g3"]] if heavy else [P["g5"], P["g6"], P["g7"], P["g8"]]
    for i in range(3):
        t = (frame + i * 4 / 3) % 4 / 4.0         # 0..1 life
        x = CX + 5 - int(t * 3) + (i - 1)
        y = CY - 18 + int(t * 34)
        r = 1.6 + t * 3.2
        for yy in range(int(y - r) - 1, int(y + r) + 2):
            for xx in range(int(x - r) - 1, int(x + r) + 2):
                d = math.hypot(xx + 0.5 - x, yy + 0.5 - y) / r
                if d <= 1 and not (t > 0.6 and px.dith(xx, yy, (t - 0.6) * 2.2)):
                    k = 0 if d > 0.75 else 1 if d > 0.4 else 2
                    if (xx - x) + (yy - y) < -r * 0.5:
                        k = min(k + 1, len(ramp) - 1)
                    px.put(img, xx, yy, ramp[k])
    if heavy:
        # flicker of fire on the bonnet
        fx_ = [(CX + 6, CY - 18), (CX + 7, CY - 19), (CX + 5, CY - 19)]
        cols = [P["o3"], P["o2"], P["o4"], P["o1"]]
        for j, (x, y) in enumerate(fx_):
            px.put(img, x, y - (frame + j) % 2, cols[(frame + j) % 4])
        px.put(img, CX + 6, CY - 20 - frame % 2, P["o3"])


def white_flash(img):
    return px.remap(img, lambda c: c if c[:3] == INK[:3] else P["g11"])


def red_tint(img):
    def f(c):
        if c[:3] == INK[:3]:
            return c
        lum = 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
        return P["r4"] if lum > 170 else P["r3"] if lum > 110 else P["r2"] if lum > 60 else P["r1"]
    return px.remap(img, f)


def charred(img, seed="char"):
    def f(c):
        if c[:3] == INK[:3]:
            return c
        lum = 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
        return P["g4"] if lum > 190 else P["g3"] if lum > 130 else P["g2"] if lum > 70 else P["g1"]
    out = px.remap(img, f)
    p = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if p[x, y][3] and p[x, y][:3] != INK[:3] and px.hash01(seed, x, y) < 0.05:
                p[x, y] = P["o1"]
    return out


def destroyed_frames(base, seed=11, n=10, size=None):
    """Explosion sequence over a vehicle: flash, fireball, smoke, charred wreck."""
    W, H = base.size
    size = size or min(W, H)
    wreck = charred(base, seed)
    frames = []
    for t in range(n):
        if t == 0:
            f = white_flash(base)
        elif t < 3:
            f = red_tint(base) if t == 1 else wreck.copy()
        else:
            f = wreck.copy()
        if t >= 1:
            fb = fxlib.fireball(size, min(t - 1, 7), 8, seed=seed, max_r=size * 0.46)
            if t < 9:
                px.blit(f, fb, (W - size) // 2, (H - size) // 2)
        if t >= 8:
            # lingering smoke wisps over the wreck
            k = t - 8
            for i, (sx, sy) in enumerate(((2, -8), (-4, 2), (5, 10))):
                y = H // 2 + sy - k * 2 - i
                px.ellipse(f, W // 2 + sx + 0.5, y + 0.5, 1.6 + k * 0.5, 1.6 + k * 0.5,
                           P["g4"] if i % 2 else P["g3"])
                px.put(f, W // 2 + sx, y - 1, P["g5"])
        frames.append(f)
    return frames


def build():
    sb = px.SheetBuilder(FW, FH, 10)
    # drive: wheels turn (tread phase), exhaust shimmer
    sb.add("drive", [base_frame(f) for f in range(4)], 12)
    # idle: wheels still, exhaust ticks, eye blinks on 4th frame
    idle = [base_frame(0), base_frame(1), base_frame(2), base_frame(3, eye="blink")]
    sb.add("idle", idle, 6)
    ang = math.radians
    sb.add("shift_left", [base_frame(0, angle=ang(a)) for a in (-9, -16, -7)], 14, loop=False)
    sb.add("shift_right", [base_frame(0, angle=ang(a)) for a in (9, 16, 7)], 14, loop=False)
    boost = []
    for f in range(4):
        img = base_frame(f, heat=False)
        flame(img, f, [9, 11, 8, 10][f])
        boost.append(img)
    sb.add("boost", boost, 16)
    brake = []
    for f in range(2):
        img = base_frame(f, brake=True, dy=-1 if f == 0 else 0, heat=False)
        # brake glow + tyre smoke pixels
        for sx in (-11, 8):
            px.put(img, CX + sx + 1, CY + 29 + (0 if f == 0 else -1), P["r3"])
            px.put(img, CX + sx + 2, CY + 30, P["r2"] if f == 0 else P["r3"])
        for sx in (-15, 13):
            px.put(img, CX + sx, CY + 23 + f, P["g6"])
            px.put(img, CX + sx + 1, CY + 25 + f, P["g5"])
        brake.append(img)
    sb.add("brake", brake, 10)
    fire = []
    for f, (m, dy) in enumerate(((3, 0), (2, 1), (1, 1), (0, 0))):
        img = base_frame(f, dy=dy)
        muzzle(img, m, dy)
        fire.append(img)
    sb.add("fire", fire, 20, loop=False)
    normal = base_frame(0)
    hit = [white_flash(normal), red_tint(normal), base_frame(1)]
    fxs = fxlib.sparks(16, 1, 5, seed=9)
    px.blit(hit[2], fxs, CX - 2, CY - 22)
    sb.add("hit", hit, 15, loop=False)
    dl = []
    for f in range(4):
        img = base_frame(f, damaged=1)
        smoke_overlay(img, f, heavy=False)
        dl.append(img)
    sb.add("damaged_light", dl, 10)
    dh = []
    for f in range(4):
        img = base_frame(f, damaged=2, eye="red")
        smoke_overlay(img, f, heavy=True)
        dh.append(img)
    sb.add("damaged_heavy", dh, 10)
    sb.add("destroyed", destroyed_frames(base_frame(0, damaged=2, eye="red", heat=False),
                                         seed=21, n=10, size=48), 12, loop=False)
    # rear mine drop: hatch opens (lighter rear), mine pops out under the tail
    drop = []
    for f in range(3):
        img = base_frame(f)
        y = CY + 27
        px.rect(img, CX - 3, y - 1, CX + 2, y, P["g1"] if f < 2 else P["mn1"])
        if f >= 1:
            my = CY + 31 + (f - 1) * 3
            px.ellipse(img, CX, my + 0.5, 2.5, 2.5, P["g3"])
            px.put(img, CX - 1, my - 1, P["g5"])
            px.put(img, CX, my, P["r3"] if f == 1 else P["r4"])
        drop.append(img)
    sb.add("drop_mine", drop, 12, loop=False)
    sheet, rows = sb.build()
    return px.register_sheet(
        "player_car", "sprites/player_car.png", sheet, FW, FH, sb.cols, rows, sb.anims,
        anchor=(CX, CY), script=SCRIPT,
        collision={"x": CX - 13, "y": CY - 27, "w": 26, "h": 54},
        notes="MOMO's car. Faces up. Anchor = car centre. Twin nose guns at (anchor.x-6/+5, "
              "anchor.y-30); mines drop from (anchor.x, anchor.y+31). Aion visible in the "
              "glass canopy. shift_* tilt only; translate the node yourself.",
        muzzle_points=[[CX - 6, CY - 31], [CX + 5, CY - 31]],
        mine_point=[CX, CY + 31],
        exhaust_points=[[CX - 5, CY + 29], [CX + 4, CY + 29]],
    ), sheet


if __name__ == "__main__":
    d, sheet = build()
    px.preview(sheet, "player_car_4x.png", 4, bg=(60, 56, 73, 255))

"""Enemy vehicles (all face up, like the player): rammer car, armed pickup (+ rotating
turret sheet), obstacle-dropping truck."""
import math

import fxlib
import px
import sdf
from gen_player import white_flash, red_tint, charred, drop_shadow
from pal import P, INK

SCRIPT = "gen_enemies.py"


def ramp(name, n):
    return [P[f"{name}{i}"] for i in range(n)]


R5 = ramp("r", 5)
BR7 = ramp("br", 7)
G12 = ramp("g", 12)


def tyre(phase, outer):
    def f(x, y):
        tread = int(math.floor(y + phase)) % 3 == 0
        if abs(x) > outer:
            return P["g4"] if tread else P["g6"]
        return P["g3"] if tread else P["g5"]
    return f


def finish(img, shadow=True):
    px.outline(img, INK)
    if shadow:
        drop_shadow(img)
    return img


def explode_seq(base, centres, n=10, size=48, seed=31):
    """Flash -> fireballs (staggered per centre) -> smoke -> charred wreck."""
    W, H = base.size
    wreck = charred(base, seed)
    frames = []
    for t in range(n):
        if t == 0:
            f = white_flash(base)
        elif t == 1:
            f = red_tint(base)
        else:
            f = wreck.copy()
        for k, (cx, cy) in enumerate(centres):
            tt = t - 1 - k
            if 0 <= tt < 8:
                fb = fxlib.fireball(size, tt, 8, seed=seed + k, max_r=size * 0.46)
                px.blit(f, fb, cx - size // 2, cy - size // 2)
        if t >= n - 2:
            k = t - (n - 2)
            for i, (sx, sy) in enumerate(((2, -8), (-4, 2), (5, 10))):
                y = H // 2 + sy - k * 2 - i
                px.ellipse(f, W // 2 + sx + 0.5, y + 0.5, 1.6 + k * 0.5, 1.6 + k * 0.5,
                           P["g4"] if i % 2 else P["g3"])
                px.put(f, W // 2 + sx, y - 1, P["g5"])
        frames.append(f)
    return frames


def hit_seq(normal, alt, spark_at):
    h2 = alt.copy()
    px.blit(h2, fxlib.sparks(16, 1, 5, seed=13), spark_at[0] - 8, spark_at[1] - 8)
    return [white_flash(normal), red_tint(normal), h2]


def fire_trail(img, pts, frame, length, cols=None):
    """Orange exhaust flames (enemy flames are fire-coloured, MOMO's are cyan)."""
    cols = cols or [P["g11"], P["o4"], P["o3"], P["o2"], P["o1"]]
    wob = [0, 2, -1, 1][frame % 4]
    for i, (x0, y0) in enumerate(pts):
        L = length + (wob if i % 2 == 0 else -wob)
        for k in range(max(1, L)):
            u = k / max(1, L - 1)
            c = cols[min(len(cols) - 1, int(u * len(cols)))]
            px.put(img, x0, y0 + k, c)
            if u < 0.5:
                px.put(img, x0 + 1, y0 + k, cols[min(len(cols) - 1, int(u * len(cols)) + 1)])


# ============================================================== rammer (48x80)
RW, RH, RCX, RCY = 48, 80, 24, 40
R_BODY = sdf.smooth_union(1.5, sdf.rbox(0, 2, 11.0, 25.5, 3.5),
                          sdf.poly([(-12.5, -22), (12.5, -22), (11, -26), (-11, -26)]))
R_PLOW = sdf.poly([(-14, -25.5), (14, -25.5), (12.5, -29.5), (-12.5, -29.5)])
R_WHEELS = sdf.mirror_x(sdf.union(sdf.rbox(12.6, -14, 3.0, 5.8, 1.0),
                                   sdf.rbox(13.0, 15.5, 3.4, 6.6, 1.0)))
R_SHADE = sdf.shader(R_BODY, R5, 2, rim=2.0, hi=0.3, lo=-0.3)


def r_spikes(x, y):
    for sx in (-11, -5.5, 0, 5.5, 11):
        u = (-29.5 - y)               # height above plow
        if 0 <= u < 4.5 and abs(x - sx) < 1.6 * (1 - u / 4.5) + 0.2:
            return True
    return False


def r_body_col(x, y):
    if 1.8 < abs(x) < 4.2 and (y < -12 or y > 8):
        return P["g1"] if x < 0 else P["g0"]              # black racing stripes
    return R_SHADE(x, y)


def r_plow_col(x, y):
    band = int(math.floor(x + y * 0.9 + 40)) // 3 % 2
    if y < -28.6:
        return P["g8"]
    return P["o3"] if band else P["g1"]


def r_windshield(x, y):
    return abs(x) < 8.2 - (y + 12) * 0.3 and -12.5 < y < -8.5


def r_roof(x, y):
    return abs(x) < 8.2 and -8.5 <= y < 2.5


def r_roof_col(x, y):
    if x < -6.5:
        return P["r3"]
    return P["r1"] if x > 6.5 else P["r2"]


def r_rear_win(x, y):
    return abs(x) < 7.4 and 2.5 <= y < 5.0


def r_lights(x, y):
    # slanted angry headlights: higher on the outside
    ax = abs(x)
    return 5.5 < ax < 10.5 and -24.5 + (ax - 5.5) * -0.35 < y < -22.6 + (ax - 5.5) * -0.35


def r_pipes(x, y):
    return 11.0 < abs(x) < 12.8 and -2 < y < 8


def rammer_shapes(phase=0, glow=False):
    return [
        (sdf.inside(R_WHEELS), tyre(phase, 14.6)),
        (sdf.inside(R_BODY), r_body_col),
        (r_pipes, lambda x, y: P["g9"] if x < 0 else P["g7"]),
        (r_windshield, lambda x, y: P["g3"] if x + (y + 10) * 1.5 < -3 else P["g1"]),
        (r_roof, r_roof_col),
        (r_rear_win, P["g1"]),
        (sdf.inside(R_PLOW), r_plow_col),
        (r_spikes, lambda x, y: P["g10"] if x < 0 else P["g7"]),
        (r_lights, (lambda x, y: P["r4"]) if glow else (lambda x, y: P["o3"])),
        (lambda x, y: 6 < abs(x) < 10.5 and 26.4 < y < 27.6, P["r3"]),     # tail lights
    ]


def rammer_frame(phase=0, angle=0.0, dy=0, glow=False):
    img = px.render(RW, RH, rammer_shapes(phase, glow), RCX, RCY + dy, angle)
    return finish(img)


def build_rammer():
    sb = px.SheetBuilder(RW, RH, 10)
    drive = []
    for f in range(4):
        img = rammer_frame(f)
        fire_trail(img, [(RCX - 13, RCY + 8), (RCX + 12, RCY + 8)], f, 1 + f % 2,
                   cols=[P["o3"], P["o1"]])
        drive.append(img)
    sb.add("drive", drive, 12)
    att = []
    for f, (dy, glow, fl) in enumerate(((2, True, 0), (-3, True, 6), (-5, True, 4), (-1, False, 2))):
        img = rammer_frame(f, dy=dy, glow=glow)
        if fl:
            fire_trail(img, [(RCX - 4, RCY + 29 + dy), (RCX + 3, RCY + 29 + dy)], f, fl)
        if f == 2:   # impact sparks on the spikes
            px.blit(img, fxlib.sparks(16, 0, 5, seed=4), RCX - 8, RCY - 42 + dy)
        att.append(img)
    sb.add("attack", att, 12, loop=False)
    for name, sgn in (("ram_left", -1), ("ram_right", 1)):
        fr = []
        for f, a in enumerate((10, 18, 8)):
            img = rammer_frame(f, angle=math.radians(a * sgn), glow=True)
            fr.append(img)
        sb.add(name, fr, 12, loop=False)
    n = rammer_frame(0)
    sb.add("hit", hit_seq(n, rammer_frame(1), (RCX, RCY - 30)), 15, loop=False)
    sb.add("destroyed", explode_seq(rammer_frame(0), [(RCX, RCY)], 10, 48, seed=41), 12, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("enemy_rammer", "sprites/enemy_rammer.png", sheet, RW, RH, sb.cols, rows,
                      sb.anims, anchor=(RCX, RCY), script=SCRIPT,
                      collision={"x": RCX - 11, "y": RCY - 22, "w": 22, "h": 44},
                      notes="Rammer car with spiked plow. attack = forward lunge (sprite "
                            "itself moves up to 5 px; keep node still). ram_left/right = "
                            "sideways ram tilt; translate the node yourself.",
                      spike_line_y=RCY - 30)
    return sheet


# ============================================================== pickup (48x80)
PW, PH, PCX, PCY = 48, 80, 24, 40
P_BODY = sdf.rbox(0, 0, 12.0, 27.5, 3.0)
P_WHEELS = sdf.mirror_x(sdf.union(sdf.rbox(13.2, -17, 2.8, 5.6, 1.0),
                                   sdf.rbox(13.2, 15, 2.8, 5.6, 1.0)))
P_SHADE = sdf.shader(P_BODY, BR7, 3, rim=2.0, hi=0.3, lo=-0.3)
TURRET_POS = (0, 12)


def p_body_col(x, y):
    if px.hash01("rust", int(x + 20), int(y + 40)) < 0.06 and -26 < y < 26 and abs(x) < 11:
        return P["br2"]
    if y < -26.2:
        return P["g8"] if x < 0 else P["g6"]          # grille bumper
    return P_SHADE(x, y)


def p_bed(x, y):
    return abs(x) < 9.6 and 1.0 < y < 26.0


def p_bed_col(x, y):
    if abs(x) > 8.0 or y < 2.5 or y > 24.5:
        return P["br2"]
    return P["g2"] if int(math.floor(x + 20)) % 3 == 0 else P["g3"]


def p_windshield(x, y):
    return abs(x) < 10 - (y + 14) * 0.25 and -15 < y < -10.5


def p_roof(x, y):
    return abs(x) < 10 and -10.5 <= y < -2


def p_roof_col(x, y):
    if x < -8.5:
        return P["br5"]
    if x > 8.5:
        return P["br3"]
    return P["br4"]


def p_lights(x, y):
    return 7 < abs(x) < 10.5 and -26 < y < -24


def turret(img, cx, cy, ang, flash=0, recoil=0):
    """Gun turret at (cx,cy); ang radians, 0 = pointing down (south)."""
    dx, dy = math.sin(ang), math.cos(ang)

    def barrel(x, y):
        # local along-barrel coordinate
        u = x * dx + y * dy
        v = -x * dy + y * dx
        return 2.0 - recoil < u < 10.5 - recoil and abs(v) < 1.3

    def barrel_col(x, y):
        v = -x * dy + y * dx
        u = x * dx + y * dy
        if u > 9.0 - recoil:
            return P["g2"]
        return P["g7"] if v < -0.3 else P["g5"]

    base = sdf.circle(0, 0, 4.6)

    def base_col(x, y):
        l = sdf.lit(base, x, y)
        if x * x + y * y < 1.6:
            return P["r3"] if flash else P["g2"]
        return P["g7"] if l > 0.35 else P["g3"] if l < -0.3 else P["g5"]
    shapes = [(sdf.inside(base), base_col), (barrel, barrel_col)]
    t = px.render(img.width, img.height, shapes, cx, cy, 0.0)
    px.outline(t, INK)
    px.blit(img, t, 0, 0)
    if flash:
        tx, ty = cx + dx * (12.5 - recoil), cy + dy * (12.5 - recoil)
        r = 2.6 if flash == 2 else 1.6
        px.ellipse(img, tx, ty, r + 0.8, r + 0.8, P["o2"])
        px.ellipse(img, tx, ty, r, r, P["o4"])
        px.put(img, int(tx), int(ty), P["g11"])


def pickup_frame(phase=0, turret_ang=0.0, flash=0, recoil=0, with_turret=True):
    shapes = [
        (sdf.inside(P_WHEELS), tyre(phase, 14.6)),
        (sdf.inside(P_BODY), p_body_col),
        (p_bed, p_bed_col),
        (p_windshield, lambda x, y: P["g3"] if x + (y + 12) * 1.5 < -4 else P["g1"]),
        (p_roof, p_roof_col),
        (lambda x, y: abs(x) < 9 and -2 <= y < 0.5, P["g1"]),              # rear cab window
        (p_lights, P["o3"]),
        (lambda x, y: 7 < abs(x) < 11 and 26.0 < y < 27.2, P["r2"]),
    ]
    img = px.render(PW, PH, shapes, PCX, PCY, 0.0)
    px.outline(img, INK)
    if with_turret:
        turret(img, PCX + TURRET_POS[0], PCY + TURRET_POS[1], turret_ang, flash, recoil)
    drop_shadow(img)
    return img


def build_pickup():
    sb = px.SheetBuilder(PW, PH, 10)
    sb.add("drive", [pickup_frame(f) for f in range(4)], 12)
    att = []
    for f, (fl, rc) in enumerate(((2, 2), (1, 1), (0, 0), (2, 2), (1, 1), (0, 0))):
        att.append(pickup_frame(f % 4, 0.0, fl, rc))
    sb.add("attack", att, 14, loop=False)
    sb.add("hit", hit_seq(pickup_frame(0), pickup_frame(1), (PCX, PCY - 10)), 15, loop=False)
    sb.add("destroyed", explode_seq(pickup_frame(0), [(PCX, PCY - 8), (PCX, PCY + 12)], 10, 48,
                                    seed=51), 12, loop=False)
    sb.add("drive_noturret", [pickup_frame(f, with_turret=False) for f in range(4)], 12)
    sheet, rows = sb.build()
    px.register_sheet("enemy_pickup", "sprites/enemy_pickup.png", sheet, PW, PH, sb.cols, rows,
                      sb.anims, anchor=(PCX, PCY), script=SCRIPT,
                      collision={"x": PCX - 12, "y": PCY - 24, "w": 24, "h": 48},
                      turret_mount=[PCX + TURRET_POS[0], PCY + TURRET_POS[1]],
                      notes="Armed pickup. drive/attack have the turret baked in pointing "
                            "down (at the player behind). For an aiming turret use "
                            "drive_noturret + sheet enemy_pickup_turret at turret_mount.")
    # turret sheet: 16 angles (index i = i*22.5 deg clockwise from pointing DOWN), idle+fire
    TS = 32
    tb = px.SheetBuilder(TS, TS, 16)
    idle, fire = [], []
    for i in range(16):
        a = i * math.tau / 16
        im = px.new(TS, TS)
        turret(im, TS // 2, TS // 2, a)
        idle.append(im)
        im2 = px.new(TS, TS)
        turret(im2, TS // 2, TS // 2, a, flash=2, recoil=2)
        fire.append(im2)
    tb.add("aim", idle, 0, loop=False)
    tb.add("fire", fire, 0, loop=False)
    sheet2, rows2 = tb.build()
    px.register_sheet("enemy_pickup_turret", "sprites/enemy_pickup_turret.png", sheet2, TS, TS,
                      tb.cols, rows2, tb.anims, anchor=(TS // 2, TS // 2), script=SCRIPT,
                      notes="Row 0 = aim, row 1 = firing (flash+recoil). Column i = angle "
                            "i*22.5 deg, clockwise starting from pointing DOWN (screen "
                            "south): 0=down, 4=left, 8=up, 12=right. Pick the column for "
                            "the aim angle; flash frame for ~2 frames per shot.",
                      angle_step_deg=22.5, angle_zero="down", angle_direction="clockwise")
    return sheet


# ============================================================== truck (64x112)
TW, TH, TCX, TCY = 64, 112, 32, 56
T_CAB = sdf.rbox(0, -35, 13.0, 9.5, 3.5)
T_TRAILER = sdf.rbox(0, 11.5, 15.0, 33.0, 1.5)
T_WHEELS = sdf.mirror_x(sdf.union(sdf.rbox(14.3, -36, 2.7, 4.8, 1.0),
                                   sdf.rbox(16.0, 25, 2.6, 4.6, 1.0),
                                   sdf.rbox(16.0, 36, 2.6, 4.6, 1.0)))
T_CAB_SHADE = sdf.shader(T_CAB, [P["o0"], P["o1"], P["o2"], P["o3"], P["o4"]], 2, rim=2.0)
T_TR_SHADE = sdf.shader(T_TRAILER, G12, 6, rim=1.8, hi=0.3, lo=-0.3)


def t_trailer_col(x, y):
    c = T_TR_SHADE(x, y)
    if int(math.floor(y)) % 4 == 0 and abs(x) < 13.5:
        c = P["g4"]                                   # roof ribs
    if px.hash01("trust", int((x + 20) // 2), int((y + 60) // 2)) < 0.035:
        c = P["br3"]                                  # rust patches
    if -3 < x < 9 and -6 < y < 6 and abs((x - 3) * 0.9 - (y) * 0.6) < 1.2:
        c = P["pu3"]                                  # graffiti slash
    if 2 < x < 9 and -4 < y < 4 and abs(math.hypot(x - 5.5, y) - 2.6) < 0.6:
        c = P["pu3"]                                  # graffiti circle (an "eye")
    if y > 41.5:                                      # hazard stripes at the hatch
        c = P["o3"] if int(math.floor(x + y + 40)) // 2 % 2 else P["g1"]
    return c


def t_cab_col(x, y):
    if y < -43.0:
        return P["g8"] if x < 0 else P["g6"]
    return T_CAB_SHADE(x, y)


def truck_frame(phase=0, hatch=0, cargo=None, angle=0.0):
    shapes = [
        (sdf.inside(T_WHEELS), tyre(phase, 17.5)),
        (lambda x, y: abs(x) < 4 and -26.5 < y < -20, P["g2"]),            # hitch
        (sdf.inside(T_TRAILER), t_trailer_col),
        (sdf.inside(T_CAB), t_cab_col),
        (lambda x, y: abs(x) < 11 - (y + 38) * 0.2 and -40 < y < -36, P["g1"]),   # windshield
        (lambda x, y: abs(x) < 11 - (y + 38) * 0.2 and -40 < y < -38.6 and x < -4, P["g4"]),
        (lambda x, y: abs(x) < 10.5 and -36 <= y < -28, lambda x, y: P["o2"] if x > 8 else P["o3"]),
        (lambda x, y: 6 < abs(x) < 10.5 and -44 < y < -42.5, P["o4"]),     # headlights
        (lambda x, y: 9 < abs(x) < 12.5 and -30 < y < -24, P["g7"]),       # exhaust stacks
    ]
    img = px.render(TW, TH, shapes, TCX, TCY, angle)
    px.outline(img, INK)
    y0 = TCY + 44                                       # trailer tail
    if hatch:
        L = [0, 3, 6, 8][hatch]
        # dark interior visible at the tail, ramp lowered below it
        px.rect(img, TCX - 12, y0 - 3, TCX + 11, y0, P["g0"])
        px.rect(img, TCX - 11, y0 + 1, TCX + 10, y0 + L, P["g5"])
        for yy in range(y0 + 1, y0 + L + 1, 2):
            px.rect(img, TCX - 11, yy, TCX + 10, yy, P["g4"])
        px.rect(img, TCX - 11, y0 + L, TCX + 10, y0 + L, P["g7"])
        px.frame_rect(img, TCX - 12, y0 + 1, TCX + 11, y0 + L + 1, INK)
        if cargo is not None:
            cx, cy = TCX - 6, y0 - 5 + cargo
            px.rect(img, cx, cy, cx + 11, cy + 10, P["br4"])
            px.rect(img, cx, cy, cx + 11, cy, P["br5"])
            px.line(img, cx, cy, cx + 11, cy + 10, P["br2"])
            px.line(img, cx + 11, cy, cx, cy + 10, P["br2"])
            px.frame_rect(img, cx - 1, cy - 1, cx + 12, cy + 11, INK)
    drop_shadow(img)
    return img


def build_truck():
    sb = px.SheetBuilder(TW, TH, 10)
    sb.add("drive", [truck_frame(f) for f in range(4)], 10)
    seq = [(1, None), (2, None), (3, None), (3, 2), (3, 7), (3, 12), (2, None), (1, None)]
    sb.add("attack", [truck_frame(i % 4, h, c) for i, (h, c) in enumerate(seq)], 10, loop=False,
           drop_frame=5)
    sb.add("hit", hit_seq(truck_frame(0), truck_frame(1), (TCX, TCY - 30)), 15, loop=False)
    sb.add("destroyed", explode_seq(truck_frame(0), [(TCX, TCY - 34), (TCX, TCY + 4),
                                                      (TCX, TCY + 30)], 12, 56, seed=61),
           12, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("enemy_truck", "sprites/enemy_truck.png", sheet, TW, TH, sb.cols, rows,
                      sb.anims, anchor=(TCX, TCY), script=SCRIPT,
                      collision={"x": TCX - 14, "y": TCY - 40, "w": 28, "h": 80},
                      drop_point=[TCX, TCY + 52],
                      notes="Cab at top, rear hatch at bottom. attack = hatch opens, a "
                            "crate slides down the ramp; spawn the real obstacle at "
                            "drop_point when the animation reaches frame offset 5.")
    return sheet


def build():
    a = build_rammer()
    b = build_pickup()
    c = build_truck()
    return a, b, c


if __name__ == "__main__":
    build()

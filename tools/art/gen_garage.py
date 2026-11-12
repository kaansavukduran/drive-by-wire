"""Garage background (640x360), DRIVE-BY WIRE logo, app icons."""
import math

import gen_momo
import px
import pxfont
import sdf
from pal import P, INK, warm

SCRIPT = "gen_garage.py"
W, H = 640, 360
FLOOR_Y = 280
LAMP = (320, 54)
WINDOW = (24, 44, 196, 156)


def sky(img):
    x0, y0, x1, y1 = WINDOW
    bands = [P["pu0"], P["pu1"], P["r1"], P["r0"], P["o0"]]
    for y in range(y0, y1 + 1):
        u = (y - y0) / (y1 - y0)
        k = u * (len(bands) - 1)
        i = int(k)
        f = k - i
        for x in range(x0, x1 + 1):
            c = bands[min(i + 1, len(bands) - 1)] if px.dith(x, y, f) else bands[i]
            img.putpixel((x, y), c)
    # sickly sun behind smog
    px.ellipse(img, 150, 120, 9, 9, P["o1"])
    px.ellipse(img, 150, 120, 6, 6, P["o2"])
    # skyline
    x = x0
    k = 0
    while x <= x1:
        bw = 8 + int(px.hash01("bw", k) * 18)
        bh = 20 + int(px.hash01("bh", k) * 60)
        top = y1 - bh
        col = P["g0"] if k % 2 else P["pu0"]
        for yy in range(top, y1 + 1):
            for xx in range(x, min(x + bw, x1 + 1)):
                c = col
                if (xx - x) % 4 == 1 and (yy - top) % 5 == 2 and px.hash01("win", xx, yy) < 0.35:
                    c = P["o3"] if px.hash01("wc", xx, yy) < 0.7 else P["cy3"]
                img.putpixel((xx, yy), c)
        if px.hash01("ant", k) < 0.4:                      # antenna with red light
            px.rect(img, x + bw // 2, top - 6, x + bw // 2, top - 1, P["g1"])
            px.put(img, x + bw // 2, top - 7, P["r3"])
        if k == 3:                                         # broken neon on a tower
            pxfont.text(img, "MOMO", x + 1, top + 4, P["pu3"])
        x += bw + (1 if px.hash01("gap", k) < 0.5 else 0)
        k += 1
    # searchlight beam
    for yy in range(y0, y1 - 30):
        xx = int(60 + (y1 - 30 - yy) * 0.55)
        for d in range(-1 - (y1 - yy) // 30, 2 + (y1 - yy) // 30):
            if px.dith(xx + d, yy, 0.35):
                px.put(img, xx + d, yy, P["pu2"])


def window(img):
    sky(img)
    x0, y0, x1, y1 = WINDOW
    for t in range(4):
        px.frame_rect(img, x0 - 1 - t, y0 - 1 - t, x1 + 1 + t, y1 + 1 + t,
                      [P["g0"], P["g5"], P["g4"], P["g2"]][t])
    for mx in (x0 + 57, x0 + 114):
        px.rect(img, mx - 1, y0, mx + 1, y1, P["g4"])
        px.rect(img, mx - 1, y0, mx - 1, y1, P["g5"])
    px.rect(img, x0, y0 + 55, x1, y0 + 57, P["g4"])
    # crack in one pane
    for (a, b) in (((140, 60), (160, 78)), ((160, 78), (172, 74)), ((160, 78), (158, 96))):
        px.line(img, *a, *b, P["g9"])
    # sill
    px.rect(img, x0 - 8, y1 + 5, x1 + 8, y1 + 9, P["g4"])
    px.rect(img, x0 - 8, y1 + 5, x1 + 8, y1 + 5, P["g6"])
    px.rect(img, x0 - 8, y1 + 10, x1 + 8, y1 + 10, P["g0"])


def wall(img):
    for y in range(FLOOR_Y):
        for x in range(W):
            row = y // 16
            off = 16 if row % 2 else 0
            mortar = (y % 16 == 15) or ((x + off) % 32 == 31)
            h = px.hash01("blk", (x + off) // 32, row)
            c = P["g1"] if mortar else (P["g3"] if h > 0.6 else P["g2"])
            if not mortar and px.hash01("spk", x, y) < 0.04:
                c = P["g1"]
            img.putpixel((x, y), c)
    # ceiling band + pipe
    px.rect(img, 0, 0, W - 1, 13, P["g1"])
    px.rect(img, 0, 13, W - 1, 13, P["g0"])
    px.rect(img, 0, 20, W - 1, 23, P["g4"])
    px.rect(img, 0, 20, W - 1, 20, P["g6"])
    px.rect(img, 0, 24, W - 1, 24, P["g0"])
    for x in range(40, W, 96):
        px.rect(img, x, 14, x + 2, 25, P["g5"])
    # skirting
    px.rect(img, 0, FLOOR_Y - 6, W - 1, FLOOR_Y - 1, P["g1"])
    # hazard stripe on the wall near the lift
    for x in range(214, 428):
        for y in range(FLOOR_Y - 14, FLOOR_Y - 8):
            img.putpixel((x, y), P["o3"] if ((x + y) // 6) % 2 else P["g0"])
    # poster: "MOMO'YU SEV" (love MOMO)
    px.rect(img, 216, 46, 268, 104, P["g9"])
    px.rect(img, 218, 48, 266, 102, P["cy1"])
    face = gen_momo.face("calm")
    px.blit(img, face.crop((gen_momo.SX, gen_momo.SY, gen_momo.SX + 38, gen_momo.SY + 30)), 223, 52)
    pxfont.text(img, "SEV", 236, 90, P["g11"], shadow=P["g0"])
    px.frame_rect(img, 215, 45, 269, 105, INK)
    px.put(img, 242, 47, P["r3"])                         # pin


def floor(img):
    vp = (320, 150)
    for y in range(FLOOR_Y, H):
        for x in range(W):
            h = px.hash01("flr", x, y)
            c = P["g3"] if h > 0.15 else P["g2"]
            img.putpixel((x, y), c)
    for y in (FLOOR_Y, 296, 318, 348):
        px.rect(img, 0, y, W - 1, y, P["g1"])
    for k in range(-6, 7):
        bx = 320 + k * 120
        px.line(img, int(vp[0] + (bx - vp[0]) * (FLOOR_Y - vp[1]) / (H - vp[1])), FLOOR_Y, bx, H - 1, P["g1"])
    px.rect(img, 0, FLOOR_Y, W - 1, FLOOR_Y, P["g0"])
    for (cx, cy, rx) in ((290, 300, 22), (150, 330, 14), (470, 340, 18)):
        for y in range(cy - 6, cy + 7):
            for x in range(cx - rx - 2, cx + rx + 3):
                d = math.hypot((x - cx) / rx, (y - cy) / (rx * 0.3))
                if d < 1:
                    px.put(img, x, y, P["pu1"] if d < 0.25 and px.hash01("o", x, y) < 0.3 else P["g1"])


def car_side(img, x0, y0):
    """MOMO's car in profile, facing right, 150x52, bottom of wheels at y0+52."""
    def body(x, y):
        return sdf.smooth_union(4, sdf.rbox(75, 34, 72, 11, 8), sdf.ellipse(70, 26, 40, 22))(x, y)
    dome = sdf.ellipse(70, 22, 30, 18)
    wheels = [(32, 44), (118, 44)]

    def bcol(x, y):
        d = body(x, y)
        if 34 <= y <= 36 and 8 < x < 142:
            return P["cr1"] if y == 34 else P["cr0"]
        if d > -1.6:
            return P["mn3"] if y < 30 else P["mn1"]
        if y > 40:
            return P["mn1"]
        return P["mn3"] if y < 28 else P["mn2"]

    def dcol(x, y):
        if math.hypot(x - 74, y - 20) < 7:
            return P["pk3"] if (x - 74) + (y - 20) < -3 else P["pk2"]
        if y > 20 and abs(x - 74) < 9 and y > 26:
            return P["g9"]
        if -4 < (x - 58) + (y - 20) * 0.7 < -1 and y < 26:
            return P["bl4"]
        return P["bl1"] if y < 18 else P["bl0"]
    shapes = [
        (lambda x, y: body(x, y) < 0, bcol),
        (lambda x, y: dome(x, y) < 0 and y < 32, dcol),
        # gills in profile
        (lambda x, y: any(abs(y - (12 + k * 4) + (x - 64) * 0.5) < 0.8 and 62 < x < 68 for k in range(3)), P["pk2"]),
        (lambda x, y: any(math.hypot(x - 63, y - (9 + k * 4)) < 1.2 for k in range(3)), P["bl4"]),
        (lambda x, y: math.hypot(x - 80, y - 19) < 1.2, P["g0"]),           # Aion's eye
        (lambda x, y: math.hypot(x - 143, y - 30) < 3.2, P["g1"]),         # sensor eye
        (lambda x, y: math.hypot(x - 143, y - 30) < 2.0, P["cy3"]),
        (lambda x, y: 138 < x < 147 and 37 < y < 41, P["o4"]),            # headlight
        (lambda x, y: 2 < x < 7 and 31 < y < 36, P["r2"]),                # tail light
        (lambda x, y: 0 <= x < 4 and 40 < y < 43, P["g6"]),               # exhaust
    ]
    for wx, wy in wheels:
        shapes.append((lambda x, y, a=wx, b=wy: math.hypot(x - a, y - b) < 9.5,
                       lambda x, y, a=wx, b=wy: P["g6"] if math.hypot(x - a, y - b) < 3.5 else
                       P["g4"] if math.hypot(x - a, y - b) < 4.5 else P["g1"]))
    car = px.render(152, 56, shapes, 0, 0)
    px.outline(car, INK)
    px.blit(img, car, x0, y0)


def lift(img):
    for x0 in (230, 404):
        for y in range(118, FLOOR_Y):
            for x in range(x0, x0 + 10):
                c = P["o3"] if ((y + x) // 5) % 2 else P["g1"]
                if x == x0:
                    c = P["g0"]
                if x == x0 + 9:
                    c = P["g0"]
                img.putpixel((x, y), c)
        px.rect(img, x0 - 3, 112, x0 + 12, 118, P["g5"])
        px.frame_rect(img, x0 - 3, 112, x0 + 12, 118, INK)
        px.rect(img, x0 - 4, FLOOR_Y - 4, x0 + 13, FLOOR_Y - 1, P["g4"])
        px.frame_rect(img, x0 - 4, FLOOR_Y - 4, x0 + 13, FLOOR_Y - 1, INK)
    # platform + arms
    px.rect(img, 224, 222, 418, 228, P["g5"])
    px.rect(img, 224, 222, 418, 222, P["g7"])
    px.frame_rect(img, 223, 221, 419, 229, INK)
    for x in range(230, 414, 12):
        px.rect(img, x, 225, x + 5, 226, P["g3"])
    # hydraulic piston
    px.rect(img, 314, 230, 326, FLOOR_Y - 1, P["g6"])
    px.rect(img, 314, 230, 315, FLOOR_Y - 1, P["g8"])
    px.frame_rect(img, 313, 229, 327, FLOOR_Y - 1, INK)
    car_side(img, 245, 166)


def pegboard(img):
    x0, y0, x1, y1 = 452, 40, 628, 142
    px.rect(img, x0, y0, x1, y1, P["br2"])
    for y in range(y0 + 3, y1, 5):
        for x in range(x0 + 3, x1, 5):
            px.put(img, x, y, P["br1"])
    px.frame_rect(img, x0, y0, x1, y1, INK)
    px.frame_rect(img, x0 + 1, y0 + 1, x1 - 1, y1 - 1, P["br3"])
    # wrenches
    for i, x in enumerate(range(462, 520, 12)):
        L = 30 + i * 4
        px.rect(img, x, 52, x + 2, 52 + L, P["g7"])
        px.rect(img, x + 2, 52, x + 2, 52 + L, P["g5"])
        px.ellipse(img, x + 1.5, 51, 3.2, 3.2, P["g7"])
        px.put(img, x + 1, 48, P["br2"])
        px.put(img, x + 2, 48, P["br2"])
        px.frame_rect(img, x - 1, 54, x + 3, 53 + L, INK) if False else None
    # hammer
    px.rect(img, 540, 56, 543, 104, P["br4"])
    px.rect(img, 543, 56, 543, 104, P["br3"])
    px.rect(img, 532, 50, 552, 57, P["g6"])
    px.rect(img, 532, 50, 552, 51, P["g8"])
    # screwdrivers
    for i, (x, c) in enumerate(((566, "r"), (576, "o"), (586, "cy"))):
        px.rect(img, x, 50, x + 3, 66, P[c + "2"])
        px.rect(img, x, 50, x, 66, P[c + "3"])
        px.rect(img, x + 1, 67, x + 2, 92, P["g7"])
    # saw
    for y in range(56, 120):
        w = (y - 56) // 6
        px.rect(img, 600, y, 606 + w, y, P["g8"])
        if y % 2 == 0:
            px.put(img, 607 + w, y, P["g6"])
    px.rect(img, 598, 48, 612, 58, P["br4"])
    px.ellipse(img, 605, 53, 3, 2.5, P["br2"])
    # outline tools
    sub = img.crop((x0 + 2, y0 + 2, x1 - 1, y1 - 1))
    mask = px.new(sub.width, sub.height)
    for y in range(sub.height):
        for x in range(sub.width):
            c = sub.getpixel((x, y))
            if c[:3] not in (P["br2"][:3], P["br1"][:3], P["br3"][:3]):
                mask.putpixel((x, y), c)
    px.outline(mask, INK)
    px.blit(img, mask, x0 + 2, y0 + 2)


def terminal(img):
    # desk
    px.rect(img, 466, 228, 632, 235, P["br3"])
    px.rect(img, 466, 228, 632, 228, P["br5"])
    px.frame_rect(img, 465, 227, 633, 236, INK)
    for x in (470, 624):
        px.rect(img, x, 237, x + 5, FLOOR_Y + 8, P["br2"])
        px.frame_rect(img, x - 1, 236, x + 6, FLOOR_Y + 9, INK)
    # big CRT housing with MOMO's face
    px.rect(img, 512, 162, 598, 226, P["g4"])
    px.rect(img, 512, 162, 598, 163, P["g6"])
    px.rect(img, 597, 164, 598, 226, P["g3"])
    px.frame_rect(img, 511, 161, 599, 227, INK)
    face = gen_momo.face("calm")
    big = face.resize((face.width, face.height))
    px.blit(img, big, 531, 172)
    # keyboard + mug
    px.rect(img, 488, 222, 538, 227, P["g5"])
    for x in range(490, 537, 3):
        px.put(img, x, 223, P["g8"])
        px.put(img, x + 1, 225, P["g8"])
    px.frame_rect(img, 487, 221, 539, 228, INK)
    px.rect(img, 606, 216, 614, 227, P["r2"])
    px.rect(img, 606, 216, 607, 227, P["r3"])
    px.frame_rect(img, 605, 215, 615, 228, INK)
    px.ellipse(img, 617, 221, 2.5, 3, P["r2"], ring=0.45)
    # cables ("wires") snaking from the terminal to the lift
    for k, c in enumerate(("cy2", "r2", "o2")):
        pts = []
        for i in range(60):
            u = i / 59
            x = 540 - u * 180 + k * 6
            y = 236 + 46 * math.sin(u * math.pi) * (0.8 + 0.1 * k) + k * 3
            if u > 0.8:
                y -= (u - 0.8) * 5 * 30
            pts.append((int(x), int(y)))
        for (a, b) in zip(pts, pts[1:]):
            px.line(img, a[0], a[1], b[0], b[1], P[c])
            px.line(img, a[0], a[1] + 1, b[0], b[1] + 1, P["g0"])


def workbench(img):
    px.rect(img, 16, 206, 200, 213, P["br3"])
    px.rect(img, 16, 206, 200, 206, P["br5"])
    px.frame_rect(img, 15, 205, 201, 214, INK)
    for x in (22, 190):
        px.rect(img, x, 215, x + 5, FLOOR_Y + 6, P["br2"])
        px.frame_rect(img, x - 1, 214, x + 6, FLOOR_Y + 7, INK)
    px.rect(img, 22, 252, 195, 255, P["br2"])
    px.frame_rect(img, 21, 251, 196, 256, INK)
    # vice
    px.rect(img, 40, 192, 62, 205, P["cy1"])
    px.rect(img, 40, 192, 62, 193, P["cy2"])
    px.rect(img, 62, 197, 74, 199, P["g7"])
    px.frame_rect(img, 39, 191, 63, 205, INK)
    # oil cans and a toxic jerrycan
    for i, (x, c) in enumerate(((96, "r"), (112, "gr"), (128, "o"))):
        px.rect(img, x, 186 + i * 2, x + 11, 205, P[c + "2"])
        px.rect(img, x, 186 + i * 2, x + 2, 205, P[c + "3"])
        px.rect(img, x + 4, 182 + i * 2, x + 7, 185 + i * 2, P["g6"])
        px.frame_rect(img, x - 1, 185 + i * 2, x + 12, 205, INK)
    # parts box on the shelf
    px.rect(img, 60, 236, 110, 251, P["br4"])
    px.frame_rect(img, 59, 235, 111, 251, INK)
    pxfont.text(img, "PARCA", 71, 241, P["br1"])
    # tyre stack on the floor
    for k in range(3):
        y = FLOOR_Y + 2 - k * 12
        px.ellipse(img, 440, y, 17, 6.5, P["g1"])
        px.ellipse(img, 440, y - 2, 16, 5.5, P["g3"])
        px.ellipse(img, 440, y - 2, 7, 2.5, P["g0"])
        px.rect(img, 427, y - 6, 453, y - 6, P["g4"])


def lamp(img):
    lx, ly = LAMP
    px.rect(img, lx, 0, lx, ly - 12, P["g0"])
    for y in range(ly - 12, ly):
        hw = 6 + (y - (ly - 12)) * 1.3
        for x in range(int(lx - hw), int(lx + hw) + 1):
            img.putpixel((x, y), P["g6"] if x < lx - hw + 3 else P["g4"])
    px.rect(img, int(lx - 21), ly - 1, int(lx + 21), ly - 1, P["g0"])
    px.ellipse(img, lx + 0.5, ly + 1, 4, 3, P["o4"])
    px.put(img, lx, ly, P["g11"])


def lighting(img):
    """Warm lamp light: shift colours one step warmer/brighter with ordered dither,
    stronger near the lamp and inside its downward cone. The window keeps its cold sky."""
    lx, ly = LAMP
    src = img.copy().load()
    p = img.load()
    for y in range(ly, H):
        for x in range(W):
            x0, y0, x1, y1 = WINDOW
            if x0 <= x <= x1 and y0 <= y <= y1:
                continue
            dx, dy = x - lx, y - ly
            ang = abs(math.atan2(dx, dy))                 # 0 = straight down
            cone = max(0.0, 1 - ang / 0.62)
            if y >= FLOOR_Y:
                # light pool on the floor
                pool = max(0.0, 1 - math.hypot(dx / 230, (y - 318) / 46))
                cone = max(cone * 0.6, pool)
            dist = math.hypot(dx, dy)
            L = cone * max(0.0, 1.15 - dist / 330) + max(0.0, 0.5 - dist / 120)
            c = src[x, y]
            if px.dith(x, y, min(1.0, L)):
                c = warm(c)
                if px.dith(x + 1, y + 2, min(1.0, L - 0.75)):
                    c = warm(c)
            p[x, y] = c


def garage_bg():
    img = px.new(W, H)
    wall(img)
    window(img)
    floor(img)
    pegboard(img)
    workbench(img)
    lift(img)
    terminal(img)
    lighting(img)
    lamp(img)
    return img


# ------------------------------------------------------------------ logo
def logo():
    s = 4
    text = "DRIVE-BY WIRE"
    glyphs = [pxfont.F5[ch] for ch in text]
    gw = sum(len(g[0]) for g in glyphs) + len(glyphs) - 1
    Wl = gw * s + 7 * s // 2 + 16
    Hl = 7 * s + 20
    mask = [[0] * Wl for _ in range(Hl)]
    ox, oy = 8, 6
    x = 0
    for g in glyphs:
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == "1":
                    for yy in range(s):
                        for xx in range(s):
                            Y = j * s + yy
                            X = (x + i) * s + xx + (7 * s - Y) // 4   # italic slant
                            mask[oy + Y][ox + X] = 1
        x += len(g[0]) + 1
    img = px.new(Wl, Hl)
    fill = [P["o4"], P["o4"], P["o3"], P["o3"], P["o2"], P["o2"], P["o1"]]
    for y in range(Hl):
        for xx in range(Wl):
            if mask[y][xx]:
                Y = y - oy
                c = fill[min(6, Y // s)]
                if Y % s == 0 and Y // s in (0, 3):
                    c = P["g11"] if Y // s == 0 else P["o4"]
                img.putpixel((xx, y), c)
    px.outline(img, INK)
    # extruded shadow (down-right, 3 px) in deep purple
    ext = px.new(Wl, Hl)
    for k in (3, 2, 1):
        px.blit(ext, px.silhouette(px.shifted(img, k, k), P["pu1"] if k < 3 else P["pu0"]), 0, 0)
    px.under(img, ext, 0, 0)
    px.outline(img, INK)
    # the wire: a cyan cable weaving under the letters with a spark on the hyphen
    hy = None
    for xx in range(Wl):
        y = int(Hl - 6 + 2 * math.sin(xx / 9.0))
        if img.getpixel((xx, y))[3] == 0:
            img.putpixel((xx, y), P["cy3"])
            if img.getpixel((xx, y + 1))[3] == 0:
                img.putpixel((xx, y + 1), P["cy1"])
    return img


def logo_spark_frames(base):
    """4-frame spark crawling along the cable."""
    frames = []
    Wl, Hl = base.size
    for f in range(4):
        im = base.copy()
        xx = int(Wl * (0.2 + 0.2 * f))
        y = int(Hl - 6 + 2 * math.sin(xx / 9.0))
        for dx, dy, c in ((0, 0, P["g11"]), (-1, 0, P["cy4"]), (1, 0, P["cy4"]), (0, -1, P["cy4"]),
                          (0, 1, P["cy4"]), (-2, -2, P["cy3"]), (2, -2, P["cy3"]), (2, 2, P["cy3"])):
            px.put(im, xx + dx, y + dy, c)
        frames.append(im)
    return frames


# ------------------------------------------------------------------ icons
def icon_base(size=64, bg=True, fg=True, pad=0):
    im = px.new(size, size)
    if bg:
        for y in range(size):
            for x in range(size):
                c = P["g2"] if px.hash01("ic", x, y) > 0.1 else P["g1"]
                if abs(x - size // 2 + 0.5) < 1 and (y // 6) % 2 == 0:
                    c = P["g8"]
                if x in (size // 2 - 22, size // 2 + 21) and size >= 64:
                    c = P["o3"]
                im.putpixel((x, y), c)
    if fg:
        face = gen_momo.face("calm")
        px.blit(im, face, (size - face.width) // 2, (size - face.height) // 2)
    return im


def rounded(im, r):
    w, h = im.size
    out = im.copy()
    for y in range(h):
        for x in range(w):
            cx = min(max(x, r), w - 1 - r)
            cy = min(max(y, r), h - 1 - r)
            if math.hypot(x + 0.5 - (cx + 0.5), y + 0.5 - (cy + 0.5)) > r:
                out.putpixel((x, y), (0, 0, 0, 0))
    return out


def up(im, k):
    from PIL import Image
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def build():
    bg = garage_bg()
    px.register_image("garage_bg", "ui/garage_bg.png", bg, script=SCRIPT,
                      floor_y=FLOOR_Y, character_feet_y=330,
                      lift_car_rect=[245, 166, 152, 56], terminal_screen_rect=[531, 172, 48, 44],
                      notes="640x360 full screen. Leave the floor (y 280-360) left/right of "
                            "the lift for standing characters (feet at y~330).")
    lg = logo()
    px.register_image("logo", "ui/logo.png", lg, script=SCRIPT,
                      notes="Title lettering. Draw at integer scale.")
    frames = logo_spark_frames(lg)
    sb = px.SheetBuilder(lg.width, lg.height, 4)
    sb.add("spark", frames, 8)
    sheet, rows = sb.build()
    px.register_sheet("logo_spark", "ui/logo_spark.png", sheet, lg.width, lg.height, sb.cols,
                      rows, sb.anims, anchor=(0, 0), script=SCRIPT,
                      notes="Logo with a spark running along the wire (optional animated title).")
    ic = rounded(icon_base(64), 10)
    px.register_image("icon", "icon.png", up(ic, 4), script=SCRIPT, design_grid=64, scale=4)
    px.register_image("icon_192", "icon-192.png", up(ic, 3), script=SCRIPT, design_grid=64, scale=3)
    px.register_image("icon_512", "icon-512.png", up(ic, 8), script=SCRIPT, design_grid=64, scale=8)
    fg = icon_base(108, bg=False)
    px.register_image("icon_adaptive_fg", "icon-adaptive-fg.png", up(fg, 4), script=SCRIPT,
                      design_grid=108, scale=4, notes="Android adaptive foreground; face inside "
                      "the 66/108 safe zone.")
    bgi = icon_base(108, fg=False)
    px.register_image("icon_adaptive_bg", "icon-adaptive-bg.png", up(bgi, 4), script=SCRIPT,
                      design_grid=108, scale=4)


if __name__ == "__main__":
    build()

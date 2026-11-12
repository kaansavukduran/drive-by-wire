"""Highway tile (3 lanes, seamless vertical wrap), roadside ground tiles, road decals,
and animated roadside props (billboards, neon, pylons, wrecks, toxic puddles)."""
import math

import px
import pxfont
import sdf
from gen_player import charred
from pal import P, INK

SCRIPT = "gen_road.py"
TW, TH = 256, 256
ROAD_SCREEN_X = 192                 # tile drawn at x=192 on the 640 px screen
LANE_W = 64
LANES_TILE_X = (32, 224)            # drivable asphalt inside tile
LANE_CENTERS_TILE = [64, 128, 192]
RAIL_L, RAIL_R = (6, 11), (244, 249)


def wput(img, x, y, c):
    if 0 <= x < img.width:
        img.putpixel((int(x), int(y) % img.height), c)


def wget(img, x, y):
    return img.getpixel((int(x), int(y) % img.height))


def blob(img, cx, cy, rx, ry, seed, colfn):
    """Irregular wrapped blob (oil stain / puddle)."""
    for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
        for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
            a = math.atan2(y - cy, x - cx)
            wob = 1 + 0.25 * math.sin(a * 3 + seed) + 0.15 * math.sin(a * 5 + seed * 2)
            d = math.hypot((x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry) / wob
            if d < 1:
                c = colfn(x, y, d)
                if c:
                    wput(img, x, y, c)


def crack(img, x, y, steps, seed, xmin, xmax, col):
    for i in range(steps):
        wput(img, x, y, col)
        r = px.hash01(seed, i)
        if r < 0.35:
            x += 1
        elif r < 0.7:
            x -= 1
        y += 1
        x = max(xmin, min(xmax, x))
        if px.hash01(seed, i, "b") < 0.06:      # branch
            crack(img, x, y, steps // 3, seed * 7 + i, xmin, xmax, col)


def road_tile():
    img = px.new(TW, TH)
    for y in range(TH):
        for x in range(TW):
            h = px.hash01("asph", x, y)
            if 32 <= x < 224:                                   # lanes
                c = P["g2"] if h > 0.12 else P["g1"] if h < 0.05 else P["g3"]
            elif 12 <= x < 32 or 224 <= x < 244:                # shoulders: paler concrete
                c = P["g3"] if h > 0.15 else P["g2"] if h < 0.08 else P["g4"]
                if (x + y) % 16 == 0 and px.hash01("hatch", (x + y) // 16) < 0.7:
                    c = P["g4"]
            else:                                               # dirt outside rails
                c = P["br1"] if h > 0.3 else P["br0"] if h > 0.1 else P["g2"]
            img.putpixel((x, y), c)
    # cracks
    for k in range(9):
        x = 34 + int(px.hash01("cx", k) * 186)
        y = int(px.hash01("cy", k) * TH)
        crack(img, x, y, 14 + int(px.hash01("cl", k) * 26), k + 3, 33, 222, P["g1"])
    # oil stains (dark with a faint purple sheen)
    for k, (cx, cy) in enumerate(((64, 40), (128, 150), (192, 210), (100, 96), (170, 30))):
        blob(img, cx + 0.5, cy + 0.5, 6 + k % 3 * 2, 4 + k % 2 * 2, k,
             lambda x, y, d: P["pu1"] if (d < 0.35 and px.hash01("sh", x, y) < 0.3) else
             P["g1"] if d < 0.85 else (P["g1"] if px.dith(x, y, 0.5) else None))
    # pothole
    blob(img, 150.5, 70.5, 5, 3.5, 9, lambda x, y, d: P["g0"] if d < 0.6 else P["g1"])
    for x in range(146, 156):
        if wget(img, x, 67)[:3] == P["g1"][:3]:
            wput(img, x, 66, P["g4"])
    # edge lines: worn solid yellow
    for y in range(TH):
        for x in (30, 31, 224, 225):
            if px.hash01("edge", x, y) > 0.12 and not (y // 37 % 5 == 3 and x in (31, 224)):
                wput(img, x, y, P["o3"] if px.hash01("ew", x, y) > 0.2 else P["br4"])
    # lane dashes: 16 on / 16 off, 2 px wide, worn white
    for lx in (95, 159):
        for y in range(TH):
            if (y % 32) < 16:
                for x in (lx, lx + 1):
                    wput(img, x, y, P["g9"] if px.hash01("dash", x, y) > 0.15 else P["g7"])
    # guard rails with posts every 32 px
    for (a, b) in (RAIL_L, RAIL_R):
        for y in range(TH):
            for x in range(a, b + 1):
                c = P["g7"]
                if x == a:
                    c = P["g0"]
                elif x == b:
                    c = P["g0"]
                elif x == a + 1:
                    c = P["g9"]
                elif x == b - 1:
                    c = P["g5"]
                if x in (a + 2, a + 3) and y % 8 == 0:
                    c = P["g6"]                      # beam corrugation
                if px.hash01("rust", x, y // 3) < 0.04 and a < x < b:
                    c = P["br3"]
                img.putpixel((x, y), c)
            if y % 32 in (8, 9, 10, 11):             # posts
                px_ = a - 2 if a < 128 else b + 1
                for x in (px_, px_ + 1):
                    img.putpixel((x, y), P["g4"] if y % 32 != 11 else P["g0"])
        # one dented section per side
    for y in range(120, 136):
        k = int(2 * math.sin((y - 120) / 16 * math.pi))
        for x in range(RAIL_R[0], RAIL_R[1] + 1):
            img.putpixel((x, y), P["g0"] if x in RAIL_R else P["g5"] if x > RAIL_R[0] + k + 2 else P["g8"])
    return img


def ground_tile(seed, w=192):
    """Dystopian roadside wasteland (seamless vertically). Road side is at x=w-1 for
    the left strip; the right strip is generated mirrored."""
    img = px.new(w, TH)
    for y in range(TH):
        for x in range(w):
            h = px.hash01("gnd", seed, x, y)
            v = y * math.tau / TH
            n = (math.sin(x * 0.051 + seed + math.sin(v * 2) * 1.7) +
                 0.7 * math.sin(v * 5 + x * 0.13 + seed * 2) +
                 0.5 * math.sin(v * 9 - x * 0.21 + math.sin(x * 0.03) * 3))
            if n > 1.35 and not px.dith(x, y, max(0.0, 1.6 - n)):
                c = P["br1"] if h > 0.2 else P["br2"]
            elif n < -1.45 and not px.dith(x, y, max(0.0, n + 1.7)):
                c = P["g2"] if h > 0.2 else P["g1"]
            else:
                c = P["br0"] if h > 0.25 else P["br1"] if h > 0.08 else P["g1"]
            img.putpixel((x, y), c)
    # sidewalk / concrete slabs along the road edge
    for y in range(TH):
        for x in range(w - 22, w):
            c = P["g3"] if px.hash01("sw", x, y) > 0.1 else P["g4"]
            if y % 24 == 0 or x == w - 22:
                c = P["g1"]
            if px.hash01("slab", seed, y // 24) < 0.2 and x < w - 12:    # broken slab
                c = P["br1"] if px.hash01("dirt", x, y) > 0.3 else P["g2"]
            img.putpixel((x, y), c)
    # cracks in the ground
    for k in range(8):
        crack(img, int(px.hash01("gx", seed, k) * (w - 30)), int(px.hash01("gy", seed, k) * TH),
              20, seed * 13 + k, 1, w - 24, P["g0"])
    # dead weed tufts
    for k in range(18):
        x = 4 + int(px.hash01("tx", seed, k) * (w - 32))
        y = int(px.hash01("ty", seed, k) * TH)
        for dx, dy in ((0, 0), (-1, -1), (1, -1), (0, -2), (2, -2), (-2, -1)):
            wput(img, x + dx, y + dy, P["gr1"] if dy > -2 else P["br3"])
    # rubble piles
    for k in range(6):
        cx = 10 + px.hash01("rx", seed, k) * (w - 50)
        cy = px.hash01("ry", seed, k) * TH
        for i in range(10):
            x = int(cx + (px.hash01("rb", seed, k, i) - 0.5) * 14)
            y = int(cy + (px.hash01("rc", seed, k, i) - 0.5) * 10)
            s = 1 + int(px.hash01("rs", seed, k, i) * 2)
            for yy in range(s + 1):
                for xx in range(s + 1):
                    c = P["g6"] if (xx == 0 or yy == 0) else P["g4"]
                    wput(img, x + xx, y + yy, c)
            wput(img, x + s + 1, y + s, P["g0"])
    # small static toxic puddles
    for k in range(3):
        cx = 20 + px.hash01("px", seed, k) * (w - 70)
        cy = px.hash01("py", seed, k) * TH
        blob(img, cx, cy, 13 + k * 3, 6 + k, k * 2.3 + seed * 1.7,
             lambda x, y, d: P["gr4"] if d < 0.3 and px.hash01("tp", x, y) < 0.2 else
             P["gr3"] if d < 0.65 else P["gr2"] if d < 0.85 else P["gr1"])
    # burnt-out car wreck baked in (top-down, charred)
    return img


def wreck_sprite(seed=3):
    """Charred car shell reusing MOMO-car geometry style, as a generic wreck."""
    import gen_enemies as ge
    base = ge.rammer_frame(0)
    w = charred(base, seed)
    # strip the spikes area into generic wreck and crop
    return w.crop((8, 6, 40, 74))


def billboard(text, col, glow, broken=False):
    im = px.new(64, 64)
    # legs
    for x in (18, 44):
        px.rect(im, x, 34, x + 2, 60, P["g4"])
        px.rect(im, x + 2, 34, x + 2, 60, P["g2"])
    # panel (seen in 3/4: face + top edge)
    px.rect(im, 4, 6, 59, 36, P["g2"])
    px.rect(im, 4, 4, 59, 6, P["g5"])
    px.rect(im, 6, 8, 57, 34, col[0])
    for y in range(8, 35):
        for x in range(6, 58):
            if px.dith(x, y, (y - 8) / 30 * 0.6):
                px.put(im, x, y, col[1])
    tw = pxfont.text_width(text)
    pxfont.text(im, text, 32 - tw // 2, 18, glow, shadow=P["g0"])
    if broken:
        # torn corner and holes
        for y in range(8, 20):
            for x in range(40 + (y - 8), 58):
                px.put(im, x, y, P["g1"])
        px.ellipse(im, 15, 28, 3, 2.5, P["g1"])
        px.line(im, 40, 8, 52, 20, P["g0"])
    # rusty light fixtures on top
    for x in (14, 30, 46):
        px.rect(im, x, 2, x + 3, 3, P["g6"])
    px.outline(im, INK)
    return im


def neon(text, cols, frame):
    """Neon sign on a dark frame; frame 0..3 flicker cycle."""
    im = px.new(64, 64)
    on = [True, True, False, True][frame]
    tw = pxfont.text_width(text)
    w = tw + 12
    x0 = 32 - w // 2
    px.rect(im, x0, 22, x0 + w - 1, 38, P["g1"])
    px.frame_rect(im, x0 + 1, 23, x0 + w - 2, 37, P["g3"])
    # pole
    px.rect(im, 31, 39, 32, 60, P["g4"])
    c_on, c_dim = cols
    pxfont.text(im, text, x0 + 6, 28, c_on if on else c_dim)
    if on:
        # tube halo: 1 px of the darker neon around the letters (opaque, no alpha)
        halo = px.new(64, 64)
        pxfont.text(halo, text, x0 + 6, 28, c_dim)
        px.outline(halo, c_dim)
        px.under(im, halo, 0, 0)
        pxfont.text(im, text, x0 + 6, 28, c_on)
    if frame == 1:
        px.put(im, x0 + 6 + tw - 2, 28, c_dim)     # one letter stutters
    px.outline(im, INK)
    return im


def pylon(frame=0):
    im = px.new(64, 64)
    # lattice tower top-down/oblique: tapered legs with cross bracing
    for y in range(8, 62):
        u = (y - 8) / 54
        hw = 4 + u * 10
        px.put(im, int(32 - hw), y, P["g6"])
        px.put(im, int(32 + hw), y, P["g4"])
        if y % 6 == 0:
            px.line(im, int(32 - hw), y, int(32 + hw), y + 5, P["g5"])
            px.line(im, int(32 + hw), y, int(32 - hw), y + 5, P["g3"])
    # crossarm with insulators
    px.rect(im, 6, 12, 58, 13, P["g6"])
    px.rect(im, 6, 14, 58, 14, P["g3"])
    for x in (8, 20, 44, 56):
        px.rect(im, x, 15, x + 1, 18, P["cy2"])
    # warning light blinks
    px.rect(im, 31, 5, 32, 7, P["r4"] if frame == 0 else P["r1"])
    px.outline(im, INK)
    # sagging cables leave the frame on both sides (ends at frame edge)
    for x in range(0, 64):
        sag = int(3 * math.sin(x / 63 * math.pi))
        for cx in (9, 21, 45, 57):
            pass
        px.put(im, x, 19 + sag, P["g1"])
    return im


def puddle(frame):
    im = px.new(64, 64)
    blob(im, 32, 40, 20, 11, 4,
         lambda x, y, d: P["gr4"] if d < 0.25 else P["gr3"] if d < 0.6 else P["gr2"] if d < 0.85
         else P["gr1"])
    # bubbles rise and pop
    for i, (bx, by) in enumerate(((24, 38), (38, 43), (31, 35))):
        ph = (frame + i) % 4
        if ph < 3:
            r = 0.8 + ph * 0.6
            px.ellipse(im, bx, by, r, r, P["gr4"], ring=0.5 if ph == 2 else None)
            if ph == 0:
                px.put(im, bx, by, P["gr4"])
    # fumes
    for i in range(2):
        y = 26 - ((frame * 3 + i * 6) % 12)
        x = 26 + i * 10 + (frame % 2)
        px.put(im, x, y, P["gr2"])
        px.put(im, x + 1, y - 1, P["gr2"])
    px.outline(im, P["g0"])
    return im


def barrels():
    im = px.new(64, 64)
    for (cx, cy, c) in ((24, 38, "gr"), (36, 36, "r"), (30, 46, "br")):
        ring = [P[f"{c}{i}"] for i in (1, 2, 3)]
        body = sdf.circle(cx, cy, 5.2)
        part = px.render(64, 64, [(sdf.inside(body), lambda x, y, b=body, r=ring:
                                   r[2] if sdf.lit(b, x, y) > 0.4 else r[0] if sdf.lit(b, x, y) < -0.3 else r[1])], 0, 0)
        px.put(part, cx, cy, P["g0"])
        px.outline(part, INK)
        px.blit(im, part, 0, 0)
    return im


def decal(kind):
    im = px.new(32, 32)
    if kind == "skid":
        for x0 in (9, 20):
            for y in range(2, 30):
                x = x0 + int(2 * math.sin(y / 9))
                if px.hash01("sk", x0, y) > 0.2:
                    px.put(im, x, y, P["g1"])
                    px.put(im, x + 1, y, P["g1"])
    elif kind == "manhole":
        px.ellipse(im, 16, 16, 8, 8, P["g4"])
        px.ellipse(im, 16, 16, 6.5, 6.5, P["g3"])
        for y in range(10, 23, 3):
            px.rect(im, 11, y, 21, y, P["g1"])
        px.ellipse(im, 16, 16, 8, 8, P["g0"], ring=0.13)
    elif kind == "crack":
        crack(im, 15, 0, 32, 77, 2, 29, P["g1"])
        crack(im, 12, 6, 14, 78, 2, 29, P["g1"])
    elif kind == "oil":
        blob(im, 16, 16, 11, 7, 2,
             lambda x, y, d: P["pu2"] if (0.3 < d < 0.4) else P["cy1"] if (0.45 < d < 0.52)
             else P["g1"] if d < 0.9 else None)
    elif kind == "patch":
        px.rect(im, 4, 6, 27, 25, P["g1"])
        px.rect(im, 5, 7, 26, 24, P["g2"])
        for y in range(7, 25):
            for x in range(5, 27):
                if px.hash01("pt", x, y) < 0.15:
                    px.put(im, x, y, P["g3"])
    elif kind == "arrow":
        for y in range(6, 28):
            w = 1 if y > 14 else (y - 5)
            for x in range(16 - w, 16 + w):
                if px.hash01("ar", x, y) > 0.2:
                    px.put(im, x, y, P["g8"])
    return im


def build():
    road = road_tile()
    px.register_image("road_tile", "road/road_tile.png", road, script=SCRIPT,
                      tile_size=[TW, TH], tiles_vertically=True, screen_x=ROAD_SCREEN_X,
                      lane_width=LANE_W, lane_centers_x_tile=LANE_CENTERS_TILE,
                      lane_centers_x_screen=[ROAD_SCREEN_X + c for c in LANE_CENTERS_TILE],
                      drivable_x_screen=[ROAD_SCREEN_X + LANES_TILE_X[0], ROAD_SCREEN_X + LANES_TILE_X[1]],
                      guard_rail_x_screen=[ROAD_SCREEN_X + RAIL_L[0], ROAD_SCREEN_X + RAIL_R[1]],
                      parallax=1.0,
                      notes="Draw at x=192, repeat every 256 px vertically, scroll down at the "
                            "road speed. Lane dividers at screen x 287-288 and 351-352.")
    left = ground_tile(1)
    right = px.flip_h(ground_tile(2))
    px.register_image("roadside_left", "road/roadside_left.png", left, script=SCRIPT,
                      tile_size=[192, TH], tiles_vertically=True, screen_x=0, parallax=1.0)
    px.register_image("roadside_right", "road/roadside_right.png", right, script=SCRIPT,
                      tile_size=[192, TH], tiles_vertically=True, screen_x=448, parallax=1.0)
    # decals
    sb = px.SheetBuilder(32, 32, 6)
    kinds = ["skid", "manhole", "crack", "oil", "patch", "arrow"]
    sb.add("decals", [decal(k) for k in kinds], 0, loop=False)
    for i, k in enumerate(kinds):
        sb.alias(k, [i], 0, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("road_decals", "road/road_decals.png", sheet, 32, 32, sb.cols, rows,
                      sb.anims, anchor=(16, 16), script=SCRIPT, parallax=1.0,
                      notes="Static decals to scatter on the asphalt for variety (scroll with road).")
    # props
    sb = px.SheetBuilder(64, 64, 4)
    sb.add("billboard_obey", [billboard("ITAAT ET", (P["r1"], P["r0"]), P["o3"])], 0, loop=False)
    sb.add("billboard_momo", [billboard("MOMO?", (P["cy1"], P["cy0"]), P["cy4"], broken=True)], 0, loop=False)
    sb.add("billboard_buy", [billboard("BUY 2 LIVE", (P["pu1"], P["pu0"]), P["pu4"], broken=True)], 0, loop=False)
    sb.add("neon_open", [neon("24 SAAT", (P["pu4"], P["pu2"]), f) for f in range(4)], 6)
    sb.add("neon_fuel", [neon("YAKIT", (P["cy4"], P["cy2"]), (f + 2) % 4) for f in range(4)], 6)
    sb.add("pylon", [pylon(0), pylon(1)], 2)
    w = px.new(64, 64)
    px.blit(w, wreck_sprite(), 16, 0)
    sb.add("wreck", [w], 0, loop=False)
    sb.add("toxic_puddle", [puddle(f) for f in range(4)], 6)
    sb.add("barrels", [barrels()], 0, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("roadside_props", "road/roadside_props.png", sheet, 64, 64, sb.cols, rows,
                      sb.anims, anchor=(32, 60), script=SCRIPT,
                      parallax={"toxic_puddle": 1.0, "wreck": 1.0, "barrels": 1.0,
                                "billboard_*": 1.15, "neon_*": 1.15, "pylon": 1.2},
                      notes="Scatter on the roadside strips (x 0-170 and 470-640). Tall props "
                            "(billboards, neon, pylons) scroll slightly faster than the ground "
                            "(parallax factor) to fake height. anchor = foot point.")


if __name__ == "__main__":
    build()

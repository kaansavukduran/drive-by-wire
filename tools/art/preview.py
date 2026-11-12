"""Contact sheets (4x) for every manifest sheet + a mock 640x360 gameplay screenshot
and a garage mock. Output: tools/art/preview/ (not imported by Godot: tools/.gdignore)."""
import json
import os

from PIL import Image, ImageDraw, ImageFont

import px

BG = (64, 57, 82, 255)


def load(rel):
    return Image.open(os.path.join(px.ROOT, rel)).convert("RGBA")


def frame(man, key, idx):
    s = man["sheets"][key]
    im = load(s["path"])
    fw, fh, cols = s["frame_width"], s["frame_height"], s["columns"]
    return im.crop(((idx % cols) * fw, (idx // cols) * fh, (idx % cols) * fw + fw, (idx // cols) * fh + fh))


def anim_frame(man, key, anim, k=0):
    a = man["sheets"][key]["animations"][anim]["frames"]
    return frame(man, key, a[k % len(a)])


def put(canvas, img, x, y, anchor=None):
    ax, ay = anchor or (0, 0)
    canvas.alpha_composite(img, (int(x - ax), int(y - ay)))


def nine(img, w, h, m):
    out = px.new(w, h)
    l, t, r, b = m["left"], m["top"], m["right"], m["bottom"]
    W, H = img.size
    xs = [(0, l, 0, l), (l, W - r, l, w - r), (W - r, W, w - r, w)]
    ys = [(0, t, 0, t), (t, H - b, t, h - b), (H - b, H, h - b, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if dx1 <= dx0 or dy1 <= dy0:
                continue
            part = img.crop((sx0, sy0, sx1, sy1))
            # tile (not stretch) to stay pixel-exact
            for yy in range(dy0, dy1, max(1, sy1 - sy0)):
                for xx in range(dx0, dx1, max(1, sx1 - sx0)):
                    pw, ph = min(sx1 - sx0, dx1 - xx), min(sy1 - sy0, dy1 - yy)
                    out.alpha_composite(part.crop((0, 0, pw, ph)), (xx, yy))
    return out


def font(size, name="PixelifySans.ttf"):
    return ImageFont.truetype(os.path.join(px.ASSETS, "fonts", name), size)


def text(canvas, s, x, y, col, size=10, name="PixelifySans.ttf"):
    # draw on a 1-bit mask so the mock has no anti-aliased text either
    m = Image.new("1", canvas.size, 0)
    ImageDraw.Draw(m).text((x, y), s, font=font(size, name), fill=1)
    layer = Image.new("RGBA", canvas.size, col)
    canvas.paste(layer, (0, 0), m)


def mock_run(man):
    W, H = 640, 360
    c = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    road = man["images"]["road_tile"]
    off = 100
    for y in range(-256, H + 256, 256):
        put(c, load(man["images"]["roadside_left"]["path"]), 0, y + off)
        put(c, load(man["images"]["roadside_right"]["path"]), 448, y + off)
        put(c, load(road["path"]), road["screen_x"], y + off)
    put(c, frame(man, "road_decals", 0), 300, 250)
    put(c, frame(man, "road_decals", 3), 360, 60)
    props = man["sheets"]["roadside_props"]
    for anim, x, y in (("billboard_obey", 70, 120), ("neon_fuel", 560, 90), ("pylon", 120, 330),
                       ("toxic_puddle", 540, 300), ("wreck", 40, 260), ("billboard_momo", 590, 230)):
        put(c, anim_frame(man, "roadside_props", anim), x, y, props["anchor"])
    lanes = road["lane_centers_x_screen"]
    pc = man["sheets"]["player_car"]
    put(c, anim_frame(man, "player_car", "fire", 0), lanes[1], 290, pc["anchor"])
    put(c, anim_frame(man, "projectiles", "player_bullet"), lanes[1] - 6, 220, (8, 8))
    put(c, anim_frame(man, "projectiles", "player_bullet", 1), lanes[1] + 5, 200, (8, 8))
    put(c, anim_frame(man, "enemy_pickup", "attack", 0), lanes[1], 110, man["sheets"]["enemy_pickup"]["anchor"])
    put(c, anim_frame(man, "projectiles", "enemy_bullet"), lanes[1], 175, (8, 8))
    put(c, anim_frame(man, "enemy_rammer", "ram_left", 1), lanes[2] - 4, 300, man["sheets"]["enemy_rammer"]["anchor"])
    put(c, anim_frame(man, "near_miss", "streak", 1), lanes[2] - 30, 300, (8, 24))
    put(c, anim_frame(man, "enemy_truck", "attack", 4), lanes[0], 70, man["sheets"]["enemy_truck"]["anchor"])
    put(c, anim_frame(man, "obstacles", "crate_idle"), lanes[0], 175, (12, 12))
    put(c, anim_frame(man, "obstacles", "spikes_idle"), lanes[2], 40, (12, 12))
    put(c, anim_frame(man, "obstacles", "barrel_idle"), lanes[0] + 10, 230, (12, 12))
    put(c, anim_frame(man, "explosion", "explode", 3), lanes[2] + 10, 150, (32, 32))
    put(c, anim_frame(man, "mine", "armed"), lanes[1], 335, (8, 8))
    put(c, anim_frame(man, "pickups", "energy"), lanes[0], 280, (8, 8))
    # HUD: MOMO face + bubble top-left, bars, command box bottom
    put(c, frame(man, "momo_face", 0), 8, 8)
    b = man["images"]["ui_speech_bubble"]
    bub = nine(load(b["path"]), 120, 30, b["nine_slice"])
    put(c, bub, 62, 10)
    put(c, load(man["images"]["ui_bubble_tail_left"]["path"]), 53, 16)
    text(c, "Kamyon geliyor!", 68, 12, (14, 11, 22, 255), 10)
    text(c, "Korkuyorum...", 68, 22, (14, 11, 22, 255), 10)
    bf = man["images"]["ui_bar_frame"]
    fills = (("ui_bar_fill_hp", "heart", 60), ("ui_bar_fill_trust", "trust", 40))
    for i, (fk, ic, pct) in enumerate(fills):
        y = 58 + i * 14
        put(c, anim_frame(man, "ui_icons", ic), 8, y)
        put(c, nine(load(bf["path"]), 80, 12, bf["nine_slice"]), 22, y)
        fill = load(man["images"][fk]["path"])
        for x in range(25, 25 + int(74 * pct / 100), 8):
            put(c, fill.crop((0, 0, min(8, 25 + int(74 * pct / 100) - x), 6)), x, y + 3)
    chip = man["images"]["ui_chip_scared"]
    put(c, nine(load(chip["path"]), 58, 14, chip["nine_slice"]), 8, 88)
    put(c, anim_frame(man, "ui_mood_icons", "scared"), 9, 89)
    text(c, "korkmuş", 24, 89, (176, 212, 255, 255), 10)
    cb = man["images"]["ui_command_box"]
    put(c, nine(load(cb["path"]), 300, 24, cb["nine_slice"]), 170, 330)
    text(c, "> sağa geç ve kamyona ateş et", 178, 333, (154, 246, 255, 255), 16, "VT323.ttf")
    put(c, frame(man, "ui_cursor", 0), 420, 337)
    # Aion portrait on the right
    put(c, load(man["images"]["ui_portrait_frame"]["path"]), 576, 8)
    put(c, frame(man, "portraits", 0), 580, 12)
    return c


def mock_garage(man):
    c = load(man["images"]["garage_bg"]["path"])
    ch = man["sheets"]["characters"]
    put(c, anim_frame(man, "characters", "aion_idle"), 120, 330, ch["anchor"])
    om = anim_frame(man, "characters", "omer_idle")
    put(c, om.transpose(Image.FLIP_LEFT_RIGHT), 520, 332, ch["anchor"])
    put(c, load(man["images"]["logo"]["path"]), 171, 290)
    p = man["images"]["ui_panel"]
    return c


def contact(man):
    for key, s in sorted(man["sheets"].items()):
        im = load(s["path"])
        bg = Image.new("RGBA", im.size, BG)
        bg.alpha_composite(im)
        bg.resize((im.width * 4, im.height * 4), Image.NEAREST).save(
            os.path.join(px.PREVIEW, f"sheet_{key}_4x.png"))


def main():
    os.makedirs(px.PREVIEW, exist_ok=True)
    with open(os.path.join(px.ASSETS, "MANIFEST.json")) as f:
        man = json.load(f)
    contact(man)
    run = mock_run(man)
    run.resize((2560, 1440), Image.NEAREST).save(os.path.join(px.PREVIEW, "mock_run_4x.png"))
    g = mock_garage(man)
    g.resize((2560, 1440), Image.NEAREST).save(os.path.join(px.PREVIEW, "mock_garage_4x.png"))
    run.resize((1280, 720), Image.NEAREST).save(os.path.join(px.PREVIEW, "mock_run_2x.png"))
    g.resize((1280, 720), Image.NEAREST).save(os.path.join(px.PREVIEW, "mock_garage_2x.png"))


if __name__ == "__main__":
    main()

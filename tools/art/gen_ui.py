"""UI pieces: 9-slice panels (speech bubble, command box, button states, bar frame,
mood chips, portrait frame), bar fills, small icons, text cursor."""
import px
from pal import P, INK

SCRIPT = "gen_ui.py"


def panel(w, h, fill, border, hi=None, lo=None, radius=2, outer=INK):
    im = px.new(w, h)
    for y in range(h):
        for x in range(w):
            # rounded corner mask
            cx = min(max(x, radius), w - 1 - radius)
            cy = min(max(y, radius), h - 1 - radius)
            if (x - cx) ** 2 + (y - cy) ** 2 > radius * radius + 0.5:
                continue
            im.putpixel((x, y), fill)
    px.inner_edge(im, outer)
    # inner border ring
    src = im.copy()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if src.getpixel((x, y)) == fill:
                edge = any(src.getpixel((x + dx, y + dy)) == outer for dx, dy in
                           ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if edge:
                    c = border
                    if hi and (src.getpixel((x, y - 1)) == outer or src.getpixel((x - 1, y)) == outer):
                        c = hi
                    if lo and (src.getpixel((x, y + 1)) == outer or src.getpixel((x + 1, y)) == outer):
                        c = lo
                    im.putpixel((x, y), c)
    return im


def nine(key, rel, im, margin, **extra):
    m = margin if isinstance(margin, (list, tuple)) else [margin] * 4
    px.register_image(key, rel, im, script=SCRIPT,
                      nine_slice={"left": m[0], "top": m[1], "right": m[2], "bottom": m[3]},
                      **extra)


def speech_bubble():
    im = panel(24, 24, P["g11"], P["g9"], hi=P["g11"], lo=P["g8"], radius=4)
    return im


def bubble_tail(direction):
    im = px.new(12, 10)
    rows = ["111111111111", "011111111110", "001111111100", "000111111000",
            "000011110000", "000001110000", "000000110000", "000000010000"]
    for j, r in enumerate(rows):
        for i, b in enumerate(r):
            if b == "1":
                px.put(im, i, j, P["g11"] if j < 6 else P["g9"])
    px.outline(im, INK)
    # cut the top outline so it merges with the bubble's bottom edge
    for x in range(1, 11):
        im.putpixel((x, 0), P["g11"])
    if direction == "left":
        im = im.rotate(-90, expand=True)
    return im


def command_box():
    im = panel(24, 24, P["cy0"], P["cy3"], hi=P["cy4"], lo=P["cy2"], radius=1)
    # scanline texture in the fill (tiles fine since rows alternate with period 2)
    for y in range(3, 21):
        if y % 2:
            for x in range(3, 21):
                if im.getpixel((x, y)) == P["cy0"]:
                    im.putpixel((x, y), P["g0"])
    # corner brackets (terminal look)
    for (x, y, dx, dy) in ((2, 2, 1, 1), (21, 2, -1, 1), (2, 21, 1, -1), (21, 21, -1, -1)):
        px.put(im, x + dx, y + dy, P["cy4"])
    return im


def cursor(on):
    im = px.new(6, 10)
    if on:
        px.rect(im, 0, 0, 5, 9, P["cy4"])
        px.rect(im, 0, 9, 5, 9, P["cy3"])
    return im


def button(state):
    cols = {
        "normal":   (P["g4"], P["g6"], P["g7"], P["g3"]),
        "hover":    (P["cy1"], P["cy3"], P["cy4"], P["cy2"]),
        "pressed":  (P["g3"], P["g2"], P["g2"], P["g4"]),
        "disabled": (P["g2"], P["g3"], P["g3"], P["g2"]),
    }[state]
    fill, border, hi, lo = cols
    im = panel(24, 16, fill, border, hi=hi, lo=lo, radius=2)
    if state == "pressed":
        px.rect(im, 2, 2, 21, 2, P["g1"])
    return im


def bar_frame():
    im = panel(16, 12, P["g0"], P["g4"], hi=P["g6"], lo=P["g3"], radius=1)
    return im


def bar_fill(ramp):
    """8x6 tileable fill segment (tile horizontally)."""
    im = px.new(8, 6)
    for y in range(6):
        for x in range(8):
            c = P[ramp + "3"] if y == 0 else P[ramp + "2"] if y < 4 else P[ramp + "1"]
            if y == 1 and x % 4 == 0:
                c = P[ramp + "4"]
            im.putpixel((x, y), c)
    return im


def icon(kind):
    im = px.new(12, 12)
    if kind == "heart":
        rows = ["011000110", "111101111", "111111111", "111111111", "011111110",
                "001111100", "000111000", "000010000"]
        for j, r in enumerate(rows):
            for i, b in enumerate(r):
                if b == "1":
                    px.put(im, i + 1, j + 2, P["r3"] if (i + j) > 3 else P["r4"])
        px.put(im, 2, 3, P["g11"])
    elif kind == "trust":       # pink heart with a plug: MOMO's trust
        rows = ["011000110", "111101111", "111111111", "111111111", "011111110",
                "001111100", "000111000", "000010000"]
        for j, r in enumerate(rows):
            for i, b in enumerate(r):
                if b == "1":
                    px.put(im, i + 1, j + 1, P["pk2"] if (i + j) > 3 else P["pk3"])
        px.put(im, 2, 2, P["g11"])
        px.rect(im, 5, 9, 5, 11, P["cy3"])
    elif kind == "wrench":
        for k in range(8):
            px.put(im, 2 + k, 9 - k, P["g8"])
            px.put(im, 3 + k, 9 - k, P["g6"])
        px.rect(im, 8, 1, 10, 3, P["g8"])
        px.put(im, 9, 2, (0, 0, 0, 0))
        px.rect(im, 1, 9, 3, 10, P["g8"])
    elif kind == "battery":
        px.rect(im, 3, 2, 8, 10, P["cy2"])
        px.rect(im, 3, 2, 4, 10, P["cy3"])
        px.rect(im, 5, 1, 6, 1, P["g7"])
        px.put(im, 6, 4, P["o4"]), px.put(im, 5, 5, P["o4"]), px.put(im, 6, 6, P["o4"])
        px.put(im, 5, 7, P["o4"])
    elif kind == "mine":
        px.ellipse(im, 6, 6, 3.6, 3.6, P["g5"])
        px.put(im, 6, 6, P["r4"])
        for dx, dy in ((0, -5), (0, 4), (-5, 0), (4, 0)):
            px.put(im, 6 + dx, 6 + dy, P["o3"])
    elif kind == "bullet":
        px.rect(im, 5, 2, 6, 9, P["cy3"])
        px.rect(im, 5, 2, 6, 3, P["g11"])
    elif kind == "distance":
        px.rect(im, 2, 1, 3, 10, P["g7"])
        px.rect(im, 4, 1, 9, 5, P["o3"])
        px.rect(im, 4, 1, 6, 3, P["g11"])
        px.rect(im, 7, 3, 9, 5, P["g11"])
    px.outline(im, INK)
    return im


def mood_icon(mood):
    """12x12 tiny face for chips: colour + expression per mood."""
    col = {"calm": "cy", "excited": "o", "scared": "bl", "sulky": "pu", "confused": "gr"}[mood]
    im = px.new(12, 12)
    px.ellipse(im, 6, 6, 5.5, 5.5, P[col + "3"])
    px.ellipse(im, 5, 5, 3, 3, P[col + "4"]) if mood != "scared" else None
    e = P["g0"]
    if mood == "calm":
        px.put(im, 4, 5, e), px.put(im, 7, 5, e), px.rect(im, 5, 8, 6, 8, e)
    elif mood == "excited":
        px.rect(im, 3, 4, 4, 5, e), px.rect(im, 7, 4, 8, 5, e), px.rect(im, 4, 7, 7, 8, e)
        px.rect(im, 5, 8, 6, 8, P["pk3"])
    elif mood == "scared":
        px.rect(im, 3, 4, 4, 5, P["g11"]), px.rect(im, 7, 4, 8, 5, P["g11"])
        px.put(im, 4, 5, e), px.put(im, 7, 5, e)
        px.put(im, 4, 8, e), px.put(im, 5, 9, e), px.put(im, 6, 8, e), px.put(im, 7, 9, e)
    elif mood == "sulky":
        px.rect(im, 3, 5, 4, 5, e), px.rect(im, 7, 5, 8, 5, e)
        px.rect(im, 5, 8, 6, 8, e), px.put(im, 4, 9, e), px.put(im, 7, 9, e)
    elif mood == "confused":
        px.rect(im, 3, 4, 4, 5, e), px.rect(im, 7, 5, 8, 5, e)
        px.put(im, 4, 8, e), px.put(im, 5, 9, e), px.put(im, 6, 8, e), px.put(im, 7, 9, e)
    px.outline(im, INK)
    return im


def build():
    nine("ui_speech_bubble", "ui/speech_bubble.png", speech_bubble(), 6,
         notes="White speech bubble 9-slice. Dark text (g0 #0e0b16).")
    px.register_image("ui_bubble_tail_down", "ui/bubble_tail_down.png", bubble_tail("down"),
                      script=SCRIPT, notes="Place under the bubble, overlapping its bottom edge by 1 px.")
    px.register_image("ui_bubble_tail_left", "ui/bubble_tail_left.png", bubble_tail("left"),
                      script=SCRIPT, notes="Place left of the bubble, overlapping its left edge by 1 px.")
    nine("ui_command_box", "ui/command_box.png", command_box(), 6,
         notes="Terminal command box 9-slice (cyan on dark). Text colour cy4 #9af6ff.")
    sb = px.SheetBuilder(6, 10, 2)
    sb.add("blink", [cursor(True), cursor(False)], 2)
    sheet, rows = sb.build()
    px.register_sheet("ui_cursor", "ui/cursor.png", sheet, 6, 10, sb.cols, rows, sb.anims,
                      anchor=(0, 0), script=SCRIPT)
    for st in ("normal", "hover", "pressed", "disabled"):
        nine("ui_button_" + st, f"ui/button_{st}.png", button(st), 5)
    nine("ui_bar_frame", "ui/bar_frame.png", bar_frame(), 3,
         notes="Bar background/frame 9-slice; inner area starts 3 px in. Tile a bar_fill_* "
               "6 px tall inside, clipped to the value.")
    for name, r in (("hp", "gr"), ("hp_low", "r"), ("trust", "pk"), ("energy", "cy"), ("boost", "o")):
        px.register_image("ui_bar_fill_" + name, f"ui/bar_fill_{name}.png", bar_fill(r),
                          script=SCRIPT, tiles_horizontally=True)
    kinds = ["heart", "trust", "wrench", "battery", "mine", "bullet", "distance"]
    sb = px.SheetBuilder(12, 12, len(kinds))
    sb.add("icons", [icon(k) for k in kinds], 0, loop=False)
    for i, k in enumerate(kinds):
        sb.alias(k, [i], 0, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("ui_icons", "ui/icons.png", sheet, 12, 12, sb.cols, rows, sb.anims,
                      anchor=(6, 6), script=SCRIPT)
    moods = ["calm", "excited", "scared", "sulky", "confused"]
    sb = px.SheetBuilder(12, 12, len(moods))
    sb.add("moods", [mood_icon(m) for m in moods], 0, loop=False)
    for i, m in enumerate(moods):
        sb.alias(m, [i], 0, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("ui_mood_icons", "ui/mood_icons.png", sheet, 12, 12, sb.cols, rows,
                      sb.anims, anchor=(6, 6), script=SCRIPT)
    for m, r in (("calm", "cy"), ("excited", "o"), ("scared", "bl"), ("sulky", "pu"),
                 ("confused", "gr")):
        nine("ui_chip_" + m, f"ui/chip_{m}.png",
             panel(16, 14, P[r + "1"], P[r + "3"], hi=P[r + "4"], lo=P[r + "2"], radius=3), 5,
             notes="Mood chip 9-slice; put the matching ui_mood_icons frame at x=3 and the "
                   "label text after it.")
    nine("ui_portrait_frame", "ui/portrait_frame.png",
         _portrait_frame(), 6, notes="56x56 frame for the 48x48 portraits (portrait at 4,4).")
    nine("ui_panel", "ui/panel.png", panel(24, 24, P["g1"], P["g3"], hi=P["g4"], lo=P["g2"], radius=2), 6,
         notes="Generic dark panel (garage dialogue, run summary).")


def _portrait_frame():
    im = px.new(56, 56)
    px.rect(im, 0, 0, 55, 55, P["g3"])
    px.rect(im, 0, 0, 55, 0, P["g5"])
    px.rect(im, 0, 0, 0, 55, P["g5"])
    px.rect(im, 4, 4, 51, 51, P["g1"])                      # backdrop behind the portrait
    for y in range(4, 52):
        for x in range(4, 52):
            if y % 2:
                im.putpixel((x, y), P["g0"])
    px.frame_rect(im, 3, 3, 52, 52, P["g0"])
    px.inner_edge(im, INK)
    for x, y in ((1, 1), (54, 1), (1, 54), (54, 54)):
        im.putpixel((x, y), P["g7"])
    return im


if __name__ == "__main__":
    build()

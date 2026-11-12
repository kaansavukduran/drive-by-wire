"""MOMO's face for the HUD: a digital pet on a little CRT. Frames are 48x44 with the
CRT bezel baked in (screen area 38x30 at (5,4)). Moods: calm, excited, scared, sulky
(idle 4 + talk 3 each), confused (idle 4 + talk 3), hurt (3)."""
import px
import pxfont
from pal import P, INK

SCRIPT = "gen_momo.py"
FW, FH = 48, 44
SX, SY, SW, SH = 5, 4, 38, 30        # screen window inside the frame

THEMES = {
    #           bg        scan      fg          mid        accent
    "calm":     ("cy0", "g0", "cy4", "cy3", "pk3"),
    "excited":  ("br1", "br0", "o4", "o3", "pk3"),
    "scared":   ("bl0", "g0", "g11", "bl3", "cy4"),
    "sulky":    ("pu0", "g0", "pu4", "pu3", "r3"),
    "confused": ("gr0", "g0", "gr4", "gr3", "o4"),
    "hurt":     ("r1", "r0", "g11", "r4", "o4"),
}


def bezel():
    im = px.new(FW, FH)
    px.rect(im, 1, 0, FW - 2, FH - 1, P["g4"])
    px.rect(im, 0, 1, FW - 1, FH - 2, P["g4"])
    px.rect(im, 1, 1, FW - 2, 1, P["g6"])             # top highlight
    px.rect(im, 1, 1, 1, FH - 3, P["g5"])
    px.rect(im, FW - 2, 2, FW - 2, FH - 2, P["g3"])
    px.rect(im, 2, FH - 2, FW - 2, FH - 2, P["g2"])
    # recessed screen frame
    px.rect(im, SX - 2, SY - 2, SX + SW + 1, SY + SH + 1, P["g2"])
    px.rect(im, SX - 1, SY - 1, SX + SW, SY + SH, P["g0"])
    # chin: LED, label, vents
    px.rect(im, 5, FH - 7, 7, FH - 5, P["g1"])
    px.put(im, 6, FH - 6, P["gr3"])
    pxfont.text(im, "MOMO", 15, FH - 8, P["g7"], shadow=P["g2"])
    for x in (36, 38, 40, 42):
        px.rect(im, x, FH - 8, x, FH - 4, P["g2"])
    # screws
    for x, y in ((2, 2), (FW - 3, 2)):
        px.put(im, x, y, P["g7"])
    px.outline(im, INK)
    # punch the screen hole (transparent) so the face sheet can be layered too
    for y in range(SY, SY + SH):
        for x in range(SX, SX + SW):
            im.putpixel((x, y), (0, 0, 0, 0))
    return im


BEZEL = bezel()


class Screen:
    def __init__(self, mood):
        t = THEMES[mood]
        self.bg, self.scan, self.fg, self.mid, self.acc = (P[k] for k in t)
        self.im = px.new(SW, SH)
        for y in range(SH):
            for x in range(SW):
                self.im.putpixel((x, y), self.scan if y % 2 else self.bg)
        # rounded screen corners
        for (x, y) in ((0, 0), (1, 0), (0, 1), (SW - 1, 0), (SW - 2, 0), (SW - 1, 1),
                       (0, SH - 1), (1, SH - 1), (0, SH - 2), (SW - 1, SH - 1),
                       (SW - 2, SH - 1), (SW - 1, SH - 2)):
            self.im.putpixel((x, y), P["g0"])
        # glare
        px.put(self.im, 3, 2, P["g9"])
        px.put(self.im, 4, 2, P["g8"])
        px.put(self.im, 3, 3, P["g8"])

    def p(self, x, y, c=None):
        px.put(self.im, x, y, c or self.fg)

    def r(self, x0, y0, x1, y1, c=None):
        px.rect(self.im, x0, y0, x1, y1, c or self.fg)

    def frame(self):
        out = px.new(FW, FH)
        out.paste(self.im, (SX, SY))
        px.blit(out, BEZEL, 0, 0)
        return out


LX, RX, EY = 11, 26, 9        # eye boxes' top-left x (left/right eye) and top y


def eye_round(s, x, y, w=5, h=7, state="open", hl=True, look=0):
    """Rounded-rect eye. state: open/half/closed."""
    if state == "closed":
        s.r(x, y + h - 3, x + w - 1, y + h - 3)
        s.p(x - 1, y + h - 4, s.fg)
        s.p(x + w, y + h - 4, s.fg)
        return
    top = y + (h // 2 if state == "half" else 0)
    s.r(x + 1 + look, top, x + w - 2 + look, y + h - 1)
    s.r(x + look, top + 1, x + w - 1 + look, y + h - 2)
    if state == "half":
        s.r(x - 1 + look, top, x + w + look, top, s.mid)       # eyelid line
    elif hl:
        s.r(x + 1 + look, top + 1, x + 2 + look, top + 2, s.bg)  # highlight hole
        s.p(x + w - 2 + look, y + h - 3, s.bg)


def blush(s):
    for x0 in (LX - 3, RX + 5):
        s.r(x0, 19, x0 + 2, 19, s.acc)


def mouth(s, kind, open_=0):
    cx = 18
    y = 21
    if kind == "smile":
        if open_ == 0:
            s.p(cx - 2, y), s.p(cx + 2, y), s.r(cx - 1, y + 1, cx + 1, y + 1)
        elif open_ == 1:
            s.r(cx - 1, y, cx + 1, y + 1)
            s.p(cx, y + 1, s.acc)
        else:
            s.r(cx - 2, y, cx + 2, y + 2)
            s.r(cx - 1, y + 3, cx + 1, y + 3)
            s.r(cx - 1, y + 2, cx + 1, y + 2, s.acc)
    elif kind == "grin":
        w = [4, 4, 5][open_]
        h = [2, 3, 4][open_]
        s.r(cx - w, y - 1, cx + w, y - 1)
        s.r(cx - w + 1, y, cx + w - 1, y + h - 1)
        s.r(cx - w + 2, y + h, cx + w - 2, y + h)
        if h >= 3:
            s.r(cx - 1, y + h - 1, cx + 1, y + h, s.acc)      # tongue
    elif kind == "wavy":
        if open_ == 0:
            for i, dx in enumerate(range(-4, 5)):
                s.p(cx + dx, y + (1 if i % 4 in (1, 2) else 0))
        else:
            h = 1 + open_
            s.r(cx - 2, y, cx + 2, y)
            s.r(cx - 3, y + 1, cx + 3, y + h)
            s.r(cx - 2, y + h + 1, cx + 2, y + h + 1)
            s.r(cx - 2, y + 1, cx + 2, y + h, s.bg)
            s.p(cx - 1, y + h + 1, s.bg)
    elif kind == "pout":
        if open_ == 0:
            s.r(cx - 1, y, cx + 1, y), s.p(cx - 2, y + 1), s.p(cx + 2, y + 1)
        elif open_ == 1:
            s.r(cx - 2, y + 1, cx + 2, y + 1)
        else:
            s.r(cx - 1, y, cx + 1, y + 1)
            s.p(cx, y + 1, s.bg)
    elif kind == "squiggle":
        if open_ == 0:
            for i, dx in enumerate(range(-3, 4)):
                s.p(cx + dx, y + [0, 1, 1, 0, 0, 1, 1][i])
        else:
            r = open_
            s.r(cx - r, y, cx + r, y + r + 1)
            s.r(cx - r + 1, y + 1, cx + r - 1, y + r, s.bg)
    elif kind == "zigzag":
        for i, dx in enumerate(range(-4, 5)):
            s.p(cx + dx, y + (i % 2))


def face(mood, eye_state="open", talk=-1, frame=0):
    s = Screen(mood)
    look = 1 if eye_state == "glance" else 0
    st = "open" if eye_state == "glance" else eye_state
    if mood == "calm":
        eye_round(s, LX, EY, state=st, look=look)
        eye_round(s, RX, EY, state=st, look=look)
        blush(s)
        mouth(s, "smile", max(0, talk))
    elif mood == "excited":
        eye_round(s, LX - 1, EY - 1, 7, 9, st, look=look)
        eye_round(s, RX - 1, EY - 1, 7, 9, st, look=look)
        if st == "open":
            for x0 in (LX - 1, RX - 1):
                s.p(x0 + 4 + look, EY + 5, s.bg)
        # sparkles twinkle (alternate corners)
        sp = [(3, 6), (33, 4), (34, 20), (2, 22)]
        for i, (x, y) in enumerate(sp):
            if (i + frame) % 2 == 0:
                s.p(x, y, s.acc), s.p(x - 1, y, s.mid), s.p(x + 1, y, s.mid)
                s.p(x, y - 1, s.mid), s.p(x, y + 1, s.mid)
        blush(s)
        mouth(s, "grin", max(0, talk))
    elif mood == "scared":
        jit = [0, 1, 0, -1][frame % 4] if talk >= 0 else 0
        for x0 in (LX - 1, RX - 1):
            x0 += jit
            if st == "closed":
                s.r(x0, EY + 5, x0 + 6, EY + 5)
                s.p(x0 + 1, EY + 4), s.p(x0 + 5, EY + 4)
                continue
            top = EY + (3 if st == "half" else 0)
            s.r(x0 + 1, top, x0 + 5, top)
            s.r(x0 + 1, EY + 8, x0 + 5, EY + 8)
            s.r(x0, top + 1, x0, EY + 7)
            s.r(x0 + 6, top + 1, x0 + 6, EY + 7)
            s.r(x0 + 2 + look, EY + 4, x0 + 3 + look, EY + 5, s.mid)     # tiny pupil
        # worried brows (slanting up toward the middle)
        s.r(LX - 1, EY - 3, LX + 1, EY - 3, s.mid), s.r(LX + 2, EY - 4, LX + 4, EY - 4, s.mid)
        s.r(RX + 3, EY - 3, RX + 5, EY - 3, s.mid), s.r(RX, EY - 4, RX + 2, EY - 4, s.mid)
        # sweat drop slides down over the loop
        dy = frame % 4
        s.p(34, 5 + dy, s.acc), s.r(33, 6 + dy, 35, 7 + dy, s.acc), s.p(34, 8 + dy, s.acc)
        mouth(s, "wavy", max(0, talk))
    elif mood == "sulky":
        for x0 in (LX, RX):
            if st == "closed":
                s.r(x0, EY + 5, x0 + 4, EY + 5)
                continue
            top = EY + (4 if st == "half" else 3)
            s.r(x0 - 1, top - 1, x0 + 5, top - 1, s.mid)    # heavy lid
            s.r(x0, top, x0 + 4, EY + 6)
            px_ = x0 + (3 if look else 2)                    # side-eye pupil
            s.r(px_, top, px_ + 1, top + 1, s.bg)
        # anger mark
        if frame % 2 == 0:
            for (x, y) in ((31, 2), (33, 2), (31, 4), (33, 4), (32, 3)):
                s.p(x, y, s.acc)
        # puffed cheek
        s.r(RX + 6, 18, RX + 7, 20, s.mid)
        mouth(s, "pout", max(0, talk))
    elif mood == "confused":
        # left eye: big ring, right eye: squint line
        x0 = LX - 1
        if st == "closed":
            s.r(x0, EY + 5, x0 + 6, EY + 5)
        else:
            top = EY + (3 if st == "half" else 0)
            s.r(x0 + 1, top, x0 + 5, top), s.r(x0 + 1, EY + 8, x0 + 5, EY + 8)
            s.r(x0, top + 1, x0, EY + 7), s.r(x0 + 6, top + 1, x0 + 6, EY + 7)
            s.r(x0 + 3 + look, EY + 4, x0 + 3 + look, EY + 5)
        s.r(RX, EY + 4, RX + 5, EY + 4)
        s.p(RX - 1, EY + 3), s.p(RX + 6, EY + 5)
        # question mark bobbing
        qy = 1 + (frame % 2)
        for (x, y) in ((30, 0), (31, 0), (32, 1), (31, 2), (30, 3), (30, 5)):
            s.p(x + 1, qy + y, s.acc)
        mouth(s, "squiggle", max(0, talk))
    elif mood == "hurt":
        for x0 in (LX, RX):          # X eyes
            for k in range(5):
                s.p(x0 + k, EY + 1 + k), s.p(x0 + 4 - k, EY + 1 + k)
        mouth(s, "zigzag")
        if frame == 1:      # inverted flash
            s.im = px.remap(s.im, lambda c: s.bg if c == s.fg else (s.fg if c in (s.bg, s.scan) else c))
        if frame == 2:      # glitch: shift some rows
            src = s.im.copy()
            for y in (6, 7, 15, 22, 23):
                for x in range(SW):
                    s.im.putpixel((x, y), src.getpixel(((x + 3) % SW, y)))
    return s.frame()


def build():
    sb = px.SheetBuilder(FW, FH, 7)
    for mood in ("calm", "excited", "scared", "sulky", "confused"):
        idle = [face(mood, st, frame=i) for i, st in enumerate(("open", "half", "closed", "glance"))]
        talk = [face(mood, "open", talk=t, frame=t) for t in range(3)]
        ids = sb.add(mood + "_idle", idle, 8, order=None)
        # hold the open frame, blink quickly, glance now and then
        sb.alias(mood + "_idle", [ids[0]] * 10 + [ids[1], ids[2], ids[1]] + [ids[0]] * 6 +
                 [ids[3]] * 4, 8)
        tids = sb.add(mood + "_talk", talk, 10, newrow=False)
        sb.alias(mood + "_talk", [tids[0], tids[1], tids[2], tids[1]], 10)
    hurt = [face("hurt", frame=f) for f in range(3)]
    sb.add("hurt", hurt, 12, loop=False)
    sheet, rows = sb.build()
    px.register_sheet("momo_face", "ui/momo_face.png", sheet, FW, FH, sb.cols, rows, sb.anims,
                      anchor=(0, 0), script=SCRIPT, screen_rect=[SX, SY, SW, SH],
                      notes="CRT bezel baked into every frame. Mood rows: calm, excited, "
                            "scared, sulky, confused (cols 0-3 idle open/half/closed/glance, "
                            "cols 4-6 talk), last row hurt flash. Idle anims repeat frames "
                            "to hold and blink. Turkish moods: sakin=calm, heyecanli=excited, "
                            "korkmus=scared, kuskun=sulky.",
                      mood_alias={"sakin": "calm", "heyecanli": "excited",
                                  "korkmus": "scared", "kuskun": "sulky"})
    px.register_image("momo_bezel", "ui/momo_bezel.png", BEZEL, script=SCRIPT,
                      screen_rect=[SX, SY, SW, SH],
                      notes="Bezel only, screen window transparent.")
    return sheet


if __name__ == "__main__":
    build()

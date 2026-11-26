"""Build registered, nearest-neighbor boss and rescue atlases from the local game art."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/art"
NEAREST = Image.Resampling.NEAREST

BOSS_STATES = ("entering", "armored", "charge", "firing", "recover", "phase", "defeated")


def make_boss_frame(source, kind, state):
    frame = Image.new("RGBA", (160, 120))
    normal = source.crop((512 * kind, 0, 512 * (kind + 1), 512))
    charged = source.crop((512 * kind, 512, 512 * (kind + 1), 1024))
    armored = charged if state in ("charge", "firing", "phase") else normal
    body = armored.resize((150, 114), NEAREST)
    frame.alpha_composite(body, (5, 3))
    draw = ImageDraw.Draw(frame)
    warm = ((242, 179, 85), (117, 211, 232))[kind]
    light = ((255, 235, 161), (206, 251, 255))[kind]
    armor = ((130, 91, 56), (99, 122, 144))[kind]
    deep = (21, 30, 45)
    if state in ("entering", "armored", "charge"):
        spread = 1 if state == "charge" else 0
        for direction in (-1, 1):
            x = 80 + direction * (8 + spread * 3)
            draw.polygon([(x - 7, 55), (x + 7, 55), (x + 9, 65), (x + 2, 72),
                          (x - 5, 69), (x - 9, 62)], fill=deep)
            draw.line([(x - 6, 56), (x + 6, 56), (x + 8, 64)], fill=armor, width=2)
    elif state in ("recover", "phase", "firing"):
        outer = 9 if state == "phase" else 7
        draw.polygon([(80, 61 - outer), (80 + outer, 61), (80, 61 + outer),
                      (80 - outer, 61)], fill=deep)
        draw.polygon([(80, 56), (86, 61), (80, 66), (74, 61)], fill=warm)
        draw.rectangle((78, 59, 82, 63), fill=light)
    if state in ("charge", "firing"):
        for x in (52, 108):
            radius = 6 if state == "firing" else 3
            draw.polygon([(x, 84 - radius), (x + radius, 84), (x, 84 + radius),
                          (x - radius, 84)], fill=warm)
            draw.rectangle((x - 1, 83, x + 1, 85), fill=light)
    if state == "phase":
        for x in (39, 119):
            draw.line([(x, 45), (x + 7, 51), (x + 1, 59)], fill=warm, width=2)
    if state == "entering":
        for x in (62, 98):
            draw.line([(x, 95), (x, 102), (x - 3, 106)], fill=deep, width=5)
            draw.line([(x, 97), (x, 102), (x - 3, 106)], fill=warm, width=2)
    if state == "defeated":
        draw.line([(76, 51), (85, 58), (77, 66), (88, 76)], fill=deep, width=3)
        draw.line([(76, 51), (85, 58), (77, 66), (88, 76)], fill=armor, width=1)
    return frame


def boss_atlas():
    source = Image.open(ART / "robots.png").convert("RGBA")
    atlas = Image.new("RGBA", (160 * len(BOSS_STATES), 240))
    for kind in range(2):
        for index, state in enumerate(BOSS_STATES):
            atlas.alpha_composite(make_boss_frame(source, kind, state), (index * 160, kind * 120))
    atlas.save(ART / "boss_0170.png", optimize=True)


def aion_atlas():
    source = Image.open(ROOT / "assets/sprites/aion_story.png").convert("RGBA")
    atlas = Image.new("RGBA", (288, 96))
    for frame, (source_frame, width, height) in enumerate(((2, 72, 54), (3, 79, 62), (0, 80, 74))):
        left = source_frame % 2 * 627
        top = source_frame // 2 * 627
        actor = source.crop((left + 38, top + 90, left + 538, top + 553))
        actor = actor.resize((width, height), NEAREST)
        foot_x = round((290 - 38) * width / 500)
        atlas.alpha_composite(actor, (frame * 96 + 48 - foot_x, 83 - height))
    atlas.save(ART / "aion_cliff_0170.png", optimize=True)


if __name__ == "__main__":
    boss_atlas()
    aion_atlas()

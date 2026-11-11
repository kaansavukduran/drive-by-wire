"""Signed-distance helpers for clean pixel silhouettes (negative = inside)."""
import math


def circle(cx, cy, r):
    return lambda x, y: math.hypot(x - cx, y - cy) - r


def ellipse(cx, cy, rx, ry):
    m = min(rx, ry)
    return lambda x, y: (math.hypot((x - cx) / rx, (y - cy) / ry) - 1.0) * m


def rbox(cx, cy, hw, hh, r=0.0):
    def f(x, y):
        qx = abs(x - cx) - (hw - r)
        qy = abs(y - cy) - (hh - r)
        return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r
    return f


def poly(points):
    """Convex or concave polygon SDF (exact, even-odd sign)."""
    pts = list(points)

    def f(x, y):
        d = 1e9
        inside = False
        n = len(pts)
        for i in range(n):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % n]
            ex, ey = bx - ax, by - ay
            wx, wy = x - ax, y - ay
            t = max(0.0, min(1.0, (wx * ex + wy * ey) / (ex * ex + ey * ey + 1e-12)))
            dx, dy = wx - ex * t, wy - ey * t
            d = min(d, dx * dx + dy * dy)
            if (ay > y) != (by > y):
                xi = ax + (y - ay) * ex / (ey + 1e-12)
                if x < xi:
                    inside = not inside
        d = math.sqrt(d)
        return -d if inside else d
    return f


def mirror_x(f):
    return lambda x, y: f(abs(x), y)


def union(*fs):
    return lambda x, y: min(f(x, y) for f in fs)


def smooth_union(k, *fs):
    def f(x, y):
        d = fs[0](x, y)
        for g in fs[1:]:
            e = g(x, y)
            h = max(0.0, min(1.0, 0.5 + 0.5 * (e - d) / k))
            d = e * (1 - h) + d * h - k * h * (1 - h)
        return d
    return f


def subtract(a, b):
    return lambda x, y: max(a(x, y), -b(x, y))


def intersect(a, b):
    return lambda x, y: max(a(x, y), b(x, y))


def grad(f, x, y, e=0.35):
    gx = f(x + e, y) - f(x - e, y)
    gy = f(x, y + e) - f(x, y - e)
    n = math.hypot(gx, gy) or 1.0
    return gx / n, gy / n


LIGHT = (-0.62, -0.78)   # light from upper-left (screen space, y down)


def lit(f, x, y):
    nx, ny = grad(f, x, y)
    return nx * LIGHT[0] + ny * LIGHT[1]


def shader(f, ramp, base, rim=2.2, hi=0.35, lo=-0.25, flat_hi=None):
    """Colour function: flat `base` index inside, rim pixels lit/shadowed by the
    surface normal. ramp is a list of palette colours dark->light."""
    def col(x, y):
        d = f(x, y)
        if d > -rim:
            l = lit(f, x, y)
            if l > hi:
                return ramp[min(len(ramp) - 1, base + 1)]
            if l < lo:
                return ramp[max(0, base - 1)]
            if d > -1.0 and l < 0.05:
                return ramp[max(0, base - 1)]
        if flat_hi and flat_hi(x, y):
            return ramp[min(len(ramp) - 1, base + 1)]
        return ramp[base]
    return col


def inside(f):
    return lambda x, y: f(x, y) < 0


def stamp(img, rows, x0, y0, key):
    """Draw a hand-pixelled map (list of strings) where key maps chars->colour."""
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            c = key.get(ch)
            if c is not None:
                img.putpixel((x0 + i, y0 + j), c) if 0 <= x0 + i < img.width and \
                    0 <= y0 + j < img.height else None

"""Draw DSU's proc arcs: Textures/ArcaneArc.tga (right of the caster) and its
mirror Textures/ArcaneArcLeft.tga (left), 256 x 256, 32-bit, top-left origin.

The art (John, 2026-11-18: "arcane energy bolts, kind of like blue/white
lightning"): crackling lightning along a crescent, three long bolts, forks
off the main one, a soft glow round each, and a faint haze along the whole
crescent. It is white, so Dyre's Toolkit tints it with each proc's color
(the StatusBar color). Our own art: nothing is copied from another AddOn.
It was the Toolkit's until John, 2026-11-18: "each client of the 'toolkit
platform' APIs could provide their own artwork"; then Mage Tools Forever's,
until John, 2026-11-18: "DSU is the right home for our 'spell activation
overlays'". DSU passes it to the Toolkit's RegisterProcs as its art
(Procs.lua).

The crescent keeps the ratios every proc art must keep (Dyre's Toolkit
Procs.lua, "Art"): the ring center 8/128 in from the flat side (CENTER_X),
118/128 of the height (OUTER_SPAN). The bolts stay within radii 178 to 236
of 256.

Each texture is SVG, rendered with headless Chrome (or Edge) at 4x on black
and on white; the two shots give the alpha. The output is the same on every
run (fixed seeds). Standard library only, plus Chrome. Run from the
repository root:

    python scripts/make_arcane_arcs.py                 # writes Textures/*.tga
    python scripts/make_arcane_arcs.py --preview DIR   # also PNG previews
"""

import argparse
import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIZE = 256
SUPER = 4
CENTER_X, CENTER_Y = SIZE * 8 / 128, SIZE / 2
MIN_R, MAX_R = 178, 236
SPAN = math.radians(33.5)
SEED = 1145
CHROMES = (r"C:\Program Files\Google\Chrome\Application\chrome.exe",
           r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
           "/usr/bin/google-chrome", "/usr/bin/chromium")


def bolt(rng, a0, a1, r0, r1, amp, levels=7):
    """Midpoint displacement between two points of the ring: (x, y) points."""
    points = [(a0, r0), (a1, r1)]
    for _ in range(levels):
        finer = []
        for (aa, ra), (ab, rb) in zip(points, points[1:]):
            finer.append((aa, ra))
            finer.append(((aa + ab) / 2 + rng.uniform(-1, 1) * (ab - aa) * 0.12,
                          (ra + rb) / 2 + rng.uniform(-1, 1) * amp))
        finer.append(points[-1])
        points = finer
        amp *= 0.55
    return [(CENTER_X + max(MIN_R, min(MAX_R, r)) * math.cos(a),
             CENTER_Y + max(MIN_R, min(MAX_R, r)) * math.sin(a)) for a, r in points]


def path(points):
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in points)


def lightning_svg(mirror):
    rng = random.Random(SEED)
    strokes = []  # (path, core width)
    main = bolt(rng, -SPAN, SPAN, 204, 204, 13)
    strokes.append((path(main), 3.6))
    for radius, width in ((194, 1.8), (218, 1.5), (206, 1.1)):
        strokes.append((path(bolt(rng, -SPAN * 0.93, SPAN * 0.9, radius, radius + 4, 16, 6)), width))
    for _ in range(14):  # forks off the main bolt
        x, y = main[rng.randrange(8, len(main) - 20)]
        a, r = math.atan2(y - CENTER_Y, x - CENTER_X), math.hypot(x - CENTER_X, y - CENTER_Y)
        out = rng.choice((-1, 1))
        length = rng.uniform(0.05, 0.11)
        fork = bolt(rng, a, a + length * rng.choice((-1, 1)), r, r + out * rng.uniform(14, 26), 5, 4)
        strokes.append((path(fork), rng.uniform(0.9, 1.4)))
    haze = path(bolt(random.Random(9), -SPAN, SPAN, 206, 206, 2, 3))
    body = [f'<path d="{haze}" stroke-width="30" opacity="0.22" filter="url(#haze)"/>']
    body += [f'<path d="{d}" stroke-width="{w * 6}" opacity="0.45" filter="url(#wide)"/>' for d, w in strokes]
    body += [f'<path d="{d}" stroke-width="{w * 2.8}" opacity="0.9" filter="url(#near)"/>' for d, w in strokes]
    body += [f'<path d="{d}" stroke-width="{w}"/>' for d, w in strokes]
    flip = f' transform="translate({SIZE},0) scale(-1,1)"' if mirror else ""
    area = f'filterUnits="userSpaceOnUse" x="0" y="0" width="{SIZE}" height="{SIZE}"'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE * SUPER}" height="{SIZE * SUPER}" '
            f'viewBox="0 0 {SIZE} {SIZE}"><defs>'
            f'<filter id="haze" {area}><feGaussianBlur stdDeviation="9"/></filter>'
            f'<filter id="wide" {area}><feGaussianBlur stdDeviation="5"/></filter>'
            f'<filter id="near" {area}><feGaussianBlur stdDeviation="1.4"/></filter>'
            '<linearGradient id="fade" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.12" stop-color="#fff"/>'
            '<stop offset="0.88" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>'
            f'</linearGradient><mask id="ends" maskUnits="userSpaceOnUse" x="0" y="0" width="{SIZE}" '
            f'height="{SIZE}"><rect width="{SIZE}" height="{SIZE}" fill="url(#fade)"/></mask></defs>'
            f'<g mask="url(#ends)"><g{flip} fill="none" stroke="#fff" stroke-linecap="round" '
            f'stroke-linejoin="round">{"".join(body)}</g></g></svg>')


def chrome():
    for candidate in (os.environ.get("CHROME"),) + CHROMES:
        if candidate and Path(candidate).is_file():
            return candidate
    sys.exit("No Chrome or Edge found; set CHROME to its path.")


def read_png(file):
    """8-bit RGB or RGBA, not interlaced (what Chrome writes): rows of RGB tuples."""
    data = file.read_bytes()
    pos, idat = 8, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and color in (2, 6) and interlace == 0, (depth, color, interlace)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    channels = 4 if color == 6 else 3
    raw, stride, rows, prev = zlib.decompress(idat), width * channels, [], bytearray(width * channels)
    for y in range(height):
        start = y * (stride + 1)
        kind, line = raw[start], bytearray(raw[start + 1:start + 1 + stride])
        for i in range(stride):
            left = line[i - channels] if i >= channels else 0
            up, corner = prev[i], prev[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + left) & 255
            elif kind == 2:
                line[i] = (line[i] + up) & 255
            elif kind == 3:
                line[i] = (line[i] + (left + up) // 2) & 255
            elif kind == 4:
                p = left + up - corner
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - corner)
                line[i] = (line[i] + (left if pa <= pb and pa <= pc else up if pb <= pc else corner)) & 255
        prev = line
        rows.append([tuple(line[j * channels:j * channels + 3]) for j in range(width)])
    return rows


def render(svg, work):
    """The SVG on black and on white, averaged SUPER x SUPER: rows of RGBA floats."""
    shots = []
    for name, background in (("black", "#000"), ("white", "#fff")):
        page, png = work / f"{name}.html", work / f"{name}.png"
        page.write_text(f'<html><body style="margin:0;background:{background}">{svg}</body></html>',
                        encoding="utf-8")
        subprocess.run([chrome(), "--headless=new", "--hide-scrollbars", "--disable-gpu",
                        "--force-device-scale-factor=1", f"--window-size={SIZE * SUPER},{SIZE * SUPER}",
                        f"--screenshot={png}", page.as_uri()], check=True, capture_output=True)
        shots.append(read_png(png))
    black, white = shots
    texture = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            color, alpha = [0.0, 0.0, 0.0], 0.0
            for sy in range(SUPER):
                for sx in range(SUPER):
                    b, w = black[y * SUPER + sy][x * SUPER + sx], white[y * SUPER + sy][x * SUPER + sx]
                    alpha += max(0.0, min(1.0, 1 - sum(w[c] - b[c] for c in range(3)) / 765))
                    for c in range(3):
                        color[c] += b[c] / 255  # on black: the color times its alpha
            alpha /= SUPER * SUPER
            row.append(tuple(min(1.0, v / SUPER / SUPER / alpha) if alpha > 0.002 else 0.0 for v in color)
                       + (alpha,))
        texture.append(row)
    return texture


def write_tga(file, texture):
    header = bytes((0, 0, 2)) + bytes(9) + struct.pack("<HH", SIZE, SIZE) + bytes((32, 0x28))
    body = bytearray()
    for row in texture:
        for r, g, b, a in row:
            body += bytes((round(b * 255), round(g * 255), round(r * 255), round(a * 255)))
    file.write_bytes(header + bytes(body))


def write_preview(file, texture, tint):
    """The texture tinted, over a dark background, as PNG."""
    rows = []
    for row in texture:
        line = bytearray(b"\x00")
        for r, g, b, a in row:
            line += bytes(int(30 * (1 - a) + 255 * v * t * a) for v, t in zip((r, g, b), tint))
        rows.append(bytes(line))
    chunk = lambda kind, data: (struct.pack(">I", len(data)) + kind + data
                                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))
    file.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--preview", type=Path, help="also write PNG previews here")
    parser.add_argument("--out", type=Path, default=ROOT / "Textures", help="where to write the TGAs")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        for name, mirror in (("ArcaneArc", False), ("ArcaneArcLeft", True)):
            texture = render(lightning_svg(mirror), Path(temp))
            write_tga(args.out / f"{name}.tga", texture)
            if args.preview:
                args.preview.mkdir(parents=True, exist_ok=True)
                write_preview(args.preview / f"{name}.png", texture, (0.62, 0.8, 1.0))
            print(f"{args.out / name}.tga")


if __name__ == "__main__":
    main()

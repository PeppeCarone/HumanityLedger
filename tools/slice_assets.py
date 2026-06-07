"""Slice the source _sheets into game-ready assets.

- 8 stat icons from icone_stats.png (light checkerboard cleared, square padded)
- era backgrounds from tilemap_ere1e2.png + main_menu_bg.png
- 8 event illustrations from scenari_catastrofi.png (label bands cropped out)
- 6 ending vignettes from trasformazioni_mondo.png (label corner cropped out)

Run from project root:  python tools/slice_assets.py
"""
from PIL import Image
from collections import deque
import os

SHEETS = "Assets/art/_sheets"
UI = "Assets/art/ui"


def light_checker(p):
    r, g, b = p[0], p[1], p[2]
    return abs(r - g) <= 10 and abs(g - b) <= 10 and abs(r - b) <= 10 and min(r, g, b) >= 190


def flood_clear_light(im):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q += [(x, 0), (x, h - 1)]
    for y in range(h):
        q += [(0, y), (w - 1, y)]
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if light_checker(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return im


def square_pad(im, pad=6):
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    w, h = im.size
    side = max(w, h) + pad * 2
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - w) // 2, (side - h) // 2), im)
    return canvas


def slice_stat_icons():
    src = Image.open(os.path.join(SHEETS, "icone_stats.png")).convert("RGB")
    xs = [14, 141, 265, 390]
    ys = [18, 153]
    cw, ch = 115, 114
    names = [
        ["militare", "tesoro", "diplomazia", "scienza"],
        ["legge", "spionaggio", "popolo", "costruzione"],
    ]
    out = "Assets/art/stats"
    os.makedirs(out, exist_ok=True)
    for r, y in enumerate(ys):
        for c, x in enumerate(xs):
            cell = src.crop((x, y, x + cw, y + ch))
            cell = flood_clear_light(cell)
            cell = square_pad(cell)
            cell.save(os.path.join(out, names[r][c] + ".png"))
    print("stat icons -> Assets/art/stats/ (8)")


def slice_backgrounds():
    out = "Assets/art/backgrounds"
    os.makedirs(out, exist_ok=True)
    tm = Image.open(os.path.join(SHEETS, "tilemap_ere1e2.png")).convert("RGB")
    tm.crop((46, 14, 330, 250)).save(os.path.join(out, "era1_caverna.png"))
    tm.crop((470, 10, 850, 250)).save(os.path.join(out, "era1_pitture.png"))
    mb = Image.open(os.path.join(UI, "main_menu_bg.png")).convert("RGB")
    mb.crop((650, 26, 1016, 300)).save(os.path.join(out, "era2_citta.png"))
    print("backgrounds -> Assets/art/backgrounds/ (3)")


def slice_events():
    out = "Assets/art/eventi"
    os.makedirs(out, exist_ok=True)
    src = Image.open(os.path.join(SHEETS, "scenari_catastrofi.png")).convert("RGB")
    cw, ch = 256, 279
    inset = (16, 44, 16, 44)  # l, t, r, b -> drops top+bottom baked labels
    names = [
        ["famine", "plague", "rebellion", "assassination"],
        ["summit", "scienza", "conflitto_religioso", "crisi_economica"],
    ]
    for r in range(2):
        for c in range(4):
            x0, y0 = c * cw, r * ch
            cell = src.crop((x0 + inset[0], y0 + inset[1], x0 + cw - inset[2], y0 + ch - inset[3]))
            cell.save(os.path.join(out, names[r][c] + ".png"))
    print("event illustrations -> Assets/art/eventi/ (8)")


def _gray_bg(p):
    r, g, b = p[0], p[1], p[2]
    return abs(r - 127) <= 24 and abs(g - 127) <= 24 and abs(b - 127) <= 24 and max(abs(r - g), abs(g - b), abs(r - b)) <= 16


def _flood_clear_gray(im):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q += [(x, 0), (x, h - 1)]
    for y in range(h):
        q += [(0, y), (w - 1, y)]
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if _gray_bg(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return im


def slice_ambasciatori():
    out = "Assets/art/ambasciatori"
    os.makedirs(out, exist_ok=True)
    src = Image.open(os.path.join(SHEETS, "npc_portraits.png")).convert("RGB")
    # npc_portraits is a 10x4 grid on a flat gray (127) background, names baked under each face.
    picks = {
        "impero_sole": (18, 433, 106, 532),
        "lega_coste": (123, 433, 205, 532),
        "clan_bisonte": (722, 24, 803, 126),
        "popolo_nebbie": (625, 24, 704, 126),
    }
    for civ_id, box in picks.items():
        cell = src.crop(box)
        cell = _flood_clear_gray(cell)
        bbox = cell.getbbox()
        if bbox:
            cell = cell.crop(bbox)
        cell.save(os.path.join(out, civ_id + ".png"))
    print("ambasciatori -> Assets/art/ambasciatori/ (4)")


def _checker_mid(p):
    r, g, b = p[0], p[1], p[2]
    avg = (r + g + b) / 3
    return max(r, g, b) - min(r, g, b) <= 18 and 116 <= avg <= 210


def _flood_clear(im, pred):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q += [(x, 0), (x, h - 1)]
    for y in range(h):
        q += [(0, y), (w - 1, y)]
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if pred(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return im


def slice_panel_frame():
    out = "Assets/art/ui"
    src = Image.open(os.path.join(UI, "menu_buttons.png")).convert("RGB")
    # middle-column, middle-row: clean rectangular double-border frame with parchment fill
    cell = src.crop((357, 193, 666, 372))
    cell = _flood_clear(cell, _checker_mid)
    bbox = cell.getbbox()
    if bbox:
        cell = cell.crop(bbox)
    cell.save(os.path.join(out, "panel_frame.png"))
    # border-only variant: flood the cream parchment center to transparent so a
    # dark interior shows through (keeps light HUD text readable).
    border = cell.convert("RGBA")
    w, h = border.size
    px = border.load()

    def is_parchment(p):
        r, g, b, a = p
        return a > 0 and r >= 172 and r >= g >= b and (r + g + b) / 3 >= 150

    seen = [[False] * w for _ in range(h)]
    q = deque([(w // 2, h // 2)])
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if is_parchment(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    border.save(os.path.join(out, "panel_border.png"))
    print("panel frame -> Assets/art/ui/panel_frame.png + panel_border.png", cell.size)


def slice_finali():
    out = "Assets/art/finali"
    os.makedirs(out, exist_ok=True)
    src = Image.open(os.path.join(SHEETS, "trasformazioni_mondo.png")).convert("RGB")
    cw, ch = 341, 279
    inset = (8, 52, 8, 8)  # drop top label corner
    names = [
        ["guerra", "prosperita", "scienza"],
        ["alleanza", "industria", "futura"],
    ]
    for r in range(2):
        for c in range(3):
            x0, y0 = c * cw, r * ch
            cell = src.crop((x0 + inset[0], y0 + inset[1], x0 + cw - inset[2], y0 + ch - inset[3]))
            cell.save(os.path.join(out, names[r][c] + ".png"))
    print("ending vignettes -> Assets/art/finali/ (6)")


if __name__ == "__main__":
    slice_stat_icons()
    slice_backgrounds()
    slice_events()
    slice_finali()
    slice_ambasciatori()
    print("done")

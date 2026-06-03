"""Re-crop Era 1 portraits from consiglieri.png:
- crop the 8 top-row cells (128x279 grid)
- flood-fill the baked checkerboard background to transparent from the borders
- strip the baked caption band at the bottom
- tight-crop to the figure alpha bbox
Outputs to tools/_out/ for preview; promotion to Assets/ is a separate step.
"""
from PIL import Image
from collections import deque
import os

SHEET = "Assets/art/_sheets/consiglieri.png"
OUT = "tools/_out"
# (row, col) -> (subdir, filename). Top row = Era 1 paleo, bottom row = Era 2 mitico.
TARGETS = {
    (0, 0): ("era1_paleo", "cacciatore_brann.png"),
    (0, 1): ("era1_paleo", "tesoriere_vesha.png"),
    (0, 2): ("era1_paleo", "diplomatico_orm.png"),
    (0, 3): ("era1_paleo", "sciamana_lyssa.png"),
    (0, 4): ("era1_paleo", "anziano_murr.png"),
    (0, 5): ("era1_paleo", "ombra_kael.png"),
    (0, 6): ("era1_paleo", "cantore_aru.png"),
    (0, 7): ("era1_paleo", "plasmatore_tev.png"),
    (1, 0): ("era2_mitico", "maresciallo_calden.png"),
    (1, 1): ("era2_mitico", "cancelliere_vorrik.png"),
    (1, 2): ("era2_mitico", "ambasciatrice_sereth.png"),
    (1, 3): ("era2_mitico", "alchimista_iove.png"),
    (1, 4): ("era2_mitico", "giurista_maren.png"),
    (1, 5): ("era2_mitico", "corvo_saekh.png"),
    (1, 6): ("era2_mitico", "tribuno_karro.png"),
    (1, 7): ("era2_mitico", "architetta_lena.png"),
}


def is_checker(p):
    r, g, b, a = p
    if a == 0:
        return True
    # two greys ~ (99,99,95) and (143,143,141): near-grey, low saturation, mid brightness
    if abs(r - g) <= 16 and abs(g - b) <= 20 and abs(r - b) <= 22:
        mx, mn = max(r, g, b), min(r, g, b)
        if mx - mn <= 22 and 78 <= r <= 170:
            return True
    return False


def flood_clear(im):
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if is_checker(px[x, y]):
            px[x, y] = (0, 0, 0, 0)
            q.append((x + 1, y)); q.append((x - 1, y))
            q.append((x, y + 1)); q.append((x, y - 1))
    return im


def strip_caption(im):
    """After flood clear, remove the bottom caption band: find the transparent gap
    separating the big figure blob from the small caption text near the bottom.
    Only searches the very bottom of the cell so mid-figure gaps are not cut."""
    w, h = im.size
    px = im.load()
    opaque = [sum(1 for x in range(w) if px[x, y][3] > 40) for y in range(h)]
    start = int(h * 0.84)
    gap_row = None
    run = 0
    for y in range(start, h):
        if opaque[y] <= 2:
            run += 1
            if run >= 3:
                gap_row = y - run + 1
                break
        else:
            run = 0
    if gap_row is not None:
        for y in range(gap_row, h):
            for x in range(w):
                px[x, y] = (0, 0, 0, 0)
    return im


def extract_tev_face(sheet):
    """Col 7 is a 2x3 grid of face thumbnails, not a full figure.
    Take the top-left face as the Shaper portrait."""
    cell = sheet.crop((7 * 128, 0, 8 * 128, 279)).copy()
    face = cell.crop((4, 12, 64, 96)).copy()
    face = flood_clear(face)
    bbox = face.getbbox()
    if bbox:
        face = face.crop(bbox)
    return face


def main():
    im = Image.open(SHEET).convert("RGBA")
    w, h = im.size
    cw, ch = w // 8, h // 2
    for (r, c), (subdir, name) in TARGETS.items():
        if r == 0 and c == 7:
            cell = extract_tev_face(im)
        else:
            cell = im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).copy()
            cell = flood_clear(cell)
            cell = strip_caption(cell)
            bbox = cell.getbbox()
            if bbox:
                cell = cell.crop(bbox)
        outdir = os.path.join(OUT, subdir)
        os.makedirs(outdir, exist_ok=True)
        cell.save(os.path.join(outdir, name))
        print(f"{subdir}/{name:26s} -> {cell.size}")


if __name__ == "__main__":
    main()

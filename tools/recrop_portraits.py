"""Re-crop Era1+Era2 portraits from consiglieri.png con filtro componente-centrale.

Migliora decrop_portraits.py: dopo il flood-fill del checkerboard, tiene SOLO le
componenti connesse che toccano la fascia verticale centrale della cella (il
soggetto), scartando i frammenti dei vicini che sconfinano dai lati. Cosi' i bleed
tipo il secondo volto in ombra_kael spariscono - SE c'e' un gap di sfondo. Se il
vicino e' attaccato al soggetto, resta (= serve rigenerare quel ritratto).

Output in tools/_out_recrop/ per valutazione; la promozione in Assets/ e' separata.
"""
from PIL import Image
from collections import deque
import numpy as np
from scipy import ndimage
import os

SHEET = "Assets/art/_sheets/consiglieri.png"
OUT = "tools/_out_recrop"

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
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
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


def keep_center_component(im):
    """Tiene solo le componenti connesse opache che intersecano la fascia centrale.
    Restituisce (im_pulita, n_componenti_scartate, frazione_pixel_scartati)."""
    w, h = im.size
    arr = np.array(im)
    alpha = arr[:, :, 3] > 40
    # dilata leggermente per unire parti dello stesso soggetto separate da contorni scuri
    structure = np.ones((3, 3), dtype=bool)
    labels, n = ndimage.label(alpha, structure=structure)
    if n == 0:
        return im, 0, 0.0
    cx0, cx1 = int(w * 0.34), int(w * 0.66)
    keep = set()
    for lab in range(1, n + 1):
        ys, xs = np.where(labels == lab)
        if xs.size < 30:
            continue
        # tieni se il blob ha massa nella fascia centrale
        if np.any((xs >= cx0) & (xs <= cx1)):
            keep.add(lab)
    if not keep:
        # nessuna massa centrale: tieni il blob piu' grande
        sizes = ndimage.sum(np.ones_like(labels), labels, range(1, n + 1))
        keep = {int(np.argmax(sizes)) + 1}
    mask_keep = np.isin(labels, list(keep))
    total_op = int(alpha.sum())
    dropped_px = int(alpha.sum() - mask_keep.sum())
    arr[~mask_keep] = (0, 0, 0, 0)
    out = Image.fromarray(arr, "RGBA")
    n_dropped = n - len(keep)
    frac = dropped_px / total_op if total_op else 0.0
    return out, n_dropped, frac


def strip_caption(im):
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


def main():
    im = Image.open(SHEET).convert("RGBA")
    w, h = im.size
    cw, ch = w // 8, h // 2
    print(f"sheet {w}x{h}  cella {cw}x{ch}")
    for (r, c), (subdir, name) in sorted(TARGETS.items()):
        cell = im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).copy()
        cell = flood_clear(cell)
        cell = strip_caption(cell)
        cell, n_drop, frac = keep_center_component(cell)
        bbox = cell.getbbox()
        if bbox:
            cell = cell.crop(bbox)
        outdir = os.path.join(OUT, subdir)
        os.makedirs(outdir, exist_ok=True)
        cell.save(os.path.join(outdir, name))
        flag = "  <-- vicino attaccato?" if frac > 0.25 else ""
        print(f"{subdir}/{name:26s} -> {str(cell.size):12s} scartati {n_drop} blob, {frac*100:4.1f}%{flag}")


if __name__ == "__main__":
    main()

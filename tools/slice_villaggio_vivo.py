#!/usr/bin/env python
# Slicer per gli asset "Villaggio Vivo" (P11). Affetta gli sheet Lovable in crop
# numerati (reading order) + un contact sheet di verifica. La rinomina/smistamento
# ai nomi-file finali e' lo step successivo (slice -> verifica -> smista).
import os
from PIL import Image, ImageDraw
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "Assets")
OUT = os.path.join(ROOT, "tools", "_out")

# sorgente UUID -> (chiave, metodo maschera). 'alpha' = RGBA vera; 'luma' = RGB su nero.
SOURCES = {
    "c3084a7a-f920-46b4-9a3e-28db0de81820.png": ("11a_deco_era1", "alpha"),
    "c4d9bd7e-5559-4d52-acf2-e8c540387e96.png": ("11b_deco_era2", "alpha"),
    "6ac18b96-7d87-4dd6-bd32-79ce4659fc31.png": ("11c_vita_era1", "alpha"),
    "1407226a-ea58-4ab2-9c74-703b881e54e5.png": ("11d_vita_era2", "alpha"),
    "534cd20b-453f-4fc3-80a0-9f581b449331.png": ("11g_acqua", "alpha"),
    "b4f11a2d-df9e-4a7b-8e7e-d56e332d363d.png": ("11e_atmosfera", "luma"),
    "b712220f-94e1-4cde-99da-5f09831ea7c9.png": ("11f_meteo", "luma"),
}


def mask_of(im, metodo):
    if metodo == "alpha" and "A" in im.getbands():
        return np.array(im.getchannel("A"))
    return np.array(im.convert("L"))


def runs(pres, min_gap):
    # Segmenti di "contenuto" lungo un asse, fondendo i buchi piu' piccoli di min_gap.
    idx = np.where(pres)[0]
    if len(idx) == 0:
        return []
    segs = [[int(idx[0]), int(idx[0])]]
    for k in idx[1:]:
        if k - segs[-1][1] <= min_gap:
            segs[-1][1] = int(k)
        else:
            segs.append([int(k), int(k)])
    return segs


# Override per sheet che si fondono (deco: ombre tenui fanno da ponte -> soglia alpha alta).
PARAMS = {
    "11a_deco_era1": dict(thr=120, min_gap=12, min_px=5, pad=10),
    "11b_deco_era2": dict(thr=120, min_gap=12, min_px=5, pad=10),
}


def slice_sheet(path, metodo, thr=12, min_gap=26, min_px=4, pad=6):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    content = mask_of(im, metodo) > thr
    crops = []
    for (y0, y1) in runs(content.sum(axis=1) > min_px, min_gap):
        sub = content[y0:y1 + 1]
        for (x0, x1) in runs(sub.sum(axis=0) > min_px, min_gap):
            cell = content[y0:y1 + 1, x0:x1 + 1]
            ys = np.where(cell.any(axis=1))[0]
            xs = np.where(cell.any(axis=0))[0]
            if len(ys) == 0 or len(xs) == 0:
                continue
            bx0 = max(0, x0 + int(xs[0]) - pad)
            by0 = max(0, y0 + int(ys[0]) - pad)
            bx1 = min(W - 1, x0 + int(xs[-1]) + pad)
            by1 = min(H - 1, y0 + int(ys[-1]) + pad)
            crop = im.crop((bx0, by0, bx1 + 1, by1 + 1))
            if metodo == "luma":
                crop.putalpha(crop.convert("L"))  # nero -> trasparente (overlay/particelle)
            crops.append(crop)
    return crops


# Sheet a griglia regolare (righe troppo vicine per la ghigliottina): taglio fisso + tight-crop.
GRID = {"11a_deco_era1": (3, 3)}


def grid_slice(path, rows, cols, thr=40, pad=8):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    a = np.array(im.getchannel("A"))
    cw, ch = W // cols, H // rows
    crops = []
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            x1 = W if c == cols - 1 else x0 + cw
            y1 = H if r == rows - 1 else y0 + ch
            sub = a[y0:y1, x0:x1] > thr
            ys = np.where(sub.any(axis=1))[0]
            xs = np.where(sub.any(axis=0))[0]
            if len(ys) == 0 or len(xs) == 0:
                continue
            bx0 = max(0, x0 + int(xs[0]) - pad)
            by0 = max(0, y0 + int(ys[0]) - pad)
            bx1 = min(W - 1, x0 + int(xs[-1]) + pad)
            by1 = min(H - 1, y0 + int(ys[-1]) + pad)
            crops.append(im.crop((bx0, by0, bx1 + 1, by1 + 1)))
    return crops


def contact(crops, key):
    if not crops:
        return
    cols = min(5, len(crops))
    rows = (len(crops) + cols - 1) // cols
    cell = 220
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (32, 30, 36, 255))
    d = ImageDraw.Draw(sheet)
    for i, c in enumerate(crops):
        cc = c.copy()
        cc.thumbnail((cell - 24, cell - 40))
        cx, cy = (i % cols) * cell, (i // cols) * cell
        sheet.alpha_composite(cc, (cx + 12, cy + 28))
        d.text((cx + 8, cy + 6), "#%d  %dx%d" % (i, c.size[0], c.size[1]),
               fill=(255, 220, 120, 255))
    sheet.convert("RGB").save(os.path.join(OUT, key + "_contact.png"))


def main():
    for fn, (key, metodo) in SOURCES.items():
        p = os.path.join(ASSETS, fn)
        if not os.path.exists(p):
            print("MISSING", fn)
            continue
        d = os.path.join(OUT, key)
        os.makedirs(d, exist_ok=True)
        if key in GRID:
            crops = grid_slice(p, *GRID[key])
        else:
            crops = slice_sheet(p, metodo, **PARAMS.get(key, {}))
        for i, c in enumerate(crops):
            c.save(os.path.join(d, "%02d.png" % i))
        contact(crops, key)
        print(key, "->", len(crops), "crops")


if __name__ == "__main__":
    main()

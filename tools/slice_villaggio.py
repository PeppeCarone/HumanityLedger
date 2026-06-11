"""Affetta gli sheet edifici-villaggio (Lovable, alpha vera) in sprite singoli.

Estrae le 6 componenti connesse piu' grandi da ogni sheet, in ordine row-major,
le ridimensiona con un fattore UNICO per sheet (preserva le proporzioni relative)
e salva in Assets/art/villaggio/era<N>/NN.png. Genera contact sheet di verifica.

Inoltre smista gli sfondi jpg: attenua la firma incisa sull'accampamento.
"""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SHEETS = {
    1: "Assets/art/_sheets/villaggio_era1.png",
    2: "Assets/art/_sheets/villaggio_era2.png",
}
BGS = {
    "era1_accampamento.jpg": "Assets/art/_sheets/bg_era1_accampamento_src.jpg",
    "era1_caverna.jpg": "Assets/art/_sheets/bg_era1_caverna_src.jpg",
}
OUT_DIR = "Assets/art/villaggio/era%d"
BG_DIR = "Assets/art/backgrounds"
PREVIEW = "tools/_preview"
MAX_H = 280  # altezza del piu' alto sprite dopo il resize


def slice_sheet(era: int, path: str, dilatazione: int = 14) -> None:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    mask = arr[:, :, 3] > 8
    big = ndimage.binary_dilation(mask, iterations=dilatazione)
    lab, n = ndimage.label(big)
    sizes = ndimage.sum(mask, lab, index=range(1, n + 1))
    keep = (np.argsort(sizes)[::-1][:6] + 1).tolist()
    boxes = ndimage.find_objects(lab)
    comps = []
    for k in keep:
        sl = boxes[k - 1]
        sub = arr[sl].copy()
        submask = (lab[sl] == k) & mask[sl]
        sub[:, :, 3] = np.where(submask, sub[:, :, 3], 0)
        ys, xs = np.where(submask)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        sub = sub[y0:y1, x0:x1]
        cy = sl[0].start + (y0 + y1) / 2
        cx = sl[1].start + (x0 + x1) / 2
        comps.append((cy, cx, sub))
    # ordine row-major: riga = sopra/sotto la mediana dei centri
    med_y = float(np.median([c[0] for c in comps]))
    comps.sort(key=lambda c: (0 if c[0] < med_y else 1, c[1]))
    fattore = MAX_H / max(c[2].shape[0] for c in comps)
    out = OUT_DIR % era
    os.makedirs(out, exist_ok=True)
    tiles = []
    for i, (_, _, sub) in enumerate(comps):
        img = Image.fromarray(sub)
        nw = max(1, round(img.width * fattore))
        nh = max(1, round(img.height * fattore))
        img = img.resize((nw, nh), Image.LANCZOS)
        img.save(os.path.join(out, "%02d.png" % i))
        tiles.append(img)
        print("era%d/%02d.png %dx%d" % (era, i, nw, nh))
    # contact sheet
    cw = sum(t.width for t in tiles) + 20 * (len(tiles) + 1)
    ch = MAX_H + 40
    cs = Image.new("RGBA", (cw, ch), (40, 40, 48, 255))
    x = 20
    for t in tiles:
        cs.paste(t, (x, ch - 20 - t.height), t)
        x += t.width + 20
    cs.save(os.path.join(PREVIEW, "cs_villaggio_era%d.png" % era))


def smista_sfondi() -> None:
    os.makedirs(BG_DIR, exist_ok=True)
    for nome, src in BGS.items():
        im = Image.open(src).convert("RGB")
        if nome == "era1_accampamento.jpg":
            # attenua la firma incisa in basso a destra: blur forte sulla zona
            box = (1650, 1005, 1920, 1080)
            patch = im.crop(box).filter(ImageFilter.GaussianBlur(14))
            im.paste(patch, box)
        im.save(os.path.join(BG_DIR, nome), quality=92)
        print("sfondo:", nome, im.size)


if __name__ == "__main__":
    os.makedirs(PREVIEW, exist_ok=True)
    # era2: torre e archivio sono vicini in verticale, dilatazione bassa per non fonderli
    slice_sheet(1, SHEETS[1], 14)
    slice_sheet(2, SHEETS[2], 4)
    smista_sfondi()
    print("fatto")

"""Integra il batch 2 Lovable: terreni-tabellone, citta' notturna, eventi
paleolitici (sheet 2x2), effetti conseguenza (alpha vera), icona spionaggio.

I sorgenti restano in Assets/art/_sheets/ con nomi parlanti.
"""
import os
import shutil
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = {
    "terreno_era1": "Assets/5bc94239-0a55-4ec3-88c4-27094c94da9c.jpg",
    "terreno_era2": "Assets/a4db35ab-69e0-41f1-a0d1-e892111f0758.jpg",
    "citta_notte": "Assets/46340233-9dba-485b-902e-6cbc36fda172.jpg",
    "eventi_era1": "Assets/ecbba295-d4b2-4fe0-8cbe-2b77d4038690.jpg",
    "fx_conseguenze": "Assets/91ae17a6-3cab-4e21-b00b-7602bdbc4e83.png",
    "icona_spionaggio": "Assets/f5c067bd-d84e-452c-b0c3-1cf27528e99f.png",
}
SHEETS = "Assets/art/_sheets"
PREVIEW = "tools/_preview"

# Nomi eventi nell'ordine row-major dello sheet 2x2
EVENTI = ["era1_inverno", "era1_confronto", "era1_trance", "era1_doni"]


def terreni() -> None:
    os.makedirs("Assets/art/terreni", exist_ok=True)
    for era in (1, 2):
        im = Image.open(SRC["terreno_era%d" % era]).convert("RGB")
        im.save("Assets/art/terreni/era%d.jpg" % era, quality=92)
        print("terreno era%d" % era, im.size)


def citta_notte() -> None:
    im = Image.open(SRC["citta_notte"]).convert("RGB")
    # firma incisa in basso a destra: blur
    box = (1700, 1010, 1920, 1080)
    im.paste(im.crop(box).filter(ImageFilter.GaussianBlur(12)), box)
    im.save("Assets/art/backgrounds/era2_citta_notte.jpg", quality=92)
    print("citta notturna", im.size)


def eventi() -> None:
    im = Image.open(SRC["eventi_era1"]).convert("RGB")
    w, h = im.size
    # quadranti 2x2 con cornice nera tra le celle: trim verso l'interno
    inset = 8
    celle = [
        (0, 0, w // 2, h // 2), (w // 2, 0, w, h // 2),
        (0, h // 2, w // 2, h), (w // 2, h // 2, w, h),
    ]
    for nome, (x0, y0, x1, y1) in zip(EVENTI, celle):
        sub = im.crop((x0 + inset, y0 + inset, x1 - inset, y1 - inset))
        sub.save("Assets/art/eventi/%s.png" % nome)
        print("evento", nome, sub.size)


def fx() -> None:
    os.makedirs("Assets/art/fx", exist_ok=True)
    im = Image.open(SRC["fx_conseguenze"]).convert("RGBA")
    arr = np.array(im)
    mask = arr[:, :, 3] > 8
    big = ndimage.binary_dilation(mask, iterations=10)
    lab, n = ndimage.label(big)
    sizes = ndimage.sum(mask, lab, index=range(1, n + 1))
    keep = (np.argsort(sizes)[::-1][:4] + 1).tolist()
    boxes = ndimage.find_objects(lab)
    comps = []
    for k in keep:
        sl = boxes[k - 1]
        sub = arr[sl].copy()
        submask = (lab[sl] == k) & mask[sl]
        sub[:, :, 3] = np.where(submask, sub[:, :, 3], 0)
        comps.append((sl[1].start, sub))
    comps.sort(key=lambda c: c[0])  # ordine sinistra->destra
    for i, (_, sub) in enumerate(comps):
        Image.fromarray(sub).save("Assets/art/fx/%02d.png" % i)
        print("fx %02d" % i, sub.shape[1], "x", sub.shape[0])


def spionaggio() -> None:
    im = Image.open(SRC["icona_spionaggio"]).convert("RGBA")
    im = im.resize((512, 512), Image.LANCZOS)
    im.save("Assets/art/strategie/spionaggio.png")
    print("icona spionaggio 512x512")


def archivia() -> None:
    for nome, src in SRC.items():
        if not os.path.exists(src):
            continue
        ext = os.path.splitext(src)[1]
        shutil.move(src, os.path.join(SHEETS, "batch2_%s%s" % (nome, ext)))
    print("sorgenti archiviati in _sheets/")


if __name__ == "__main__":
    terreni()
    citta_notte()
    eventi()
    fx()
    spionaggio()
    archivia()
    print("fatto")

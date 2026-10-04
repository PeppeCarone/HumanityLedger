"""Pulizia mirata dei ritratti consiglieri con difetti visibili (Docs/24).

La griglia uniforme di recrop_portraits.py (8 celle da 128px) taglia male due soggetti che
nel foglio `consiglieri.png` non stanno al centro della loro cella:

- **Murr** (anziano_murr): la cella prendeva a sinistra il bastone col teschio di cervo e la
  mano della Sciamana (cella accanto) e tagliava di ~30px il suo braccio destro.
- **Lyssa** (sciamana_lyssa): il suo bastone col teschio finiva nella cella di Murr.

Qui i due si ritagliano con una FINESTRA su misura (stessa pipeline: via la scacchiera,
via la didascalia, tieni le componenti centrali). Per **Lena** (architetta_lena) basta
togliere i frammenti staccati: la stella-filigrana del generatore e le lettere "Ar" della
didascalia "The Architect". Stesso trattamento per l'icona-strategia `pergamena` (in fondo
spuntava l'arco dell'oggetto sotto, nel foglio sorgente).

Esegui dalla radice del progetto:  python tools/fix_ritratti.py
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from recrop_portraits import SHEET, flood_clear, keep_center_component, strip_caption  # noqa: E402

# Finestre (x0, y0, x1, y1) nel foglio, misurate sui soggetti reali, e se pulire la
# scacchiera rimasta chiusa dentro la figura (solo dove serve: la tavoletta di pietra di
# Murr ha gli stessi due grigi e verrebbe bucata).
FINESTRE = {
    "Assets/art/era1_paleo/anziano_murr.png": ((550, 0, 690, 279), False),
    "Assets/art/era1_paleo/sciamana_lyssa.png": ((420, 0, 568, 279), True),
}
SOLO_FRAMMENTI = [
    "Assets/art/era2_mitico/architetta_lena.png",
    "Assets/art/strategie/pergamena.png",
]


def pulisci_scacchiera_chiusa(im):
    """Toglie la "finta trasparenza" rimasta CHIUSA dentro la figura (es. tra braccio e
    fianco), dove il flood-fill dai bordi non arriva. La scacchiera del foglio alterna due
    grigi neutri (~98 e ~147, quadri da ~8px): si azzerano solo le regioni di quei due toni
    che li contengono ENTRAMBI in buona parte, così pietre o barbe grigie restano intatte."""
    arr = np.array(im).astype(int)
    rgb = arr[:, :, :3]
    neutro = (rgb.max(axis=2) - rgb.min(axis=2)) <= 9
    v = rgb.mean(axis=2)
    scuro = neutro & (np.abs(v - 98) <= 11)
    chiaro = neutro & (np.abs(v - 147) <= 11)
    tono = (scuro | chiaro) & (arr[:, :, 3] > 0)
    lab, n = ndimage.label(tono)
    tolti = 0
    for i in range(1, n + 1):
        m = lab == i
        tot = int(m.sum())
        if tot < 30:
            continue
        fs = (scuro & m).sum() / tot
        if 0.25 <= fs <= 0.75:
            arr[m] = (0, 0, 0, 0)
            tolti += tot
    print(f"  scacchiera chiusa: {tolti} px")
    return Image.fromarray(arr.astype(np.uint8), "RGBA").copy()


def ritaglia(path, finestra, buchi):
    im = Image.open(SHEET).convert("RGBA").crop(finestra).copy()
    im = flood_clear(im)
    if buchi:
        im = pulisci_scacchiera_chiusa(im)
    im = strip_caption(im)
    im, n_drop, frac = keep_center_component(im)
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    im.save(path)
    print(f"{path}: {im.size}  scartati {n_drop} blob ({frac * 100:.1f}%)")


def togli_frammenti(path):
    """Tiene la componente opaca più grande (il soggetto) e azzera il resto; tela invariata."""
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    opaco = arr[:, :, 3] > 10
    lab, n = ndimage.label(opaco, structure=np.ones((3, 3), dtype=bool))
    if n <= 1:
        print(f"{path}: nessun frammento")
        return
    sizes = ndimage.sum(opaco, lab, range(1, n + 1))
    tieni = int(np.argmax(sizes)) + 1
    arr[(lab != tieni) & (lab > 0)] = (0, 0, 0, 0)
    Image.fromarray(arr, "RGBA").save(path)
    print(f"{path}: rimossi {n - 1} frammenti ({int(sizes.sum() - sizes.max())} px)")


def main():
    for path, (finestra, buchi) in FINESTRE.items():
        ritaglia(path, finestra, buchi)
    for path in SOLO_FRAMMENTI:
        togli_frammenti(path)


if __name__ == "__main__":
    main()

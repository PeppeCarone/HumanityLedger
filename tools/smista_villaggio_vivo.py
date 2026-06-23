#!/usr/bin/env python
# Smista i crop verificati (slice_villaggio_vivo.py) ai nomi-file finali che il codice
# carica (P11). Copia da tools/_out/<key>/NN.png a Assets/art/<percorso>/<nome>.png.
import os
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "_out")
ART = os.path.join(ROOT, "Assets", "art")

# key -> (cartella_dest, {indice_crop: nome_file})
MAP = {
    "11a_deco_era1": ("villaggio/deco/era1", {
        0: "masso", 1: "cespuglio", 2: "albero_secco", 3: "catasta",
        4: "ossa", 5: "pelli", 6: "idolo", 7: "erba"}),
    "11b_deco_era2": ("villaggio/deco/era2", {
        1: "casse", 2: "lampione", 3: "statua", 4: "fioriera",
        5: "panca", 6: "pozzo", 7: "carretto"}),
    "11c_vita_era1": ("villaggio/vita/era1", {
        0: "abitante1", 1: "abitante2", 2: "anziano", 3: "bambino",
        4: "cane", 5: "cervo", 6: "corvi"}),
    "11d_vita_era2": ("villaggio/vita/era2", {
        0: "mercante", 1: "guardia", 2: "studioso", 3: "bambino",
        4: "cavallo", 5: "colombe", 6: "gatto"}),
    "11f_meteo": ("fx/meteo", {
        0: "neve", 1: "brace", 2: "pioggia", 3: "foglia", 4: "lucciola"}),
    "11e_atmosfera": ("villaggio/atmosfera", {
        0: "raggi", 1: "nebbia", 2: "nuvole", 3: "cielo_notte", 4: "alone_alba"}),
}
# Acqua: crop -> percorsi specifici (ere diverse).
ACQUA = {0: "villaggio/deco/era1/pozza", 1: "villaggio/deco/era2/fontana_acqua"}


def place(src, dest_rel):
    dst = os.path.join(ART, dest_rel + ".png")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    print("->", dest_rel + ".png")


def main():
    n = 0
    for key, (folder, names) in MAP.items():
        for idx, nome in names.items():
            src = os.path.join(OUT, key, "%02d.png" % idx)
            if not os.path.exists(src):
                print("MISSING", key, idx)
                continue
            place(src, folder + "/" + nome)
            n += 1
    for idx, dest in ACQUA.items():
        src = os.path.join(OUT, "11g_acqua", "%02d.png" % idx)
        if os.path.exists(src):
            place(src, dest)
            n += 1
    print("TOTALE", n)


if __name__ == "__main__":
    main()

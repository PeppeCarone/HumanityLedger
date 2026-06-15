# Smista gli asset Lovable "era futura" droppati in Assets/ root nelle cartelle giuste.
import os
from PIL import Image

A = "Assets"
ART = "Assets/art"

def ensure(d):
    os.makedirs(d, exist_ok=True)

# 1) Ritratti futuri -> era3_futuro/
ensure(f"{ART}/era3_futuro")
ritratti = {
    "Consigliere_di_guerra_futuro.png": "consigliere_guerra.png",
    "Consigliere_futuro_o_moderno.png": "consigliere_moderno.png",
    "Ecologista.png": "ecologista.png",
    "Tecnico_futuro.png": "tecnico.png",
}
for src, dst in ritratti.items():
    Image.open(f"{A}/{src}").convert("RGBA").save(f"{ART}/era3_futuro/{dst}")
    os.remove(f"{A}/{src}")
    print("ritratto ->", dst)

# 2) Sfondi -> backgrounds/era3_*.jpg (photographic, jpg come era1)
ensure(f"{ART}/backgrounds")
sfondi = {
    "BG_Insediamento.png": "era3_insediamento.jpg",
    "BG_città_in_crescita.png": "era3_citta_crescita.jpg",
    "BG_Metropoli_futuristica.png": "era3_metropoli.jpg",
}
for src, dst in sfondi.items():
    Image.open(f"{A}/{src}").convert("RGB").save(f"{ART}/backgrounds/{dst}", quality=88)
    os.remove(f"{A}/{src}")
    print("sfondo ->", dst)

# 3) VFX cambio era -> fx/cambio_era.png
ensure(f"{ART}/fx")
Image.open(f"{A}/VFX Cambio Era.png").save(f"{ART}/fx/cambio_era.png")
os.remove(f"{A}/VFX Cambio Era.png")
print("vfx -> cambio_era.png")

# 4) Slicing sheet icone 192x128 RGBA, griglia 3 col x 2 righe (celle 64x64),
#    autocrop sull'alpha di ogni cella + padding.
def slice_icons(src, names, outdir, cols=3, rows=2):
    ensure(outdir)
    im = Image.open(f"{A}/{src}").convert("RGBA")
    w, h = im.size
    cw, ch = w // cols, h // rows
    pad = 2
    for i, name in enumerate(names):
        r, c = divmod(i, cols)
        cell = im.crop((c*cw, r*ch, c*cw+cw, r*ch+ch))
        bbox = cell.getbbox()  # bounding box dei pixel non trasparenti
        if bbox:
            x0 = max(0, bbox[0]-pad); y0 = max(0, bbox[1]-pad)
            x1 = min(cw, bbox[2]+pad); y1 = min(ch, bbox[3]+pad)
            cell = cell.crop((x0, y0, x1, y1))
        cell.save(f"{outdir}/{name}.png")
        print(f"icona -> {outdir}/{name}.png", cell.size)

slice_icons("Risorse_di_gioco.png",
    ["popolo", "prestigio", "ecologia", "legge", "mistero", "tecnologia"],
    f"{ART}/risorse_era3")
slice_icons("Decisioni_gioco.png",
    ["guerra", "diplomazia", "industria", "ecologia", "economia", "catastrofe"],
    f"{ART}/decisioni_era3")

# 5) Sorgenti sheet -> _sheets/ per provenienza
ensure(f"{ART}/_sheets")
for src in ["Risorse_di_gioco.png", "Decisioni_gioco.png"]:
    os.replace(f"{A}/{src}", f"{ART}/_sheets/{src}")
    print("sheet sorgente ->", src)

print("FATTO")

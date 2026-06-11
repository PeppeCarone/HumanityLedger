# 08 — Prompt asset (Lovable)

> Lista ordinata per impatto visivo. Generare con Lovable, droppare i file grezzi in `Assets/` root: lo slicing/integrazione avviene poi via tool Python (D036).
>
> **Regole valide per OGNI prompt** (incollarle in coda se il tool tende a sbagliare):
> - Stile unico del gioco: *painterly dark-fantasy epico, pennellate visibili, luce calda drammatica* (riferimento: lo sfondo del menu attuale).
> - NIENTE testo, etichette, scritte, watermark, firme, bordi decorativi.
> - Per gli sprite trasparenti: **vera trasparenza alpha, MAI sfondo a scacchiera dipinto** (problema ricorrente).
> - Sfondi: 1920×1080, niente figure umane in primissimo piano.

---

## P1 — Sfondi di scena (impatto massimo)

### 1. Accampamento Era 1 (MANCANTE — atti 2-3 si svolgono all'aperto ma si vede ancora la caverna)

```
Epic painterly dark-fantasy digital painting, 1920x1080. A paleolithic tribal camp
on an open plain at dusk, seen from a slight elevation. Hide tents and bone-framed
huts around a large central campfire, smoke rising into a dramatic amber-and-violet
sky, distant snowy mountains and the dark edge of a primeval forest. Warm firelight
against cold blue dusk. Visible brushstrokes, muted earthy palette, cinematic
lighting, atmospheric depth. No people in the foreground, no text, no watermark.
```

### 2. Caverna Era 1 (DEBOLE — l'attuale è roccia piatta e vuota)

```
Epic painterly dark-fantasy digital painting, 1920x1080. Interior of a vast
paleolithic cave lit by a central fire out of frame below: warm orange light dancing
on layered rock walls, faded ochre cave paintings of bison and hunters and one
strange faceless figure, stalactites, deep shadows receding into darkness at the
edges. Mysterious, sacred atmosphere. Visible brushstrokes, cinematic chiaroscuro,
high detail on the painted wall. No people, no text, no watermark.
```

### 3. Città Era 2 notturna (OPZIONALE — variante atto 3 per progressione visiva)

```
Epic painterly dark-fantasy digital painting, 1920x1080. A mythic fortified city on
a stone hill at night, seen from the walls: torchlit streets, a great temple and
foundry chimneys glowing ember-red, banners in the wind, full moon behind dramatic
clouds, mountains silhouetted. Tension before a great decision. Warm torch light
against deep blue night. Visible brushstrokes, cinematic, atmospheric. No people in
the foreground, no text, no watermark.
```

---

## P2 — Edifici del villaggio (il palco protagonista usa ritagli pensati per la mappa)

> Servono **sprite singoli, vista isometrica/tre-quarti, su sfondo trasparente**.
> Consegnare come sheet va bene, MA: elementi ben separati (almeno 60px di vuoto),
> nessuna piattaforma/base sotto gli edifici, nessuna etichetta.

### 4. Set edifici Era 1 — paleolitico (6 elementi)

```
Sprite sheet, 6 separate isolated isometric buildings on a fully transparent
background, generous spacing between them, painterly dark-fantasy style with warm
lighting, consistent scale and light direction (top-left). Paleolithic tribal
structures: (1) hide tent with wooden poles, (2) bone-and-hide hut, (3) carved
wooden totem with small fire offerings, (4) stone fire pit with cooking spit,
(5) wooden drying rack with hanging fish and hides, (6) defensive palisade segment
of sharpened logs. No ground platform under them, no checkerboard, no text,
no labels, no watermark.
```

### 5. Set edifici Era 2 — regno mitico (6 elementi)

```
Sprite sheet, 6 separate isolated isometric buildings on a fully transparent
background, generous spacing between them, painterly dark-fantasy style with warm
lighting, consistent scale and light direction (top-left). Mythic-medieval kingdom
structures: (1) stone temple with columns and brazier, (2) market hall with striped
awnings, (3) round watchtower with banner, (4) foundry with glowing chimney,
(5) stone wall segment with gate, (6) scholar's archive tower with bronze dome.
No ground platform under them, no checkerboard, no text, no labels, no watermark.
```

---

## P3 — Icone e token

### 6. Icona strategia Spionaggio (l'attuale faretra è un placeholder)

```
Single game icon on fully transparent background, 512x512, painterly dark-fantasy
style: a curved bronze-age dagger with a wrapped leather hilt, lying over a dark
hooded mask, subtle purple rim light, slight glow. Matches a set of hand-painted
strategy tokens (axe, book, scroll, shield). Centered, no background circle,
no checkerboard, no text, no watermark.
```

---

## P4 — Effetti conseguenza sul villaggio

### 7. Burst "mistero/religione" (la colonna Religion dello sheet conseguenze è inutilizzabile, fusa)

```
Sprite sheet, 4 separate isolated magical effect sprites on a fully transparent
background, painterly style, generous spacing: (1) rising swirl of deep red embers
and smoke, (2) soft violet glowing mist with faint star-like sparks, (3) golden
radiant halo burst seen slightly from above, (4) circle of small pale flames.
Semi-transparent gradients at the edges, no hard borders, no checkerboard, no text,
no watermark.
```

---

## P5 — Illustrazioni eventi Era 1 (le 8 attuali sono in stile medievale, anacronistiche nell'Era 1)

### 8. Eventi paleolitici (4 scene)

```
Sprite sheet, 4 separate framed event illustrations, each 16:9, arranged in a 2x2
grid with clear gaps, painterly dark-fantasy style, cinematic lighting. Paleolithic
scenes: (1) tribe huddling around a dying fire in a snowstorm, famine and cold,
(2) two tribal groups facing each other across a river at dawn, spears raised,
(3) a shaman in a trance before a glowing ochre cave painting, red firelight,
(4) tribesmen discovering strange carved bone gifts at the misty forest edge.
No text, no labels, no borders with writing, no watermark.
```

---

## Già a posto (NON rigenerare)

- Ritratti 16 consiglieri (post-recrop), ambasciatori, icone stat, artefatti Ledger
- Menu bg, logo, sfondo Era 2 diurno, 6 vignette finali (painterly 16:9)
- Mappa-mondo: 4 layer + insediamenti + rotte/zone pulite
- 4 icone strategia originali (ascia/libro/pergamena/scudo) + economico/decreto/rivoluzionaria

## Flusso di integrazione (per chi sviluppa)

1. File grezzi in `Assets/` root
2. Slicing con tool dedicato (`tools/slice_assets.py` o nuovo `slice_*.py`) + contact sheet di verifica
3. Smistamento in `Assets/art/<categoria>/` con nomi-convenzione
4. Wiring via `load("res://...")` negli script (mai uid nei .tscn)
5. Screenshot di verifica con `tools/shoot.tscn`

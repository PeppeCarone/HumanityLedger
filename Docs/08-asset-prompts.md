# 08 — Prompt asset (Lovable)

> Lista ordinata per impatto visivo. Generare con Lovable, droppare i file grezzi in `Assets/` root: lo slicing/integrazione avviene poi via tool Python (D036).
>
> **Regole valide per OGNI prompt** (incollarle in coda se il tool tende a sbagliare):
> - Stile unico del gioco: *painterly dark-fantasy epico, pennellate visibili, luce calda drammatica* (riferimento: lo sfondo del menu attuale).
> - NIENTE testo, etichette, scritte, watermark, firme, bordi decorativi.
> - Per gli sprite trasparenti: **vera trasparenza alpha, MAI sfondo a scacchiera dipinto** (problema ricorrente).
> - Sfondi: 1920×1080, niente figure umane in primissimo piano.

---

## P0 — Terreni-tabellone del villaggio (D046 — PRIORITÀ ASSOLUTA)

> Il villaggio è un board stile Clash of Clans: il terreno deve essere VUOTO,
> gli edifici li piazza il gioco. Vista rialzata a tre quarti.

### 0a. Terreno Era 1 — radura tribale

```
Epic painterly dark-fantasy digital painting, 1920x1080, view from an elevated
three-quarter angle like a strategy game board. A large EMPTY dirt-and-grass
clearing prepared for a tribal village: worn footpaths crossing the open ground,
a stone-ringed bare patch at the center, scattered rocks and tufts of grass,
a stream on one side. Forest edge and mountains only at the top 20% as horizon,
dusk light with warm tones. COMPLETELY EMPTY of buildings, tents, people or fires:
it is a game board waiting for buildings to be placed. No text, no watermark.
```

### 0b. Terreno Era 2 — spianata del regno

```
Epic painterly dark-fantasy digital painting, 1920x1080, view from an elevated
three-quarter angle like a strategy game board. A large EMPTY paved stone plateau
inside a mythic kingdom: a wide flagstone plaza with a circular emblem at the
center, low stone boundary walls at the edges, stairs on one side, braziers
unlit. City rooftops and mountains only at the top 20% as horizon, golden-hour
light. COMPLETELY EMPTY of buildings, market stalls or people: it is a game board
waiting for buildings to be placed. No text, no watermark.
```

> Integrazione: i file vanno (rinominati da me) in `Assets/art/terreni/era1.png` e
> `era2.png`; il codice li aggancia automaticamente (fallback attivo fino ad allora).

---

## P0b — Edifici per-stadio (D046 — villaggio migliorabile, GIÀ implementato)

> Il villaggio migliorabile è **già funzionante** con stelle di livello + scala via
> codice. Questi asset sono **opzionali e migliorativi**: se esistono, il codice
> sostituisce lo sprite quando l'edificio sale di livello (Lv2/Lv3). Il Lv1 è lo
> sprite base attuale in `Assets/art/villaggio/era<N>/`.
>
> **Convenzione di nome** (il codice li aggancia da solo, nessuna modifica necessaria):
> `Assets/art/villaggio/era<N>/<TT>_lv<L>.png` — `TT` = indice tipo a 2 cifre, `L` = 2 o 3.
>
> | Era 1 (TT) | Edificio | Era 2 (TT) | Edificio |
> |---|---|---|---|
> | 00 | Tenda | 00 | Tempio |
> | 01 | Capanna | 01 | Mercato |
> | 02 | Totem | 02 | Torre |
> | 03 | Focolare | 03 | Fonderia |
> | 04 | Essiccatoio | 04 | Mura |
> | 05 | Palizzata | 05 | Archivio |
>
> Esempio: la palizzata Era 1 migliorata a Lv2 → `Assets/art/villaggio/era1/05_lv2.png`.
> Regola visiva: **stessa identità, stessa posa, stessa scala/inquadratura** dello
> sprite Lv1, solo più sviluppato/ricco (così lo swap non "salta"). Sprite isometrico
> trasparente, ~256×256, stessa palette painterly bronzo/sepia degli edifici esistenti.

### Template (sostituisci le parti in MAIUSCOLO)

```
Isometric game building sprite, painterly dark-fantasy style, warm bronze-and-sepia
palette, visible brushstrokes, soft contact shadow, TRUE alpha transparency (NO
painted checkerboard), ~256px, centered, same camera angle and footprint as a base
village building. Subject: A NOME_EDIFICIO, DESCRIZIONE_DELLO_STADIO. No text,
no watermark, no background scene.
```

### Progressione consigliata per edificio (Lv1 base → Lv2 → Lv3)

**Era 1** — *tribale, legno/pelli/pietra grezza:*
- **Tenda**: pelli su pali → tenda più grande con secondo telo e fochetto → gruppo di tende con pellame appeso.
- **Capanna**: capanna di frasche → capanna di fango e legno con tetto solido → capanna ampliata con recinto.
- **Totem**: palo intagliato → totem alto dipinto con teschi → totem cerimoniale con offerte e bracieri.
- **Focolare**: cerchio di pietre col fuoco → focolare ampio con graticcio → grande braciere comunitario con pietre erette.
- **Essiccatoio**: rastrelliera di carne → essiccatoio coperto con più ripiani → magazzino-essiccatoio con scorte abbondanti.
- **Palizzata**: staccionata di pali → palizzata alta rinforzata con porta → bastione di pali e pietra con piattaforma di guardia.

**Era 2** — *mitico-medievale, pietra/metallo/stendardi:*
- **Tempio**: piccola cappella di pietra → tempio con colonne e fiamma sull'altare → grande tempio con cupola e bracieri.
- **Mercato**: bancarella → mercato coperto con più banchi e merci → loggia mercantile con stendardi e casse d'oro.
- **Torre**: torre di guardia bassa → torre più alta con feritoie e vedetta → alta torre di vedetta con fanali e bandiere.
- **Fonderia**: fucina con incudine → fonderia con altoforno fumante → grande fonderia con ingranaggi e colata.
- **Mura**: tratto di mura basse → mura merlate con camminamento → possenti mura con bastione e porta rinforzata.
- **Archivio**: scaffale di pergamene → archivio con scaffali e lettorino → grande biblioteca con tomi e simboli arcani luminosi.

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

## P6 — Icona artefatto: L'Occhio dello Spirito

Quarto artefatto del Ledger (gli altri 3 esistono già: corno, lacrima, pietra).
Oggi usa come placeholder il medaglione-spionaggio. Stessa resa degli artefatti
esistenti: oggetto singolo, painterly dark-fantasy, fondo scuro.

```
A single mystical artifact on a plain dark background: a polished crystal eye
the size of a river stone, amber-gold iris with a faint spiral inside, ancient
and slightly luminous, resting like an orb, painterly dark-fantasy style,
warm rim light, high detail, centered, no hands, no text, no watermark.
```

Dopo il drop: salvare come `Assets/art/ledger/occhio_dello_spirito.png` e
aggiornare il path icona in `data/artefatti/occhio_dello_spirito.tres`.

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

# 08 — Prompt asset (Lovable)

> Lista ordinata per impatto visivo. Generare con Lovable, droppare i file grezzi in `Assets/` root: lo slicing/integrazione avviene poi via tool Python (D036).
>
> **Regole valide per OGNI prompt** (incollarle in coda se il tool tende a sbagliare):
> - Stile unico del gioco: *painterly dark-fantasy epico, pennellate visibili, luce calda drammatica* (riferimento: lo sfondo del menu attuale).
> - NIENTE testo, etichette, scritte, watermark, firme, bordi decorativi.
> - Per gli sprite trasparenti: **vera trasparenza alpha, MAI sfondo a scacchiera dipinto** (problema ricorrente).
> - Sfondi: 1920×1080, niente figure umane in primissimo piano.

---

## STATO ASSET (aggiornato 2026-06-18)

Inventario reale di `Assets/art/`. **Generato (NON rigenerare):** UI-kit §P8 completo, edifici
per-stadio §P0b (Era 1+2, Lv1/2/3), terreni §P0, backgrounds (incl. Era 3), **Assedio Era 1**
(campo/roccaforte/enemy/4 `unit_*`/proiettili), 8 icone stat, 9 strategie, 4 artefatti (incl. Occhio),
mappa-mondo, 6 vignette finali, logo/menu, ritratti, ambasciatori.

**Tutto generato e integrato al 2026-06-18** (organizzati, importati, in uso a schermo):
boss Era 1 (mammut) + Era 2 (drago), Assedio Era 2 completo (campo/roccaforte painterly/enemy/4
unità), icone barra unità, nemici per-tipo Era 1 (iena/cinghiale/orso) + Era 2 (predone/scheletro/
minotauro/golem), cornici Assedio (`boss_bar`/`wave_banner`), icona Risorse, stendardo alleanza
(§P10), e rifiniture UI-kit (`ring_focus`/`plot_pad`/`chip_{ally,hostile,gold}`). Orientamento
verificato: difensori→DESTRA, nemici/boss→SINISTRA. Prompt qui sotto conservati come riferimento
per eventuali rigenerazioni.

> Nessun asset placeholder/"default" residuo nel flusso Assedio/villaggio. I prompt §P0–§P10
> restano archiviati: rigenerare solo se si vuole rifinire ulteriormente.

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

## P7 — L'Assedio: boss fight tower-defense (design in `Docs/11-boss-fight.md`)

> Battaglia **orizzontale**: villaggio a sinistra, nemici che entrano da destra e
> marciano verso sinistra, difensori schierati lungo le corsie. Tutti gli sprite sono
> **opzionali con fallback codice** (forme/sprite riusati finché non arrivano): il gioco
> è giocabile senza. Convenzione di nome (il codice li aggancia da solo):
>
> | Asset | Path | Quando |
> |---|---|---|
> | Sfondo campo | `Assets/art/siege/era<N>/campo.jpg` **o** `campo.png` (1920×1080) | **Fase B ✓** |
> | Roccaforte/villaggio (lato sx, guarda a destra) | `Assets/art/siege/era<N>/roccaforte.png` (trasparente) | **Fase B ✓** |
> | Unità/difensori — 4 archetipi | `…/era<N>/unit_tiratore.png` · `unit_bloccatore.png` · `unit_sciamano.png` · `unit_totem.png` | **Fase B ✓** |
> | Nemico generico (marciatore) | `Assets/art/siege/era<N>/enemy.png` (trasparente) | **Fase B ✓** |
> | Proiettili | `Assets/art/siege/fx/proiettile.png` · `proiettile_aoe.png` (trasparenti) | **Fase B ✓** |
> | Icone barra unità | `Assets/art/icons/siege/tiratore.png` · `bloccatore.png` · `sciamano.png` · `totem.png` | **Fase B ✓** |
> | Nemici per-tipo (lupo/orso/…) | `Assets/art/siege/era<N>/enemy_<nome>.png` (trasparente) | Fase D |
> | Boss | `Assets/art/siege/era<N>/boss.png` (trasparente, grande) | Fase C |
> | Barra HP boss / banner ondata | `Assets/art/siege/ui/boss_bar.png` · `wave_banner.png` | Fase C/D |
>
> **➜ Cosa cabla il codice ORA (Fase B):** le 6 righe marcate **✓**. Appena droppi un PNG
> con quel nome esatto nella cartella, l'Assedio lo usa **automaticamente**; se manca, resta
> l'arte-codice attuale (fallback, già funzionante). Genera per primi **`campo`** e
> **`roccaforte`** (impatto massimo), poi le 4 **`unit_*`** e **`enemy`**.
>
> **Orientamento (importante per chi genera)**: i **nemici e il boss guardano a
> SINISTRA** (marciano verso il villaggio); i **difensori guardano a DESTRA** (verso i
> nemici in arrivo). Vista laterale leggermente dall'alto (3/4 di lato), così le corsie
> si leggono in profondità.

### 7a. Sfondo campo — Era 1 (paleolitico)

```
Epic painterly dark-fantasy digital painting, 1920x1080, horizontal side-scrolling
battlefield seen from a slight elevated 3/4 side angle. LEFT edge: a fortified
paleolithic village gate of sharpened logs and stone, hinted but mostly off-frame.
CENTER and RIGHT: an open muddy plain at dusk with worn lanes leading toward the
village, scattered boulders, bone totems, patches of dry grass, a dark primeval
forest and snowy mountains on the far right horizon as the enemy approach. Stormy
amber-and-violet sky, cold light, tension before an attack. COMPLETELY EMPTY of
creatures, soldiers and people: it is a battle stage. Visible brushstrokes,
cinematic, atmospheric depth. No text, no watermark.
```

### 7b. Sfondo campo — Era 2 (regno mitico)

```
Epic painterly dark-fantasy digital painting, 1920x1080, horizontal side-scrolling
battlefield seen from a slight elevated 3/4 side angle. LEFT edge: the great stone
gate and battlemented walls of a mythic kingdom, banners on poles, braziers, hinted
at the frame edge. CENTER and RIGHT: a wide field of trampled earth and flagstone
roads leading to the gate, broken statues, scorched ground, a blood-red sky over
distant mountains where the enemy host gathers on the right. Dramatic stormy light,
ember glow. COMPLETELY EMPTY of creatures and soldiers: it is a battle stage.
Visible brushstrokes, cinematic, atmospheric depth. No text, no watermark.
```

### 7c. Roccaforte / villaggio (lato sinistro, sprite trasparente)

```
Isometric/3-quarter-side game sprite, painterly dark-fantasy, warm bronze-and-sepia
palette, visible brushstrokes, soft contact shadow, TRUE alpha transparency (NO
painted checkerboard), tall format ~512x768, FACING RIGHT (the gate opens toward the
battlefield on the right). Subject: ERA_DESCRIPTION fortified settlement gate with
defensive wall. ERA1 = sharpened-log palisade gate with a watch platform and hide
banners. ERA2 = battlemented stone gatehouse with bronze-bound doors and kingdom
banners. No text, no watermark, no background scene.
```

### 7d. Nemici — set Era 1 (sprite sheet trasparente, **guardano a sinistra**)

```
Sprite sheet, 4 separate isolated creature sprites on a fully transparent background,
generous spacing, painterly dark-fantasy style, warm dramatic lighting, consistent
scale and light direction, side view ALL FACING LEFT (charging left), TRUE alpha
transparency (NO checkerboard). Paleolithic predators: (1) lean grey dire wolf
snarling, (2) spotted cave hyena, (3) tusked wild boar charging, (4) young cave bear
on all fours. Each as a single isolated full-body sprite, soft contact shadow.
No ground platform, no text, no labels, no watermark.
```
> **Per la Fase B** serve un solo marciatore generico: esporta il **lupo (1)** come
> `era1/enemy.png`. Gli altri 3 ritagli diventano `enemy_<nome>.png` in Fase D.

### 7e. Nemici — set Era 2

```
Sprite sheet, 4 separate isolated enemy sprites on a fully transparent background,
generous spacing, painterly dark-fantasy style, warm dramatic lighting, side view
ALL FACING LEFT (charging left), TRUE alpha transparency (NO checkerboard).
Mythic-medieval invaders: (1) ragged raider with axe and shield, (2) armored skeletal
warrior with rusted sword, (3) hulking minotaur with a great club, (4) stone golem
with glowing cracks. Each a single isolated full-body sprite, soft contact shadow.
No ground platform, no text, no labels, no watermark.
```

### 7f. BOSS — Era 1: "Il Colosso" (mammut-titano; variante dinosauro)

```
A single epic boss creature on a fully transparent background, painterly dark-fantasy
style, dramatic warm-and-cold lighting, side view FACING LEFT, massive in scale,
TRUE alpha transparency (NO checkerboard), ~1024px tall, soft contact shadow.
Subject: a colossal primordial woolly mammoth-titan with cracked tusks, matted fur,
battle scars and faint glowing runes in its hide, head lowered to charge. Ancient,
mythic, terrifying. Centered, full body. No text, no watermark, no background scene.
```
> Variante "rule of cool" (sostituisce il soggetto): `a colossal scarred theropod
> dinosaur, scaled hide, glowing eyes, jaws open in a roar, primordial and mythic`.
> Variante coerente alternativa: `a giant primordial cave bear, enormous, scarred,
> standing on hind legs mid-roar`.

### 7g. BOSS — Era 2: "Il Drago"

```
A single epic boss creature on a fully transparent background, painterly dark-fantasy
style, dramatic ember lighting, side view FACING LEFT, massive in scale, TRUE alpha
transparency (NO checkerboard), ~1024px wide, soft contact shadow. Subject: a great
fire wyrm dragon, dark bronze-and-charcoal scales, tattered membranous wings half
spread, molten glow in throat and between scales, head low and menacing as it advances.
Ancient and mythic. Centered, full body. No text, no watermark, no background scene.
```

### 7h. Difensori / unità — set Era 1 (sprite sheet, **guardano a destra**)

```
Sprite sheet, 4 separate isolated character sprites on a fully transparent background,
generous spacing, painterly dark-fantasy style, warm lighting, consistent scale, side
view ALL FACING RIGHT (defending toward the right), TRUE alpha transparency (NO
checkerboard), soft contact shadow. Paleolithic defenders: (1) hunter throwing a stone
spear, (2) warrior with bone club and hide shield in guard stance, (3) shaman raising
a frost-ritual staff with pale blue glow, (4) carved wooden fire-totem with a small
flame. Each a single isolated sprite. No ground platform, no text, no labels, no watermark.
```
> **Esporta i 4 ritagli con questi nomi esatti** (il codice li aggancia 1:1 agli archetipi):
> (1)→`unit_tiratore.png`, (2)→`unit_bloccatore.png`, (3)→`unit_sciamano.png`,
> (4)→`unit_totem.png`, in `Assets/art/siege/era1/`. Idem Era 2 (7i) in `era2/`.

### 7i. Difensori / unità — set Era 2

```
Sprite sheet, 4 separate isolated character sprites on a fully transparent background,
generous spacing, painterly dark-fantasy style, warm lighting, side view ALL FACING
RIGHT (defending toward the right), TRUE alpha transparency (NO checkerboard), soft
contact shadow. Mythic-medieval defenders: (1) archer drawing a longbow, (2) legionary
with tower shield and spear in guard stance, (3) robed priest raising a glowing relic,
(4) wooden catapult/onager loaded with a boulder. Each a single isolated sprite.
No ground platform, no text, no labels, no watermark.
```

### 7j. Proiettili ed effetti (sprite sheet trasparente)

```
Sprite sheet, 6 separate isolated small effect sprites on a fully transparent
background, generous spacing, painterly dark-fantasy style, TRUE alpha transparency
(NO checkerboard), semi-transparent soft edges: (1) flying stone-tipped spear pointing
right, (2) flying arrow pointing right, (3) small fireball with trail, (4) pale-blue
frost burst, (5) golden impact spark, (6) red ground shockwave ring seen from above
(boss stomp telegraph). No hard borders, no text, no watermark.
```

### 7k. UI d'assedio (cornici, trasparenti)

```
Two separate ornate UI frames on a fully transparent background, painterly dark-fantasy
bronze-and-sepia style, hand-painted metal-and-leather look, TRUE alpha transparency
(NO checkerboard): (1) a wide horizontal boss health-bar frame, ornate bronze ends,
empty hollow center for a red fill, ~1200x90; (2) a banner/cartouche plate for a wave
announcement, ~700x160, empty center. No text, no letters, no watermark.
```

> Integrazione: stessi step del flusso sotto. Tutti gli asset §P7 sono **fallback-safe**
> (il codice usa forme/colori finché il PNG non esiste). Priorità per impatto:
> **boss** (7f, 7g) → **sfondi campo** (7a, 7b) → **nemici** (7d, 7e) → **difensori**
> (7h, 7i) → fx/UI (7j, 7k).

---

## P8 — UI KIT (sostituisce cornici/pulsanti/barre disegnati via codice)

> **Il pezzo più importante del redesign.** Oggi pannelli, pulsanti, badge, barre e
> medaglioni sono `StyleBoxFlat`/forme disegnate a codice → look "engine di default".
> Questi asset li rimpiazzano con arte vera. Piano di cablaggio in `Docs/13-redesign-estetico.md`.
>
> **Palette esatta (dal codice):** bronzo trim `#99703D`, oro chiaro/hover `#EDB861`,
> oro titoli `#E8C87A`, cuoio/pannello scuro `#1C1612`, fondo più scuro `#14100C`,
> pergamena chiara (riempimenti) `#E8DCC0`. Accenti: guerra `#C85A4A`, alleanza
> `#C9C27E`, mistero `#B79AE0`.
>
> **Regole UI (in aggiunta a quelle globali in cima al file):**
> - **Vista frontale piatta, ortografica**: nessuna prospettiva, nessun angolo 3/4,
>   nessuna ombra proiettata lunga (è UI, non un oggetto in scena).
> - **9-slice**: cornici e pulsanti devono essere **simmetrici**, con **angoli
>   ornati** e **bordi laterali semplici e ripetibili (tileable)**, **centro vuoto/piatto
>   riempibile**; margine trasparente attorno. In Godot diventano `NinePatchRect`
>   (imposto io i margini di patch).
> - **Trasparenza alpha vera** fuori dalla cornice (MAI scacchiera dipinta).
> - Stile coerente: **bronzo invecchiato + cuoio + pergamena**, pennellate fini,
>   nessun look "vetro/neon/sci-fi".

### 8a. Pannello maestro (cornice 9-slice — il frame di TUTTI i modali/HUD)

```
Ornate rectangular UI panel frame, flat front view, painterly dark-fantasy game UI,
aged bronze and dark leather, warm gold filigree on the four corners, simple repeatable
bronze border on the edges, EMPTY flat dark-parchment center (#1C1612) meant to be
filled, generous fully transparent margin outside the frame, perfectly symmetric,
designed for 9-slice scaling, no perspective, no long shadow. 512x512. Palette bronze
#99703D, gold #E8C87A, dark leather #1C1612. No text, no watermark, no checkerboard.
```

### 8b. Pulsante (sheet 9-slice, 4 stati)

```
Sprite sheet, 4 separate flat front-view UI button frames stacked vertically with
clear gaps, painterly dark-fantasy game UI, bronze trim on dark leather, rounded
rectangle, EMPTY fillable center, symmetric and 9-slice ready, transparent outside:
(1) NORMAL bronze #99703D trim on #21170F; (2) HOVER brighter gold #EDB861 trim with
soft warm glow; (3) PRESSED darker, inset look; (4) DISABLED desaturated grey-bronze,
faded. No perspective, no text, no label, no watermark, no checkerboard.
```

### 8c. Chip / badge (cornice 9-slice piccola — per rapporti, effetti duraturi)

```
Small flat front-view UI chip/badge frame, painterly dark-fantasy, thin bronze border
on dark leather, slightly rounded, EMPTY fillable center, symmetric 9-slice ready,
transparent outside, no perspective. A neutral bronze version. 256x128. No text,
no watermark, no checkerboard.
```
> Generare anche 3 varianti di **solo bordo tinto** (riusabili come overlay): verde
> alleato `#C9C27E`, rosso ostile `#C85A4A`, oro artefatto `#E8C87A`.

### 8d. Cornice tooltip

```
Flat front-view UI tooltip frame, painterly dark-fantasy, very dark leather center
(#14100C), thin warm bronze border, small folded-corner detail, EMPTY fillable center,
9-slice ready, symmetric, transparent outside, no perspective. 256x256. No text,
no watermark, no checkerboard.
```

### 8e. Divisori e filigrana

```
Sprite sheet on transparent background, painterly dark-fantasy bronze filigree, flat
front view, generous spacing: (1) a slim horizontal divider with a centered diamond
ornament and tapering ends, ~600x40; (2) a thinner plain bronze rule, ~600x16;
(3) a small centered flourish ornament, ~160x60. Aged gold #E8C87A on transparent.
No text, no watermark, no checkerboard.
```

### 8f. Ornamenti d'angolo (per le viste "pagina": Ledger, Menu, Mappa → effetto tomo)

```
Sprite sheet, 4 separate ornate corner ornaments on a fully transparent background,
painterly dark-fantasy bronze-and-gold filigree, flat front view, one for each corner
(top-left, top-right, bottom-left, bottom-right), mirror-symmetric as a set, like the
engraved corners of an ancient illuminated tome, ~256x256 each, generous spacing.
Aged gold #E8C87A and bronze #99703D. No text, no watermark, no checkerboard.
```

### 8g. Medaglione circolare vuoto (porta-icona — incornicia OGNI icona in modo coerente)

```
Empty circular medallion frame, flat front view, painterly dark-fantasy, aged bronze
ring with subtle engraved knotwork, hollow dark center (#1C1612) ready to hold an icon,
soft inner bevel, fully transparent outside the ring, perfectly round and symmetric,
no perspective. 512x512. Bronze #99703D, gold rim #E8C87A. Provide also a brighter
"selected/glow" variant with a warm gold halo. No text, no watermark, no checkerboard.
```

### 8h. Barre (cornice + riempimento: HP, stat, progressione)

```
Sprite sheet on transparent background, flat front-view UI bars, painterly dark-fantasy
bronze: (1) a horizontal bar FRAME with ornate bronze caps and an empty hollow channel,
9-slice ready, ~600x60; (2) a plain fill texture (warm gradient, slightly brushed) to
sit inside it, ~600x60; (3) a smaller compact bar frame ~360x36. Bronze #99703D, fill
warm gold #EDB861. No text, no watermark, no checkerboard.
```

### 8i. Cartiglio / targa titolo (per era card, titoli sezione, banner ondata)

```
Ornate horizontal title cartouche plate, flat front view, painterly dark-fantasy,
aged bronze and dark leather with gold filigree ends and a hanging-banner silhouette,
EMPTY fillable center for a title, symmetric, transparent outside, no perspective.
~1100x220. Bronze #99703D, gold #E8C87A. No text, no watermark, no checkerboard.
```

### 8j. Fondo pergamena (interno modali / pagine del Ledger)

```
Seamless painterly parchment texture for a UI panel interior, dark aged vellum, subtle
warm stains and fiber detail, very low contrast so text reads on top, edges fading to
darker leather, no objects, no figures, no border ornament (frame is separate). 1024x1024,
tileable-ish. Muted #2A2018 to #1C1612 with faint #E8DCC0 highlights. No text, no watermark.
```

### 8k. Anelli di affordance e selezione (rimpiazzano i dischi-gradiente a codice)

```
Sprite sheet, 4 separate flat top-down glow/marker sprites on a fully transparent
background, painterly, soft semi-transparent gradients, generous spacing: (1) warm gold
"selectable here" pulse ring, (2) ground build-plot pad (oval, dashed bronze rim with a
soft glow), (3) green "upgradeable now" halo ring, (4) thin gold focus/selection ring.
No hard borders, no text, no watermark, no checkerboard.
```

---

## P9 — SISTEMA ICONE (icone vere al posto di forme/medaglioni a codice)

> Le 8 icone stat e 4 strategie esistono già ma sono incorniciate da medaglioni
> disegnati a codice; lo Spionaggio è un placeholder; "+", stelle, lucchetti, freccia
> di upgrade, icona Risorse sono tutti a codice. Questo set le rende coerenti e finite.
> **Stile token:** oggetto dipinto centrato, painterly dark-fantasy, **trasparente**,
> leggibile a 48–64px. Dove indicato "medaglione", l'icona è già dentro un anello bronzo
> (così non serve la cornice §8g).

### 9a. Set 8 icone statistiche (medaglioni coerenti)

```
Sprite sheet, 8 separate isolated circular medallion icons on a fully transparent
background, generous spacing, painterly dark-fantasy, aged bronze ring around each,
warm hand-painted symbol inside, consistent style and lighting, readable at 64px:
(1) Militare = crossed spear and axe, (2) Tesoro = stack of gold coins/gem,
(3) Diplomazia = clasped hands / olive branch, (4) Scienza = open eye over a star,
(5) Legge = balance scales, (6) Spionaggio = hooded mask with a dagger,
(7) Popolo = group of three stylized figures, (8) Costruzione = mason's hammer and
trowel. Bronze #99703D rim, gold #E8C87A symbols. No text, no watermark, no checkerboard.
```

### 9b. Set 9 medaglioni strategia (token finiti)

```
Sprite sheet, 9 separate isolated circular medallion tokens on a fully transparent
background, generous spacing, painterly dark-fantasy, aged bronze ring, hand-painted
emblem inside, consistent style: (1) Ascia (battle axe), (2) Scudo (round shield),
(3) Libro (open book), (4) Pergamena (rolled scroll), (5) Voce (open mouth / sound
waves), (6) Economico (coin with wheat), (7) Decreto (sealed edict with wax),
(8) Rivoluzionaria (raised fist / broken chain), (9) Spionaggio (hooded mask + dagger).
Bronze #99703D, gold #E8C87A. No text, no watermark, no checkerboard.
```

### 9c. Icona Risorse / Materiali (valuta del villaggio — ora riusa l'icona Costruzione)

```
Single game icon on a fully transparent background, painterly dark-fantasy, 512x512,
centered: a small heap of building materials — cut timber logs, stone blocks and a
coil of rope — warm bronze-sepia palette, soft rim light, readable at 48px. Matches the
stat medallion set. No background circle needed, no text, no watermark, no checkerboard.
```

### 9d. Icone azione / affordance (rimpiazzano "+", stelle, frecce, lucchetto a codice)

```
Sprite sheet, 8 separate isolated game icons on a fully transparent background, generous
spacing, painterly dark-fantasy, warm bronze-gold, consistent style, readable at 40px:
(1) BUILD = bronze trowel+hammer crossed, (2) UPGRADE = upward gold chevron/arrow,
(3) LEVEL STAR = small gold five-point star (level pip), (4) LOCKED/MYSTERY = bronze
padlock with a faint violet glow, (5) CHECK = gold checkmark, (6) COIN = single gold
coin, (7) POPOLAZIONE = small bronze figure bust, (8) TEMPO/ERA = hourglass.
No text, no watermark, no checkerboard.
```

### 9e. Icone categoria Ledger (lore / artefatto / evento / epilogo / run)

```
Sprite sheet, 5 separate isolated circular medallion icons on a fully transparent
background, generous spacing, painterly dark-fantasy, aged bronze ring: (1) LORE = open
tome, (2) ARTEFATTO = faceted glowing gem, (3) EVENTO = carved rune stone,
(4) EPILOGO = laurel wreath, (5) RUN/VITE = spiral of years / hourglass with stars.
Bronze #99703D, gold #E8C87A. No text, no watermark, no checkerboard.
```

### 9f. Glifi tasti (opzionale — per i suggerimenti comandi)

```
Sprite sheet, 5 separate isolated keycap glyphs on a fully transparent background,
painterly dark-fantasy, small bronze-rimmed leather keycaps with an engraved letter
each: ESC, L, Q, B, ENTER (return arrow). Aged bronze #99703D, gold engraving #E8C87A,
flat front view. No extra text, no watermark, no checkerboard.
```

### 9g. Icone unità d'assedio (per la barra di schieramento — Fase B/G del boss fight)

```
Sprite sheet, 8 separate isolated square card-icons on a fully transparent background,
generous spacing, painterly dark-fantasy, bronze corner frame, a character/structure
bust inside each, consistent style. ERA 1: (1) Hunter with spear, (2) Warrior with hide
shield, (3) Shaman with frost staff, (4) Fire totem. ERA 2: (5) Archer, (6) Legionary
with tower shield, (7) Priest with relic, (8) Catapult. Bronze #99703D, gold #E8C87A.
No text, no watermark, no checkerboard.
```
> **Nomi file** (per la barra di schieramento, Fase B): ritaglia in
> `Assets/art/icons/siege/` come `tiratore.png` `bloccatore.png` `sciamano.png`
> `totem.png` (gli Era 2 condividono gli stessi archetipi → stessi 4 nomi).

---

## P10 — Stendardo d'alleanza sul villaggio (J15)

Oggi il gonfalone alleato è disegnato a codice (telo colorato) col volto dell'ambasciatore in
un medaglione. Asset dedicato opzionale (il codice lo aggancerà al posto del telo):
`Assets/art/villaggio/stendardo_alleato.png`.

```
A single isolated heraldic gonfalon banner sprite on a fully transparent background, painterly
dark-fantasy, warm bronze-and-gold cloth hanging from a dark wooden cross-pole, gently waving,
an EMPTY round medallion holder at its center (to overlay an ambassador portrait), soft contact
shadow at the base, vertical format ~256x384, TRUE alpha transparency (NO checkerboard). No text,
no watermark.
```

---

## Già a posto (NON rigenerare — vedi STATO ASSET in cima per la lista completa)

- UI-kit §P8 completo, edifici per-stadio §P0b (Era 1+2), terreni §P0, backgrounds (incl. Era 3)
- Assedio Era 1 completo (campo/roccaforte/enemy/4 unità/proiettili)
- Ritratti 16 consiglieri (post-recrop), ambasciatori, 8 icone stat, 9 strategie, 4 artefatti Ledger
- Menu bg, logo, sfondo Era 2 diurno, 6 vignette finali (painterly 16:9)
- Mappa-mondo: 4 layer + insediamenti + rotte/zone pulite

## Flusso di integrazione (per chi sviluppa)

1. File grezzi in `Assets/` root
2. Slicing con tool dedicato (`tools/slice_assets.py` o nuovo `slice_*.py`) + contact sheet di verifica
3. Smistamento in `Assets/art/<categoria>/` con nomi-convenzione
4. Wiring via `load("res://...")` negli script (mai uid nei .tscn)
5. Screenshot di verifica con `tools/shoot.tscn`

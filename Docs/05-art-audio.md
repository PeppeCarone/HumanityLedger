# 05 — Arte e audio

> Direzione artistica e strategia per acquisire gli asset senza farci uccidere dai tempi.
> Versione 0.2 — riscritta dopo intervista del 2026-06-01.

---

## Vincolo di partenza

2 persone, 1-3 mesi, nessun artista dedicato. Lo scope arte è ora considerevole: 2 ere visivamente distinte, 16 ritratti consiglieri, ambasciatori, illustrazioni catastrofi, 6 schermate finali, UI ledger.

Strategia: **AI generativa come pipeline primaria** + asset CC0 per oggetti di contorno + post-produzione manuale per unificare stile.

## Direzione artistica

**Stile painterly dettagliato in chiave mythico-epica**

Riferimenti diretti dai prototipi già in `Assets/`:
- `Consiglieri.png` — stile illustrato/dipinto con tratto morbido
- `Scenari.png` — illustrazioni narrative cinematiche
- `EffettiVisiviStrategie.png` — composizioni con texture e simboli
- `TrasformazioniMondo.png` — paesaggi tematici

> Il prototipo medievale **non si applica direttamente** all'Era 1 Paleolitica e va riadattato per l'Era 2 Mitica (no re/coron, sì simboli arcani). Stile *visivo* mantiene la qualità painterly, ma soggetti e atmosfera cambiano per era.

**Palette globale** (da definire definitiva W1):
- Era 1 Paleolitica: terre, ocra, rosso ferro, nero carbone, bianco osso, blu notte
- Era 2 Mitica: oro pallido, porpora, bronzo, blu profondo, bianco marmo, nero ferro

**Stile UI**: cornici stile pergamena/pietra incisa con texture, font serif antico. Cornici diverse per le 2 ere:
- Era 1: cornici di pietra grezza con segni rupestri
- Era 2: cornici di metallo dorato con simboli arcani

**Font candidati** (Google Fonts, licenza OFL):
- **Cinzel** (capitalini eleganti) — titoli e finali
- **IM Fell English** (serif arcaico) — corpo testo
- **EB Garamond** (serif classica) — fallback

## Asset inventory necessario per MVP

### Visivi — Era 1 Paleolitica

| Categoria | Quantità | Note |
|---|---|---|
| Ritratti 8 consiglieri | 8 | Stile painterly, palette tribale |
| Ambasciatori civiltà rivali | 2-3 | Clan del Bisonte, Popolo delle Nebbie (opzionale) |
| Sfondo caverna interna | 2-3 stati | Atto 1 (intatto), atto 2 (con pittura modificata), atto 3 (acceso) |
| Sfondo accampamento esterno | 1-2 | Quando si esce dalla caverna in atto 2 |
| Sprite edifici tribali | 4-5 | Idolo, prima capanna, recinto, fuoco esterno, totem |
| Illustrazioni catastrofi Era 1 | 3-4 | Carestia, peste, ribellione, conflitto (Era 1 ne usa una sottosezione) |

### Visivi — Era 2 Regno Mitico

| Categoria | Quantità | Note |
|---|---|---|
| Ritratti 8 consiglieri | 8 | Stile painterly, palette regale-mitica |
| Ambasciatori civiltà rivali | 2-3 | Impero del Sole, Lega delle Coste, Tribù della Steppa (opzionale) |
| Sfondo città dall'alto | 2-3 stati | A seconda dei percorsi dominanti |
| Sprite edifici mitici | 6-8 | Tempio, mura, mercato, fonderia, biblioteca, monumento |
| Illustrazioni catastrofi Era 2 | 5-6 | Tutte le 8 servono, qui ne usiamo la maggior parte |

### Visivi — Trasversali

| Categoria | Quantità | Note |
|---|---|---|
| 8 icone strategia | 8 | Usabili in entrambe le ere (con eventuale palette ritocco) |
| Schermate epilogo (6 finali) | 6 | Illustrazioni grandi, riferimento `TrasformazioniMondo.png` |
| Icona artefatti Ledger | 3 | Pietra del Fuoco, Corno, Lacrima |
| Sfondo schermata Ledger | 1 | Stile pergamena/scrigno |
| UI cornici Era 1 | 3-4 | Decision panel, narrative panel, HUD, quest log |
| UI cornici Era 2 | 3-4 | Stesso ma stile mitico |
| Schermata menu principale | 1 illustrazione | Idolo + paesaggio archetipico |
| Cinematica transizione era | 3-5 frame statici | Mostrati in sequenza con dissolvenze |

### Audio

| Categoria | Quantità | Note |
|---|---|---|
| Musica di sottofondo Era 1 | 1-2 brani | Tribale percussivo + drone |
| Musica di sottofondo Era 2 | 1-2 brani | Orchestrale solenne |
| Musica transizione era | 1 brano breve | Cinematica 30-60 sec |
| Musica finali | 1 brano (riusabile per i 6) | Con variazioni per tonalità |
| SFX gesti drag | 4 | drag pickup, hover positivo, drop conferma, drop fallito |
| SFX cambiamenti stat | 2 | stat sale, stat scende |
| SFX eventi narrativi | 4-5 | apparizione consigliere, evento mystery, transizione era, sblocco lore |
| SFX ambiente | 3-4 | Fuoco crepita, vento, suono di metallo, suono di pietra |
| Stinger narrativo | 2-3 | Per momenti chiave (catastrofe, finale, mystery) |

## Strategia di acquisizione

### 1. AI generativa (pipeline primaria)

Per la maggior parte degli asset visivi (ritratti, sfondi, illustrazioni), useremo generatori di immagini con stile painterly consistente.

**Tool candidati**:
- **Stable Diffusion locale** (gratuito, completa libertà): richiede GPU decente
- **Midjourney** (a pagamento, qualità alta): ~$10/mese
- **Bing Image Creator** / Google ImageFX (gratuiti, limitati ma decenti)
- **Leonardo.ai** (freemium, tier gratuito generoso)

**Pipeline**:
1. Prompt template condiviso (es. "painterly oil painting, fantasy mythical style, [SUBJECT], earthy palette, dramatic lighting")
2. Generare 3-5 varianti per asset
3. Selezionare la migliore + ritocco manuale (palette unification in GIMP/Krita)
4. Esportare in PNG con trasparenza dove serve

**Policy università**:
- **VERIFICARE** la policy del corso sull'uso di AI generativa per asset
- Documentare in `Assets/CREDITS.md`: modello usato, prompt utilizzato, modifiche manuali
- Discutere apertamente nella relazione di esame
- Avere un piano B: se AI non è ammessa, ripiegare su silhouette + asset CC0 (vedi sezione 2)

### 2. Asset gratuiti CC0 (fallback / contorno)

Fonti affidabili:

| Sito | Cosa cercare | Licenza |
|---|---|---|
| [Kenney.nl](https://kenney.nl) | UI kit, icone | CC0 |
| [OpenGameArt.org](https://opengameart.org) | Sprite, illustrazioni | CC0/CC-BY (filtrare) |
| [Freesound.org](https://freesound.org) | SFX | CC0/CC-BY |
| [Pixabay Music](https://pixabay.com/music/) | Musica gratuita uso commerciale | gratuita |
| [ccMixter](http://ccmixter.org) | Musica | CC vari |
| [Google Fonts](https://fonts.google.com) | Font | OFL / Apache |
| [itch.io free assets](https://itch.io/game-assets/free) | Asset pack tematici | varia |

> **Per ogni asset esterno**: salvare in `Assets/CREDITS.md` autore, fonte, licenza, link. Senza eccezioni.

### 3. Asset originali (manuali, dove servono)

Asset che vale la pena fare a mano:
- **Logo del gioco** (titolo "HumanityLedger") — identità del progetto
- **Cornici UI delle 2 ere** — coerenza
- **Icone delle 8 strategie** — riusabili, semplici, da fare bene

## Pipeline tecnica

- **Formato sprite**: PNG con trasparenza
- **Compressione**: TinyPNG o oxipng prima del commit
- **Risoluzione di lavoro**:
  - Ritratti: 768×768 (poi scalati in scena)
  - Sfondi: 1920×1080 nativo
  - Edifici/sprite: 256×256
  - Icone: 128×128 o 64×64
- **Risoluzione gioco**: 1920×1080 (da confermare)
- **Audio**: OGG Vorbis q5 per musica, WAV per SFX corti
- **Repo size**: monitorare. Se `Assets/` cresce oltre ~150 MB attivare Git LFS (vedi `CONTRIBUTING.md`)

## Stile vocale dei consiglieri (per scrittura)

Ogni consigliere ha un **tic linguistico** che lo distingue:

| Consigliere Era 1 | Tic |
|---|---|
| Brann (Cacciatore) | Brusco, frasi di 5-8 parole, metafore animali |
| Vesha (Accumulatrice) | Pratica, conta sempre ("Sette pelli, sei lune") |
| Orm (Pacificatore) | Calmo, lungo, scelte chiare |
| Lyssa (Sciamana) | Per immagini, oracolare, paragoni naturali |
| Murr (Anziano) | Ripete le regole vecchie come ritornello |
| Kael (Ombra) | Sintetico, frasi spezzate, mai promesse |
| Aru (Cantore) | Ritmico, quasi cantilenato |
| Tev (Plasmatore) | Concreto, descrive sempre ciò che si può fare |

Per l'Era 2 (Maresciallo, Cancelliere, ecc.) tic più "alti" e formali ma riconoscibilmente derivanti dagli archetipi paleolitici.

## Coerenza visiva attraverso le ere

Importante: il giocatore deve **riconoscere** la stessa entità in due ere diverse.

Tecniche:
- Stessa **palette dominante** per la stat (es. Sciamano in Era 1 e Alchimista in Era 2 hanno entrambi sfumature blu-viola)
- Stesso **archetipo di posa** nei ritratti (es. Cacciatore-Capo ed Erede Maresciallo sono entrambi di profilo, con arma)
- Echi di **oggetti** (l'idolo Era 1 riappare come tempio Era 2)
- Cinematica di transizione che **mostra esplicitamente** la corrispondenza

## Pianificazione asset (sintesi)

| Settimana | Output asset minimo |
|---|---|
| 1 | Palette + font, 2 ritratti Era 1 di test, cornice UI base, prompt template AI |
| 2 | 4 ritratti Era 1, sfondo caverna, 4 icone strategia |
| 3 | Tutti 8 ritratti Era 1, 1 ambasciatore Era 1, 3 sprite edifici |
| 4 | Ritratti Era 2 (4), sfondo città Era 2, 1 brano musicale Era 1 |
| 5 | Ritratti Era 2 restanti, illustrazioni catastrofe (3-4), 2 brani musicali |
| 6 | Ambasciatori Era 2, illustrazioni catastrofe restanti, brano transizione |
| 7-8 | Illustrazioni 6 epiloghi, sfondo Ledger, icone artefatti, SFX completi |
| 9-10 | Polish, ritocchi palette, asset extra emergenti |

## Cosa NON fare

- Niente animazione frame-by-frame complessa: solo 2-3 frame per loop ambientali (fuoco, vessillo, ecc.)
- Niente font commerciali a pagamento
- Niente asset da fonti dubbie (Pinterest, Google Images senza filtro) — violazione di copyright = bocciatura
- Niente Sketchfab/3D anche gratuiti — siamo 2D
- Niente AI generativa **senza** documentazione completa in `CREDITS.md`

## Crediti

Mantenere `Assets/CREDITS.md` aggiornato con:

```
## Nome del file
- Autore: [nome o "AI Generated"]
- Fonte: [URL o "Stable Diffusion locale"]
- Licenza: [CC0, CC-BY 4.0, AI-generated, ecc.]
- Prompt (se AI): [testo del prompt]
- Modifiche manuali: [se ce ne sono]
```

---

*Versione 0.2 — 2026-06-01.*

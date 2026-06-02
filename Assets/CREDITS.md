# Asset credits

> Crediti e licenze di tutti gli asset (visivi e audio) usati nel gioco.
> **Aggiornare a ogni nuovo asset.** Senza eccezioni — la consegna universitaria potrebbe richiedere questo file.

---

## Struttura cartelle

- `art/_sheets/` — **reference sheet** (immagini composite con più sprite per foglio). Non usate direttamente in gioco: vanno SLICED via `AtlasTexture` Godot in `art/<era>/` o `art/<categoria>/`.
- `art/era1_paleo/` — sprite paleolitici (Era 1)
- `art/era2_mitico/` — sprite mitici (Era 2)
- `art/strategie/` — icone 8 strategie politiche
- `art/catastrofi/` — illustrazioni 8 catastrofi
- `art/ambasciatori/` — ritratti civiltà rivali
- `art/finali/` — illustrazioni 6 epiloghi
- `art/ui/` — cornici, pannelli, font
- `art/ledger/` — icone artefatti, sfondo schermata Ledger
- `audio/music/` — brani musicali
- `audio/sfx/` — effetti sonori
- `fonts/` — font tipografici

---

## Reference sheets (art/_sheets/)

Tutti i seguenti file sono generati AI (forniti dal team) e usati come riferimento di stile / fonte di sprite da slicizzare.

### `consiglieri.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 16 ritratti consiglieri — 8 paleolitici (top row) + 8 mitici (bottom row). Corrispondono ai 16 personaggi MVP (D019).
- **Da slicizzare in**: `art/era1_paleo/consigliere_<archetipo>.tres` + `art/era2_mitico/consigliere_<archetipo>.tres`

### `consiglieri_v1.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: vecchia versione dei consiglieri (8 medievali). Mantenuta come riferimento storico; usare `consiglieri.png` per la produzione.

### `npc_portraits.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: ~30 ritratti NPC, candidati per ambasciatori e personaggi secondari. Da selezionare/slicizzare per `art/ambasciatori/`.

### `oggetti_decisioni.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 8 oggetti-token per drag (scudo, scrigno, pergamena, libro, runa, fionda/arco, idolo, ascia+pergamena). Sono i **draggable visuali** per le 8 strategie.
- **Da slicizzare in**: `art/strategie/oggetto_<strategia>.tres`

### `strategie_politiche_v1.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: vecchia versione delle 8 icone strategia in stile medaglione (figura intera in cornice circolare). Riferimento alternativo a `oggetti_decisioni.png`.

### `icone_stats.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 8 icone-scudo per le stat (Militare, Tesoro, Diplomazia, Scienza, Legge, Spionaggio, Popolo, Costruzione) + 6 badge per i percorsi/finali.
- **Da slicizzare in**: `art/ui/stat_<nome>.tres` per la HUD.

### `altari_decisione.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 8 "altari" (piattaforme circolari tematiche) usabili come **drop target** centrali nella scena di gioco. Stile coerente Era 1 (pietra) / Era 2 (metallo).

### `scenari_catastrofi.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 8 illustrazioni di catastrofi (Carestia, Peste, Ribellione, Tentato Assassinio, Vertice Diplomatico, Breakthrough Scientifico, Conflitto Religioso, Crisi Economica). Allineate a `Catastrofe.illustrazione`.
- **Da slicizzare in**: `art/catastrofi/<catastrofe_id>.tres`

### `eventi_chiave.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 8 illustrazioni narrative di eventi chiave + riga di icone piccole (probabilmente sblocco lore / eventi). Da inventariare in dettaglio prima della produzione.

### `edifici_era2.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: sprite isometrici di edifici Era 2 (case, mercato, fattorie, palazzo). Per la scena `game.tscn` Era 2 (vista dall'alto).
- **Da slicizzare in**: `art/era2_mitico/edificio_<tipo>.tres`

### `tilemap_ere1e2.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: backgrounds caverna (Era 1) + braciere/altare. Materiale base per la scena Era 1.
- **Da slicizzare in**: `art/era1_paleo/caverna_<variante>.tres`

### `artefatti.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 10 artefatti illustrati. Sceglieremo 3 per l'MVP (D026: Pietra del Fuoco / Corno dell'Adunata / Lacrima di Lyssa o equivalenti).
- **Da slicizzare in**: `art/ledger/artefatto_<nome>.tres`

### `effetti_visivi_strategie.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: visualizzazione degli effetti per 4 percorsi macro (Guerra, Diplomazia, Scienza, Religione/Industria). Riferimento di mood per gli stati di trasformazione del mondo.

### `trasformazioni_mondo.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 6 stati del mondo (Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura). Riferimenti per le 6 illustrazioni finali (D023).
- **Da slicizzare in**: `art/finali/finale_<id>.tres`

### `ui_hud_v1.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: mockup UI "Royal Council" con re medievale. Stile cornice utile per ispirazione; **soggetto re NON applicabile** all'MVP (D011 — no leader visibile). Usare solo per riferimento cornici/composizione.

### `dragndrop_demo.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: dimostrazione 4 stati del drag (drag/hover/successful drop/failed drop). Riferimento implementativo per `drag_handler.gd`.

---

## Asset di gioco (sliced / originali)

### `art/era1_paleo/cacciatore_brann.png` ... `plasmatore_tev.png` (8 file)
- **Origine**: ritagli da `art/_sheets/consiglieri.png` (top row paleolitico)
- **Coordinate**: 128×279 ciascuno, posizioni x=0,128,256,384,512,640,768,896 a y=0
- **Strumento**: PowerShell + System.Drawing (W3 setup)
- **Note**: i ritagli sono pixel-equal-grid; le posizioni esatte dei sprite nella sheet potrebbero discostarsi leggermente. Per perfezionamenti usare AtlasTexture in Godot editor.

### `art/era2_mitico/maresciallo_calden.png` ... `architetta_lena.png` (8 file)
- **Origine**: ritagli da `art/_sheets/consiglieri.png` (bottom row mitico)
- **Coordinate**: 128×279 a y=280

### `art/strategie/scudo.png`, `pergamena.png`, `libro.png`, `ascia.png`
- **Origine**: ritagli da `art/_sheets/oggetti_decisioni.png`
- **Coordinate**: 256×279 ciascuno
  - scudo: (0, 0)
  - pergamena: (512, 0)
  - libro: (768, 0)
  - ascia: (768, 280)

### `art/ui/logo.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Note**: Logo del gioco "Humanity Ledger" con castello+fuoco in cerchio. Per menu principale e branding.

### `art/ui/main_menu_bg.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Note**: Background per menu principale: caverna + consiglieri + tomo "Humanity Ledger" aperto + split Era 1/2.

---

## Audio

*(nessuno ancora — popolare a partire da W4)*

---

## Font

*(nessuno ancora — scelta definitiva W1, vedi 05-art-audio.md)*

---

## Pipeline slicing

Per produrre uno sprite dal reference sheet:

1. In Godot editor, FileSystem → `Assets/art/_sheets/<nome>.png`
2. Click destro → New AtlasTexture
3. Impostare `atlas` = il PNG sheet, `region` = rettangolo del singolo sprite
4. Salvare il `.tres` nella subfolder appropriata (`era1_paleo/`, `strategie/`, ecc.)
5. Documentare qui l'origine

---

## Licenze CC0 / consentite per uso commerciale

Tutti gli asset commitati devono avere licenza compatibile con la consegna universitaria. Compatibili sono almeno:

- **CC0** (Public Domain dedication) — preferita
- **CC-BY 4.0** (Attribution) — ok con attribuzione qui
- **OFL** (per font) — ok
- **Apache 2.0**, **MIT** — ok per codice/asset

**Incompatibili**:
- CC-BY-NC (Non-Commercial)
- CC-BY-ND (No Derivatives) — di solito problematico
- Asset da fonti senza licenza esplicita (Pinterest, screenshot, Google Images) — NON USARE

Per asset AI-generated documentare modello, prompt e modifiche.

# Asset credits

> Crediti e licenze di tutti gli asset (visivi e audio) usati nel gioco.
> **Aggiornare a ogni nuovo asset.** Senza eccezioni — la consegna universitaria potrebbe richiedere questo file.

---

## Struttura cartelle

- `art/_sheets/` — **reference sheet** (immagini composite con più sprite per foglio). Non usate direttamente in gioco: vanno SLICED via `AtlasTexture` Godot in `art/<era>/` o `art/<categoria>/`.
- `art/era1_paleo/` — sprite paleolitici (Era 1)
- `art/era2_mitico/` — sprite mitici (Era 2)
- `art/era3_futuro/` — ritratti consiglieri era futura (Era 3, non ancora integrata in gioco)
- `art/risorse_era3/` — icone risorse/stat era futura (popolo, prestigio, ecologia, legge, mistero, tecnologia)
- `art/decisioni_era3/` — icone categorie decisione era futura (guerra, diplomazia, industria, ecologia, economia, catastrofe)
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

### `villaggio_era1.png`, `villaggio_era2.png`
- **Autore**: AI Generated (Lovable, prompt in `Docs/08-asset-prompts.md` §P2, 2026-06-11)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 6+6 edifici isometrici trasparenti (Era 1 paleolitica: tenda, capanna, totem, focolare, essiccatoio, palizzata; Era 2 mitica: tempio, mercato, torre, fonderia, mura, archivio).
- **Sliced in**: `art/villaggio/era1/00-05.png`, `era2/00-05.png` via `tools/slice_villaggio.py`

### `batch2_*` (terreni, città notturna, eventi Era 1, fx, icona spionaggio)
- **Autore**: AI Generated (Lovable, prompt in `Docs/08-asset-prompts.md` §P0/P1.3/P3/P4/P5, 2026-06-11)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 2 terreni-tabellone (radura tribale, spianata del regno) → `art/terreni/era<N>.jpg`; città Era 2 notturna (firma sfumata) → `art/backgrounds/era2_citta_notte.jpg`; 4 illustrazioni eventi paleolitici → `art/eventi/era1_*.png`; 3 effetti conseguenza con alpha (vortice braci, nebbia viola, alone dorato) → `art/fx/00-02.png` (il 4° del prompt, anello di fiamme, è uscito con alpha vuota: scartato); icona Spionaggio (pugnale+maschera) → `art/strategie/spionaggio.png`.
- **Tool**: `tools/slice_batch2.py`

### `Risorse_di_gioco.png`, `Decisioni_gioco.png` (batch "era futura", 2026-06-15)
- **Autore**: AI Generated (Lovable)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: 2 sheet 192×128 RGBA, griglia 3×2 (celle 64px). Risorse: popolo, prestigio, ecologia, legge, mistero, tecnologia. Decisioni: guerra, diplomazia, industria, ecologia, economia, catastrofe.
- **Sliced in**: `art/risorse_era3/*.png`, `art/decisioni_era3/*.png` via `tools/smista_batch_futuro.py` (autocrop alpha per cella).

### Ritratti + sfondi + VFX "era futura" (batch, 2026-06-15)
- **Autore**: AI Generated (Lovable)
- **Licenza**: AI-generated, uso interno
- **Contenuto e destinazione** (smistati da `tools/smista_batch_futuro.py`):
  - 4 ritratti consiglieri 1024² → `art/era3_futuro/`: `consigliere_guerra.png` (militare neon), `consigliere_moderno.png` (diplomatico hi-tech), `ecologista.png`, `tecnico.png` (cyborg).
  - 3 sfondi 1920×1080 → `art/backgrounds/`: `era3_insediamento.jpg` (campo dystopico al crepuscolo), `era3_citta_crescita.jpg` (città cyberpunk), `era3_metropoli.jpg` (metropoli verde futura). Convertiti in jpg q88.
  - 1 VFX transizione 1024×572 → `art/fx/cambio_era.png`.
- **Nota**: `Consigliere.png` (anziano in toga oro, stile Regno Mitico) NON smistato: in attesa di conferma sulla destinazione (Era 2 vs era futura). Resta in `Assets/` root.

### `bg_era1_caverna_src.jpg`, `bg_era1_accampamento_src.jpg`
- **Autore**: AI Generated (Lovable, prompt in `Docs/08-asset-prompts.md` §P1, 2026-06-11)
- **Licenza**: AI-generated, uso interno
- **Contenuto**: sfondi di scena Era 1 (caverna con pitture rupestri e volto senza nome; accampamento esterno al crepuscolo). Firma incisa sull'accampamento attenuata via blur in post (`slice_villaggio.py`).
- **Processed in**: `art/backgrounds/era1_caverna.jpg`, `era1_accampamento.jpg`

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

### `art/ui/menu_buttons.png`
- **Autore**: AI Generated (team)
- **Licenza**: AI-generated, uso interno
- **Note**: Sheet con 9 button cornici (3 dimensioni × 3 stati: normale, hover, pressed). Da slicizzare via AtlasTexture per StyleBoxTexture in W11.

### `art/ledger/pietra_del_fuoco.png`, `corno_adunata.png`, `lacrima_di_lyssa.png`
- **Origine**: ritagli da `art/_sheets/artefatti.png` (top row, posizioni 0/1/2)
- **Coordinate**: 204×279 ciascuno, posizioni x=0, 204, 408 a y=0
- **Note**: 3 artefatti MVP per il Ledger meta-progressivo (D026).

---

## Audio

Tutto l'audio è **sintetizzato da zero** con `tools/gen_audio.py` (numpy/scipy →
OGG Vorbis). Nessun campione di terzi: opera originale, nessun vincolo di licenza
(di fatto CC0). Rigenerabile con `python tools/gen_audio.py`.

### SFX (`audio/sfx/*.ogg`)
- `drag_pickup`, `drag_hover` — tick legnosi soft al prelievo/hover dell'icona
- `drop_success` — campanella a due note (do→sol) sul drop valido
- `drop_fail` — tonfo basso ovattato (asset pronto, trigger opzionale)
- `stat_up` / `stat_down` — arpeggio breve ascendente/discendente sul cambio stat
- `quest_complete` — arpeggio maggiore al completamento quest
- `ledger_unlock` — shimmer acuto allo sblocco di lore/eventi/artefatti del Ledger
- `era_transition` — swell + gong al passaggio d'era

### Musica (`audio/music/*.ogg`, ambient loopata)
- `menu` — pad caldo contemplativo (Am-F-C-G)
- `era1` — drone scuro e rado, pulsazione bassa (Paleolitico)
- `era2` — pad più pieno e regale (Regno Mitico)
- `ending` — risoluzione calma in maggiore

Sintesi: oscillatori sine + campane inarmoniche, inviluppi ADSR, riverbero a
convoluzione, filtri Butterworth, LFO lenti. Livelli: SFX picco ~-2/-16 dB,
musica picco ~-12 dB (sottofondo). Cablato in `AudioManager` (loop + mute
persistente + ripresa su unmute).

---

## Font

### `fonts/Cinzel.ttf` — titoli
- **Autore**: Natanael Gama
- **Licenza**: SIL Open Font License 1.1 (`fonts/Cinzel-OFL.txt`)
- **Fonte**: Google Fonts (github.com/google/fonts, `ofl/cinzel`)
- **Uso**: titoli/intestazioni (capitali romane, tono mitico-epico). Applicato via codice
  con `FontVariation` (wght 600-700) a: nome consigliere proponente, titolo schermata
  finale, titolo menu pausa.

### `fonts/Alegreya.ttf` — corpo
- **Autore**: Juan Pablo del Peral (Huerta Tipográfica)
- **Licenza**: SIL Open Font License 1.1 (`fonts/Alegreya-OFL.txt`)
- **Fonte**: Google Fonts (github.com/google/fonts, `ofl/alegreya`)
- **Uso**: font di default del progetto (`project.godot` → `gui/theme/custom_font`),
  serif letterario per tutto il testo di interfaccia.

Entrambi variabili (asse `wght`). OFL = uso commerciale/accademico consentito con
mantenimento del file di licenza (incluso). Nessuna modifica ai font.

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

# 19 — PIANO MASTER (scanner del gioco) — HumanityLedger

> **Documento vivo, rigenerato automaticamente dalla routine delle 6:00** (vedi §6). Ultimo
> aggiornamento: **2026-06-23 (mattina)**. Audit a sola lettura del progetto Godot 4.6.
> Ogni `- [ ]` è azionabile: priorità (P0/P1/P2), passi concreti, file, asset necessari.
> **L'Assedio 2.0 e il Villaggio Vivo sono COMPLETI** e non vanno ripianificati.

## 0. Sintesi — stato del gioco e cosa manca per un gioco "bello e finito"

HumanityLedger è **feature-complete e coerente esteticamente**. Funzionano end-to-end: 2 ere con
transizione, ~34 decisioni drag-and-drop, 8 stat + economia Risorse, villaggio costruibile con
camera libera + diorama vivo (giorno/notte, meteo, abitanti), mappa-mondo animata, Ledger
meta-progressivo, 6 finali, mystery, **Assedio 2.0** (auto-battler boss/mini-boss/abilità,
ultimate telegrafata, juice). Audio originale, shader, animazione procedurale ovunque.

**Asset confermati presenti (scan 2026-06-23):**
- `Assets/art/stats/` — tutte e 8 le icone stat (costruzione, diplomazia, legge, militare,
  popolo, scienza, spionaggio, tesoro). **Cablate e usate via `STAT_ICON_DIR`.**
- `Assets/art/strategie/` — 8 icone strategia (ascia, decreto, economico, libro, pergamena,
  rivoluzionaria, scudo, spionaggio). **Presenti.**
- `Assets/art/ui/` — UI-kit 9-slice COMPLETO: panel, button (5 stati), chip, 4 corner,
  divider, medallion+glow, bar_frame/fill, cartouche, parchment, ring_*/plot_pad, tooltip.
- `Assets/art/icons/risorse.png` — **ESISTE** (l'helper `_icona_risorse()` lo usa già).
- `Assets/art/icons/siege/` — bloccatori, caster, sciamano, tiratore, totem. **Completi.**

**Cosa manca per il salto "prototipo → gioco rifinito" (per impatto):**
1. **HUD densità/tooltip (P0)** — le 8 stat mostrano nome sempre visibile (lista verticale),
   zero tooltip. Griglia 2×4 + tooltip + STAT_DESCR = max ROI codice.
2. **Resource bar proxy (P0-facile)** — 1 riga: `_setup_resource_bar` usa ancora
   `costruzione.png`; `_icona_risorse()` e `risorse.png` esistono già, basta chiamarla.
3. **Tooltip strategia (P0)** — draggable_item non mostra nome/natura della carta.
4. **Quest pacing Era 2 (P1)** — 3 quest vs 4 di Era 1; alcuni testi lunghi.
5. **Icone Ledger mancanti (P1)** — `icons/ledger/` è vuota (solo `.gitkeep`).
6. **Pannelli inline non uniformi (P1)** — `call_button` e backing card usano `StyleBoxFlat`
   inline invece di `UiStyle`; convivono 3 stili di pannello.
7. **Debito tecnico minore** — build .exe manuale, `asset_audit.py` da eseguire, tween kill.

---

## 1. OVERHAUL UI — stile Clash of Clans / Age of Empires (P0)

### 1.0 Principi (COC/AoE/strategici) come barra di qualità
- **Risorse in alto · comandi in basso · mondo al centro** (struttura già corretta — va resa
  più compatta/iconica).
- **Icone prima del testo** — ogni risorsa/edificio/comando è icona riconoscibile; nome a hover.
- **Modali con cornice ricca e contenuto tabellare** (icona+label+costo allineati, grande CTA).
- **Affordance di stato** — verde=puoi, grigio/rosso=no, glow=consigliato ora.
- **Tooltip ovunque coi numeri reali.**
- **Densità/scaling** — 1920×1080 canvas_items; corpo testo ≥ 16px, tappabili ≥ 40px.

### 1.1 Stato UI attuale (scan codice 2026-06-23)
- Tema globale `ui_style.gd`: pulsanti bronzo, tooltip, font. **Buono.**
- UI-kit 9-slice completo in `Assets/art/ui/`. **Cablato.**
- **Problema centrale**: `_setup_hud` (`main.gd:582`) costruisce 8 righe verticali con nome
  sempre visibile + valore + barra → lista lunga "da pannello di controllo", niente tooltip.
- `_setup_resource_bar` (`main.gd:2606`) carica `costruzione.png` come proxy per Risorse
  (riga 2624) **anche se** `_icona_risorse()` (riga 2391) e `icons/risorse.png` esistono già.
- `call_button` (`main.gd:264-280`) usa `StyleBoxFlat` inline, non `UiStyle`.

### 1.2 Migliorie per schermata

**A. HUD stat (sinistra) — `main.gd:_setup_hud` (riga 582), `scenes/main.tscn` HUDPanel**
- [ ] **P0** Compattare le 8 stat in **griglia 2×4** di pill `[icona][valore]` (GridContainer
  2 colonne, dimezza l'altezza, legge come COC); spostare il **nome nel `tooltip_text`**.
  _Struttura target_: `GridContainer(2 col)` → per ogni stat: `HBox(icon 28px + label valore)`,
  tooltip su ogni HBox: `"NomeStat — DescrizioneStat\nValore: N/100"`.
- [ ] **P0** Aggiungere `const STAT_DESCR: Dictionary` in `main.gd` con 1 riga/stat (testo
  breve dal doc 02): `"militare": "Capacità offensiva e difensiva"` ecc. 8 voci totali.
- [ ] **P1** Barra fill colorata per fascia: rosso <25, bronzo medio, verde >70.
  File: `_aggiorna_barra_stat()` `main.gd` (oggi usa colore fisso).
- [ ] **P1** Incorniciare HUDPanel con `UiStyle.panel_stylebox()` (il pannello stretto potrebbe
  preferire gli angoli §8f).
- [ ] **P2** Quest-log come mini-pannello (titolo "Obiettivo" + icona + step N/M).
- [ ] **P2** Tasto-chip (V/L/ESC) come glifi visivi (oggi è Label nuda, opacity 45%).

**B. Barra Risorse (alto-centro) — `main.gd:_setup_resource_bar` (riga 2606)**
- [ ] **P0-facile** Fix 1 riga: sostituire `var icp: String = STAT_ICON_DIR + "costruzione.png"`
  (riga 2624) con `ic.texture = _icona_risorse()` (la funzione esiste già a riga 2391 e
  `icons/risorse.png` è presente). **10 secondi di lavoro, impatto visivo immediato.**
- [ ] **P1** Cornice barra §8h (`bar_frame.png`) per look "contatore" da COC.

**C. Vista decisione (la più vista) — `main.gd`, `draggable_item.gd`**
- [ ] **P0** Tooltip sulle carte strategia: `draggable_item.gd` oggi mette tooltip generico
  "Trascina su X"; aggiungere nome+natura dal `.tres` strategia. Pattern: quando la carta
  viene creata in `main.gd` (cerca `DRAG_ITEM_SCENE.instantiate()`), settare `tooltip_text`
  con `strategia.nome + " — " + strategia.descrizione`.
- [ ] **P0** Verificare a schermo che il **medaglione** strategia carichi `medallion.png` (non
  il cerchio a codice); se piccolo, ingrandire icona interna.
- [ ] **P1** Quando manca l'event-image, far espandere il testo proponente nello spazio liberato
  (`event_image.visible = false` → `proposer_text_label` occupa tutto).
- [ ] **P1** Testi decisione: "ritaglio" (vedi §2).
- [ ] **P2** Hover-glow verde `ring_focus.png` sulle drop-zone consiglieri.

**D. Modali build/upgrade — `main.gd:_apri_pannello_costruzione/_upgrade`**
- [ ] **P1** CTA primaria più grande/accesa (stile `main_menu`).
- [ ] **P2** Icona-stat accanto al "+N Stat" nei pulsanti build.

**E. Uniformità pannelli inline**
- [ ] **P1** `call_button` (`main.gd:264-280`): migrare da `StyleBoxFlat` inline a
  `UiStyle.panel_stylebox()` o variante bronzo da `UiStyle`.
- [ ] **P1** Backing card `draggable_item.gd`: usare `UiStyle` invece di StyleBoxFlat inline.

**F. Ledger — `ledger_screen.gd`**
- [ ] **P1** Icone-categoria tab: generare `icons/ledger/lore.png`, `artefatto.png`,
  `evento.png` (3 file — prompt §9e in `Docs/08`). Cablaggio automatico già in `UiStyle`.
- [ ] **P2** Card lore/artefatto a griglia con scroll.

**G. Menu / Epilogo / Opzioni / Pausa** — già coerenti (P2 minori).

### 1.3 Fattibile ORA solo-codice (P0)
Nell'ordine: fix resource bar (1 riga) → griglia 2×4 stat + STAT_DESCR + tooltip → tooltip
strategia → CTA modali → pannelli uniformi. **Gran parte è in `main.gd`** → coordinare con
git pull se l'amico lavora su quel file, o branch dedicato.

### 1.4 Asset UI da generare (prompt in `Docs/08` §P9)
- **P0** (già presente) `icons/risorse.png` ✅ — solo cablare `_setup_resource_bar`.
- **P1** `icons/ledger/{lore,artefatto,evento}.png` (3 file, §9e). `icons/siege/caster.png` ✅.
- **P2** `icons/keys/*`, `icons/action/*` (fallback a codice ok); catastrofi dedicate.

---

## 2. QUEST LINE / NARRATIVA (P1)

**Dove vivono i testi:** decisioni `data/decisions/*.tres` (`testo_consigliere`, `label_text`,
`feedback_testo`); quest `data/quests/*.tres`; richiami cross-era `main.gd:RICHIAMI`;
lore `ledger_screen.gd:LORE_REGISTRY`; finali `data/finali/*.tres`.

**Pacing confermato (scan `main.gd:QUEST_SEQUENZE`):**
Era 1 = 4 quest (`q_caverna_tutorial`, `q_accampamento`, `q_confronto`, `q_idolo_del_fuoco`).
Era 2 = 3 quest (`q_corte_si_forma`, `q_pressione_imperi`, `q_scelta_finale`). Asimmetria.

- [ ] **P1** Riequilibrare Era 2: spezzare `q_pressione_imperi` o `q_scelta_finale` **oppure**
  assegnare 2-3 decisioni `d_corte_*` orfane a una quest dedicata → 4 quest anche in Era 2.
  File: `data/quests/*.tres`, `main.gd:QUEST_SEQUENZE`.
- [ ] **P1** "Ritaglio" testi: `testo_consigliere` >40 parole → accorciare mantenendo voce;
  ogni prompt finisce con domanda (D040). Tool: `tools/improve_decisions.py`.
- [ ] **P1** Typewriter adattivo: `main.gd:_show_narrative` usa `len/45`s → cap a ~1.6s o `/60`.
- [ ] **P2** Quest-log con titolo + step "N/M" (`current_step`, `current_quest.passi.size()`).
- [ ] **P2** Riverificare 6 finali + mystery dopo riequilibrio (`tools/balance_sim.py`).
- [ ] **P2** Tutorial diegetico: micro-tooltip al primo pickup carta.

---

## 3. AUDIT ASSET (P1)

**Presenti e USATI** (confermati via scan 2026-06-23): 16 ritratti consiglieri, 4 ambasciatori,
5 sfondi decisione, 2 terreni, 72 edifici villaggio + deco/atmosfera, **8 icone stat** (in
`art/stats/`), **8 icone strategia** (in `art/strategie/`), 12 illustrazioni eventi, 6 finali,
3+1 artefatti, mappa-mondo (layers/transformation/feedback/lines), UI-kit (~32 file in `art/ui/`),
**Assedio 37 sprite + icons/siege completi**, FX, 13 SFX + 4 musiche, font, shader vignette.
`icons/risorse.png` presente ma NON ancora cablato in `_setup_resource_bar` (solo in helper).

**MANCANTI / da generare:**
- [ ] **P1** `icons/ledger/{lore,artefatto,evento}.png` (3 file, §9e). Solo questi bloccano il
  redesign Ledger.
- [ ] **P2** `icons/keys/*`, `icons/action/*` — fallback a codice, non bloccanti.
- [ ] **P2** Catastrofi dedicate (oggi riusano `eventi/*`).

**INUTILIZZATI (candidati a pulizia — confermare con `tools/asset_audit.py`):**
- [ ] **P2** `Assets/art/_sheets/*` (~35 sheet sorgente raw): spostare in `art_src/` ignorata
  o escludere dall'export; **non rimuovere** (servono a ri-slicing).
- [ ] **P2** Set Era 3 (`backgrounds/era3_*`, `era3_futuro/*`, `decisioni_era3/*`, ~13 file):
  tenere se si valuta Era 3, altrimenti `art_src/`.
- [ ] **P2** `backgrounds/era1_pitture.png`, set `map/Chosen_consequences/`, `interactive_marker`:
  verificare uso reale con `tools/asset_audit.py` prima di toccare.
- [ ] **P1** Eseguire `tools/asset_audit.py` per la lista autoritativa referenziati/orfani/rotti.

---

## 4. POLISH / BUG / DEBITO TECNICO (P1/P2)

- [ ] **P1** Build `.exe` Windows (manuale): Godot → Export → Windows Desktop → test su PC pulito.
- [ ] **P1** Verificare export esclude `_sheets`/`art_src`/`Docs`/`tools` (`export_presets.cfg`).
- [ ] **P1** Uniformare pannelli inline (`call_button`, backing card) via `UiStyle` (§1.2.E).
- [ ] **P2** Audit kill-tween al reset run (idle decisione, vignette, narrative, drift) per
  evitare callback su nodi liberati.
- [ ] **P2** J16: ciclo giorno/notte legato allo step quest. Overlay attuale molto tenue —
  opzione: accentuare la notte se si vuole che il giocatore la noti.
- [ ] **P2** Relazione/video d'esame (`Docs/14`, `Docs/15`): parti soggettive + cattura video.
- [ ] **P2** QA regressione dopo interventi: `--import` (exit0), `validate_scenes` (0 failures),
  `balance_sim` (6 finali + Assedio), `playtest_curve` (Era 1+2), riverificare `tools/shoot.gd`.

---

## 5. Sequenza consigliata (impatto/sforzo)

1. **Fix immediato (5 min, P0)** — resource bar: sostituire riga 2624 di `main.gd`
   (`STAT_ICON_DIR + "costruzione.png"`) con `_icona_risorse()`. Visibile subito.
2. **Sprint UI-A (P0, solo codice)** — griglia 2×4 stat + STAT_DESCR + tooltip stat + tooltip
   strategia + CTA modali. Max ROI. `main.gd` + `draggable_item.gd`.
3. **Sprint Asset-UI (P1)** — 3 icone Ledger (prompt §9e → Nano Banana → cabla in `ledger_screen.gd`).
4. **Sprint Narrativa (P1)** — pacing Era 2 (4a quest) + ritaglio testi + typewriter. Rilancia
   `balance_sim`.
5. **Sprint Pulizia & Build (P1)** — `asset_audit.py` → orfani in `art_src/` + .exe + doc.
6. **Polish residuo (P2)** — pannelli inline, J16, glifi tasti, kill-tween.

## 6. Routine automatica delle 6:00

Una routine (cron `0 6 * * *`) ri-scansiona il progetto, ri-legge Docs/codice/asset/git, e
**rigenera+pusha questo documento** così, riaprendo, il team trova sempre lo "scanner" aggiornato
con cosa fare. Vedi setup in `tools/` / scheduled task.

---

### File chiave

HUD/decisione/villaggio/resource-bar/modali → `scripts/main.gd` (HUD: riga 582, resource bar: 2606)
· tema+UI-kit → `scripts/autoload/ui_style.gd` · stato → `scripts/autoload/game_state.gd`
· carta drag → `scripts/ui/draggable_item.gd` · scena → `scenes/main.tscn`
· quest/dati → `scripts/autoload/quest_manager.gd`, `data/{quests,decisions}/*.tres`
· Ledger → `scripts/ui/ledger_screen.gd` · Assedio (completo) → `scripts/siege/*.gd`
· QA → `tools/{asset_audit,balance_sim}.py`, `tools/{validate_scenes,shoot}.gd`,
  `tools/playtest_curve.tscn`.

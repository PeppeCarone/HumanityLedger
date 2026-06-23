# 19 — PIANO MASTER (scanner del gioco) — HumanityLedger

> **Documento vivo, rigenerato automaticamente dalla routine delle 6:00** (vedi §6). Ultimo
> aggiornamento manuale/audit: **2026-06-23**. Audit a sola lettura del progetto Godot 4.6.
> Ogni `- [ ]` è azionabile: priorità (P0/P1/P2), passi concreti, file, asset necessari.
> **L'Assedio 2.0 e il Villaggio Vivo sono COMPLETI** e non vanno ripianificati.

## 0. Sintesi — stato del gioco e cosa manca per un gioco "bello e finito"
HumanityLedger è **feature-complete e coerente esteticamente**. Funzionano end-to-end: 2 ere con
transizione, ~34 decisioni drag-and-drop, 8 stat + economia Risorse, villaggio costruibile con
camera libera + diorama vivo (giorno/notte, meteo, abitanti), mappa-mondo animata, Ledger
meta-progressivo, 6 finali, mystery, **L'Assedio 2.0** (auto-battler con boss/mini-boss/abilità,
ultimate telegrafata, juice). Audio originale, shader, animazione procedurale ovunque. Pipeline
asset matura (Perplexity→Nano Banana, slicing, caricamento fallback-safe per nome).

**Cosa manca per il salto "prototipo → gioco rifinito" (per impatto):**
1. **Coerenza UI (P0)** — l'UI-kit 9-slice bronzo esiste ma molti pannelli usano ancora
   `StyleBoxFlat`/`panel_clean()`; l'HUD di sinistra è denso "da pannello di controllo". Mancano
   compattezza, gerarchia, icone sui pulsanti, tooltip ricchi. **Investimento a più alto ritorno.**
2. **Onboarding/leggibilità decisione (P0/P1)** — schermata più vista: più compatta, tooltip sulle
   icone-strategia.
3. **Quest line (P1)** — arco solido ma pacing asimmetrico (Era1 4 quest / Era2 3); alcuni testi
   lunghi; quest-log è una Label nuda.
4. **Pulizia asset (P1/P2)** — sheet sorgente raw + set Era 3 + 2 `unit_totem.png` inutilizzati.
5. **Debito tecnico minore** — build .exe manuale; barra Risorse usa icona Costruzione come proxy.

---

## 1. OVERHAUL UI — stile Clash of Clans / Age of Empires (P0)

### 1.0 Principi (COC/AoE/strategici) come barra di qualità
- **Risorse in alto · comandi in basso · mondo al centro** (già impostato: resource-bar in alto,
  decisione in basso — struttura giusta, va resa più compatta/iconica).
- **Icone prima del testo** — ogni risorsa/edificio/comando è un'icona riconoscibile; nome a hover.
  (Oggi l'HUD mostra "Nome … valore" per 8 stat: troppo testo.)
- **Modali con cornice ricca e contenuto tabellare** (icona+label+costo allineati, grande CTA).
- **Affordance di stato** — verde=puoi, grigio/rosso=no, glow=consigliato ora (già presente, da
  rendere sistematico).
- **Tooltip ovunque coi numeri reali**.
- **Densità/scaling** — 1920×1080 canvas_items; corpo testo ≥ ~16px, tappabili ≥ ~40px.

### 1.1 Stato UI attuale
- Tema globale centralizzato (`ui_style.gd`): pulsanti bronzo, tooltip, font. **Buono.**
- UI-kit 9-slice completo in `Assets/art/ui/`. `panel_stylebox()` ornato vs `panel_clean()` flat.
- **Problema centrale**: convivono 3 stili di pannello (ornato / flat / `StyleBoxFlat` inline es.
  `call_button` main.gd, backing card draggable_item.gd) → feel non uniforme tra schermate.

### 1.2 Migliorie per schermata
**A. HUD stat (sinistra) — `main.gd:_setup_hud`, `scenes/main.tscn` HUDPanel**
- [ ] **P0** Compattare le 8 stat in **griglia 2×4** di pill `[icona][valore]` (dimezza l'altezza,
  legge come COC); spostare il **nome nel `tooltip_text`** invece che Label sempre visibile.
- [ ] **P0** Tooltip ricco su ogni stat: `"<Nome> — <descrizione dominio>\nValore: N/100"`
  (aggiungere const `STAT_DESCR`, 1 riga/stat, dalla tabella `Docs/02`).
- [ ] **P1** Barra 0-100 da 6→8px, fill colorato per fascia (rosso <25, bronzo medio, verde >70).
- [ ] **P1** Incorniciare l'HUDPanel con la cornice ornata (`UiStyle.panel_stylebox()`), o angoli
  §8f se la cornice 84px è troppa sul pannello stretto.
- [ ] **P2** Quest-log come mini-pannello (titolo "Obiettivo" + icona + step), mystery come "???".
- [ ] **P2** Scorciatoie in glifi-tasto §9f (cartella `icons/keys/` vuota) o chip.

**B. Barra Risorse (alto-centro) — `main.gd:_setup_resource_bar`**
- [ ] **P0** Icona Risorse dedicata: generare `Assets/art/icons/risorse.png` (§9c) — oggi riusa
  `stats/costruzione.png` come proxy. Cablaggio: cambiare `icp` a `ICON_DIR+"risorse.png"`.
- [ ] **P1** Cornice barra §8h (`bar_frame.png`) per un look "contatore" da COC.

**C. Vista decisione (la più vista) — `main.gd`, scene `ConsigliereProposer`/`DecisionPanel`**
- [ ] **P0** Tooltip sulle icone-strategia/carte: oggi `draggable_item` mette solo "Trascina su X";
  aggiungere nome+natura strategia (es. "Decreto Reale — rafforza la Legge"), dai `.tres` strategie.
- [ ] **P0** Verificare a schermo che il **medaglione** strategia carichi `medallion.png` (non il
  cerchio a codice); ingrandire l'icona interna se piccola.
- [ ] **P1** Quando manca l'event-image, far espandere il testo proponente nello spazio liberato.
- [ ] **P1** "Ritaglio" testi decisione (vedi §2).
- [ ] **P2** Hover-glow verde §8k (`ring_focus.png`) sulle drop-zone consiglieri.

**D. Modali build/upgrade — `main.gd:_apri_pannello_costruzione/_upgrade`**
- [ ] **P1** Già i più curati. Rendere la **CTA primaria più grande/accesa** (stile `main_menu`).
- [ ] **P2** Icona-stat accanto al "+N Stat" nei pulsanti build.

**E. Menu principale** — già forte (no P0/P1).
**F. Ledger — `ledger_screen.gd`**
- [ ] **P1** Icone-categoria tab §9e: generare `icons/ledger/{lore,artefatto,evento}.png`.
- [ ] **P2** Card lore/artefatto a griglia con scroll (~30 voci).
**G. Mappa/Epilogo/Opzioni/Pausa** — già coerenti (P2 minori).

### 1.3 Fattibile ORA solo-codice (P0/P1)
- [ ] Griglia 2×4 stat + tooltip stat · tooltip strategia · CTA modali · espansione testo
  proponente · barra stat colorata per fascia. **Nota: gran parte è in `main.gd`, file su cui
  l'amico lavora attivamente → coordinare (git pull) o lavorare su branch per evitare conflitti.**

### 1.4 Asset UI da generare (prompt in `Docs/08` §P9)
- [ ] **P0** `icons/risorse.png` (§9c). **P1** `icons/ledger/{lore,artefatto,evento}.png` (§9e),
  `icons/siege/caster.png`. **P2** `icons/keys/*`, `icons/action/*` (fallback a codice ok).

---

## 2. QUEST LINE / NARRATIVA (P1)
**Dove vivono i testi:** decisioni `data/decisions/*.tres` (`testo_consigliere`, `label_text`,
`feedback_testo`); quest `data/quests/*.tres`; richiami cross-era hardcoded in `main.gd:RICHIAMI`;
lore `ledger_screen.gd:LORE_REGISTRY`; finali `data/finali/*.tres`.

- [ ] **P1** Riequilibrare il pacing Era 2 (oggi 3 quest vs 4 di Era 1): spezzare
  `q_pressione_imperi`/`q_scelta_finale` o assegnare 2-3 `d_corte_*` orfane a una quest dedicata →
  4 quest anche in Era 2. File: `data/quests/*`, `main.gd:QUEST_SEQUENZE`.
- [ ] **P1** "Ritaglio" testi: `testo_consigliere` >40 parole e `feedback_testo` >35 → accorciare
  mantenendo la voce; ogni prompt finisce con una domanda (D040). Tool: `tools/improve_decisions.py`.
- [ ] **P1** Typewriter adattivo: `main.gd:_show_narrative` usa `len/45`s → cap a ~1.6s o `/60`.
- [ ] **P2** Quest-log con titolo + step "N/M" (`current_step`, `current_quest.passi.size()`).
- [ ] **P2** Riverificare 6 finali + mystery dopo il riequilibrio (`tools/balance_sim.py`).
- [ ] **P2** Tutorial diegetico: micro-tooltip al primo pickup carta.

---

## 3. AUDIT ASSET (P1)
**Presenti e USATI** (confermati via grep): 16 ritratti consiglieri, 4 ambasciatori, 5 sfondi
decisione, 2 terreni, 72 edifici villaggio + deco/atmosfera, 8 icone stat, 8 icone strategia, 12
illustrazioni eventi, 6 finali, 3+1 artefatti, mappa-mondo (layers/transformation/feedback/lines),
UI-kit (~22), **Assedio 37 sprite (set Era 2 + nemici F3 + caster ORA completi e cablati)**, FX,
13 SFX + 4 musiche, font.

**MANCANTI / da generare**
- [ ] **P0** `icons/risorse.png` (§9c). **P1** `icons/ledger/{lore,artefatto,evento}.png`,
  `icons/siege/caster.png`. **P2** `icons/keys/*`, `icons/action/*`, catastrofi dedicate (oggi
  riusano `eventi/*`).

**INUTILIZZATI (candidati a pulizia — confermare con `tools/asset_audit.py`)**
- [ ] **P2** `Assets/art/_sheets/*` (~35 sheet sorgente raw, solo input di `tools/slice_*.py`):
  spostare in `art_src/` ignorata o escludere dall'export; **non** rimuovere (servono a ri-slicing).
- [ ] **P2** Set Era 3 (`backgrounds/era3_*`, `era3_futuro/*`, `decisioni_era3/*`, ~13 file): seme
  Era 3 opzionale; tenere se si valuta l'Era 3, altrimenti `art_src/`.
- [ ] **P2** `siege/era1|2/unit_totem.png` (2): superati da `unit_caster` → **rimuovibili** (fatto, vedi §4).
- [ ] **P2** `backgrounds/era1_pitture.png`, set `map/Chosen_consequences`/`interactive_marker`:
  verificare uso reale con `tools/asset_audit.py` prima di toccare.
- [ ] **P1** Eseguire `tools/asset_audit.py` per la lista autoritativa referenziati/orfani/rotti.

---

## 4. POLISH / BUG / DEBITO TECNICO (P1/P2)
- [ ] **P0 (doc-only)** Allineare `Docs/17` §8/§10 e `Docs/16/18`: gli asset Assedio dati per
  mancanti **esistono e sono cablati** — marcarli risolti per non rifare lavoro.
- [ ] **P1** Build `.exe` Windows (manuale): Godot → Export → Windows Desktop → test su PC pulito.
- [ ] **P1** Verificare export esclude `_sheets`/`art_src`/`Docs`/`tools` (`export_presets.cfg`).
- [ ] **P1** Uniformare pannelli inline (`call_button`, backing card) via `UiStyle` (causa del
  "non uniforme").
- [ ] **P2** Audit kill-tween al reset run (idle decisione, vignette, narrative, drift) per evitare
  callback su nodi liberati.
- [ ] **P2** J16: legare il ciclo giorno/notte allo step quest. Ciclo attuale molto **sottile**
  (overlay alpha bassi) — opzione: accentuare la notte se la si vuole notare di più.
- [ ] **P2** Relazione/video d'esame (`Docs/14`, `Docs/15`): parti soggettive + cattura video.
- [ ] **P2** QA regressione dopo gli interventi: `--import` (exit0), `validate_scenes` (0 failures),
  `balance_sim` (6 finali + Assedio), `playtest_curve` (Era 1+2), rivedere `tools/shoot.gd`.

---

## 5. Sequenza consigliata (impatto/sforzo)
1. **Sprint UI-A (solo codice, P0)** §1.3 — griglia 2×4 stat + tooltip + CTA + barra colorata. Max ROI.
2. **Sprint Asset-UI (P0/P1)** — `risorse.png` + icone Ledger (cablaggio automatico).
3. **Sprint Narrativa (P1)** §2 — pacing Era 2 + ritaglio testi + typewriter. Rilancia `balance_sim`.
4. **Sprint Pulizia & Build (P1)** §3.3/3.4 (`asset_audit.py` → orfani in `art_src/`) + .exe + doc.
5. **Polish residuo (P2)** — pannelli inline, J16, glifi tasti, kill-tween.

## 6. Routine automatica delle 6:00
Una routine (cron `0 6 * * *`) ri-scansiona il progetto, ri-legge i Docs/codice/asset/git, e
**rigenera+pusha questo documento** così, riaprendo, il team trova sempre lo "scanner" aggiornato
con cosa fare. Vedi setup in `tools/` / scheduled task.

---
### File chiave
HUD/decisione/villaggio/resource-bar/modali → `scripts/main.gd` · tema+UI-kit → `scripts/autoload/ui_style.gd`
· stato → `scripts/autoload/game_state.gd` · carta drag → `scripts/ui/draggable_item.gd` · scena →
`scenes/main.tscn` · quest/dati → `scripts/autoload/quest_manager.gd`, `data/{quests,decisions}/*.tres`
· Ledger → `scripts/ui/ledger_screen.gd` · Assedio (completo) → `scripts/siege/*.gd` · QA →
`tools/{asset_audit,balance_sim}.py`, `tools/{validate_scenes,shoot}.gd`, `tools/playtest_curve.tscn`.

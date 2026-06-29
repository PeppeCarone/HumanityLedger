# 19 — PIANO MASTER (scanner del gioco) — HumanityLedger

> **Documento vivo, rigenerato automaticamente dalla routine delle 6:00** (vedi §6). Ultimo
> aggiornamento: **2026-06-29 (mattina)**. Audit a sola lettura del progetto Godot 4.6.
> Ogni `- [ ]` è azionabile: priorità (P0/P1/P2), passi concreti, file, asset necessari.
> **L'Assedio 2.0 e il Villaggio Vivo sono COMPLETI** e non vanno ripianificati.

## 0. Sintesi — stato del gioco e cosa manca per un gioco "bello e finito"

HumanityLedger è **feature-complete, esteticamente coerente e molto avanzato verso il "rifinito"**.
Funzionano end-to-end: 2 ere con transizione, ~34 decisioni drag-and-drop, 8 stat + economia Risorse,
villaggio costruibile con camera libera + diorama vivo (giorno/notte, meteo, abitanti), mappa-mondo
animata, Ledger meta-progressivo, 6 finali, mystery, **Assedio 2.0** completo (auto-battler boss
multi-fase cinematografico, ultimate telegrafata, truppe ascesa, balance verificato). Audio originale,
shader, animazione procedurale ovunque.

**Progresso dalla scansione precedente (2026-06-23 → 2026-06-29):**
- ✅ **Sprint UI-A COMPLETO**: HUD griglia 2×4, STAT_DESCR + tooltip stat, resource bar icona dedicata,
  tooltip strategia (draggable_item.gd), barra fill colorata per fascia.
- ✅ **Icone Ledger**: `lore.png`, `artefatto.png`, `evento.png` — presenti, importati, cablati.
- ✅ **Boss multi-fase cinematografico**: letterbox + title-card, cambio fase con itstop/zoom/vignetta,
  ultimate telegrafata, balance (normali ~1/4 vita, solo ULTIMATE one-shotta).
- ✅ **Truppe ascesa (Lv5)**: `unit_*_ascesa.png` per tutti e 4 gli archetipi — presenti e integrati.
- ✅ **Sprite nemici completi**: bruto, cinghiale, golem, guaritore, iena, minotauro, negromante, orso,
  predone, scheletro, sciamano-oscuro, scudiero, stregone, tessitore, stregone-capo — tutti presenti.
- ✅ **Drago Era 2** (boss + fase 2) + VFX soffio/fiammata.
- ✅ **Modali leggibili**: righe accese, barra salute villaggio a gradiente.
- ✅ **Polish UI anti-prototipo**: decisione/Ledger/pausa.

**Cosa manca per il salto "molto buono → esame-pronto":**
1. **Uniformità pannelli (P1)** — `call_button` e backing card di `draggable_item` usano ancora
   `StyleBoxFlat` inline invece di `UiStyle`; convivono 2 stili di pannello.
2. **Quest pacing Era 2 (P1)** — 3 quest vs 4 di Era 1; asimmetria percepibile.
3. **Typewriter cap (P1 minore)** — `text.length() / 45.0` può restituire testi >3s; cappare a 1.6s.
4. **Build .exe (P1)** — nessun `export_presets.cfg` trovato; l'exe non è stato esportato.
5. **asset_audit.py (P1)** — lista autoritativa orfani/rotti non eseguita.
6. **Relazione / video d'esame (P1-P2)** — parti soggettive, cattura video da fare.

---

## 1. OVERHAUL UI — stile Clash of Clans / Age of Empires (P1 residuo)

### 1.1 Stato UI al 2026-06-29

**FATTO:**
- HUD stat: griglia 2×4 (`GridContainer 2 col`), pill `[icona][valore]`, tooltip con `STAT_DESCR`. ✅
- Barra fill colorata: rosso <25, bronzo medio, verde >70. ✅
- Resource bar: `_icona_risorse()` usa `icons/risorse.png` (non più proxy costruzione). ✅
- Tooltip strategia: `draggable_item.gd` usa `descrizione_strategia` (nome + natura). ✅
- Icone Ledger: `lore.png`, `artefatto.png`, `evento.png` → cablate. ✅
- Modali: righe accese, barra salute villaggio gradiente. ✅

**ANCORA DA FARE:**

**A. Uniformità pannelli inline (P1)**
- [ ] **P1** `call_button` (`main.gd:275-291`): migrare `_stile_call_button()` da
  `StyleBoxFlat` inline a `UiStyle.panel_stylebox()` con i border-radius bronzo.
  Impatto visivo basso (il pulsante è già stilizzato) ma rimuove duplicazione.
  File: `scripts/main.gd` riga 275.
- [ ] **P1** Backing card `draggable_item.gd` (riga 83): `StyleBoxFlat` inline con
  `bg_color (0.10, 0.08, 0.06, 0.45)` → migrare a `UiStyle.panel_clean()` o variante traslucida.
  File: `scripts/ui/draggable_item.gd` riga 81-90.

**B. CTA modali (P1-facile)**
- [ ] **P1** Pulsante "Costruisci" / "Migliora" nei modali build/upgrade: aumentare il
  font_size da default a 18px e aggiungere colore oro (Color(0.97, 0.9, 0.7)).
  File: `main.gd:_apri_pannello_costruzione/_upgrade` (cerca `add_child(_pulsante_costruisci`).

**C. Hover-glow drop-zone (P2)**
- [ ] **P2** `ring_focus.png` come hover-glow verde sulle piazzole consiglieri. Già presente
  in `Assets/art/ui/ring_focus.png`. File: `main.gd` (`_crea_drop_zone`).

**D. Cornici tomo (P2)**
- [ ] **P2** Aggiungere cornici angolo (`corner_tl/tr/bl/br.png`) a Menu principale e Mappa-mondo
  (già presenti su Ledger). File: `main_menu.gd`, `world_map.gd`.

**E. Glifi tasti (P2 opzionale)**
- [ ] **P2** Sostituire Label "V/L/ESC" con chip visivi (piccolo badge bronzo).
  File: `main.gd` HUD chip shortcuts.

---

## 2. QUEST LINE / NARRATIVA (P1)

**Dove vivono i testi:** decisioni `data/decisions/*.tres` (`testo_consigliere`, `label_text`,
`feedback_testo`); quest `data/quests/*.tres`; richiami cross-era `main.gd:RICHIAMI`;
lore `ledger_screen.gd:LORE_REGISTRY`; finali `data/finali/*.tres`.

**Pacing confermato (scan `main.gd:QUEST_SEQUENZE`):**
Era 1 = 4 quest (`q_caverna_tutorial`, `q_accampamento`, `q_confronto`, `q_idolo_del_fuoco`).
Era 2 = 3 quest (`q_corte_si_forma`, `q_pressione_imperi`, `q_scelta_finale`). **Asimmetria persistente.**

- [ ] **P1** Riequilibrare Era 2: spezzare `q_pressione_imperi` o `q_scelta_finale` **oppure**
  assegnare 2-3 decisioni `d_corte_*` orfane a una quest dedicata → 4 quest anche in Era 2.
  File: `data/quests/*.tres`, `main.gd:QUEST_SEQUENZE` (riga 11-23).
- [ ] **P1** Typewriter cap: `main.gd:_show_narrative` riga 1708 usa `text.length() / 45.0`;
  aggiungere `min(..., 1.6)` per evitare animazioni >1.6s su testi lunghi.
  File: `scripts/main.gd` riga 1705-1709.
- [ ] **P1** "Ritaglio" testi: `testo_consigliere` >40 parole → accorciare mantenendo voce;
  ogni prompt finisce con domanda (D040). Tool: `tools/improve_decisions.py`.
- [ ] **P2** Quest-log mini-pannello: titolo + step "N/M" (`current_step`, `current_quest.passi.size()`).
- [ ] **P2** Riverificare 6 finali + mystery dopo riequilibrio (`tools/balance_sim.py`).
- [ ] **P2** Tutorial diegetico: micro-tooltip al primo pickup carta.

---

## 3. AUDIT ASSET (P1)

**Presenti e USATI** (confermati via scan 2026-06-29): 16 ritratti consiglieri, 4 ambasciatori,
5 sfondi decisione, 2 terreni, 72 edifici villaggio + deco/atmosfera, **8 icone stat** (in
`art/stats/`), **8 icone strategia** (in `art/strategie/`), 12 illustrazioni eventi, 6 finali,
3+1 artefatti, mappa-mondo (layers/transformation/feedback/lines), UI-kit (~32 file in `art/ui/`),
**3 icone Ledger** (`lore.png`, `artefatto.png`, `evento.png`), `icons/risorse.png`.

**ASSEDIO — ASSET COMPLETI** (aggiornamento 2026-06-29):
- Difensori: `unit_bloccatore/tiratore/sciamano/caster.png` + `_ascesa.png` per tutti 4. ✅
- Boss: `boss.png` (Colosso Era1 + Drago Era2), `boss_fase2.png` (drago). ✅
- Nemici: 14 varianti (bruto, cinghiale, golem, guaritore, iena, minotauro, negromante, orso,
  predone, scheletro, sciamano-oscuro, scudiero, stregone, tessitore + stregone-capo). ✅
- Mini-boss Era 2: `enemy_tessitore.png` (Il Tessitore d'Ossa). ✅
- VFX: `fiammata_drago`, `fire_burst`, `frost_burst`, `impatto_terra`, `onda_ruggito`,
  `portale_evoca`, `proiettile_aoe`, `shockwave`, `splash_trionfo/sopraffatto`, `aura_gelo`. ✅
- UI Assedio: `boss_bar.png`, `wave_banner.png`. ✅

**Unico asset mancante per l'Assedio:** sprite mini-boss Era 1 (*Lo Stregone della Tribù*) —
oggi usa `enemy_stregone_capo.png` come proxy, accettabile.

**MANCANTI / da generare (non-Assedio):**
- [ ] **P2** `icons/keys/*`, `icons/action/*` — fallback a codice, non bloccanti.
- [ ] **P2** Catastrofi dedicate (oggi riusano `eventi/*`).
- [ ] **P2** Edifici Lv2/Lv3 (`Assets/art/villaggio/era<N>/<TT>_lv<L>.png`) — codice li carica se
  presenti, ma il fallback (Lv1 ripetuto) è accettabile. Priorità bassa.

**INUTILIZZATI (candidati a pulizia — confermare con `tools/asset_audit.py`):**
- [ ] **P1** Eseguire `tools/asset_audit.py` per la lista autoritativa referenziati/orfani/rotti.
- [ ] **P2** `Assets/art/_sheets/*` (~35 sheet sorgente raw): spostare in `art_src/` ignorata
  o escludere dall'export; **non rimuovere** (servono a ri-slicing).
- [ ] **P2** Set Era 3 (`backgrounds/era3_*`, `era3_futuro/*`, `decisioni_era3/*`, ~13 file):
  tenere se si valuta Era 3, altrimenti `art_src/`.
- [ ] **P2** `backgrounds/era1_pitture.png`, set `map/Chosen_consequences/`: verificare con `asset_audit.py`.

---

## 4. POLISH / BUG / DEBITO TECNICO (P1/P2)

- [ ] **P1** Build `.exe` Windows: nessun `export_presets.cfg` trovato → creare preset da Godot
  (Editor → Project → Export → Add Windows Desktop), escludere `Docs/`, `tools/`, `_sheets/`,
  `art_src/` dal build, esportare e testare su PC pulito.
- [ ] **P1** Verificare export esclude `_sheets`/`art_src`/`Docs`/`tools` (`export_presets.cfg`).
- [ ] **P1** Eseguire `balance_sim.py` con le nuove ondate Assedio 2.0 (il playtest automatico
  copre ancora Era 1; aggiornare per Era 2). File: `tools/balance_sim.py`.
- [ ] **P2** Audit kill-tween al reset run (idle decisione, vignette, narrative, drift) per
  evitare callback su nodi liberati. File: `main.gd` (cerca `Tween`).
- [ ] **P2** J16: ciclo giorno/notte legato allo step quest. Overlay attuale molto tenue —
  opzione: accentuare la notte per la `q_scelta_finale` (atmosfera vigilia).
- [ ] **P2** MCP bridge (`scripts/autoload/mcp_interaction_server.gd`) — verificare che sia
  escluso dall'export release (solo editor-only). UID file `mcp_interaction_server.gd.uid`
  non-committato: aggiungere a `.gitignore` se si vuole.
- [ ] **P2** Relazione/video d'esame (`Docs/14`, `Docs/15`): parti soggettive + cattura video.
- [ ] **P2** QA regressione dopo interventi: `--import` (exit0), `validate_scenes` (0 failures),
  `balance_sim` (6 finali + Assedio), `playtest_curve` (Era 1+2), riverificare `tools/shoot.gd`.

---

## 5. Sequenza consigliata (impatto/sforzo) — oggi

> Sprint UI-A e asset Assedio sono COMPLETI. Il gioco è già in stato "da esame" con i contenuti
> attuali. Quello che segue è il delta finale per renderlo esame-eccellente.

1. **Typewriter cap (15 min, P1)** — `main.gd:1708`: `min(text.length() / 45.0, 1.6)`.
   Elimina lentezze sui testi lunghi.
2. **Quest Era 2 (1-2h, P1)** — aggiungere una 4a quest o redistribuire decisioni d_corte_*;
   rilancia `balance_sim`. File: `data/quests/*.tres`, `main.gd:QUEST_SEQUENZE`.
3. **Uniformità pannelli (30 min, P1)** — `call_button` e backing card → `UiStyle`.
   File: `main.gd:275`, `draggable_item.gd:81`. Zero impatto gameplay, tocca solo lo stile.
4. **asset_audit.py (10 min, P1)** — identifica orfani prima di creare export.
5. **Build .exe (30 min, P1)** — Godot Export → Windows Desktop → testa su PC pulito.
6. **Polish residuo (P2)** — hover-glow drop-zone, J16 notte vigilia, cornici tomo menu/mappa,
   kill-tween, tutorial diegetico.

---

## 6. Routine automatica delle 6:00

Una routine (cron `0 6 * * *`) ri-scansiona il progetto, ri-legge Docs/codice/asset/git, e
**rigenera+pusha questo documento** così, riaprendo, il team trova sempre lo "scanner" aggiornato
con cosa fare. Vedi setup in `tools/` / scheduled task.

---

### File chiave

HUD/decisione/villaggio/resource-bar/modali → `scripts/main.gd`
(HUD griglia: riga 593, resource bar: 2666, typewriter: 1708, call_button style: 275)
· tema+UI-kit → `scripts/autoload/ui_style.gd`
· stato → `scripts/autoload/game_state.gd`
· carta drag → `scripts/ui/draggable_item.gd`
· scena → `scenes/main.tscn`
· quest/dati → `scripts/autoload/quest_manager.gd`, `data/{quests,decisions}/*.tres`
· Ledger → `scripts/ui/ledger_screen.gd`
· Assedio (completo) → `scripts/siege/*.gd`
· QA → `tools/{asset_audit,balance_sim}.py`, `tools/{validate_scenes,shoot}.gd`,
  `tools/playtest_curve.tscn`

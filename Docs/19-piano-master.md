# 19 — PIANO MASTER (scanner del gioco) — HumanityLedger

> **Documento vivo.** Ultimo aggiornamento: **2026-10-04**, con audit a schermo (Godot 4.6.1
> renderizzato: 28 scatti `shoot.gd` + 14 `shot_ui.gd`) e QA completa. La versione precedente
> (2026-06-29) era generata da una routine locale delle 6:00 che non gira più: questo file
> va aggiornato a mano a fine sessione.
> Ogni `- [ ]` è azionabile: priorità (P0/P1/P2), file, passi.

## 0. Sintesi

HumanityLedger è **consegnato** (esame, luglio 2026: exe Windows, GDD, manuale, note
tecniche) e **feature-complete**: 2 ere, 41 decisioni, 8 quest (4+4), 8 stat + Risorse,
villaggio costruibile e vivo, mappa-mondo, Ledger meta-progressivo, 6 finali + finale
segreto, NG+ (Eone), difficoltà, L'Assedio 2.0 (auto-battler con boss multi-fase) e il
Duello finale con l'Ultimo Dio.

**Sessione 2026-10-04 — pass di integrità visiva** (dettaglio in
[`24-integrita-visiva.md`](24-integrita-visiva.md)): l'arte dipinta del kit (barra del boss,
banner d'ondata, cartigli, cornici, pulsanti) era stirata col 9-slice su tele piene di padding
e i pulsanti sotto i CanvasLayer erano grigi di sistema; 8 illustrazioni Era 2 avevano
didascalie inglesi stampate; 3 ritratti avevano pezzi dei vicini. Tutto corretto e verificato.

**QA al 2026-10-04:** import pulito · `validate_scenes` 0 failure · `balance_sim` 6/6 finali +
Assedio "sfida" · `asset_audit` nessun riferimento rotto · `playtest_curve`/`_finale`/`_assedio`
dentro l'envelope noto.

---

## 1. Chiuso dal piano del 2026-06-29

- [x] Typewriter cap (`minf(text.length() / 45.0, 1.6)` in `main.gd`).
- [x] Quest Era 2 a 4 (`q_prova_del_regno`): pacing simmetrico 4+4.
- [x] Uniformità pannelli: `call_button` → `UiStyle.cta_button_stylebox`, backing della carta
  → `UiStyle.card_backing_stylebox`.
- [x] Hover-glow `ring_focus` sulle piazzole (`drop_zone.gd`), cornici d'angolo su menu e mappa,
  chip dei tasti (V/L/ESC) nell'HUD, mini quest-log "passo N/M".
- [x] Build `.exe` Windows consegnata (icona, PCK embedded) + fix `.tres.remap` nei build.
- [x] Mini-boss Era 1 dedicato (Stregone della Tribù), Duello finale a 3 fasi.
- [x] J16: la vigilia (`q_scelta_finale`) resta notte.
- [x] MCP bridge solo-editor (`OS.has_feature("editor")`, mai nei build).
- [x] `asset_audit.py` eseguito **e corretto** (falsi "MANCA"/"non usate" eliminati).
- [x] **Integrità visiva** del UI kit, delle illustrazioni e dei ritratti (Docs/24).

## 2. Ancora aperto

**Testi**
- [ ] **P1** 34 `testo_consigliere` su 41 superano le 40 parole (picchi 60-67 in Era 2:
  `d_corte_06/09/05/02/08`). Accorciare tenendo la voce e la domanda finale (D040).
  Strumento: `tools/improve_decisions.py`. Rileggere a schermo con `shot_ui` (`ui_carestia`).

**Robustezza**
- [ ] **P2** Audit dei `Tween` al reset run (idle decisione, vignette, narrative, drift):
  nessun callback su nodi liberati. File: `scripts/main.gd`.
- [ ] **P2** `playtest_curve` è stocastico (stesse build → esiti diversi tra run): fissare il
  seed (`seed()` in `_ready`) per un envelope ripetibile. File: `tools/playtest_curve.gd`.

**Build**
- [ ] **P2** Escludere `Assets/art/_sheets/` (34 MB di fogli sorgente) dall'export: filtro in
  `export_presets.cfg` (non versionato) o spostamento in una cartella ignorata.

**Arte (opzionale, serve generazione)**
- [ ] **P2** Catastrofi con illustrazioni dedicate (oggi riusano `eventi/*`).
- [ ] **P2** Tutorial diegetico: micro-suggerimento al primo trascinamento di una carta.

**Esame / dopo l'esame**
- [ ] **P2** Video e parti soggettive della relazione (`Docs/14`, `Docs/15`) — se servono ancora.
- [ ] **Opz.** Era 3 "Futuro" (asset parziali in `Assets/art/era3_futuro`, `decisioni_era3`,
  `risorse_era3`): terza voce in `QUEST_SEQUENZE`, decisioni/quest/finali, edifici, terzo
  set Assedio. Grosso scope: da decidere esplicitamente.

## 3. Sequenza consigliata

1. Testi lunghi Era 2 (P1, solo dati) → riverifica `balance_sim` (i testi non toccano i numeri).
2. Seed fisso in `playtest_curve` (P2, 10 minuti) → envelope ripetibile per i ritocchi futuri.
3. Tween al reset (P2) e pulizia export `_sheets` (P2).
4. Era 3, solo se si decide di continuare il progetto oltre l'esame.

---

### File chiave

HUD/decisione/villaggio/modali → `scripts/main.gd` · tema, UI kit, arte dipinta →
`scripts/autoload/ui_style.gd` + `scripts/ui/cornice_dipinta.gd` + `scripts/ui/style_box_dipinto.gd`
· Assedio → `scripts/siege/*.gd` · dati → `data/{quests,decisions,...}/*.tres`
· QA → `tools/{asset_audit,balance_sim}.py`, `tools/{validate_scenes,shoot,shot_ui}.gd`,
`tools/playtest_{curve,assedio,finale}.tscn` · asset da fogli → `tools/slice_assets.py`,
`tools/fix_ritratti.py`.

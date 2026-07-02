# HUMANITY LEDGER — Note tecniche

*Godot 4.6.1 · GDScript · Windows x86_64 (Vulkan Forward+ / GL Compatibility)*

## Struttura del progetto
```
scenes/            main_menu, main (loop di gioco), ui/ (drop_zone, ending, ledger, opzioni…)
scripts/
  autoload/        GameState · Ledger · QuestManager · Diplomacy · SaveSystem
                   AudioManager · NarrativeLog · UiStyle · PostFX
  data/            Resource: Decision, DecisionOption, Strategia, Quest, Personaggio,
                   Effect, Finale, Catastrofe, Artefatto, EventoSbloccabile, Civilta
  siege/           siege.gd (arena) · enemy · defender · projectile · boss
  ui/              main.gd è il game-loop; village_view (diorama vivo), world_map, …
data/              contenuti .tres (decisioni, quest, strategie, personaggi, finali…)
Assets/art|audio   arte e musica (cablaggio fallback-safe: PNG assente → placeholder)
tools/             QA: validate_scenes, playtest_curve/assedio/finale, shoot/shot_arsenale
Docs/              design log (01–20), GDD (21), manuale (22), queste note (23)
```

## Scelte architetturali
- **Data-driven**: i contenuti sono Resource `.tres`; aggiungere decisioni/quest/finali non
  richiede codice. Il game-loop legge sequenze per era.
- **Autoload come servizi**: stato di run (GameState) separato dalla meta-progressione
  (Ledger) e dalle preferenze (AudioManager/settings.cfg). Save JSON versionati in `user://`.
- **Assedio costruito via codice** (nessuna scena): l'arena genera HUD, corsia, formazioni;
  le unità scalano dalle statistiche della run e dal livello per-tipo; il villaggio
  contribuisce con l'**arsenale** (hp/monete/truppe/livello).
- **Fallback-safe art pipeline**: ogni texture passa da helper con cache
  (`_siege_tex/_fx_tex/UiStyle.icona`); PNG mancante → resa procedurale coerente. Gli asset
  si "cablano da soli" per convenzione di nome (es. `fx/<base>_<boss>.png`).
- **Post-FX**: CanvasLayer autoload con shader screen-space (vignette, grade, grana,
  aberrazione) sopra ogni scena; parametri regolabili a runtime.
- **Fluidità**: prewarm delle texture del fight in `configura()` (niente load nel frame di
  spawn), aggiornamenti label solo-su-cambio, tween con cleanup, hitstop re-entrant-safe.

## Qualità / QA
- `validate_scenes.gd` — istanzia tutte le scene: 0 failure richiesti.
- `playtest_curve` — giocatore ATTIVO simulato su 3 build × 2 ere: envelope atteso
  (debole lotta/perde · medio passa · forte trionfa). Isolato dallo stato utente
  (NG+/difficoltà azzerati in memoria).
- `playtest_finale` — il duello su 4 combinazioni build×arsenale: sempre vittoria con
  tensione (villaggio 40–65%).
- `shot_arsenale` / `shoot` — harness di screenshot per la verifica visiva di ogni schermata.

## Build
1. Godot 4.6.1 + export templates 4.6.1.
2. Preset "Windows Desktop" (incluso): PCK embedded, exclude di Docs/tools.
3. `godot --headless --path . --export-release "Windows Desktop"` → `exports/HumanityLedger.exe`.
4. Icona: `icon.png` (progetto) + `icon.ico` impressa nell'exe con rcedit.

## Salvataggi (user://)
`save.json` (run corrente) · `ledger.json` (meta: lore/artefatti/eventi/Eone) ·
`settings.cfg` (audio/video/difficoltà).

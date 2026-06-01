# 04 — Architettura tecnica

> Come è strutturato il progetto Godot 4.6. Struttura di cartelle, scene principali, autoload, modello dati, save system, Ledger.
> Documento operativo: ciò che è scritto qui va implementato così salvo modifiche tracciate in `07-decisions-log.md`.
> Versione 0.2 — riscritta dopo intervista del 2026-06-01.

---

## Linguaggio

- **GDScript** (no C#). Motivo: iterazione più rapida, meno overhead per un team di 2, nessuna dipendenza .NET.
- Tipizzazione **statica** dove possibile (`var x: int = 0`), per leggibilità e autocomplete.

## Struttura di cartelle

```
HumanityLedger/
├── project.godot
├── README.md
├── CONTRIBUTING.md
├── Docs/                   # documentazione di design
├── addons/                 # plugin Godot (vuoto inizialmente)
├── Assets/                 # asset visivi e audio
│   ├── art/
│   │   ├── era1_paleo/     # ritratti, sfondi, edifici Era 1
│   │   ├── era2_mitico/    # ritratti, città, edifici Era 2
│   │   ├── strategie/      # 8 icone strategia
│   │   ├── catastrofi/     # 8 illustrazioni catastrofe
│   │   ├── ambasciatori/   # ritratti civiltà rivali
│   │   ├── finali/         # 6 illustrazioni epilogo
│   │   ├── ui/             # cornici, pannelli, font
│   │   └── ledger/         # icone artefatti, sfondo schermata
│   ├── audio/
│   │   ├── music/          # 3-4 brani orchestrali
│   │   └── sfx/            # 10-15 SFX
│   ├── fonts/
│   └── CREDITS.md          # crediti asset esterni e licenze
├── data/                   # Resource .tres data-driven
│   ├── quests/             # 1 .tres per quest
│   ├── decisions/          # 1 .tres per decisione
│   ├── characters/         # 1 .tres per consigliere
│   ├── ambasciatori/       # 1 .tres per ambasciatore
│   ├── catastrofi/         # 1 .tres per catastrofe
│   ├── strategie/          # 1 .tres per strategia
│   ├── artefatti/          # 1 .tres per artefatto del Ledger
│   ├── eventi_sbloccabili/ # 1 .tres per evento Ledger
│   ├── finali/             # 1 .tres per finale
│   └── effetti/            # effetti riutilizzabili (modifica stat)
├── scenes/
│   ├── main.tscn           # entry point: menu principale
│   ├── game.tscn           # scena di gioco principale (cambia layout per era)
│   ├── transition.tscn     # transizione tra ere
│   ├── ending.tscn         # schermata finale
│   ├── ledger.tscn         # schermata Ledger
│   └── ui/
│       ├── hud.tscn        # HUD con 8 stat
│       ├── decision_panel.tscn  # pannello con drag
│       ├── narrative_panel.tscn # pannello feedback testo
│       ├── quest_log.tscn       # pannello quest attive
│       ├── minimap.tscn         # mini-mappa diplomatica
│       └── ambasciatore.tscn    # ritratto ambasciatore in scena
├── scripts/
│   ├── autoload/           # singleton scripts
│   │   ├── game_state.gd
│   │   ├── ledger.gd
│   │   ├── quest_manager.gd
│   │   ├── narrative_log.gd
│   │   ├── diplomacy.gd
│   │   └── save_system.gd
│   ├── ui/
│   ├── gameplay/
│   └── data/               # classi Resource
└── exports/                # build esportate (gitignored)
```

## Autoload (singleton)

Configurati in `Project Settings → Autoload`. Sempre disponibili globalmente.

### `GameState`

Mantiene lo stato della run corrente.

```gdscript
extends Node

# 8 stat
var militare: int = 30
var tesoro: int = 30
var diplomazia: int = 30
var scienza: int = 30
var legge: int = 30
var spionaggio: int = 30
var popolo: int = 30
var costruzione: int = 30

# risorse derivate
var popolazione: int = 40

# progressione
var era_corrente: int = 1
var atto_corrente: int = 1
var quest_completate: Array[String] = []
var flag_narrativi: Dictionary = {}
var decisioni_chiave: Array[String] = []   # per finali

# rivali (relazione -100..+100)
var rapporti_civilta: Dictionary = {}

# artefatto attivo nella run
var artefatto_equipaggiato: String = ""

signal stat_changed(nome: String, valore_vecchio: int, valore_nuovo: int)
signal flag_set(nome: String, valore: Variant)
signal era_advanced(nuova_era: int)

func apply_effect(effect: Effect) -> void:
    # modifica le stat e emette il segnale stat_changed
    ...
```

### `Ledger`

Persistente tra le run. Salva separatamente da `GameState`.

```gdscript
extends Node

var lore_sbloccata: Array[String] = []          # id di frammenti
var artefatti_disponibili: Array[String] = []   # id artefatti sbloccati
var eventi_sbloccati: Array[String] = []        # eventi nascosti scoperti

# stato del playthrough corrente da "registrare" a fine run
var current_run_discoveries: Array[String] = []

signal lore_unlocked(id: String)
signal artefatto_unlocked(id: String)

func unlock_lore(id: String) -> void: ...
func unlock_artefatto(id: String) -> void: ...
func is_evento_sbloccabile_available(id: String) -> bool: ...

func save() -> void: ...   # scrive user://ledger.json
func load() -> void: ...
```

### `QuestManager`

Carica tutte le quest da `data/quests/*.tres`, valuta quale offrire in base ai prerequisiti.

```gdscript
extends Node

var tutte_le_quest: Array[Quest] = []
var quest_attive: Array[Quest] = []
var quest_chiave_corrente: Quest = null
var quest_log_visibili: Array[Quest] = []

signal quest_avviata(quest: Quest)
signal quest_completata(quest: Quest)
signal quest_chiave_completata(quest: Quest)

func valuta_prossima_quest() -> Quest: ...
func aggiorna_log() -> void: ...
```

### `NarrativeLog`

Coda dei testi di feedback narrativo da mostrare in UI.

### `Diplomacy`

Gestisce stato delle civiltà rivali, eventi diplomatici, ambasciatori.

```gdscript
extends Node

class CivData:
    var id: String
    var nome: String
    var era: int          # 1 o 2
    var militare_rel: int # quanto sono forti rispetto a noi
    var rapporto: int     # -100..+100
    var ambasciatore_id: String

var civilta: Dictionary = {}   # id -> CivData

func presenta_ambasciatore(civ_id: String) -> void: ...
func aggiorna_rapporto(civ_id: String, delta: int) -> void: ...
```

### `SaveSystem`

Serializza `GameState` in `user://save.json` dopo ogni decisione. NON tocca il `Ledger` (gestito da `Ledger.save()`).

```gdscript
extends Node

const SAVE_PATH := "user://save.json"
const LEDGER_PATH := "user://ledger.json"

func save_run() -> void: ...
func load_run() -> bool: ...
func exists_run() -> bool: ...
func reset_run() -> void: ...   # cancella save corrente, mantiene Ledger
```

## Modello dati (Resource classes)

Definite in `scripts/data/`. Sono `Resource` Godot, salvabili come `.tres`, editabili dall'editor.

### `Effect`

```gdscript
class_name Effect
extends Resource

@export var stat_delta: Dictionary = {}    # {"militare": -10, "tesoro": +5}
@export var set_flags: Dictionary = {}     # {"straniero_accolto": true}
@export var unlock_lore: Array[String] = []   # id lore Ledger da sbloccare
@export var add_decisione_chiave: String = ""  # per logica finali
@export var add_to_log: String = ""        # testo narrativo
@export var rapporti_civilta: Dictionary = {}  # {"impero_sole": -10}
```

### `Strategia`

```gdscript
class_name Strategia
extends Resource

@export var id: String                # es. "azione_militare"
@export var nome: String              # "Azione Militare"
@export var icona: Texture2D
@export var prerequisiti_stat: Dictionary = {}   # {"militare": 20}
@export var prerequisiti_flag: Array[String] = []
@export var gesto_tipo: String         # "icona_su_mappa", "ritratto_su_consigliere", ecc.
@export var target_tag: String          # tag che il drop target deve avere
```

### `Decision`

```gdscript
class_name Decision
extends Resource

@export var id: String
@export var era: int                   # 1 o 2
@export var testo_consigliere: String  # max 80 parole
@export var personaggio_id: String     # chi parla (consigliere o ambasciatore)
@export var opzioni: Array[DecisionOption]
@export var tipo_decisione: String     # "proposta_consigliere" o "reazione_evento"
```

### `DecisionOption`

```gdscript
class_name DecisionOption
extends Resource

@export var strategia_id: String       # link a Strategia
@export var oggetto_drag: String       # "icona_strategia" | "ritratto_consigliere" | "token_tematico"
@export var icona_drag: Texture2D
@export var target_tag: String
@export var effetto: Effect
@export var feedback_testo: String     # max 40 parole
```

### `Quest`

```gdscript
class_name Quest
extends Resource

@export var id: String
@export var titolo: String
@export var era: int                   # 1 o 2
@export var tipo: String               # "principale" | "chiave" | "opzionale" | "mystery"
@export var precondizioni_flag: Array[String] = []
@export var precondizioni_stat: Dictionary = {}
@export var passi: Array[Decision]
@export var effetto_completamento: Effect
@export var flag_di_completamento: String
@export var visibile_nel_log: bool = true
@export var descrizione_log: String    # cosa mostrare nel quest log
```

### `Personaggio`

```gdscript
class_name Personaggio
extends Resource

@export var id: String                 # es. "lyssa_era1"
@export var nome: String               # "Lyssa"
@export var archetipo: String          # "Sciamano"
@export var era: int                   # 1 o 2
@export var stat_collegata: String     # "scienza"
@export var ritratto: Texture2D
@export var tic_linguistico: String    # nota per autori
```

### `Civilta`

```gdscript
class_name Civilta
extends Resource

@export var id: String                 # "clan_del_bisonte"
@export var nome: String
@export var era: int
@export var ambasciatore: Personaggio
@export var simbolo: Texture2D
@export var militare_relativo_iniziale: int  # rispetto al nostro
```

### `Catastrofe`

```gdscript
class_name Catastrofe
extends Resource

@export var id: String                 # "peste"
@export var titolo: String
@export var illustrazione: Texture2D
@export var trigger_condizioni: Dictionary  # stat min/max per attivare
@export var era: int                   # 1, 2 o 0 (entrambe)
@export var decisione_iniziale: Decision
@export var decisioni_followup: Array[Decision] = []
```

### `Artefatto`

```gdscript
class_name Artefatto
extends Resource

@export var id: String                 # "pietra_del_fuoco"
@export var nome: String
@export var descrizione: String        # max 60 parole
@export var icona: Texture2D
@export var effetto_inizio_run: Effect # bonus iniziale
@export var sblocca_dialoghi: Array[String] = []
@export var sblocca_finali: Array[String] = []  # finali resi più ricchi
```

### `EventoSbloccabile`

```gdscript
class_name EventoSbloccabile
extends Resource

@export var id: String                 # "il_fiume_rosso"
@export var nome_visibile: String      # "???" finché non scoperto
@export var nome_segreto: String       # "Il Fiume Rosso"
@export var precondizioni_run_precedenti: Dictionary
@export var decisioni: Array[Decision]
```

### `Finale`

```gdscript
class_name Finale
extends Resource

@export var id: String                 # "era_guerra"
@export var nome: String               # "Era della Guerra"
@export var illustrazione: Texture2D
@export var testo: String              # max 400 parole
@export var musica: AudioStream
@export var condizioni_stat: Dictionary     # stat dominanti necessarie
@export var decisioni_chiave_richieste: Array[String] = []
@export var decisioni_chiave_escludenti: Array[String] = []
```

## Scene tree principale

### `game.tscn` — Era 1 (caverna)

```
Game (Node2D)
├── CavernaBackground (Sprite2D)
├── FuocoCentrale (AnimatedSprite2D)
├── PittureRupestri (Node2D)            # palette cambia per mystery
├── ConsiglieriLayer (Node2D)
│   └── 8 Consigliere (Area2D + Sprite2D + Label)
├── EdificiLayer (Node2D)               # vuoto in Era 1 atto 1
├── DropTargetsLayer (Node2D)           # Area2D + tag per drop
└── UI (CanvasLayer)
    ├── HUD (Control)                   # 8 stat + popolazione
    ├── DecisionPanel (Control)
    ├── NarrativePanel (Control)
    ├── QuestLog (Control)              # toggle apertura
    └── MinimapButton (Control)          # apre minimap.tscn
```

### `game.tscn` — Era 2 (città dall'alto)

```
Game (Node2D)
├── CittaBackground (Sprite2D)          # vista dall'alto
├── EdificiLayer (Node2D)               # mura, tempio, mercati
├── PanelliConsiglieriLaterali (Control)  # 4 a sx, 4 a dx
├── DropTargetsLayer (Node2D)
└── UI (CanvasLayer)                    # stessa di Era 1
```

## Sistema drag-and-drop

Godot ha API nativa (`_get_drag_data`, `_can_drop_data`, `_drop_data` su `Control`). Per il drag in scena 2D usiamo direttamente segnali su `Area2D` + un Control "DragGhost" che segue il mouse.

Flusso:

1. Pressione su un'icona/ritratto/token in `DecisionPanel` → si crea un nodo `DragGhost` con la grafica corrispondente
2. `DragGhost` segue `get_global_mouse_position()` in `_process`
3. Hover su un `Area2D` con tag matching → cambia stato (glow)
4. Al rilascio: si cerca un `Area2D` valido sotto al mouse
5. Se trovato → `DecisionManager` applica `effetto`, emette `decision_resolved`
6. Se non trovato → il ghost si distrugge

Pseudocodice del DecisionManager:

```gdscript
func _on_drop(decision: Decision, opzione: DecisionOption, target_node: Node) -> void:
    GameState.apply_effect(opzione.effetto)
    NarrativeLog.append(opzione.feedback_testo)
    if opzione.effetto.add_decisione_chiave != "":
        GameState.decisioni_chiave.append(opzione.effetto.add_decisione_chiave)
    for lore_id in opzione.effetto.unlock_lore:
        Ledger.unlock_lore(lore_id)
    SaveSystem.save_run()
    Ledger.save()
    emit_signal("decision_resolved", decision, opzione)
```

## Save system

- **Save di run**: autosave dopo ogni decisione in `user://save.json`
- **Ledger save**: persistente in `user://ledger.json`, aggiornato a ogni sblocco
- Formato JSON con tutti i campi di `GameState` (run) e `Ledger` (meta)
- Versionamento: campo `version` per migrazioni future

Esempio JSON di run:

```json
{
  "version": 1,
  "stats": {"militare": 45, "tesoro": 50, "diplomazia": 30, "scienza": 60, "legge": 40, "spionaggio": 20, "popolo": 55, "costruzione": 50},
  "popolazione": 60,
  "era_corrente": 1,
  "atto_corrente": 2,
  "quest_completate": ["q01_caverna_intro", "q02_uscita"],
  "flag_narrativi": {"straniero_accolto": true},
  "decisioni_chiave": ["accolto_popolo_nebbie"],
  "rapporti_civilta": {"clan_del_bisonte": -10},
  "artefatto_equipaggiato": "pietra_del_fuoco"
}
```

Esempio JSON di Ledger:

```json
{
  "version": 1,
  "lore_sbloccata": ["lore_001_fuoco", "lore_002_visione"],
  "artefatti_sbloccati": ["pietra_del_fuoco", "lacrima_di_lyssa"],
  "eventi_sbloccati": ["fiume_rosso"]
}
```

## Pattern: data-driven, non hardcoded

Tutto vive come **risorse `.tres`** editabili dall'editor di Godot. Lo script di gioco non contiene mai testo narrativo o numeri di stat hardcoded.

Questo permette:
- Al designer di scrivere quest e bilanciare senza toccare codice
- Versionamento granulare (diff per file `.tres`)
- Testing più semplice (mock di un `.tres`)

## Tooling

- **Editor**: Godot 4.6 stable
- **Versionamento**: git, vedi `CONTRIBUTING.md`
- **Format script**: 4 spazi indent, snake_case, type hints
- **Testing**: per MVP nessun framework di test automatico — testing manuale tramite playthrough

## Cose da NON fare

- Non usare `_unhandled_input` per drag-and-drop (sovrappone alla UI)
- Non creare `GameState` o `Ledger` come `Node` in scena (devono essere Autoload)
- Non scrivere logica di gameplay dentro le risorse `.tres` — solo dati
- Non usare `print` in produzione: usare un logger autoload se serve
- Non mischiare la persistenza `GameState` (run) con `Ledger` (meta)

## Open questions tecniche

- Risoluzione target: 1920×1080? 1280×720? (decide rendering UI)
- Stretch mode: `viewport` o `canvas_items`?
- Cifratura del file Ledger per impedire trucchi? (probabilmente non serve per MVP)
- Migrazione save tra versioni: come gestiamo upgrade del formato?

---

*Versione 0.2 — 2026-06-01.*

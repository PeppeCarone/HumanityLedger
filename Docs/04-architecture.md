# 04 — Architettura tecnica

> Come è strutturato il progetto Godot 4.6. Struttura di cartelle, scene principali, autoload, modello dati, save system.
> Documento operativo: ciò che è scritto qui va implementato così salvo modifiche tracciate in `07-decisions-log.md`.

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
├── Docs/
│   └── (tutti i .md di design)
├── addons/                 # eventuali plugin Godot (vuoto inizialmente)
├── assets/
│   ├── art/                # immagini, sprite, UI
│   │   ├── icons/          # icone gesti (soldato, monete, pergamena, ecc.)
│   │   ├── characters/     # ritratti consiglieri
│   │   ├── buildings/      # silhouette edifici
│   │   └── ui/             # cornici, pannelli, font
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
├── data/                   # Resource .tres data-driven
│   ├── quests/             # 1 .tres per quest
│   ├── decisions/          # 1 .tres per decisione
│   ├── characters/         # 1 .tres per NPC
│   └── effects/            # effetti riutilizzabili (modifica stat)
├── scenes/
│   ├── main.tscn           # entry point: menu principale
│   ├── game.tscn           # scena di gioco principale
│   ├── ending.tscn         # schermata finale
│   └── ui/
│       ├── hud.tscn        # HUD con 4 stat
│       ├── decision_panel.tscn  # pannello con icone trascinabili
│       └── narrative_panel.tscn # pannello feedback testo
├── scripts/
│   ├── autoload/           # singleton scripts
│   │   ├── game_state.gd
│   │   ├── quest_manager.gd
│   │   ├── narrative_log.gd
│   │   └── save_system.gd
│   ├── ui/
│   ├── gameplay/
│   └── data/               # classi Resource
└── exports/                # build esportate (gitignored)
```

## Autoload (singleton)

Configurati in `Project Settings → Autoload`. Sempre disponibili globalmente.

### `GameState`

Mantiene lo stato del gioco in memoria.

```gdscript
extends Node

var tecnologia: int = 50
var felicita: int = 50
var economia: int = 50
var militare: int = 50
var popolazione: int = 150
var reputazione_rivale: int = 0

var atto_corrente: int = 1
var quest_completate: Array[String] = []
var flag_narrativi: Dictionary = {}  # es. "straniero_accolto": true
var decisioni_storia: Array[Dictionary] = []  # log per epilogo

signal stat_changed(nome: String, valore_vecchio: int, valore_nuovo: int)
signal flag_set(nome: String, valore)

func apply_effect(effect: Effect) -> void:
    # modifica le stat e emette il segnale stat_changed
    ...
```

### `QuestManager`

Carica tutte le quest da `data/quests/*.tres`, decide quale offrire al giocatore in base ai precondizioni.

```gdscript
extends Node

var tutte_le_quest: Array[Quest] = []
var quest_attiva: Quest = null

signal quest_avviata(quest: Quest)
signal quest_completata(quest: Quest)

func valuta_prossima_quest() -> Quest:
    # filtra per precondizioni soddisfatte, ordina per priorità, ritorna la prima
    ...
```

### `NarrativeLog`

Coda dei testi di feedback narrativo da mostrare in UI.

### `SaveSystem`

Serializza `GameState` in un file JSON in `user://save.json` dopo ogni decisione.

```gdscript
extends Node

const SAVE_PATH := "user://save.json"

func save() -> void: ...
func load() -> bool: ...
func exists() -> bool: ...
```

## Modello dati (Resource classes)

Definite in `scripts/data/`. Sono `Resource` Godot, salvabili come `.tres`, editabili dall'editor.

### `Effect`

```gdscript
class_name Effect
extends Resource

@export var stat_delta: Dictionary = {}  # {"felicita": -10, "economia": +5}
@export var set_flags: Dictionary = {}   # {"straniero_accolto": true}
@export var add_to_log: String = ""      # testo narrativo da inserire in NarrativeLog
```

### `Decision`

```gdscript
class_name Decision
extends Resource

@export var id: String
@export var testo_consigliere: String      # max 80 parole
@export var personaggio_id: String         # chi parla
@export var opzioni: Array[DecisionOption] # 2-4 opzioni-gesto
```

### `DecisionOption`

```gdscript
class_name DecisionOption
extends Resource

@export var gesto: String      # es. "moneta_su_edificio", "soldato_su_confine"
@export var icona: Texture2D
@export var target_tag: String # tag che il drop target deve avere
@export var effetto: Effect
@export var feedback_testo: String  # max 40 parole
```

### `Quest`

```gdscript
class_name Quest
extends Resource

@export var id: String
@export var titolo: String
@export var atto: int                     # 1, 2, 3
@export var precondizioni: Array[String]  # flag che devono essere true
@export var stat_min: Dictionary = {}     # es. {"felicita": 30} = serve felicita>=30
@export var passi: Array[Decision]
@export var effetto_completamento: Effect
@export var priorita: int = 0
```

## Scene tree principale

### `game.tscn`

```
Game (Node2D)
├── Background (Sprite2D)         # vista del villaggio
├── BuildingsLayer (Node2D)        # sprite edifici (vengono mostrati/nascosti via flag)
├── CharactersLayer (Node2D)       # consiglieri visibili nella scena
├── DropTargetsLayer (Node2D)      # zone target per drag-and-drop (Area2D + tag)
└── UI (CanvasLayer)
    ├── HUD (Control)             # 4 stat + popolazione
    ├── DecisionPanel (Control)   # icone trascinabili (instanziata quando serve)
    └── NarrativePanel (Control)  # testo feedback
```

## Sistema drag-and-drop

Godot ha API nativa (`_get_drag_data`, `_can_drop_data`, `_drop_data` su `Control`). Per il drag in scena 2D usiamo direttamente segnali su `Area2D` + un Control "DragGhost" che segue il mouse.

Flusso:

1. Pressione su un'icona in `DecisionPanel` → si crea un nodo `DragGhost` con l'icona
2. `DragGhost` segue `get_global_mouse_position()` in `_process`
3. Al rilascio (`InputEventMouseButton` released): si cerca un `Area2D` sotto al mouse con tag corrispondente
4. Se trovato → `DecisionManager` applica `effetto`, emette `decision_resolved`
5. Se non trovato → il ghost si distrugge, niente succede

Pseudocodice del DecisionManager:

```gdscript
func _on_decision_made(decision: Decision, opzione: DecisionOption) -> void:
    GameState.apply_effect(opzione.effetto)
    NarrativeLog.append(opzione.feedback_testo)
    SaveSystem.save()
    emit_signal("decision_resolved", decision, opzione)
```

## Save system

- Save automatico dopo **ogni decisione** in `user://save.json`
- Singolo slot
- Formato JSON con tutti i campi di `GameState` + lista quest completate + flag
- Caricamento all'avvio se `SaveSystem.exists()` e l'utente sceglie "Continua"

Esempio JSON:

```json
{
  "version": 1,
  "tecnologia": 60,
  "felicita": 35,
  "economia": 45,
  "militare": 55,
  "popolazione": 178,
  "reputazione_rivale": -10,
  "atto_corrente": 2,
  "quest_completate": ["q01_fondazione", "q02_idolo"],
  "flag_narrativi": {"straniero_accolto": true}
}
```

## Pattern: data-driven, non hardcoded

Tutte le quest, decisioni, effetti vivono come **risorse `.tres`** editabili dall'editor di Godot. Lo script di gioco non contiene mai testo narrativo o numeri di stat hardcoded. Questo permette a una persona di scrivere quest senza toccare codice.

## Tooling

- **Editor**: Godot 4.6 stable
- **Versionamento**: git, vedi `CONTRIBUTING.md`
- **Format script**: 4 spazi indent, snake_case, type hints
- **Testing**: per MVP nessun framework di test automatico — testing manuale tramite playthrough

## Cose da NON fare

- Non usare `_unhandled_input` per drag-and-drop (sovrappone alla UI)
- Non creare `GameState` come `Node` in scena (deve essere Autoload)
- Non scrivere logica di gameplay dentro le risorse `.tres` — solo dati
- Non usare `print` in produzione: usare un logger autoload se serve (post-MVP)

## Open questions tecniche

- Risoluzione target: 1920×1080? 1280×720? (decide rendering della UI)
- Stretch mode: `viewport` o `canvas_items`?
- Localizzazione: per ora `tr()` non usato — testi inline. Se si vuole post-MVP, refactor.

---

*Versione 0.1 — 2026-06-01. Da rivedere prima di scrivere il primo prototipo.*

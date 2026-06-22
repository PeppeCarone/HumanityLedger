# HumanityLedger

Gioco di simulazione politica narrativa in **Godot 4.6** (GDScript). Il giocatore è lo **spirito anonimo di un popolo** che attraversa le ere della storia: non parla e non ha volto, esiste solo nelle decisioni che prende. Ogni scelta è un **gesto** — si trascina un'azione politica sul consigliere che la sostiene — e il mondo reagisce subito, in numeri e in racconto. Quello che lo spirito decide resta scritto nel *Ledger*, la memoria che sopravvive da una partita all'altra.

Progetto universitario (esame di Sviluppo di Videogiochi) sviluppato da 2 persone.

---

## Stato

**Vertical slice giocabile dall'inizio alla fine.** Si parte dal menu, si gioca attraverso due ere complete e si arriva a uno dei 6 epiloghi in ~1 ora. Tutti i sistemi principali (decisioni, stat, quest, catastrofi, trama mystery, finali, meta-progressione) sono implementati e funzionanti.

### Cosa c'è nel gioco

- **2 ere** in sequenza con transizione cinematografica: Era 1 Paleolitica → Era 2 Regno Mitico, collegate da una mappa-mondo dipinta che mostra il mondo trasformarsi.
- **~40 decisioni** narrative (drag-and-drop) distribuite su **7 quest**, con **16 consiglieri** unici (8 per era), ciascuno con ritratto, archetipo e voce.
- **8 stat** (Militare, Tesoro, Diplomazia, Scienza, Legge, Spionaggio, Popolo, Costruzione) + Popolazione, con **9 strategie politiche** e prerequisiti dinamici.
- **L'Assedio** — boss fight tower-defense di fine era: le tue **stat diventano l'esercito**, difendi il villaggio su 3 corsie da ondate annunciate + un **boss** (mammut Era 1, drago Era 2) con abilità telegrafate. L'esito (immacolata/trionfo/fatica/sopraffatto) modula ricompense e un trofeo nel Ledger, senza game over.
- **Menu Opzioni**: volumi musica/effetti, schermo intero, risoluzione, rigioca tutorial (persistiti).
- **Catastrofi** ed eventi del mondo che interrompono il flusso (carestie, pesti, rivolte, vertici diplomatici…).
- **Civiltà rivali** con rapporti dinamici (alleati/ostili) e ambasciatori.
- **Trama mystery parallela** che alcune scelte sbloccano, con un sesto finale dedicato.
- **6 finali** differenziati (Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura), determinati da stat dominanti + decisioni chiave.
- **Ledger meta-persistente**: frammenti di lore, artefatti sbloccabili ed equipaggiabili, eventi nascosti che cambiano le run successive.
- **Save/Load** automatico (run + ledger su file JSON separati).
- **Audio** originale (musiche per era + epilogo, SFX per gesti/eventi/transizioni).
- **Cura "juice"**: testo che si scrive a macchina, screen shake calibrato, villaggio che cresce e riflette la prosperità, atmosfera per era, vignettatura, richiami narrativi che ricordano scelte di ere precedenti.

Lo sviluppo è tracciato decisione per decisione in [`Docs/07-decisions-log.md`](Docs/07-decisions-log.md) e per "ondate" di polish in [`Docs/09-piano-aaa.md`](Docs/09-piano-aaa.md).

## Come avviare

### Requisiti

- [Godot Engine 4.6](https://godotengine.org/download) stable (testato con 4.6.1)
- Windows / macOS / Linux

### Setup

```bash
git clone https://github.com/PeppeCarone/HumanityLedger.git
cd HumanityLedger
```

Apri `project.godot` con Godot 4.6 e premi **F5**. La scena iniziale è il menu principale.

### Comandi

| Tasto | Azione |
|---|---|
| Mouse (drag-and-drop) | Trascina un'azione sul consigliere che la sostiene |
| **V** | Apri/chiudi la vista gestionale del Villaggio |
| **L** | Apri/chiudi il Ledger |
| **ESC** | Pausa / chiudi pannello |
| **INVIO** | Avanza la transizione tra ere |

## Struttura del progetto

```
HumanityLedger/
├── project.godot
├── Assets/            # arte, audio, font (painterly, palette bronzo/oro)
├── data/              # contenuti data-driven in .tres (decisioni, quest, consiglieri, finali…)
├── scenes/            # scene Godot (menu, gioco, ledger, epilogo, mappa, UI)
├── scripts/
│   ├── autoload/      # singleton: GameState, Ledger, QuestManager, Diplomacy, SaveSystem, AudioManager
│   ├── data/          # classi Resource (Decision, Quest, Effect, Finale…)
│   └── ui/            # logica delle schermate
├── tools/             # strumenti di sviluppo (vedi sotto)
└── Docs/              # documentazione di design
```

Architettura **data-driven**: la logica vive negli script, i contenuti (testi, numeri, effetti) nelle risorse `.tres`, editabili senza toccare codice. Dettagli in [`Docs/04-architecture.md`](Docs/04-architecture.md).

## Strumenti di sviluppo (`tools/`)

- `validate_scenes.gd` — carica e istanzia le scene principali per intercettare errori.
  `godot --headless --path . --script res://tools/validate_scenes.gd`
- `balance_sim.py` — verifica (senza Godot) che i 6 finali siano raggiungibili e il bilanciamento regga. `python tools/balance_sim.py`
- `asset_audit.py` — controlla riferimenti agli asset rotti, illustrazioni mancanti e asset orfani. `python tools/asset_audit.py`
- `shoot.gd` — cattura screenshot di tutte le schermate in `tools/_preview/` (eseguire con contesto di rendering, non `--headless`).

## Documentazione

Tutta la documentazione di design vive in `Docs/`:

| File | Cosa contiene |
|---|---|
| [`00-overview.md`](Docs/00-overview.md) | One-pager: cos'è il gioco |
| [`01-mvp-scope.md`](Docs/01-mvp-scope.md) | Cosa entra/non entra nella deadline |
| [`02-game-design.md`](Docs/02-game-design.md) | GDD: meccaniche, core loop, sistemi |
| [`03-narrative.md`](Docs/03-narrative.md) | Ere, trama, quest, mystery event |
| [`04-architecture.md`](Docs/04-architecture.md) | Struttura tecnica Godot |
| [`05-art-audio.md`](Docs/05-art-audio.md) | Direzione artistica e strategia asset |
| [`06-roadmap.md`](Docs/06-roadmap.md) | Milestone settimanali |
| [`07-decisions-log.md`](Docs/07-decisions-log.md) | Log delle decisioni di progetto |
| [`08-asset-prompts.md`](Docs/08-asset-prompts.md) | Prompt e stato degli asset |
| [`09-piano-aaa.md`](Docs/09-piano-aaa.md) | Audit visivo, juice, lezioni da Lapse |
| [`10-ui-audit.md`](Docs/10-ui-audit.md) | Audit UI e villaggio |
| [`11-boss-fight.md`](Docs/11-boss-fight.md) | L'Assedio (boss fight tower-defense) |
| [`12-roadmap.md`](Docs/12-roadmap.md) | Master roadmap finale (finire/aggiungere/esame) |
| [`13-redesign-estetico.md`](Docs/13-redesign-estetico.md) | Redesign estetico (UI kit) |
| [`14-relazione.md`](Docs/14-relazione.md) | **Relazione di progetto (consegna d'esame)** |
| [`15-video-demo.md`](Docs/15-video-demo.md) | Script del video demo |
| [`16-piano-sessione.md`](Docs/16-piano-sessione.md) | Piano di sviluppo sessione 2026-06-22 (Assedio vivo) |

C'è anche un pitch in PowerPoint: `Docs/HumanityLedger_Pitch.pptx`.

## Contribuire

Vedi [`CONTRIBUTING.md`](CONTRIBUTING.md) per il workflow git e le convenzioni di commit.

## Team

| Ruolo | GitHub |
|---|---|
| Owner del repo | [@PeppeCarone](https://github.com/PeppeCarone) |
| Contributor | [@Ventus2202](https://github.com/Ventus2202) |

## Licenza

Progetto universitario a scopo didattico: tutti i diritti riservati al team, nessuna licenza d'uso concessa al di fuori della valutazione d'esame. Audio e codice sono opera originale; gli asset visivi sono generati e post-prodotti dal team (pipeline in [`Docs/08-asset-prompts.md`](Docs/08-asset-prompts.md)). Crediti e licenze dei font/strumenti di terze parti in [`Assets/CREDITS.md`](Assets/CREDITS.md).

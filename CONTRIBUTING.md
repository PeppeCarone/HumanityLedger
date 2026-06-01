# Contribuire a HumanityLedger

Documento operativo per i 2 membri del team. Definisce il workflow git, le convenzioni di branch/commit/PR e le regole di review.

---

## Setup iniziale

Ognuno dei due collaboratori dovrebbe avere:

- Un **fork** personale del repo su GitHub
- `origin` puntato al proprio fork
- `upstream` puntato al repo originale `PeppeCarone/HumanityLedger`

Esempio di configurazione (sostituire `TUO_USERNAME`):

```bash
git clone https://github.com/PeppeCarone/HumanityLedger.git
cd HumanityLedger
git remote rename origin upstream
git remote add origin https://github.com/TUO_USERNAME/HumanityLedger.git
git config user.name "Il tuo nome"
git config user.email "tua@email"
```

Verifica:

```bash
git remote -v
# origin    https://github.com/TUO_USERNAME/HumanityLedger.git  (fetch + push)
# upstream  https://github.com/PeppeCarone/HumanityLedger.git   (fetch + push)
```

> Per chi è owner del repo (PeppeCarone): può lavorare direttamente con `origin` = repo originale, saltando il passo di fork.

## Workflow: feature → PR → merge

### 1. Aggiornare `main` dall'upstream

Prima di iniziare una nuova feature, allineare il proprio `main` al repo originale:

```bash
git checkout main
git pull upstream main
git push origin main          # opzionale: allinea anche il fork
```

### 2. Creare un branch di feature

```bash
git checkout -b feat/nome-corto-descrittivo
```

### 3. Lavorare e committare

Commit piccoli e frequenti. Vedi convenzioni sotto.

### 4. Pushare sul proprio fork

```bash
git push -u origin feat/nome-corto-descrittivo
```

### 5. Aprire una Pull Request

Su GitHub, dal proprio fork, aprire PR verso `PeppeCarone/HumanityLedger:main`. Compilare:

- Titolo: usa lo stesso prefisso del commit (es. `feat: sistema drag-and-drop di base`)
- Descrizione: cosa cambia, perché, eventuali screenshot/video, link al file `Docs/` rilevante

### 6. Review

L'altro membro del team controlla:

- Funziona? (provare il branch in locale se cambia gameplay)
- Rispetta `04-architecture.md`?
- Decisioni nuove → aggiunte a `07-decisions-log.md`?
- Asset nuovi → aggiunti a `assets/CREDITS.md`?

### 7. Merge

Quando approvato → merge via GitHub. Eliminare il branch remoto. In locale:

```bash
git checkout main
git pull upstream main
git branch -d feat/nome-corto-descrittivo
git push origin --delete feat/nome-corto-descrittivo
```

## Convenzioni di branch

| Prefisso | Uso |
|---|---|
| `feat/` | Nuova funzionalità |
| `fix/` | Bug fix |
| `docs/` | Solo documentazione |
| `art/` | Nuovi asset visivi |
| `audio/` | Nuovi asset audio |
| `refactor/` | Refactoring senza cambio comportamento |
| `chore/` | Manutenzione (deps, config, ecc.) |

Esempi: `feat/drag-and-drop`, `fix/save-corruption`, `art/ritratto-murr`.

## Convenzioni di commit

Stile **Conventional Commits semplificato**:

```
tipo: descrizione breve in minuscolo

[body opzionale con dettagli]
```

Tipi: stessi prefissi dei branch (`feat`, `fix`, `docs`, `art`, `audio`, `refactor`, `chore`).

Buoni esempi:
- `feat: drag-and-drop con cancellazione su rilascio fuori target`
- `fix: stato di GameState non si serializza per le quest opzionali`
- `art: ritratto di Murr in stile silhouette`
- `docs: aggiorna roadmap dopo W3`

Cattivi esempi:
- `update` (vago)
- `Fixed Bug` (non descrive nulla)
- `WIP` (non committare WIP su main; va bene su un branch personale)

## Regole sui file

### Cosa va committato

- Tutto il codice (`scripts/`)
- Tutte le scene (`scenes/`)
- Tutti i dati (`data/`)
- Asset finali (`assets/`)
- Documentazione (`Docs/`, `README.md`, ecc.)
- `project.godot` e `.gitattributes`, `.gitignore`

### Cosa NON va committato

Coperto da `.gitignore`:

```gitignore
# Godot
.godot/
*.import
exports/

# OS
.DS_Store
Thumbs.db
desktop.ini

# Editor
.vscode/
.idea/
*.swp
*.tmp

# Save di gioco locali
user://
```

> Mai committare `user://save.json` di test, screenshot di debug, asset scaricati a caso non ancora valutati per licenza.

## Git LFS (se serve)

Se gli asset binari fanno crescere il repo oltre ~100 MB, attivare Git LFS:

```bash
git lfs install
git lfs track "*.png" "*.ogg" "*.wav" "*.pptx"
git add .gitattributes
```

Decisione da prendere insieme prima di committare il primo batch grosso. Aggiornare `07-decisions-log.md`.

## Asset e licenze

Per ogni asset di terze parti aggiunto a `assets/`, aggiornare `assets/CREDITS.md` con:

- Nome del file nel repo
- Autore originale
- Fonte (URL)
- Licenza (CC0, CC-BY 4.0, ecc.)
- Eventuali modifiche fatte

Se l'asset richiede attribuzione, va riportata anche nel gioco (schermata Credits).

## Stile codice GDScript

- 4 spazi per indent (no tab)
- `snake_case` per variabili e funzioni
- `PascalCase` per classi e Resource types
- `SCREAMING_SNAKE_CASE` per costanti
- Type hints sempre dove possibile
- Commenti `#` solo per spiegare *perché*, non *cosa* (il nome della funzione/variabile deve già dire *cosa*)
- Niente `print()` lasciato in produzione

Esempio:

```gdscript
class_name DecisionResolver
extends Node

const MIN_FELICITA: int = 5

func resolve(decision: Decision, opzione: DecisionOption) -> void:
    GameState.apply_effect(opzione.effetto)
    NarrativeLog.append(opzione.feedback_testo)
```

## Standup settimanale

Decidere un giorno fisso (es. lunedì sera o venerdì pomeriggio). 30 minuti. Tre domande:

1. Cosa ho fatto la scorsa settimana?
2. Cosa farò questa settimana?
3. Cosa mi blocca?

Decisioni importanti dello standup → finiscono in `Docs/07-decisions-log.md`.

## Conflitti di merge

Se ne nasce uno:

- Mai forzare con `--theirs`/`--ours` su file di documentazione o dati di quest (rischio di perdere lavoro dell'altro)
- Risolvere a mano file per file
- Chiedere all'altro membro se non si è sicuri di chi ha scritto cosa

Se non si riesce a risolvere: chiamarsi al volo, non perdere ore in chat.

## Domande?

Scrivere in chat di team o aprire una Issue su GitHub con label `question`.

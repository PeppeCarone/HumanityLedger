# 06 — Roadmap

> Milestone settimanali fino alla consegna. Pianificazione su un orizzonte di 12 settimane (limite alto: 3 mesi).
> Se la deadline reale è più corta, comprimere proporzionalmente.

---

## Assunzioni

- 2 persone × ~15-20 ore/settimana ciascuna = ~30-40 ore di lavoro effettivo / settimana
- Ruoli flessibili. Suggerimento iniziale:
  - **Persona A** (lead code): scripting Godot, architettura, save system, integrazione
  - **Persona B** (lead design/content): scrittura quest, scelta asset, audio, UI/UX
- Standup settimanale fisso (lun o ven, 30 min) per sincronizzazione

> Chi fa cosa va deciso esplicitamente nello standup di kickoff e tracciato in `07-decisions-log.md`.

## Fasi macro

```
W1-W2  Setup + Prototipo core gesto (drag-and-drop su 1 decisione finta)
W3-W5  Sistema decisioni + Stat + Quest manager + Save
W6-W8  Contenuto (10+ quest, ritratti, sfondi, audio)
W9-W10 Atto finale + 4 epiloghi + Evento mystery
W11    Polish, balance, bug fix
W12    Build finale, relazione, video demo
```

## Milestone settimanali

### Settimana 1 — Kickoff e setup

**A**
- Inizializzare progetto Godot 4.6 nel repo
- Configurare `.gitignore` (vedi sotto)
- Creare struttura cartelle come da `04-architecture.md`
- Set up autoload `GameState` con le 4 stat e segnale `stat_changed`
- Scena `main.tscn` placeholder

**B**
- Definire palette definitiva e font
- Scaricare cornice UI base (Kenney o originale)
- Bozza scritta del primo atto (3 quest in markdown)
- Creare `CREDITS.md` in `assets/`

**Definition of done W1**: il progetto Godot apre, mostra una scena "ciao mondo" con HUD che mostra 4 numeri delle stat. Repo organizzato.

### Settimana 2 — Prototipo gesto

**A**
- Implementare scena `decision_panel.tscn` con 1 icona trascinabile
- Implementare `Area2D` target con tag
- Logica drag-and-drop completa (drag ghost, hover feedback, drop, cancel)
- Test: trascinare moneta su edificio fa cambiare stat Economia di +5

**B**
- Disegnare/scaricare 3 icone gesto (moneta, soldato, pergamena) in stile finale
- Disegnare/scaricare 2 silhouette edifici
- Scrivere 5 testi di decisione per Atto 1

**DoD W2**: una decisione testuale + drag funziona end-to-end. Prototipo dimostrabile in 30 secondi di gameplay.

### Settimana 3 — Sistema dati

**A**
- Definire classi `Decision`, `DecisionOption`, `Effect`, `Quest` come Resource
- Creare 3 file `.tres` di esempio per testarle
- `QuestManager` autoload con caricamento da `data/quests/*.tres`

**B**
- Convertire le 5 decisioni W2 in `.tres`
- Continuare scrittura Atto 1 (testi consiglieri, testi feedback)
- Disegnare 2 ritratti consiglieri (Murr, Tev)

**DoD W3**: il gioco esegue una catena di 3 decisioni caricate da file, lo stato cambia di conseguenza.

### Settimana 4 — Feedback e UI

**A**
- `NarrativePanel` con pop-in del testo feedback (max 40 parole)
- Animazione count-up/down delle stat in HUD
- Suoni placeholder (beep) su drag pickup e drop
- Autosalva su `user://save.json` dopo ogni decisione

**B**
- Cornici UI definitive (decision panel, narrative panel, HUD)
- Tutti i 5 ritratti consiglieri
- Scaricare/scegliere 1 brano musicale per Atto 1

**DoD W4**: una decisione produce: animazione gesto + stat che si animano + testo che appare + suono. Salva e ricarica.

### Settimana 5 — Atto 1 completo

**A**
- Sistema di transizione tra quest (`QuestManager.valuta_prossima_quest()`)
- Schermata di bilancio fine atto
- Schermata menu principale (nuova partita / continua / esci)

**B**
- 3 quest dell'Atto 1 complete in `.tres` (con tutte le opzioni-gesto)
- Sfondo del villaggio Atto 1
- 4-5 SFX definitivi

**DoD W5**: l'Atto 1 si gioca per intero (3 quest principali → bilancio).

### Settimana 6 — Atto 2 contenuto

**A**
- Sistema flag narrativi (`GameState.flag_narrativi`) e precondizioni quest
- Logica di trigger evento mystery
- Integrazione Tribù del Nord come stat su HUD

**B**
- 3 quest dell'Atto 2 + 1 quest opzionale Straniero
- Sogno condiviso (testo + presentazione UI speciale)
- Sfondo villaggio Atto 2

**DoD W6**: Atto 2 giocabile, trigger mystery testato in almeno 2 percorsi.

### Settimana 7 — Atto 2 polish

**A**
- Effetto "fiume rosso" (cambio palette temporanea della scena per una notte di gioco)
- Schermata bilancio Atto 2
- Pulizia bug e refactor

**B**
- Brano musicale Atto 2 (più teso)
- Eventuali asset visivi mancanti
- Iniziare scrittura Atto 3

**DoD W7**: due atti consecutivi giocabili end-to-end.

### Settimana 8 — Atto 3 + finali

**A**
- Logica di valutazione finale (quale dei 4 epiloghi)
- Scena `ending.tscn` con epilogo testuale + ricap delle scelte

**B**
- 2-3 quest dell'Atto 3
- Scrittura dei 4 epiloghi (max 400 parole ciascuno)
- Sfondo villaggio Atto 3 (degradato o trasformato)

**DoD W8**: si arriva a un epilogo dall'inizio.

### Settimana 9 — Mystery completo

**A**
- Quest "Trasfigurazione" con presentazione UI alternativa
- Verifica trigger mystery in tutte le condizioni

**B**
- Brano musicale per finale + stinger sonori
- Illustrazioni schermate finale (4)
- Quest opzionali nascoste / easter egg leggeri

**DoD W9**: 4 finali distinguibili. Mystery raggiungibile.

### Settimana 10 — Polish e balance

**A**
- Bilanciare i delta delle stat (5+ playthrough completi, registrare numeri)
- Sistemare bug noti, controllare save/load in tutti gli atti
- Tooltip e hint per il giocatore al primo drag

**B**
- Tutorial implicito nei primi 2-3 testi consiglieri ("Trascina l'icona…")
- Credits screen
- Verifica licenze in `CREDITS.md`

**DoD W10**: gioco completo, bilanciato, niente crash noti.

### Settimana 11 — Bug fix e accessibilità

- Bug fix prioritizzati
- Test su più macchine se possibile
- Volume audio, keybind, opzione mute
- Build di test Windows 64-bit

**DoD W11**: build esportabile funzionante.

### Settimana 12 — Consegna

- Build finale Windows
- Video demo (3-5 minuti)
- Relazione di esame
  - Visione completa vs MVP (perché abbiamo tagliato)
  - Decisioni di design (citare `07-decisions-log.md`)
  - Architettura tecnica (citare `04-architecture.md`)
  - Diari di sviluppo / retrospettiva
- README aggiornato

**DoD W12**: progetto consegnabile.

## File da creare a inizio progetto

- `.gitignore` con:
  ```
  .godot/
  exports/
  *.import
  .DS_Store
  Thumbs.db
  ```
- `.gitattributes` per Git LFS se gli asset crescono:
  ```
  *.png filter=lfs diff=lfs merge=lfs -text
  *.ogg filter=lfs diff=lfs merge=lfs -text
  *.wav filter=lfs diff=lfs merge=lfs -text
  ```
  (Da attivare solo se `assets/` supera ~100 MB)

## Cosa fare se siamo in ritardo

Ordine di **taglio aggressivo**, dal meno doloroso al più doloroso:

1. Ridurre quest opzionali a 0
2. Ridurre 4 epiloghi a 3 (tagliare "Sopravvivenza")
3. Ridurre Atto 3 da 3 a 2 quest
4. Tagliare l'evento "fiume rosso" (resta solo il sogno condiviso come segno)
5. Ridurre numero di ritratti a 3 invece di 5
6. Ridurre tracce musicali a 1 sola che cambia tono via filtri

## Cosa fare se siamo in anticipo

Nell'ordine, aggiungere:

1. Più quest opzionali (lore, easter egg)
2. Una quinta opzione gesto (es. "torcia su idolo")
3. Personalizzazione del nome del villaggio
4. Animazioni di transizione tra atti più curate
5. Schermata di achievement / collezionabili

---

*Versione 0.1 — 2026-06-01. Da rivedere a fine W2 con dati reali di velocità del team.*

# 06 — Roadmap

> Milestone settimanali fino alla consegna. Pianificazione su 12 settimane (limite alto: 3 mesi).
> Versione 0.2 — riscritta dopo intervista del 2026-06-01 con scope ampliato.

---

## Assunzioni

- 2 persone × ~15-20 ore/settimana = ~30-40 ore di lavoro effettivo / settimana
- Ruoli flessibili. Suggerimento:
  - **Persona A** (lead code): scripting Godot, architettura, save system, drag-and-drop, Ledger
  - **Persona B** (lead design/content): scrittura quest e dialoghi, generazione asset AI, audio, UI
- Standup settimanale fisso (lun o ven, 30 min)

> Chi fa cosa va deciso esplicitamente nello standup di kickoff e tracciato in `07-decisions-log.md`.

## Promemoria di scope

Lo scope MVP (vedi `01-mvp-scope.md`) è **ambizioso oltre il realistico**. La gerarchia di tagli in `01-mvp-scope.md` va consultata a ogni standup. Aspettarsi di aver tagliato almeno 2-3 voci entro W6.

## Fasi macro

```
W1-W2   Setup + Prototipo core drag-and-drop + Palette/font
W3-W4   Sistema dati + Stat + Quest manager + Save + Ledger base
W5-W6   Era 1 contenuto (tutorial caverna + atto 1-2)
W7      Era 1 atto 3 + transizione + inizio Era 2
W8-W9   Era 2 contenuto + ambasciatori + civiltà rivali
W10     Trama mystery + 6 finali + Ledger eventi sbloccabili
W11     Polish, balance, bug fix, accessibilità
W12     Build finale, relazione, video demo
```

## Milestone settimanali

### Settimana 1 — Kickoff e setup

**A (code)**
- Inizializzare progetto Godot 4.6 nel repo
- `.gitignore` configurato
- Struttura cartelle come da `04-architecture.md`
- Autoload `GameState` con le 8 stat + segnali
- Autoload `Ledger` con persistenza base
- Scena `main.tscn` placeholder

**B (design/content)**
- Decidere palette definitiva + font + cornici UI base
- Prompt template per AI generation (test 2-3 ritratti Era 1)
- Verificare policy università su AI generativa
- Outline dell'Atto 1 della caverna (3-4 decisioni testuali in markdown)
- `Assets/CREDITS.md` inizializzato

**DoD W1**: Godot apre, HUD mostra 8 numeri stat, autoload funzionanti. 2 ritratti di prova generati. Policy AI chiarita.

### Settimana 2 — Prototipo gesto

**A**
- Implementare `decision_panel.tscn` con drag generico
- Implementare `Area2D` target con tag matching
- Drag-and-drop end-to-end: drag ghost, hover state, drop success/fail, animazioni base
- Test: trascinare un'icona placeholder su un consigliere → cambia stat correlata

**B**
- 4 icone strategia disegnate/scaricate in stile finale
- 4 ritratti consiglieri Era 1 (mezzo cast)
- Sfondo caverna interno
- Scrivere 5 testi decisione del tutorial caverna

**DoD W2**: prototipo giocabile di 30 secondi con drag-and-drop reale e 1 consigliere reale.

### Settimana 3 — Sistema dati

**A**
- Classi Resource: `Strategia`, `Decision`, `DecisionOption`, `Effect`, `Quest`, `Personaggio`, `Civilta`, `Catastrofe`, `Artefatto`
- `QuestManager` autoload con caricamento da `data/quests/*.tres`
- Sistema prerequisiti stat (icona disabilitata se non soddisfatto)
- Sistema flag narrativi in `GameState`

**B**
- Convertire le 5 decisioni W2 in `.tres`
- Continuare scrittura Atto 1 caverna (8-10 decisioni)
- 4 ritratti consiglieri Era 1 restanti
- 2 sprite edifici tribali (idolo, capanna)

**DoD W3**: 3 decisioni concatenate funzionano da `.tres`, prerequisiti rispettati, stat aggiornate.

### Settimana 4 — Feedback e UI completi

**A**
- `NarrativePanel` con pop-in del testo feedback animato
- Animazione count-up/down delle 8 stat in HUD
- `QuestLog` con voci attive visibili
- Mini-mappa diplomatica (placeholder)
- Autosave dopo ogni decisione
- Ledger autoload con sblocco lore funzionante

**B**
- Cornici UI definitive Era 1 (decision, narrative, HUD, quest log)
- Disegnare 4-5 icone strategia mancanti
- 1 brano musicale Era 1 (CC0 o AI)
- 5 SFX (drag pickup, hover, drop ok, drop fail, stat change)
- 1 ambasciatore Era 1 (Clan del Bisonte)

**DoD W4**: una decisione produce animazione gesto + stat animate + testo feedback + sound + autosave. Lore sbloccata visibile in Ledger schermata placeholder.

### Settimana 5 — Era 1 atti 1-2

**A**
- Sistema transizione quest → quest
- Sistema catastrofe (interruzione flusso normale)
- Schermata bilancio fine atto
- Schermata menu principale completa
- Schermata Ledger funzionante (3 tab: Lore, Artefatti, Eventi)

**B**
- Tutorial caverna completo: 5-8 decisioni dell'Atto 1
- Inizio Atto 2: 4-5 decisioni (caccia, dispute, costruzione)
- 1 catastrofe Era 1 (inverno)
- 1 quest opzionale (Popolo delle Nebbie)
- Sfondo accampamento esterno

**DoD W5**: Atti 1-2 dell'Era 1 giocabili end-to-end con catastrofe gestita.

### Settimana 6 — Era 1 atto 3 + trama mystery

**A**
- Trigger trama mystery (logica condizionale)
- Effetti speciali mystery (fuoco rosso, palette change, ecc.)
- Quest chiave dell'era (Idolo del Fuoco) con condizioni stat + flag
- Cinematica transizione era (placeholder)

**B**
- 3 quest principali Atto 3
- Eventi mystery Era 1 (sogno condiviso, pittura che cambia, fuoco rosso)
- Brano musicale Era 1 #2 (più teso)

**DoD W6**: Era 1 completa end-to-end con trama mystery e quest chiave. Mystery raggiungibile in playthrough mirato.

> **CHECKPOINT W6**: se siamo già in ritardo, applicare primi tagli dalla gerarchia in `01-mvp-scope.md`.

### Settimana 7 — Transizione + Era 2 setup

**A**
- Cinematica transizione era funzionante con animazione stat
- Setup scena Era 2 `game.tscn` con città dall'alto + pannelli laterali
- Sistema rapporti civiltà rivali con valori dinamici
- Pulizia bug Era 1

**B**
- 4 ritratti consiglieri Era 2
- Sfondo città Era 2 (vista dall'alto)
- 3-4 sprite edifici mitici (tempio, mura, mercato)
- Brano musicale Era 2 #1

**DoD W7**: il giocatore può completare Era 1 e iniziare Era 2 con stat trasferite.

### Settimana 8 — Era 2 contenuto principale

**A**
- Logica eventi diplomatici con ambasciatori
- Mini-mappa diplomatica completa (click → pannello dettagli)
- Sistema decisioni chiave (`decisioni_chiave` in `GameState`)

**B**
- 4 ritratti consiglieri Era 2 restanti
- 2 ambasciatori Era 2 (Impero del Sole, Lega delle Coste)
- 5-6 decisioni Atto 1 Era 2
- 5-6 decisioni Atto 2 Era 2
- 1 catastrofe Era 2 (Conflitto Religioso)

**DoD W8**: Era 2 atti 1-2 giocabili.

### Settimana 9 — Finali e mystery completo

**A**
- Logica valutazione finale (`Finale` resource + matching stat + decisioni chiave)
- Scena `ending.tscn` con 6 epiloghi
- Sistema eventi sbloccabili del Ledger
- Bilanciamento iniziale stat

**B**
- 4-5 decisioni Atto 3 Era 2
- Eventi mystery Era 2 (La Voce nel Bosco, Tempio Vuoto, Convergenza Finale)
- Scrittura dei 6 epiloghi (testo max 400 parole ciascuno)
- 6 illustrazioni epilogo
- Brano musicale finale

**DoD W9**: si arriva a uno dei 6 finali dal'inizio. Mystery raggiungibile in run mirato.

### Settimana 10 — Polish e balance

**A**
- Bilanciare i delta delle stat (5+ playthrough completi, registrare numeri)
- Sistemare bug noti, controllare save/load in tutte le fasi
- Tooltip e hint per il giocatore al primo drag
- Tutorial tooltip text reviewato

**B**
- Tutti i 3 artefatti completi (icone + descrizioni + effetti)
- 5-10 frammenti di lore scritti
- Credit screen
- Verifica licenze in `CREDITS.md`
- SFX completi (mystery stinger, transizione, ecc.)

**DoD W10**: gioco completo, bilanciato, niente crash noti, tutti i sistemi rifiniti.

### Settimana 11 — Accessibilità e build

**A**
- Bug fix prioritizzati
- Test su più macchine se possibile
- Volume audio, keybind base, opzione mute
- Build di test Windows 64-bit
- Eventuale Git LFS attivato se repo cresciuto

**B**
- Sistemazione testi finali
- Verifica coerenza voci consiglieri
- Sound design pass finale
- Asset extra emergenti

**DoD W11**: build esportabile funzionante, audio bilanciato.

### Settimana 12 — Consegna

- Build finale Windows
- Video demo (3-5 minuti)
- Relazione di esame
  - Visione completa vs MVP
  - Decisioni di design (citare `07-decisions-log.md`)
  - Architettura tecnica
  - Sistema Ledger come scelta caratterizzante
  - Diari di sviluppo / retrospettiva
- README aggiornato

**DoD W12**: progetto consegnabile.

## File da creare a inizio progetto

- `.gitignore`:
  ```
  .godot/
  exports/
  *.import
  .DS_Store
  Thumbs.db
  ```
- `.gitattributes` per Git LFS se asset crescono:
  ```
  *.png filter=lfs diff=lfs merge=lfs -text
  *.ogg filter=lfs diff=lfs merge=lfs -text
  *.wav filter=lfs diff=lfs merge=lfs -text
  ```
  (Attivare solo se `Assets/` supera ~100 MB)

## Cosa fare se siamo in ritardo

Applicare la **gerarchia di tagli** in `01-mvp-scope.md` (sezione "Gerarchia tagli"). In ordine dal meno doloroso al più doloroso:

1. Ridurre quest mystery → indizi senza quest
2. Ridurre artefatti da 3 a 1
3. Ridurre civiltà rivali da 2-3 a 1 per era
4. Tagliare eventi sbloccabili Ledger
5. Ridurre consiglieri Era 1 da 8 a 5-6
6. Ridurre finali da 6 a 4
7. Tagliare Ledger interamente
8. **Tagliare Era 2**: solo Era 1 polished — taglio più doloroso

Ogni decisione di taglio va loggata in `07-decisions-log.md`.

## Cosa fare se siamo in anticipo

Nell'ordine, aggiungere:

1. Più frammenti di lore (rigiocabilità)
2. Più eventi sbloccabili Ledger
3. Più catastrofi attivate
4. Animazioni di transizione più curate
5. Easter egg leggeri (riferimenti meta)
6. Schermata achievement / collezionabili

---

*Versione 0.2 — 2026-06-01.*

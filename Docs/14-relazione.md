# Relazione di progetto — HumanityLedger

> Esame di Sviluppo di Videogiochi. Relazione tecnica e di design.
> Team: 2 persone ([@PeppeCarone](https://github.com/PeppeCarone) · [@Ventus2202](https://github.com/Ventus2202)).
> Engine: Godot 4.6 (GDScript). Lingua del gioco: italiano.
>
> Questo documento è la sintesi ragionata del progetto. Il dettaglio cronologico
> delle scelte vive in `07-decisions-log.md` (ID `D001`–`D047`), il design in
> `00`–`05`, la roadmap in `06`/`12`, il percorso di polish in `09`/`10`/`13`, la
> feature-climax in `11`. I riferimenti `Dxxx` qui sotto puntano lì.

---

## 1. Introduzione

**HumanityLedger** è un gioco di **simulazione politica narrativa** in cui il
giocatore impersona lo **spirito anonimo di un popolo** che attraversa le ere della
storia. Lo spirito non parla e non ha volto: esiste solo nelle decisioni che prende.
Ogni scelta è un **gesto** — si trascina un'azione politica sul consigliere che la
sostiene — e il mondo reagisce subito, in numeri (le statistiche della civiltà) e in
racconto. Ciò che lo spirito decide resta scritto nel *Ledger*, la memoria che
sopravvive da una partita all'altra.

- **Genere**: simulazione politica/management mitico con elementi di visual novel e
  meta-progressione roguelike-light.
- **Pubblico**: giocatori di simulazioni narrative (*Reigns*, *Suzerain*), roguelike
  narrativi (*Hades*, *Inscryption*), gestionali storici (*Crusader Kings*, *Frostpunk*).
- **Piattaforma**: PC Windows 64-bit (export Godot; D010).
- **Stato**: vertical slice **giocabile dall'inizio alla fine** — dal menu, attraverso
  due ere complete, fino a uno dei 6 epiloghi, in circa un'ora.

Il titolo riassume il concept: un *registro dell'umanità* che testimonia le scelte
oltre la vita dei singoli leader.

## 2. Visione completa vs. MVP

La visione "north star" prevedeva 7 ere, civiltà rivali con IA autonoma, più trame
mystery, un sistema di artefatti profondo, eventi procedurali, localizzazione. Con un
**team di 2 persone e una finestra di 1–3 mesi**, questo equivaleva a circa un anno di
lavoro a tempo pieno: irrealistico (D003). Il progetto è stato quindi ridotto a un MVP
con una **gerarchia di tagli esplicita** (`01-mvp-scope.md`) da applicare a ogni
checkpoint.

Lo scope MVP effettivamente realizzato:

- **2 ere** in sequenza con transizione esplicita (D012): Era 1 Paleolitico → Era 2
  Regno Mitico. La transizione tra ere è un pilastro identitario, non un dettaglio.
- **16 consiglieri** unici (8 per era, D019), con ritratti, archetipi e voci proprie.
- **8 statistiche** globali (D016) e **9 strategie** politiche con prerequisiti (D017/D044).
- **Catastrofi** come eventi-decisione speciali (D020), **civiltà rivali** scriptate
  (D021/D033), **trama mystery** parallela (D022) con un sesto finale dedicato.
- **6 finali** differenziati (D023) e **nessun game over** (D024).
- **Ledger meta-persistente** con lore, artefatti equipaggiabili ed eventi nascosti
  (D025/D026/D047).
- **L'Assedio**: una boss-fight tower-defense di fine era, aggiunta in corso d'opera
  (vedi §5.9 e §6, che rivede D006).

Tutto ciò che non rientra nell'MVP resta documentato come visione futura (§11).

## 3. Pilastri di design

Dal documento di visione (`00-overview.md`) e dal GDD (`02-game-design.md`):

1. **Decisione come gesto** (D008) — ogni scelta è un'azione fisica di drag-and-drop su
   un target visivo, non una voce di menu. È ciò che distingue il gioco da *Reigns*.
2. **Feedback narrativo immediato** — il mondo reagisce entro 2-3 secondi a ogni
   decisione, in numeri e in testo, e visivamente sul villaggio (D038).
3. **Mythico-epico, non realistico** (D015) — tono solenne, oracolare, archetipico.
   Ispirazioni: Hades, Pyre, Annihilation.
4. **Lo spirito attraversa le ere, il Ledger lo testimonia** (D011/D026) — la
   meta-progressione trattiene scoperte e artefatti da una run all'altra.
5. **Nessun game over: solo finali** (D024) — non si perde mai; si arriva sempre a uno
   dei 6 epiloghi. Coerente col framing dello spirito che osserva tutti gli esiti.
6. **Struttura 8 + 8 + 8 + 6** (D016) — 8 consiglieri, 8 stat, 9 strategie (originariamente
   8), 6 finali: un sistema chiuso e coerente in cui il numero è una struttura.

## 4. Architettura tecnica

> Dettaglio completo in `04-architecture.md`.

### 4.1 Scelte di base

- **Engine**: Godot 4.6 stable (D001) — gratuito, open source, eccellente per 2D + UI,
  export rapido su PC.
- **Linguaggio**: GDScript con type hints statici (D002) — iterazione veloce, nessuna
  dipendenza .NET, hot-reload, ottima integrazione con l'editor.
- **Risoluzione**: 1920×1080, stretch `canvas_items`, aspect `keep` (D034).

### 4.2 Architettura data-driven

Il principio cardine (D007): **la logica vive negli script, i contenuti vivono nei dati**.
Decisioni, quest, effetti, personaggi, finali sono `Resource` Godot serializzate come
file `.tres`, editabili dall'editor. Nessuno script contiene testo narrativo o numeri di
bilanciamento hardcoded. Vantaggi: il designer scrive e bilancia senza toccare codice;
versionamento granulare (un diff per file); testing più semplice.

Classi `Resource` principali (`scripts/data/`): `Decision`, `DecisionOption`, `Effect`,
`Strategia`, `Quest`, `Personaggio`, `Civilta`, `Catastrofe`, `Artefatto`,
`EventoSbloccabile`, `Finale`. I contenuti corrispondenti stanno in `data/` (es. ~40
decisioni in `data/decisions/`, 16 personaggi in `data/characters/`, 6 finali in
`data/finali/`).

### 4.3 Autoload (singleton)

Lo stato globale è gestito da autoload (`scripts/autoload/`):

- **`GameState`** — stato della run corrente: le 8 stat come variabili tipizzate
  dedicate + popolazione, era/atto, quest completate, flag narrativi, decisioni chiave,
  rapporti con le civiltà, artefatto equipaggiato, scelte registrate. Tutte le mutazioni
  passano per metodi che emettono segnali (`stat_changed`, …), così la UI è reattiva
  senza polling (D035).
- **`Ledger`** — stato meta-persistente, salvato separatamente: lore, artefatti
  sbloccati ed equipaggiati, eventi nascosti.
- **`QuestManager`** — carica le quest da `data/quests/*.tres` e valuta quale offrire in
  base a prerequisiti di flag e stat.
- **`Diplomacy`** — stato e rapporti delle civiltà rivali.
- **`SaveSystem`** / **`AudioManager`** — persistenza e audio (vedi §4.5, §7).

### 4.4 Sistema drag-and-drop

Cuore dell'interazione (D008/D018). Ogni opzione di decisione è una carta trascinabile
che punta a un consigliere-bersaglio; l'azione si risolve trascinando la carta sul
consigliere giusto (hover verde di conferma, flash rosso al drop errato). Il color-coding
collega carta e zona di destinazione; le opzioni con prerequisiti non soddisfatti sono
mostrate disabilitate (desaturate + tooltip col motivo), mai nascoste.

### 4.5 Save system

Due file separati (D025):

- `user://save.json` — autosave della run, riscritto dopo ogni decisione, azzerato a
  fine run.
- `user://ledger.json` — persistente cross-run, accumula le scoperte del Ledger.

Non c'è interazione tra i due: avviare una "Nuova Partita" azzera la run ma **non** tocca
il Ledger. Entrambi versionati (campo `version`) per migrazioni future.

## 5. Sistemi di gioco

### 5.1 Decisioni e strategie
~40 decisioni narrative drag-and-drop, distribuite su 7 quest (D031). Ogni decisione
presenta un consigliere che descrive una situazione concreta e pone una domanda esplicita
(D040); le opzioni sono azioni imperative collegate alle **9 strategie** (Militare,
Diplomatico, Economico, Costruzione, Decreto, Scientifico, Spionaggio, Rivoluzionaria +
la strategia speciale "Voce" del mystery). Le strategie hanno **prerequisiti-stat**
(D017/D044) che creano tensione: non puoi sempre fare ciò che vorresti.

### 5.2 Statistiche
8 stat globali 0–100 allineate ai consiglieri (D016): Militare, Tesoro, Diplomazia,
Scienza, Legge, Spionaggio, Popolo, Costruzione, più la Popolazione derivata. L'HUD le
mostra come medaglioni con valore; al cambio, il medaglione pulsa e un `+N`/`-N` fluttua e
dissolve (juice, §8).

### 5.3 Quest e progressione
`QuestManager` guida una sequenza ordinata di quest per era; ciascuna si sblocca per
precondizioni di flag/stat. La quest **chiave** dell'era è gated da una soglia di stat
(D027): combina agenzia narrativa (completare la quest) e progressione meccanica
(raggiungere la soglia) per passare all'era successiva. Un quest log mostra gli obiettivi;
le quest mystery appaiono come "???" finché non rivelate (D028).

### 5.4 Catastrofi
Eventi-decisione speciali con peso narrativo aumentato (D020), con illustrazione dedicata
(carestia, peste, ribellione, assassinio, crisi economica, conflitto religioso…). Non
sono boss fight (D006): l'utente le *vive* nel flusso delle scelte.

### 5.5 Civiltà rivali
2-3 per era, con comportamento interamente scriptato (no IA autonoma, D033). Si
manifestano come ambasciatori narrativi e tramite i `rapporti_civilta`, mostrati nell'HUD
e sulla mappa-mondo (alleati/ostili). Le scelte del giocatore ne muovono i rapporti.

### 5.6 Trama mystery
Branching narrativo opzionale (D022) attivabile da decisioni specifiche in **entrambe** le
ere (D045). Accumula "punti mystery" da flag seminati; superata la soglia, sblocca eventi
visivi (tinte, voci, pitture) e l'accesso al sesto finale.

### 5.7 Finali
6 epiloghi (D023): Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura. La scelta
combina **stat dominanti** a fine Era 2 e **decisioni chiave** specifiche; un sistema di
fallback garantisce sempre un esito coerente anche con stat bassissime (D024). Verificato
con `balance_sim.py`: tutti e 6 i finali sono raggiungibili.

### 5.8 Ledger meta-persistente
La feature caratterizzante (D026), incarnazione del titolo. Tre sezioni: **Lore**
(frammenti narrativi), **Artefatti** (sbloccabili per traguardi della run ed
equipaggiabili, ognuno con un effetto d'inizio-run distinto, D047), **Eventi** nascosti.
Il ciclo sblocco→equip→bonus chiude il loop "ogni run lascia qualcosa alla successiva" e
dà un motivo concreto per rigiocare. Un contatore "Epiloghi X/6 · Artefatti X/N" rende
visibile la collezione (lezione da *Lapse*, §8).

### 5.9 L'Assedio (boss fight tower-defense)
Feature-climax di fine era (design in `11-boss-fight.md`). Le **statistiche diventano
l'esercito**: HP del villaggio derivati da Costruzione + Popolazione, budget di
schieramento da Tesoro/Risorse/Popolo, 4 unità ognuna scalata da una stat diversa. Su 3
corsie si difende il villaggio da 4 ondate (3 crescenti + boss) annunciate, con un **boss**
per era (mammut "Il Colosso" in Era 1, drago in Era 2) dalle abilità telegrafate (pestone
AoE, ruggito stunnante mitigato da Legge, carica). Gli **alleati** dai rapporti positivi
forniscono truppe gratuite, gli **ostili** rinforzano i nemici. Coerente col "no game
over" (D024): l'esito è graduato (immacolata/trionfo/fatica/sopraffatto) e modula
ricompense + un trofeo nel Ledger, senza mai bloccare il giocatore.

## 6. Scelte di design motivate (case study)

Il `07-decisions-log.md` documenta 47 decisioni con motivazione e alternative scartate.
Le più caratterizzanti:

- **No game over (D024)** — invece della classica schermata di sconfitta, ogni run
  prosegue fino a un finale. Rispetta il framing (lo spirito non muore, osserva), riduce
  la frustrazione e alza il completion rate. Ha implicato un bilanciamento più morbido e
  un sistema di finali-fallback.
- **Stat → esercito (L'Assedio)** — la decisione iniziale D006 escludeva le boss fight dal
  MVP per ragioni di tempo. A gioco maturo, l'Assedio è stato aggiunto **riusando** ciò che
  esisteva: le stat già governate dalle decisioni diventano la forza in campo, così la
  boss-fight non è un sotto-gioco scollegato ma la **resa dei conti** di un'intera era di
  scelte. È l'esempio più chiaro di come il design sia evoluto a contatto con la
  realizzazione: D006 viene di fatto rivista, ma solo dopo che il resto del gioco era
  solido (coerente con la regola "valutare nuove feature solo a base stabile").
- **Architettura data-driven (D007)** — ha pagato: l'espansione dei contenuti (es. Era 2
  da 9 a 16 decisioni, D045) è avvenuta a costo basso, generando nuovi `.tres` con uno
  strumento dedicato anziché scrivendo codice.
- **Linguaggio delle decisioni (D040)** — regola di design precisa: mai rivelare quale
  stat un'opzione rinforza *prima* di sceglierla (l'unica eccezione è sbloccabile via
  l'artefatto Occhio dello Spirito, D047). Preserva il dilemma e differenzia il gioco dai
  builder a delta-espliciti.
- **Due view: villaggio ↔ decisione (D039/D046)** — nate da feedback di playtest
  ("schermata sovraffollata", "mi aspettavo un villaggio alla Clash of Clans"): separare
  il villaggio-tabellone (default) dalla decisione (overlay) dà ritmo
  (attesa→urgenza→scelta→conseguenza) e leggibilità.

## 7. Pipeline asset e direzione artistica

> Dettaglio in `05-art-audio.md`, `08-asset-prompts.md`, `13-redesign-estetico.md`.

- **Stile**: painterly dark-fantasy epico, pennellate visibili, luce calda drammatica,
  palette bronzo/oro/seppia (D013/D015). Forte salto visivo cercato tra Era 1 paleolitica
  ed Era 2 mitica (D014).
- **Produzione**: asset generati con strumenti AI esterni (Lovable/Nano-Banana) seguendo
  prompt mirati documentati, poi **ritagliati, ripuliti e organizzati** con tool Python
  dedicati (`tools/slice_*.py`, `recrop_portraits.py`) e integrati via `load("res://…")`
  per evitare problemi di import-order (D036). Ogni asset è verificato a vista prima del
  wiring.
- **UI**: dopo aver sperimentato cornici-texture 9-slice (che si deformavano su pannelli
  larghi), si è adottato un mix di `StyleBoxFlat` bronzo (D043) e un **UI-kit** dipinto
  (pannelli, pulsanti, barre, medaglioni, cartigli) cablato con fallback graduale
  (`UiStyle`, doc 13).
- **Audio**: musiche e SFX **sintetizzati da zero** con `tools/gen_audio.py`
  (numpy/scipy → OGG), opera originale che azzera ogni vincolo di licenza ed è interamente
  documentabile (D041). 9 SFX + 4 brani ambient per era/epilogo.
- **Font**: Cinzel (titoli) + Alegreya (corpo), OFL da Google Fonts (D042).

## 8. "Verso AAA": juice e animazione

Requisito guida: ogni decisione deve produrre una **catena di feedback visibile** —
flash/shake → conseguenza sul villaggio → pulse della stat → riga narrativa che si scrive
(doc `09`). Realizzato: typewriter sul testo narrativo, screen-shake calibrato per tipo di
conseguenza, pulse dei medaglioni con float dei delta, preview di drag inclinata, drop-zone
che "respira", villaggio che cresce e **riflette la prosperità** (edifici desaturati in
crisi / dorati nel benessere).

Successivamente, **5 pass di animazione procedurale** (shader + tween, senza nuovi asset,
doc `12`) hanno reso vive tutte le schermate principali: dondolio idle degli edifici,
ritratto che respira + Ken Burns sui fondali, braci e flicker del fuoco (shader
`fire_flicker`), heat-haze e pulviscolo sul campo dell'Assedio (`heat_haze`), rotte
luminose e nubi sulla mappa-mondo (`flow`), godrays nella caverna. I 3 shader sono
riusabili.

Diversi accorgimenti vengono da una ricerca su *Lapse: A Forgotten Future* (stesso genere,
10M+ download, doc `09`): indicatori di **effetti-duraturi** sotto l'HUD (artefatto
equipaggiato, mistero desto, alleati/ostili), **contatore di epiloghi** nel Ledger, e
**richiami narrativi cross-era** in cui una decisione dell'Era 2 cita una scelta presa
nell'Era 1.

## 9. Strumenti di sviluppo

Il progetto include un toolkit (`tools/`) che ha reso sostenibile lo sviluppo per 2 persone:

- **`validate_scenes.gd`** — istanzia headless le scene principali per intercettare errori
  di caricamento/runtime. *(Durante la QA finale ha rivelato un crash reale: una particella
  `CPUParticles2D` aggiunta a un array tipizzato `TextureRect` nel villaggio — corretto
  allargando il tipo dell'array a `Node`.)*
- **`balance_sim.py`** — simula (senza Godot) i percorsi ottimali verso ogni finale e
  verifica che tutti e 6 siano raggiungibili e che l'Assedio sia una sfida vincibile.
- **`asset_audit.py`** — controlla riferimenti rotti, illustrazioni mancanti e asset orfani.
- **`shoot.gd`** — cattura screenshot di ~26 schermate in `tools/_preview/` per la
  verifica visiva a schermo (criterio: "se aprissi il gioco per la prima volta, sembrerebbe
  un prototipo?").
- **`gen_audio.py`**, **`gen_decision.py`**, **`slice_*.py`** — generazione/preparazione di
  audio, decisioni e asset.

## 10. Divisione del lavoro e processo

> *[DA COMPLETARE dal team: ripartizione precisa dei ruoli e dei contributi.]*

Team di 2 persone con ruoli flessibili suggeriti (D / `06-roadmap.md`):
- **Lead code**: architettura Godot, autoload, save system, drag-and-drop, Ledger, Assedio.
- **Lead design/content**: scrittura quest e dialoghi, generazione e integrazione asset,
  audio, UI.

Processo: sviluppo iterativo tracciato **decisione per decisione** in `07-decisions-log.md`
e per **ondate di polish** in `09`/`12`. Workflow git documentato in `CONTRIBUTING.md`
(branch + commit convenzionali). Verifica sistematica a schermo dopo ogni feature visiva.

> *[DA COMPLETARE dal team: retrospettiva — cosa è andato bene, cosa rifaremmo diversamente,
> stima ore per persona.]*

## 11. Conclusioni e lavori futuri

Il progetto raggiunge l'obiettivo dell'MVP: un gioco **completo, giocabile dall'inizio alla
fine e rifinito**, che dimostra tutti i sistemi previsti (decisioni-gesto, 8 stat, quest,
catastrofi, civiltà, mystery, 6 finali, Ledger meta-persistente) più una feature-climax
non pianificata inizialmente (L'Assedio). La direzione artistica è coerente e l'esperienza
è curata sul piano del feedback e dell'animazione.

Lavori futuri (north-star, fuori MVP — `00`/`12` §C):
- **Era 3 "Futuro"**: gli asset (consiglieri, sfondi, icone) esistono già; mancano
  quest/decisioni/finali e un terzo set Assedio. L'architettura data-driven rende
  l'aggiunta strutturalmente lineare ma di scope grande.
- Più trame mystery, sistema artefatti più profondo, eventi procedurali, localizzazione
  multilingua, achievement.

---

## Appendice A — Come avviare e come costruire la build

**Eseguire da sorgente**: aprire `project.godot` con Godot 4.6 e premere **F5** (scena
iniziale = menu principale).

**Build Windows `.exe`** (preset "Windows Desktop" già in `export_presets.cfg`):
1. Godot → *Editor > Manage Export Templates > Download and Install* (4.6.x stable).
2. *Project > Export* → verificare il preset → *Export Project…* su `exports/HumanityLedger.exe`
   (oppure da CLI: `Godot_console.exe --headless --path . --export-release "Windows Desktop" exports/HumanityLedger.exe`).
3. Testare l'eseguibile su una cartella/macchina pulita (nuova partita → salva → riapri →
   opzioni). Zippare `exports/` per la consegna.

**Comandi in gioco**: drag-and-drop per decidere · **V** villaggio · **L** Ledger ·
**ESC** pausa · **INVIO** avanza la transizione.

## Appendice B — Mappa dei documenti

| Doc | Contenuto |
|---|---|
| `00` | Overview / visione | `01` | Scope MVP e gerarchia tagli |
| `02` | Game design (GDD) | `03` | Narrativa, ere, mystery |
| `04` | Architettura tecnica | `05` | Arte e audio |
| `06` | Roadmap settimanale | `07` | Log decisioni (D001–D047) |
| `08` | Prompt asset | `09` | Audit AAA / juice / Lapse |
| `10` | Audit UI / villaggio | `11` | L'Assedio (boss fight) |
| `12` | Master roadmap finale | `13` | Redesign estetico (UI kit) |
| `14` | **Questa relazione** | `15` | Script del video demo |

*Documento di consegna. Le sezioni marcate `[DA COMPLETARE dal team]` richiedono
l'apporto soggettivo degli autori (ruoli, ore, retrospettiva).*

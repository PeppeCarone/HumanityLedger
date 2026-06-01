# 02 — Game Design Document

> Le meccaniche del gioco. Definisce **come** si gioca, non **cosa** si racconta (quello è `03-narrative.md`).
> Versione 0.2 — riscritta dopo intervista del 2026-06-01.

---

## Core gameplay loop

### Loop dei 30 secondi (micro-loop)

1. Sullo schermo appare un **evento decisione** — può essere:
   - Una **proposta di un consigliere** ("Il Generale propone una scorreria")
   - Una **reazione a un evento del mondo** ("Una carestia colpisce il popolo. Cosa fai?")
2. Vengono mostrate 2-4 **opzioni** sotto forma di icone/elementi trascinabili
3. Il giocatore esegue il **gesto** (drag-and-drop di un'icona su un target)
4. **Conferma**: animazione del gesto + cambio numerico delle 8 stat in HUD + 1-2 righe narrative come ricaduta
5. Il save autosalva. Si torna in attesa del prossimo evento (auto-triggered dopo 1-3 secondi)

### Loop dei 5 minuti (medio)

- 6-10 decisioni si concatenano dentro un **atto narrativo dell'era**
- Tra atti si presenta una **schermata di bilancio**: stat correnti + ricap narrativo
- Periodicamente arriva un evento **catastrofe** o **diplomatico** che pesa di più

### Loop dell'era (~20-25 decisioni)

- 3 atti narrativi → eventi di pre-transizione
- **Quest chiave dell'era** completata + **soglia stat** raggiunta → si attiva la cinematica di transizione

### Loop della run completa (1-1.5 ore)

- Era 1 Paleolitico → cinematica transizione → Era 2 Regno Mitico → epilogo
- L'epilogo è uno dei 6 finali (vedi `03-narrative.md`)
- A fine run il **Ledger** si aggiorna con le scoperte fatte

### Loop meta (più run nel tempo)

- Il Ledger accumula lore, sblocca eventi nascosti per le run successive
- 3 artefatti scelti a inizio run modificano il bilanciamento

## Sistema di stat

### Le 8 stat globali (allineate ai consiglieri)

| Stat | Consigliere | Range | Cosa rappresenta |
|---|---|---|---|
| **Militare** | Generale | 0-100 | Capacità offensiva e difensiva |
| **Tesoro** | Tesoriere | 0-100 | Risorse accumulate, ricchezza |
| **Diplomazia** | Diplomatico | 0-100 | Relazioni con civiltà rivali e popolo |
| **Scienza** | Scienziato | 0-100 | Conoscenza, innovazione |
| **Legge** | Giurista | 0-100 | Stabilità interna, ordine pubblico |
| **Spionaggio** | Spia | 0-100 | Informazioni, sabotaggi, intelligence |
| **Popolo** | Rivoluzionario | 0-100 | Consenso popolare, morale |
| **Costruzione** | Mastro Costruttore | 0-100 | Infrastrutture, edifici, sviluppo materiale |

> I nomi dei consiglieri sono gli **archetipi** (visti nei prototipi `Consiglieri.png`). I personaggi reali (con nomi) sono in `03-narrative.md`. In Era 1 Paleolitico questi ruoli sono trasposti in chiave tribale (Cacciatore-Capo invece di Generale, Sciamano invece di Scienziato, ecc.).

### Risorsa secondaria

- **Popolazione**: intero ≥ 0. Aumenta/decresce per eventi (carestia, festa, guerra, peste).

### Regole di base

- Le stat **non decadono nel tempo**. Cambiano solo per effetto di decisioni o eventi.
- Cambi minori: ±2-5. Cambi medi: ±10-15. Cambi maggiori (catastrofi, eventi chiave): ±20-30.
- Le stat **transitano** da Era 1 a Era 2 (con eventuale ridimensionamento, decidere W3 in fase di balance).
- **Nessun game over** legato a stat: anche con stat tutte a 0 si continua, ma il finale sarà "Decadenza".

## Sistema delle 8 strategie politiche

Ogni strategia ha un'**icona** (vedi `StrategiePolitiche.png`), un **gesto** associato, e **prerequisiti**.

| Strategia | Stat richiesta (esempio) | Tipo gesto | Target di drop |
|---|---|---|---|
| Azione Militare | Militare ≥ 20 | Icona spada → confine/rivale | Mini-mappa diplomatica |
| Piano Diplomatico | Diplomazia ≥ 15 | Icona pergamena → ambasciatore | Ritratto ambasciatore in scena |
| Piano Economico | Tesoro ≥ 10 | Icona moneta → edificio | Edificio in scena |
| Piano Costruzione | Costruzione ≥ 15 | Icona ascia → lotto vuoto | Lotto/zona costruzione |
| Decreto Reale | Legge ≥ 20 | Icona stendardo → popolazione | Sprite folla |
| Progetto Scientifico | Scienza ≥ 15 | Icona pergamena → consigliere Scienziato | Ritratto Scienziato |
| Missione Spionaggio | Spionaggio ≥ 10 | Icona pugnale → rivale/consigliere | Ambasciatore o consigliere |
| Azione Rivoluzionaria | Popolo ≥ 25 OR Popolo ≤ 15 | Icona torcia → idolo/simbolo | Idolo/vessillo in scena |

### Sistema dei prerequisiti

Quando una strategia non è disponibile (prerequisito non soddisfatto), la sua icona appare **disabilitata** (alpha 50%) con tooltip che spiega cosa manca. Non viene mai *nascosta*: il giocatore deve sapere cosa potrebbe fare se avesse le stat giuste, perché questo è un'indicazione strategica.

### Drag misto (oggetto e target variano)

L'oggetto trascinato **dipende dal tipo di decisione**:

- A volte è l'**icona-strategia** (es. "Costruzione" come ascia)
- A volte è il **ritratto del consigliere proponente** (es. trascinare lo Scienziato sulla biblioteca per assegnarlo a una ricerca)
- A volte è un **token tematico** (moneta, pergamena, soldato)

Il target di drop **dipende dalla strategia**:

- Strategie militari → mini-mappa diplomatica (confine, rivale)
- Strategie sociali → sprite folla o consigliere Rivoluzionario
- Strategie scientifiche → ritratto Scienziato o biblioteca
- Strategie diplomatiche → ambasciatori in scena
- Strategie economiche → edifici
- Strategie costruttive → lotti vuoti

> Questo richiede attenzione al **tutorial diegetico**: le prime 2-3 decisioni nella caverna devono insegnare i 2-3 pattern principali. Vedi `03-narrative.md` per il flow tutorial.

### 4 stati visivi del drag

(Vedi `Assets/dragndrop.png`)

| Stato | Descrizione |
|---|---|
| **Drag** | L'icona segue il mouse, leggermente ingrandita, ombra esterna |
| **Hover** | Quando passa sopra un target valido: glow verde sul target, l'icona reagisce |
| **Successful drop** | Animazione di assorbimento + flash sul target + suono conferma |
| **Failed drop** | Drop fuori target valido: l'icona torna alla posizione iniziale + suono leggero di errore |

## Sistema delle decisioni

### Tipi di decisione

1. **Proposte attive dei consiglieri** (~50% del totale): un consigliere propone una strategia. Il giocatore accetta (drag) o rifiuta (cancel/timeout).
2. **Reazioni a eventi del mondo** (~50% del totale): un evento (catastrofe, opportunità) arriva e i consiglieri propongono 2-4 risposte alternative.

### Cancellazione di una decisione

- **Drag e rilascio fuori target** → la decisione si annulla, si torna in attesa
- **Timeout** (se implementato in v2): la decisione passa, la stat del consigliere proponente diminuisce leggermente (ha perso credito)

> MVP: niente timeout. Il giocatore ha tutto il tempo che vuole.

## Sistema delle catastrofi

Quando una catastrofe viene innescata (scripted in base a quest/stat), il flusso normale si **interrompe**:

1. Schermata centrale con l'illustrazione della catastrofe (vedi `Scenari.png`)
2. Testo evento ("Una peste colpisce il villaggio.")
3. 2-4 opzioni proposte da consiglieri specifici (es. peste → propongono Scienziato, Giurista, Spia)
4. Drag della soluzione scelta
5. Conseguenze immediate + spesso catena di 1-2 decisioni di follow-up

Le 8 catastrofi (vedi `Scenari.png`):

| Catastrofe | Trigger tipico | Risoluzione tipica |
|---|---|---|
| Carestia | Tesoro/Costruzione bassi | Razionamento, scambio, decreto |
| Peste | Scienza/Costruzione bassi | Quarantena, ricerca, fede |
| Ribellione | Popolo/Legge bassi | Repressione, riforma, propaganda |
| Tentato Assassinio | Spionaggio alto rivale | Indagine, contro-attacco, vendetta |
| Vertice Diplomatico | Tensione con rivale | Accordo, rottura, doppio gioco |
| Breakthrough Scientifico | Scienza alta | Industrializzare, segretare, dono |
| Conflitto Religioso | Popolo/Legge in tensione | Tolleranza, repressione, sintesi |
| Crisi Economica | Tesoro basso | Tassazione, dazi, prestiti |

## Sistema delle quest

### Tipi di quest

- **Quest narrative principali** (3 per era, ~6 totali): fanno avanzare la trama dell'era
- **Quest chiave dell'era** (1 per era, ~2 totali): completarla è prerequisito per passare all'era successiva
- **Quest opzionali** (1-3 per era): scoperte, easter egg, lore
- **Trama mystery parallela** (1 in totale, attraversa entrambe le ere): sbloccata da scelte specifiche

### Quest log

Il giocatore vede un **pannello quest log** (accessibile dall'HUD) che mostra:

- Quest attive con descrizione e step corrente
- Quest chiave dell'era con condizioni di completamento
- Quest opzionali sbloccate

### Schema dati semplificato

```
Quest {
  id: string
  titolo: string
  era: 1 | 2
  tipo: principale | chiave | opzionale | mystery
  precondizioni: { flag: bool, stat: {nome: min} }
  passi: [Decisione...]
  esiti: {success: Effetto, fail: Effetto}
  flag_di_completamento: string
  visibile_nel_log: bool
}
```

Dettagli implementativi in `04-architecture.md`.

## Sistema di feedback narrativo realtime

Dopo ogni decisione:

1. **Immediatamente (0-200ms)**: animazione del gesto sull'icona + flash visivo sul target
2. **0.5-1s**: i numeri delle 8 stat coinvolte si animano (count-up/down) e si colorano (verde positivo, rosso negativo)
3. **1-2s**: appare 1-2 righe di testo narrativo (max 40 parole) in un pannello inferiore
4. **2-3s**: se la decisione ha conseguenze visive (nuovo edificio appare, consigliere se ne va, palette cambia), animazione di entrata/uscita

L'utente **non può prendere la decisione successiva** finché il feedback non è completato. Questo dà peso alla scelta.

## Transizione tra ere

Quando il giocatore ha:
- Completato la **quest chiave dell'Era 1** (es. "Costruisci il primo Idolo"), E
- Raggiunto la **soglia stat** richiesta (es. Costruzione + Popolo ≥ 80)

Si attiva la **cinematica di transizione**:

1. Schermata nera con testo: *"Le stagioni passano. Il fuoco della caverna si spegne. Le stat sopravvissute attraversano i secoli."*
2. Animazione delle stat che "viaggiano" verso l'Era 2 (alcune vengono ridotte: i numeri non sono direttamente proporzionali tra ere)
3. Schermata Era 2 si apre: città fortificata vista dall'alto, 8 nuovi consiglieri nei pannelli laterali
4. Primo evento Era 2 è una **decisione di reintroduzione** (es. "Il nuovo Consiglio si forma. Quale è la prima priorità?")

## Sistema delle civiltà rivali

### Presentazione

- **Mini-mappa diplomatica**: pulsante nell'HUD apre un pannello con 2-3 "blocchi" rappresentanti le civiltà rivali
- Ogni blocco mostra: simbolo, nome, **relazione corrente** con noi (-100 ostile / 0 neutro / +100 alleato)
- Click su un blocco → pannello dettagli con stat relative (es. "Loro Militare: 60 / Nostro: 45") e azioni possibili

### Ambasciatori

- Quando arriva un **evento diplomatico**, appare in scena (laterale) il **ritratto dell'ambasciatore** di quella civiltà
- L'ambasciatore "parla" (testo): proposte di accordo, minacce, scambi
- Il giocatore reagisce via drag (es. drag "Diplomazia" su ambasciatore = accetta; drag "Militare" = rompi)

### Comportamento

- Niente IA autonoma: le civiltà rivali sono **guidate da script** narrativo
- I loro stat cambiano via eventi scripted in punti predefiniti
- Possono diventare **alleati**, **rivali aperti**, o **neutrali** in base alle decisioni

## Sistema Ledger (meta-progressione)

### Schermata Ledger

Accessibile dal menu principale, tre tab:

1. **Lore** — frammenti di testo sbloccati (5-10 frammenti)
2. **Artefatti** — i 3 artefatti disponibili da selezionare a inizio run + descrizione
3. **Eventi sbloccabili** — 3-5 eventi nascosti, indicati con ??? finché non scoperti

### Persistenza

- File separato `user://ledger.json`, non si resetta a fine run
- Si aggiorna a fine run e durante run in momenti specifici

### Artefatti MVP (effetti meccanici esempi — da bilanciare)

| Nome (provvisorio) | Effetto |
|---|---|
| **La Pietra del Fuoco** | +10 a Costruzione iniziale; sblocca un dialogo del Mastro Costruttore extra |
| **Il Corno dell'Adunata** | Tutte le decisioni del Generale costano 2 stat in meno; sblocca un finale "Era della Guerra" più ricco |
| **La Lacrima di Lyssa** | Aumenta la probabilità di trigger dell'evento mystery (+30%); 1 visione gratuita |

> I nomi sono provvisori, da finalizzare in `03-narrative.md`. L'importante è che ognuno abbia: un buff numerico, uno sblocco narrativo, e un'identità tematica.

### Eventi sbloccabili nascosti (esempi)

- Evento "Il Fiume Rosso": appare solo se hai accolto lo Straniero in una run precedente
- Evento "L'Ultima Pittura": appare solo se hai investito 3+ volte in Cultura
- Evento "La Voce nel Bosco": appare solo se hai equipaggiato La Lacrima di Lyssa

## Condizioni di "vittoria" (finali)

Vedi `03-narrative.md` per i 6 finali in dettaglio. Sintesi delle condizioni:

- **Determinazione**: stat dominante/i a fine Era 2 + decisioni chiave specifiche fatte (NON solo somma stat)
- Alcune decisioni sono "diramazioni definitive" che possono cambiare il finale anche con stat non perfettamente allineate

Esempio: anche con Scienza altissima, se hai "esiliato lo Scienziato Rivoluzionario" il finale "Era della Scienza" si chiude e ripieghi su un altro.

## Sistemi v2 (post-deadline)

Idee parcheggiate, non da implementare ora ma da menzionare nella relazione:

- Albero tecnologico esplicito con sblocco di gesti nuovi
- IA reattiva delle civiltà rivali
- Sistema economico con valuta, tasse, prezzi dinamici
- Personaggi consiglieri con relazioni reciproche (Spia ostile col Generale, ecc.)
- 10+ artefatti con sistema di build/combinazioni
- Mappa esplorabile in modalità RTS leggera
- Boss fight giocabili come sotto-gioco
- Ere 3-7 con transizioni tematiche
- Eventi procedurali generati
- Sistema reputazione personale per ogni NPC

---

*Versione 0.2 — 2026-06-01.*

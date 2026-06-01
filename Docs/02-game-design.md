# 02 — Game Design Document

> Le meccaniche del gioco. Definisce **come** si gioca, non **cosa** si racconta (quello è `03-narrative.md`).

---

## Core gameplay loop

### Loop dei 30 secondi (micro-loop)

1. Sullo schermo appare un **evento decisione**: testo del consigliere + 2-4 *opzioni-gesto*
2. Il giocatore esegue il gesto (drag-and-drop di un'icona)
3. Animazione di conferma + cambio numerico delle 4 stat in HUD + 1-2 frasi narrative come ricaduta
4. Si torna in attesa del prossimo evento (auto-triggered dopo qualche secondo)

### Loop dei 5 minuti (medio)

- 6-10 decisioni si concatenano in un *atto narrativo*
- Alla fine dell'atto un evento più grande (crisi, scoperta, ambasceria) cambia il tono
- Le stat tra atti vengono congelate e mostrate in una **schermata di bilancio**

### Loop della run completa (30-60 min)

- 3 atti narrativi → 1 finale
- Il finale è scelto in base a: stat finali, decisioni chiave, attivazione/non-attivazione dell'evento mystery

## Sistema di stat

### Le 4 stat globali

| Stat | Range | Descrizione | Game over se |
|---|---|---|---|
| Tecnologia | 0-100 | Conoscenza, strumenti, sapere | <10 per 2 atti consecutivi |
| Felicità | 0-100 | Morale del popolo | <5 per 1 atto |
| Economia | 0-100 | Cibo, risorse, scambi | <10 per 1 atto |
| Potenza Militare | 0-100 | Capacità difensiva/offensiva | <5 + civiltà rivale forte |

> **Game over** = finale "fallimento del popolo" anticipato. Non un crash o reset: comunque si arriva a un epilogo, solo più triste.

### Risorse derivate

- **Popolazione**: intero ≥0. Aumenta o decresce per eventi (carestia, festa, guerra).
- **Reputazione con la civiltà rivale**: -100 (guerra aperta) a +100 (alleati). Influenza i finali.

### Regole di base

- Le stat **non decadono nel tempo**. Cambiano solo per effetto di decisioni o eventi.
- Cambi minori: ±2-5. Cambi medi: ±10-15. Cambi maggiori (eventi grandi): ±20-30.
- Non esiste UI per "spendere stat": le stat sono *condizioni*, non valute.

## Sistema delle decisioni-gesto

Ogni decisione propone 2-4 opzioni, ciascuna rappresentata da un'**icona trascinabile**. Il giocatore trascina UNA delle icone su un **target visivo** (un edificio, un personaggio, un confine) per confermare la scelta.

### Tipi di gesto pre-definiti per MVP

| Tipo gesto | Icona | Target | Esempio narrativo |
|---|---|---|---|
| **Soldato → confine** | Sprite soldato | Bordo della mappa | Dichiara guerra |
| **Ramo d'ulivo → ambasciatore** | Ramo | NPC ambasciatore | Proponi alleanza |
| **Monete → edificio** | Sacchetto monete | Edificio (mercato, tempio, mura) | Investi/potenzia |
| **Pugnale → personaggio** | Pugnale | NPC consigliere/rivale | Decisione drastica (esilio, assassinio) |
| **Pergamena → studioso** | Pergamena | NPC studioso | Investi in conoscenza |
| **Pane → folla** | Pane | Sprite popolazione | Distribuisci cibo |
| **Torcia → simbolo** | Torcia | Idolo / vessillo | Cambia ideologia / religione |

> **Vincolo MVP**: ne implementiamo solo 4-5 dei 7 sopra, riusando le icone su decisioni diverse.

### Cosa **non** è un gesto

- Cliccare su un pulsante "Conferma"
- Selezionare una voce di menu a tendina
- Navigare in un albero di dialoghi tradizionale (alla CRPG)

Se serve una scelta secondaria (es. *quale* edificio costruire dopo aver scelto "costruisci"), si apre un secondo gesto subito dopo, non una finestra modale.

### Cancellazione

Il giocatore può rilasciare il drag fuori dal target → la scelta si annulla, si torna alla decisione. Solo dopo aver rilasciato su un target valido la scelta è **definitiva**.

## Sistema delle quest

### Tipi di quest

- **Quest narrative principali** (3 per atto, ~9-10 totali): fanno avanzare la trama
- **Quest opzionali** (1-3 per atto): scoperte, easter egg, lore. Non bloccanti.
- **Evento mystery** (1 per run): trigger condizionato a una stat o decisione specifica, attiva il ramo strano

### Struttura di una quest

Una quest è una **sequenza di 1-5 decisioni** + uno **stato di completamento** che modifica permanentemente lo stato del gioco (flag booleano + modifiche stat).

Schema dati semplificato (vedi `04-architecture.md` per impl):

```
Quest {
  id: string
  titolo: string
  precondizioni: [stat o flag richiesti]
  passi: [Decisione...]
  esiti: {success: Effetto, fail: Effetto}
  flag_di_completamento: string
}
```

## Sistema di feedback narrativo realtime

Dopo ogni decisione:

1. **Immediatamente (0-200ms)**: animazione del gesto sull'icona trascinata + flash visivo sul target
2. **0.5-1s**: i numeri delle 4 stat in HUD si animano (count-up/down) e si colorano di verde/rosso
3. **1-2s**: appare 1-2 righe di testo narrativo come tooltip o pannello in basso ("Il popolo accoglie la decisione con entusiasmo." / "Mercanti si lamentano del nuovo dazio.")
4. **2-3s**: se la decisione ha conseguenze visive (es. un nuovo edificio appare, un NPC se ne va), animazione di entrata/uscita

L'utente **non può prendere la decisione successiva** finché il feedback non è completato (~2-3s). Questo dà peso alla scelta.

## Condizioni di vittoria / sconfitta

- **Vittoria**: arrivare al finale dell'Atto 3 con almeno 2 stat sopra 50 → epilogo "prospero"
- **Vittoria parziale**: arrivare al finale ma con stat compromesse → epilogo "sopravvivenza"
- **Sconfitta**: game over per crollo stat → epilogo "decadenza"
- **Finale mystery**: attivazione dell'evento mystery + scelta specifica → epilogo "alternativo"

Quindi: **3-4 finali totali** per MVP.

## Sistemi v2 (post-deadline)

Idee parcheggiate, non da implementare ora:

- Albero tecnologico esplicito con sblocco di gesti nuovi
- Personaggi consiglieri con personalità persistente e relazioni reciproche
- Economia con valuta, tasse, prezzi dinamici
- Mappa esplorabile in modalità RTS leggera (Clash of Clans-like)
- Boss fight giocabili (battle system tipo turn-based)
- Civiltà rivali con IA reattiva e simulazione autonoma
- Ere multiple con transizione (proceduri di "Era successiva" che modificano UI/gesti)

---

*Versione 0.1 — 2026-06-01. Da rivedere dopo intervista narrative.*

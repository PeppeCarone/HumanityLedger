# 07 — Decisions Log

> Registro cronologico delle decisioni di design e tecniche. Ogni voce ha un ID stabile, una motivazione, e uno stato (attiva/superata).
> Materiale prezioso per la relazione finale di esame: documenta il *perché* delle scelte.

---

## Convenzioni

- Ogni decisione ha un ID `D###` progressivo
- Quando una decisione viene revocata, NON va cancellata: si imposta `status: superata` e si linka alla decisione che la sostituisce
- Formato voce:

```
### Dxxx — Titolo breve
- **Data**: AAAA-MM-GG
- **Status**: attiva | superata da Dxxx
- **Decisione**: cosa
- **Motivazione**: perché
- **Implicazioni**: cosa cambia in pratica
- **Alternative considerate**: cosa abbiamo escluso e perché
```

---

## Decisioni iniziali (2026-06-01)

### D001 — Godot 4.6 come engine

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: usiamo Godot 4.6 stable.
- **Motivazione**: gratuito, open source, ottimo per 2D + UI, esporto rapido su PC, GDScript ha curva di apprendimento bassa.
- **Implicazioni**: tutto il codice in GDScript, asset in formato Godot-friendly, nessun vincolo di costo.
- **Alternative considerate**: Unity (più heavy, licensing ambiguo), Unreal (overkill per 2D), engine custom (impossibile nei tempi).

### D002 — GDScript, non C#

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: il codice è scritto in GDScript con type hints statici.
- **Motivazione**: iterazione più veloce, nessuna dipendenza .NET, meglio integrato con Godot, niente overhead di compilazione.
- **Implicazioni**: i programmatori devono usare GDScript anche se più abituati a C#.
- **Alternative considerate**: C# (build più lente, dipendenze, meno hot-reload).

### D003 — MVP a 1 sola era

- **Data**: 2026-06-01
- **Status**: **superata da D012**
- **Decisione (originale)**: l'MVP copre la sola era Tribale/Antica. Le altre 6 ere restano come visione futura.
- **Motivazione**: con 2 persone e 1-3 mesi, 7 ere sono ~12 mesi di lavoro a tempo pieno.
- **Esito**: durante l'intervista narrativa il team ha scelto di **mostrare la transizione** tra ere come pilastro del gioco. Decisione aggiornata in D012 (2 ere con transizione).

### D004 — Stile silhouette + texture carta

- **Data**: 2026-06-01
- **Status**: **superata da D013**
- **Decisione (originale)**: silhouette + palette ristretta + texture pergamena.
- **Esito**: i prototipi forniti dal team mostrano uno stile painterly dettagliato (vedi `Assets/`). Il team ha scelto di adottare quello stile via AI generativa + post-produzione. Vedi D013.

### D005 — Italiano only per MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: l'MVP è solo in italiano. Niente sistema di localizzazione.
- **Motivazione**: il target sono i valutatori del corso universitario (italofoni). Implementare `tr()` aggiunge overhead.
- **Implicazioni**: testi inline nelle Resource `.tres`. Refactor futuro se si vuole pubblicare.
- **Alternative considerate**: bilingue it/en (raddoppia il lavoro di scrittura), solo english (svantaggio sui valutatori).

### D006 — Niente boss fight nel MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: l'evento mystery è gestito come quest narrativa, non come boss fight giocabile.
- **Motivazione**: un battle system (anche minimal) è un sotto-gioco intero che richiederebbe 2-3 settimane di lavoro per balance, animazioni, feedback. Non compatibile con i tempi.
- **Implicazioni**: il mystery vive nei testi e in qualche cambio visivo (palette del fiume). L'utente lo *vive*, non lo *combatte*.
- **Alternative considerate**: minigioco di scelta a tempo (rischio: rompe il tono), boss fight stile turn-based (impossibile nei tempi), boss fight stile QTE (banale).

### D007 — Architettura data-driven con Resource `.tres`

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: quest, decisioni, effetti vivono come `.tres` editabili dall'editor di Godot. Lo script di gioco non contiene mai testo narrativo o numeri hardcoded.
- **Motivazione**: permette al designer di scrivere quest senza toccare codice; permette versionamento granulare; testing più semplice.
- **Implicazioni**: tempo iniziale per definire le classi Resource (W3). Dopo, contenuti aggiunti a costo basso.
- **Alternative considerate**: tutto in script (cresce a dismisura, conflitti git), JSON esterno (perde tipizzazione e editor di Godot), CSV (orribile per testi multilingua/lunghi).

### D008 — Decisioni come gesti drag-and-drop, mai click-su-menu

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: ogni decisione importante si esegue trascinando un'icona su un target visivo nella scena.
- **Motivazione**: pilastro di design (vedi `00-overview.md`). Differenzia il gioco da *Reigns* e simili.
- **Implicazioni**: la prima settimana va spesa per prototipare il sistema. Se non funziona, è un rischio grosso.
- **Alternative considerate**: click classico (perde l'identità), tastiera (escluso per UX), gesture su touch (escluso per scope PC).

### D009 — Save singolo, autosave dopo ogni decisione

- **Data**: 2026-06-01
- **Status**: **estesa da D025**
- **Decisione (originale)**: un solo slot di save, autosave dopo ogni decisione.
- **Esito**: la decisione resta valida MA va affiancata da un secondo file persistente per il Ledger meta-progressivo. Vedi D025.

### D010 — Solo PC Windows come piattaforma target MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: MVP esporta solo Windows 64-bit.
- **Motivazione**: i valutatori useranno PC Windows. macOS/Linux sono export gratuiti ma non vengono testati.
- **Implicazioni**: nessun test su altre piattaforme. Se serve a fine progetto, export aggiuntivo richiede solo qualche ora.
- **Alternative considerate**: multi-piattaforma (overhead di QA), web (limitazioni di Godot 4 per HTML5), mobile (UI da rifare).

---

---

## Decisioni post-intervista narrativa (2026-06-01)

Decisioni emerse dall'intervista strutturata del 2026-06-01 in cui il team ha definito visione, sistemi e scope del gioco a partire dai prototipi visivi forniti.

### D011 — Giocatore = "spirito anonimo del popolo"

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: il giocatore è lo spirito del popolo che attraversa le ere. Niente leader visibile (re/capo). I consiglieri sono gli unici volti del potere.
- **Motivazione**: framing coerente con il titolo *HumanityLedger* (registro tramandato). Permette riuso del framework di sistemi attraverso ere diverse. Riduce il lavoro di scrittura (no dialoghi col leader, no eventi di successione).
- **Implicazioni**: niente succession events, nessun ritratto re/capo, l'UI mockup "Royal Council" va riadattata, il giocatore non viene mai chiamato per nome.
- **Alternative considerate**: leader visibile stile Crusader Kings (più lavoro, costringe a personalizzazione), consiglio collettivo (più astratto), personaggio specifico (più intimo ma rompe il concept di ledger trans-era).

### D012 — MVP a 2 ere con transizione

- **Data**: 2026-06-01
- **Status**: attiva (supersede D003)
- **Decisione**: l'MVP copre 2 ere giocabili con transizione esplicita tra esse.
- **Motivazione**: la transizione tra ere è un pilastro identitario del gioco. Senza, "humanity ledger" perde significato. Una sola era polished non dimostra il sistema.
- **Implicazioni**: scope quasi raddoppiato rispetto a D003. Va affrontato con gerarchia di tagli (`01-mvp-scope.md`). Doppio set di consiglieri, doppia scenografia, sistema transizione da implementare.
- **Alternative considerate**: 1 era (escluso, vedi sopra), 3 ere (impossibile nei tempi, ci si ritrova senza nessuna era polished).

### D013 — Stile painterly dettagliato mythico-epico via AI generativa

- **Data**: 2026-06-01
- **Status**: attiva (supersede D004)
- **Decisione**: direzione artistica painterly dettagliata in chiave mitico-epica. Pipeline primaria: AI generativa con post-produzione manuale per unificare lo stile.
- **Motivazione**: i prototipi forniti dal team (`Assets/Consiglieri.png`, ecc.) mostrano già questo stile. È coerente con il tono mythico-epico (vedi D015). AI rende fattibile in tempi brevi senza un artista dedicato.
- **Implicazioni**: dipendenza da tool AI. Va verificata policy università. `CREDITS.md` deve documentare prompt e modifiche. Per asset trasversali (logo, icone, cornici) preferire produzione manuale.
- **Alternative considerate**: silhouette (D004, troppo lontano dalla qualità dei prototipi), artista dedicato (non c'è), CC0 puro (mancanza di coerenza stilistica).

### D014 — Setting MVP: Paleolitico → Regno Mitico

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: Era 1 = Paleolitico (caverna interna, 8 consiglieri attorno al fuoco). Era 2 = Regno Mitico non-storico (città fortificata vista dall'alto + consiglieri come pannelli laterali).
- **Motivazione**: Paleolitico dà origine narrativa forte e visivamente distinta dalle ere successive. Regno Mitico (non Medievale storico) dà libertà narrativa massima e permette di riusare lo stile dei prototipi medievali come "fantasy mitico".
- **Implicazioni**: serve produrre asset paleolitici da zero (i prototipi medievali non si applicano all'Era 1). I prototipi vanno riadattati per Era 2. Forte salto visivo tra le due ere è cercato, non accidentale.
- **Alternative considerate**: Tribale + Classica (più storico, ma Era 2 non sfrutta i prototipi), Medievale + Moderna (storico, ma perde l'origine narrativa), Era 1 sola (esclusa in D012).

### D015 — Tono mythico-epico

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: tono narrativo solenne, oracolare, archetipico. Niente realismo storico, niente ironia, niente moderno.
- **Motivazione**: coerente con il framing "spirito che attraversa le ere", con i prototipi visivi, con le ispirazioni dichiarate (Hades, Pyre, Annihilation).
- **Implicazioni**: linee guida di scrittura precise (frasi brevi, immagini, niente parole moderne). I consiglieri parlano per immagini e tic linguistici.
- **Alternative considerate**: realismo antropologico (più documentaristico, meno emotivo), satirico tipo Reigns (rompe il tono), epico-rinascimentale (troppo elevato).

### D016 — Sistema 8 stat allineate ai consiglieri

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: 8 stat globali, una per consigliere: Militare, Tesoro, Diplomazia, Scienza, Legge, Spionaggio, Popolo, Costruzione. Range 0-100.
- **Motivazione**: si appoggia direttamente sui prototipi `Consiglieri.png` e `StrategiePolitiche.png` (già 8). Mappa pulita: ogni consigliere ha un dominio. I 6 finali emergono da combinazioni di stat.
- **Implicazioni**: HUD denso (8 numeri da mostrare leggibilmente). Balance più complesso di un sistema a 4 stat. Numerazione "8+8+8+6" diventa identità del sistema.
- **Alternative considerate**: 4 stat (troppo grossolano per il sistema), 6 stat allineate ai finali (sovrapposizione confusa con i percorsi), score complesso a pesi (intrasparente al giocatore).

### D017 — 8 strategie politiche drag-and-drop con prerequisiti

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: 8 strategie come strumenti di azione del giocatore: Azione Militare, Piano Diplomatico, Piano Economico, Piano Costruzione, Decreto Reale, Progetto Scientifico, Missione Spionaggio, Azione Rivoluzionaria. Alcune richiedono prerequisiti (stat minime o consiglieri attivi).
- **Motivazione**: rispecchia `StrategiePolitiche.png`. Prerequisiti danno tensione strategica: non puoi sempre scegliere quello che vuoi.
- **Implicazioni**: ogni strategia ha definizione di prerequisiti precisa. Le icone disabilitate vanno mostrate (non nascoste) con tooltip. Più lavoro di balance.
- **Alternative considerate**: nessun prerequisito (banale, sandbox), turni limitati (rompe il flusso event-driven), prerequisiti hard-locked invisibili (frustra il giocatore).

### D018 — Drag misto: oggetto e target variano

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: ciò che si trascina varia per tipo di decisione (icona strategia / ritratto consigliere / token tematico). Il target di drop varia coerentemente (mappa, edificio, consigliere, ambasciatore).
- **Motivazione**: più ricco e narrativamente espressivo del drag uniforme. Coerente col pilastro "decisione come gesto".
- **Implicazioni**: il tutorial diegetico deve insegnare 2-3 pattern in 3-4 decisioni. Più complessità di implementazione (ghost diversi, target diversi). Da progettare attentamente in W2.
- **Alternative considerate**: solo icona strategia (più semplice, meno espressivo), solo ritratto consigliere (limitato), un pattern per tutto (meno emergente).

### D019 — 16 consiglieri unici (8 per era)

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: ogni era ha 8 consiglieri unici con nomi, ritratti, voci e tic linguistici propri. Stessi 8 archetipi attraverso le ere ma personaggi reinventati ad ogni era.
- **Motivazione**: dà personalità forte ad ogni era. La continuità è negli archetipi, non nei volti — coerente con "spirito che attraversa le ere".
- **Implicazioni**: 16 ritratti da produrre. 16 voci scritte da definire. Più lavoro di asset e scrittura ma più memorabilità.
- **Alternative considerate**: 8 personaggi cross-era (più economico ma rompe il senso del "trans-era"), numero variabile per era (asimmetrico).

### D020 — Catastrofi come eventi-decisione speciali

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: 8 tipi di catastrofe (Carestia, Peste, Ribellione, Tentato Assassinio, Vertice Diplomatico, Breakthrough Scientifico, Conflitto Religioso, Crisi Economica) gestite come eventi-decisione speciali con peso aumentato, non come boss fight giocabili.
- **Motivazione**: coerente con D006 (no boss fight in MVP). Aggiunge variazione narrativa senza richiedere sistema di combat dedicato.
- **Implicazioni**: ogni catastrofe ha 2-4 risposte proposte da consiglieri specifici + 1-2 decisioni di follow-up. 8 illustrazioni dedicate (vedi `Scenari.png`).
- **Alternative considerate**: boss fight (escluso, troppo costoso), eventi normali (perde il senso di catastrofe), QTE (banale).

### D021 — 2-3 civiltà rivali per era + ambasciatori + mini-mappa

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: ogni era ha 2-3 civiltà rivali rappresentate da: (a) ambasciatore narrativo con ritratto che appare in scena durante eventi diplomatici; (b) mini-mappa diplomatica accessibile dall'HUD con stat relative.
- **Motivazione**: due livelli di interazione: narrativo (ambasciatori) e strategico (mini-mappa). Più ricco di una sola modalità.
- **Implicazioni**: 4-6 ritratti ambasciatori. Mini-mappa UI da implementare. Comportamento delle civiltà rivali interamente scriptato (no IA autonoma).
- **Alternative considerate**: solo stat in HUD (poco narrativo), solo ambasciatori (manca visione strategica), IA reattiva (impossibile nei tempi).

### D022 — Trama mystery parallela sbloccabile

- **Data**: 2026-06-01
- **Status**: attiva (estende D006)
- **Decisione**: c'è una trama mystery parallela attivabile tramite decisioni specifiche. Ha quest dedicate, eventi visivi (fuoco rosso, pittura che cambia, voce nel bosco), e conduce a un finale alternativo distinto ("Era Futura").
- **Motivazione**: il pilastro mystery dal brain dump iniziale resta vivo ma incanalato come BRANCHING NARRATIVO opzionale, non come elemento meccanico separato.
- **Implicazioni**: scrittura di 5-6 quest aggiuntive. Effetti visivi speciali (palette change, animazioni). Trigger condizioni multiple. Lavoro narrativo non banale.
- **Alternative considerate**: mystery come irruzione narrativa rara (più piccolo, meno impatto), mystery con meccanismo gameplay dedicato (9ª stat, troppo costoso), niente mystery (perde un'idea identitaria).

### D023 — 6 finali differenziati determinati da stat + decisioni chiave

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: 6 finali (Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura). Determinati da stat dominanti a fine Era 2 + decisioni chiave specifiche fatte durante la run.
- **Motivazione**: gli 8 percorsi sarebbero stati troppi; 6 corrispondono ai trasformazioni mostrate in `TrasformazioniMondo.png`. Il mix stat + decisioni chiave evita finali "vinti per puntini" e premia coerenza narrativa.
- **Implicazioni**: 6 illustrazioni epilogo + 6 testi (max 400 parole ciascuno). Logica condizionale complessa per scelta finale. Sistema fallback in caso di nessuna condizione chiara.
- **Alternative considerate**: stat dominante singola (semplice ma poco sfumato), score puro con pesi (intrasparente), tutti i 6 finali via stat (manca peso narrativo).

### D024 — Nessun game over, sempre si arriva a un finale

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: anche con stat tutte a zero, la run prosegue fino a un finale (in quel caso un "Decadenza"). Niente schermata Game Over.
- **Motivazione**: rispetta il framing "spirito che attraversa le ere" — lo spirito non muore, osserva tutti gli esiti. Riduce frustrazione, aumenta completion rate.
- **Implicazioni**: bilanciamento delle decisioni più morbido. Sistema di fallback per finali con stat bassissime.
- **Alternative considerate**: game over classico (rompe il framing), restart automatico (troppo punitivo per una run da 1-1.5h).

### D025 — Save run + Ledger persistente separato

- **Data**: 2026-06-01
- **Status**: attiva (estende D009)
- **Decisione**: due file di save:
  - `user://save.json` — autosave della run corrente, sovrascritto a ogni decisione, cancellato a fine run
  - `user://ledger.json` — persistente cross-run, accumula lore sbloccata, artefatti, eventi sbloccati
- **Motivazione**: necessario per il sistema Ledger (D026). Mantiene la semplicità del single-slot per la run.
- **Implicazioni**: due percorsi di salvataggio. Nessuna interazione tra i due file. Pulire `save.json` ma mai `ledger.json` a fine run.
- **Alternative considerate**: file unico (mischia preoccupazioni), no Ledger persistente (perde meta-progressione D026).

### D026 — Sistema Ledger meta-progressivo

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: schermata Ledger accessibile da menu principale con 3 sezioni: Lore (frammenti narrativi sbloccati), Artefatti (3 disponibili, scelta a inizio run, ognuno con effetto meccanico distinto), Eventi sbloccabili (3-5 eventi nascosti che si attivano solo dopo aver fatto certe scoperte in run precedenti).
- **Motivazione**: incarna il titolo *HumanityLedger* — il registro che si tramanda. Aggiunge rigiocabilità senza richiedere multiplayer o procedurale.
- **Implicazioni**: persistenza separata (D025). 3 artefatti da progettare e bilanciare. Lore extra da scrivere (5-10 frammenti). Logica di "evento sbloccabile in run successive". Aggiunge ~1-2 settimane di lavoro.
- **Alternative considerate**: solo lore (semplice ma piatto), 10+ artefatti con build (scope creep), niente Ledger (perde caratterizzazione del gioco).

### D027 — Transizione era = soglia stat + quest chiave

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: per passare da Era 1 a Era 2 servono: (a) il completamento di una quest narrativa chiave dell'era; (b) il raggiungimento di una soglia di stat predefinita.
- **Motivazione**: combina agenzia narrativa (quest) e progressione meccanica (stat). Evita i due estremi: pure stat (privo di senso) e pure quest (puoi finire l'era con stat zero).
- **Implicazioni**: design della quest chiave è delicato (deve essere raggiungibile in tutti i percorsi). Soglia stat da bilanciare per non bloccare il giocatore.
- **Alternative considerate**: solo turni (banale), solo stat (privo di senso narrativo), solo quest (rompe la progressione meccanica), libera scelta del giocatore (rischio di stallo).

### D028 — Quest log con obiettivi visibili

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: pannello quest log accessibile dall'HUD che mostra: quest attive, quest chiave dell'era, quest opzionali sbloccate. Le quest mystery appaiono come ??? finché non rivelate.
- **Motivazione**: con un sistema complesso (8 stat, prerequisiti, transizioni condizionali), il giocatore ha bisogno di una guida visibile. Riduce frustrazione.
- **Implicazioni**: UI aggiuntiva (pannello quest log). Va scritta una descrizione log per ogni quest.
- **Alternative considerate**: al buio (più immersivo ma frustrante), solo quest chiave visibile (info parziale), quest log solo in momenti chiave (incoerente).

### D029 — Spirito silenzioso, parlano solo i consiglieri

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: lo spirito (il giocatore) non ha voce esplicita né come narratore né come personaggio. Tutto il testo viene dai consiglieri o da descrizioni neutre.
- **Motivazione**: riduce il lavoro di scrittura. Lo spirito *è* l'intenzione delle decisioni, non un personaggio. Coerente con D011.
- **Implicazioni**: niente narratore in apertura/finali. Tutti i finali sono raccontati dai consiglieri o da prose oggettive.
- **Alternative considerate**: voce narrante oracolare (più atmosferico ma più scrittura), spirito che dialoga col giocatore (rompe l'astrazione), solo in apertura/finale (poco utile).

### D030 — Tutorial diegetico nella caverna

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: le prime 2-3 decisioni del gioco (dentro la caverna paleolitica) sono il tutorial. Insegnano drag, stat che cambiano, quest log — diegeticamente, senza pop-up esplicativi.
- **Motivazione**: non rompe l'immersione. Sfrutta il "gioco inizia quando i consiglieri escono dalla caverna" come arco narrativo.
- **Implicazioni**: le prime decisioni vanno progettate con doppia funzione (tutorial + narrativa). Possono servire pochi tooltip minimi su drag/drop al primo gesto.
- **Alternative considerate**: tutorial pop-up esplicito (rompe immersione), tutorial in menu separato (lavoro UI in più), niente tutorial (rischio confusione).

### D031 — Durata run 1-1.5 ore

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: target di durata per una run completa Era 1 → Era 2 → finale: 1-1.5 ore. ~20-25 decisioni per era.
- **Motivazione**: abbastanza lungo per dare peso narrativo, abbastanza corto per essere rigiocabile (Ledger). Non confondere col tempo del giocatore: il bilancio è 40-50 decisioni totali per run.
- **Implicazioni**: ogni decisione deve avere peso (no filler). Bilanciamento delle stat su 40-50 cambi.
- **Alternative considerate**: 30-45 min (run troppo corte per narrativa), 2-3 ore (rischio scope), 3+ ore (impossibile testare).

### D032 — Musica orchestrale epico-solenne

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: direzione musicale orchestrale (cori, archi, ottoni), epica e solenne. Riferimenti Hades, Pyre, Conan il Barbaro.
- **Motivazione**: coerente col tono mythico-epico (D015).
- **Implicazioni**: difficile trovare CC0 di qualità orchestrale. Probabilmente useremo Pixabay Music o ccMixter selettivamente, o licenze a basso costo. 3-4 brani totali nell'MVP.
- **Alternative considerate**: ambient minimalista (più facile da reperire ma meno epico), tribale percussivo (giusto per Era 1, manca per Era 2), misto (compromesso).

### D033 — Multipla civiltà rivali, niente IA autonoma

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: 2-3 civiltà rivali per era. Comportamento interamente guidato da script narrativo, niente IA reattiva.
- **Motivazione**: dà varietà narrativa senza richiedere AI di gioco (che sarebbe impossibile nei tempi).
- **Implicazioni**: ogni civiltà rivale ha un "arco scriptato" predefinito. Le interazioni del giocatore modificano stat/eventi, ma le civiltà non "pensano" autonomamente.
- **Alternative considerate**: IA autonoma (impossibile), una sola civiltà rivale (troppo poco), pure stat senza personalità (anonimo).

---

## Decisioni future (template vuoto)

Aggiungere qui sotto man mano. ID prossimo libero: **D034**.

```
### D034 — ...

- **Data**:
- **Status**: attiva
- **Decisione**:
- **Motivazione**:
- **Implicazioni**:
- **Alternative considerate**:
```

---

*Versione 0.2 — 2026-06-01. File vivo: aggiornare a ogni decisione di rilievo.*

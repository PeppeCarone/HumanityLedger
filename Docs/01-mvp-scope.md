# 01 — MVP Scope

> Cosa entra e cosa **non** entra nella consegna universitaria.
> Documento più importante per non sforare i tempi.
> Versione 0.2 — riscritta dopo intervista del 2026-06-01.

---

## Premessa: lo scope è ancora tirato

Dopo l'intervista narrativa il team ha scelto consapevolmente di tenere alto il livello di ambizione (2 ere, ledger meta-progressivo, mystery parallel storyline, multiple rivali, 8 stat, 6 finali). Questo è **oltre il limite realistico** per 2 persone in 1-3 mesi.

La strategia è: **proviamo a costruire il tutto**, ma con una **gerarchia di tagli pronta** da applicare al primo segnale di ritardo. Vedi sezione "Gerarchia tagli" in fondo.

## IN scope per MVP

### Gameplay

- **2 ere** giocabili in sequenza con transizione:
  - Era 1 — Paleolitico (caverna interior + 8 consiglieri attorno al fuoco)
  - Era 2 — Regno Mitico (città fortificata vista dall'alto + consiglieri come pannelli laterali)
- **16 consiglieri** unici (8 per era), ciascuno con ritratto, nome, archetipo e voce
- **8 stat** globali (allineate ai consiglieri): Militare, Tesoro, Diplomazia, Scienza, Legge, Spionaggio, Popolo, Costruzione. Range 0-100.
- **1 risorsa secondaria**: Popolazione (intero ≥ 0).
- **Sistema decisioni**: ~20-25 decisioni per era (~40-50 totali per run completa), eseguibili via drag-and-drop con interazioni miste (l'oggetto trascinato e il target variano per tipo di decisione).
- **8 strategie politiche** disponibili: Azione Militare, Piano Diplomatico, Piano Economico, Piano Costruzione, Decreto Reale, Progetto Scientifico, Missione Spionaggio, Azione Rivoluzionaria.
- **Prerequisiti dinamici**: alcune strategie richiedono stat minime o consiglieri attivi.
- **8 tipi di catastrofe** come eventi-decisione speciali: Carestia, Peste, Ribellione, Tentato Assassinio, Vertice Diplomatico, Breakthrough Scientifico, Conflitto Religioso, Crisi Economica.
- **2-3 civiltà rivali per era**, presentate come ambasciatori narrativi (con ritratto + dialogo) + mini-mappa diplomatica accessibile dall'HUD.
- **1 trama mystery parallela** con quest dedicate, sbloccabile solo dopo scelte specifiche.
- **Transizione tra ere**: soglia stat (somma o specifica) **+** completamento quest narrativa chiave dell'era.
- **6 finali** differenziati: Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura. Determinati da stat dominanti + alcune decisioni chiave specifiche.
- **Nessun game over**: ogni run arriva sempre a un finale.
- **Durata run completa**: 1-1.5 ore target.

### Ledger meta-progressivo

- **Schermata Ledger** accessibile dal menu principale
- **Frammenti di lore** sbloccati durante le run (5-10 frammenti)
- **3 artefatti** disponibili da inizio gioco; il giocatore ne sceglie uno a inizio run; ciascuno ha un effetto meccanico distinto
- **Eventi/quest sbloccabili** solo dopo aver fatto certe scoperte in run precedenti (3-5 eventi nascosti)
- **Persistenza separata** dal save di run (file separato)

### UI / UX

- **Menu principale**: Nuova partita / Continua / Ledger / Esci
- **Scena di gioco Era 1**: caverna interior con fuoco centrale e 8 consiglieri in cerchio
- **Scena di gioco Era 2**: vista dall'alto della città fortificata + 8 pannelli laterali per consiglieri
- **HUD permanente**: 8 stat + popolazione + accesso a mini-mappa diplomatica + accesso a quest log
- **Quest log**: pannello con obiettivi attivi e progresso visibili
- **Schermata transizione era**: cinematica testuale-illustrata
- **Schermata epilogo**: una delle 6 illustrazioni + testo finale (max 400 parole)
- **Schermata Ledger**: tre tab (Lore / Artefatti / Eventi sbloccabili)
- Tutorial **diegetico** integrato nelle prime 2-3 decisioni della caverna

### Tech

- Build PC Windows 64-bit funzionante esportata da Godot 4.6
- **Save di run**: singolo, autosalva dopo ogni decisione (`user://save.json`)
- **Ledger save**: persistente cross-run (`user://ledger.json`)
- Audio: musica orchestrale epico-solenne (3-4 tracce) + 10-15 SFX per gesti, eventi, transizioni

## OUT of scope per MVP

Rinviato a versione post-deadline (o tagliato del tutto):

- Ere oltre la seconda (le altre 5 ere della visione)
- Boss fight giocabili come sotto-gioco
- IA autonoma delle civiltà rivali (sono guidate da script narrativo)
- Mappa esplorabile in tempo reale tipo RTS / city builder
- Albero tecnologico esplicito con sblocco di gesti
- Editor di scenari
- Localizzazione multilingua
- Sistemi economici sofisticati (mercato, tasse, valute dinamiche)
- Personalizzazione del leader / nome del popolo
- Reputazione individuale per ogni NPC
- Telemetria, achievement, leaderboard
- Build per mobile, web, console
- Save manuali multipli (solo autosave singolo)
- Voice acting / TTS
- Più di 3 artefatti
- Combinazioni artefatto / build profonde
- Eventi procedurali oltre lo scripted

## Definition of Done (MVP)

L'MVP è "finito" quando:

1. Un giocatore apre l'eseguibile Windows, sceglie un artefatto, e arriva a uno dei 6 finali in 60-90 minuti
2. Ogni decisione drag-and-drop produce cambio stat visibile + testo narrativo entro 2 secondi
3. La transizione Era 1 → Era 2 funziona: stat trasferite, quest chiave completata, cambio scenografia
4. Almeno 4 dei 6 finali sono raggiungibili (gli altri 2 possono essere "deboli" ma presenti)
5. La trama mystery viene innescata in almeno il 30% delle run; risolverla porta a un finale alternativo distinto
6. Il Ledger registra scoperte tra run; sbloccando un evento nascosto si vede un cambiamento alla run successiva
7. Sono presenti: 3-4 brani musicali, SFX completi, schermate menu/gioco/transizione/epilogo/ledger
8. 5 run consecutive di test completate senza crash bloccanti

## Rischi e mitigazioni

| Rischio | Probabilità | Impatto | Mitigazione |
|---|---|---|---|
| Drag-and-drop misto più costoso del previsto | Alta | Alto | Prototipare W2; standardizzare a 2-3 pattern di drag riusati |
| 16 ritratti consiglieri ruba troppo tempo | Alta | Alto | AI generation con post-processing manuale; standardizzare composizione |
| 8 stat × prerequisiti = balance complesso | Alta | Medio | Spreadsheet di bilancio fin da W3; revisione settimanale |
| Trama mystery rimane "appiccicata" | Media | Medio | Scriverla all'inizio (W6), testarla nel flow normale |
| Ledger sembra un add-on inutile | Media | Medio | Integrarla narrativamente: gli artefatti hanno lore che si scopre giocando |
| Asset paleolitici da generare da zero | Alta | Alto | Iniziare W1 con palette + 2 archetipi; valutare se ridurre a 5-6 consiglieri Era 1 |
| Civiltà rivali sembrano vuote (no IA) | Media | Basso | Scrittura forte degli ambasciatori; far emergere personalità via dialoghi |
| Disallineamento tra le 2 persone sul tono | Media | Alto | Documento di stile narrativo + 2 esempi scritti insieme prima di W6 |

## Gerarchia tagli (applicare al primo ritardo)

Ordine dal **meno doloroso** al **più doloroso**. Tagliare in sequenza fino a tornare in carreggiata.

1. **Ridurre quest mystery** da una linea con quest a 2-3 indizi sparsi senza quest. Salva ~1 settimana.
2. **Ridurre artefatti** da 3 a 1. Salva ~0.5 settimane.
3. **Ridurre civiltà rivali** da 2-3 a 1 per era. Salva ~1 settimana.
4. **Tagliare eventi sbloccabili** dal Ledger (resta solo lore + artefatti). Salva ~0.5 settimane.
5. **Ridurre consiglieri Era 1** da 8 a 5-6 archetipi. Salva ~1 settimana di arte/scrittura.
6. **Ridurre finali differenziati** da 6 a 4 (accorpare Guerra+Era Futura, Scienza+Industria). Salva ~0.5 settimane.
7. **Tagliare il Ledger interamente**: solo run isolate, niente meta-progressione. Salva ~1.5 settimane.
8. **Tagliare l'Era 2**: rimane solo Era 1 polished. Salva ~3 settimane. **TAGLIO PIÙ DOLOROSO MA AMMESSO**.
9. **Ridurre durata run** da 1-1.5h a 30-45 min, dimezzando quest. Salva ~1 settimana.

Lavorare con questa gerarchia *in vista*. Ogni standup settimanale (vedi `06-roadmap.md`) chiedersi: serve tagliare adesso, o aspettiamo un'altra settimana?

## Cosa fare con le idee escluse

Le idee tagliate vengono parcheggiate in `02-game-design.md` (sezione "Sistemi v2") e `03-narrative.md` (sezione "Visione futura"). Servono come north star per il post-progetto e come materiale di discussione nella relazione di esame: *"ecco cosa avremmo voluto fare e perché abbiamo tagliato"*.

---

*Versione 0.2 — 2026-06-01.*

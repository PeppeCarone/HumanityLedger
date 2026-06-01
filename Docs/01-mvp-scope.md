# 01 — MVP Scope

> Cosa entra e cosa **non** entra nella consegna universitaria.
> Documento più importante per non sforare i tempi.

---

## Premessa: il taglio è necessario

Con 2 persone e 1-3 mesi in Godot, lo scope iniziale (7 ere + Spore + AoE + boss fight + alleanze + mistery) **non è realizzabile**. Un dato di riferimento: un singolo sistema politico ben fatto richiede 2-4 settimane di sviluppo *e* design *e* testing. Sette ere richiederebbero ~12 mesi a tempo pieno per 2 persone, prima ancora dell'arte.

Quindi l'MVP è **un gioco completo ma piccolo**: meglio una singola era polished che 7 ere abbozzate.

## IN scope per MVP

### Gameplay

- **1 era sola** (proposta: Età Antica / formazione di una città-stato, ~3000 a.C.). Da confermare in intervista narrativa.
- **4 stat globali**: Tecnologia, Felicità, Economia, Potenza Militare. Range 0-100. Visibili sempre in HUD.
- **1 risorsa accumulabile**: Popolazione (numero intero, cresce/decresce per eventi).
- **Sistema decisioni**: 5-10 decisioni "gesto" implementate con drag-and-drop su una scena principale. Ogni decisione modifica le stat e fa avanzare la trama.
- **Trama principale**: lineare, 1 arco narrativo (es. fondazione → crisi → risoluzione) con **2-3 biforcazioni** che cambiano il finale (3 finali totali).
- **1 evento mystery**: un'irruzione "strana" (es. una pestilenza con dettagli inspiegabili, una figura ricorrente nei sogni del consigliere) gestita come quest narrativa scritta, **non** come boss fight giocabile.
- **Durata target di una run**: 30-60 minuti. Una run sola, niente new game+.

### Civiltà rivali

- 1 civiltà rivale (es. "Tribù del Nord")
- Rappresentata solo come **stat sull'HUD** (loro Potenza Militare relativa alla nostra)
- Interazione: 2-3 momenti in cui il giocatore decide diplomazia/guerra/alleanza
- **Nessuna IA autonoma** — i loro stat cambiano via script narrativo

### UI / UX

- 1 schermata principale di gioco (vista dell'insediamento + HUD stat + pannello decisione)
- 1 schermata menu principale (nuova partita / continua / esci)
- 1 schermata finale (epilogo con ricap delle scelte)
- Animazioni di transizione tra stati, non sostituibili da semplici tagli

### Tech

- Build PC Windows funzionante esportata da Godot 4.6
- Save singolo (autosalva tra una decisione e l'altra)
- Audio: musica di sottofondo + 5-10 SFX per decisioni gesto

## OUT of scope per MVP

Tutto quanto sotto è **rinviato a versione post-deadline** (o tagliato del tutto):

- Ere multiple oltre la prima
- Boss fight giocabili
- Sistema di alleanze complesso con più civiltà
- Multiplayer di qualsiasi tipo
- Mappa esplorabile in tempo reale (RTS / city builder a là Clash of Clans / AoE)
- Albero tecnologico (le tecnologie sono solo stat numerica)
- Editor di scenari
- Localizzazione multilingua (MVP è solo italiano)
- Sistemi economici sofisticati (tasse, commercio, valute)
- Personalizzazione del leader (nome, faccia)
- Sistema di reputazione individuale per NPC
- Telemetria, achievement, leaderboard
- Build per mobile, web, console
- Pixel-perfect art con animazioni complesse: meglio stile silhouette/minimalista (vedi `05-art-audio.md`)

## Definition of Done (MVP)

L'MVP è "finito" quando:

1. Un giocatore può aprire l'eseguibile su Windows e arrivare a uno dei finali in 30-60 minuti
2. Ogni decisione drag-and-drop produce un cambiamento visibile delle stat e/o del testo narrativo entro 2 secondi
3. I 3 finali sono tutti raggiungibili e differenziano almeno nel testo dell'epilogo
4. L'evento mystery viene innescato in almeno il 50% delle run
5. Non ci sono crash bloccanti in 5 run consecutive di test
6. Sono presenti: musica di fondo, SFX per i gesti, schermate menu/gioco/fine

## Rischi e mitigazioni

| Rischio | Probabilità | Mitigazione |
|---|---|---|
| Drag-and-drop più costoso da implementare del previsto | Alta | Prototipare la prima settimana, fallback su click se serve |
| Arte ruba troppo tempo | Alta | Usare stile minimalista/silhouette + asset CC0 (vedi 05) |
| Trama troppo ambiziosa da scrivere | Media | Scriverla in massimo 3000 parole totali, riusare strutture |
| Bug di stato/save corruption | Media | Architettura semplice, autoload singolo con dati seriali |
| Disallineamento tra le 2 persone | Media | Decisions log + standup settimanale (vedi 06-roadmap) |

## Cosa fare con le idee escluse

Le idee tagliate **non vengono perse**: vengono parcheggiate in `03-narrative.md` (sezione "Visione futura") e in `02-game-design.md` (sezione "Sistemi v2"). Servono come north star per il post-progetto e come materiale di discussione nella relazione di esame ("ecco cosa avremmo voluto fare e perché abbiamo tagliato").

---

*Versione 0.1 — 2026-06-01.*

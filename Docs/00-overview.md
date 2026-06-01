# HumanityLedger — Overview

> One-pager del progetto. Documento di partenza che fissa visione, genere e scope.
> Tutti gli altri documenti (GDD, narrativa, architettura, roadmap) si riferiscono a questo.
> Versione 0.2 — riscritta dopo intervista del 2026-06-01.

---

## High concept

**HumanityLedger** è un gioco di simulazione politica mythico-narrativa in cui il giocatore impersona lo **spirito anonimo di un popolo** che attraversa le ere. Lo spirito non parla e non ha volto: si manifesta come *intenzione* nelle decisioni che modellano la civiltà. I leader umani cambiano. Lo spirito resta. Il *registro* — il *Ledger* — ricorda.

In ogni era, il popolo è rappresentato da un consiglio di **8 archetipi** che propongono strategie politiche; il mondo, in parallelo, risponde con eventi (carestie, pesti, rivelazioni, incontri diplomatici) che richiedono reazione.

Le decisioni si prendono con **interazioni gestuali**: il giocatore trascina icone-strategia su target visivi (consiglieri, edifici, confini, ambasciatori), e il mondo cambia immediatamente nello stato — stat, scenario, testo narrativo.

A intervalli irregolari la cornice mythico-storica viene rotta da una **trama parallela mystery** che alcune scelte sbloccano.

## Pilastri di design

1. **Decisione come gesto** — ogni scelta è un'azione visibile (drag-and-drop), non una voce di menu.
2. **Feedback narrativo immediato** — il mondo reagisce entro 2-3 secondi a ogni decisione, sia in numeri (stat) sia in testo.
3. **Mythico-epico, non realistico** — il tono è solenne, oracolare, archetipico. Non vogliamo cronaca storica, vogliamo mito.
4. **Lo spirito attraversa le ere, il Ledger lo testimonia** — il sistema di meta-progressione (Ledger) trattiene scoperte, artefatti ed eventi sbloccabili da una run all'altra.
5. **Nessun game over: solo finali** — non si perde mai. Si arriva sempre a uno dei 6 epiloghi, alcuni gloriosi, alcuni tragici.
6. **8 + 8 + 8 + 6** — il numero è una struttura: 8 consiglieri, 8 stat, 8 strategie, 6 percorsi finali. Tutto si chiude in un sistema coerente.

## Genere

Simulazione politica narrativa / management mitico — con elementi di visual novel e meta-progressione roguelike-light.

## Piattaforma target

- **Primaria**: PC Windows (build da Godot 4.6)
- Secondaria: macOS / Linux (gratis come export Godot, non testati)
- **Fuori scope** per MVP: mobile, console, web

## Pubblico

Giocatori di simulazioni narrative (*Reigns*, *Suzerain*), roguelike narrativi (*Hades*, *Inscryption*), e giochi storici (*Crusader Kings*, *Frostpunk*) interessati a un'esperienza più breve e archetipica che simulativa.

## Ispirazioni dichiarate

| Gioco | Cosa prendiamo |
|---|---|
| Hades | Meta-progressione narrativa via Ledger, tono mythico-epico, illustrazioni dei personaggi |
| Pyre | Tono solenne, narrativa attraverso archetipi, palette epica |
| Reigns | Decisioni binarie/multiple come perno del gameplay, accessibilità |
| Crusader Kings | Consigli, intrighi, peso delle stat, ambientazione storica |
| Papers Please | UI diegetica, conseguenze morali, peso delle scelte |
| Spore | Progressione attraverso ere |
| Expedition 33 | Atmosfera onirica, intreccio realismo/fantastico |
| Annihilation | Tono mystery dell'irruzione |

## Scope: visione completa vs. MVP

### Visione completa (north star, non deadline)

- 7 ere giocabili (Paleolitica, Antica, Medievale, Moderna, Industriale, Contemporanea, Prossima)
- Mappa diplomatica complessa con civiltà rivali autonome
- Più trame parallele mystery per era
- Sistema artefatti profondo (10+, combinazioni, build)
- Eventi procedurali oltre quelli scritti
- Localizzazione multilingua
- Easter egg, achievement, leaderboard

### MVP per la deadline universitaria (1-3 mesi, 2 persone)

- **2 ere**: Era 1 Paleolitico → Era 2 Regno Mitico
- **16 personaggi consiglieri** (8 per era), con ritratti e archetipi unici
- **8 stat globali** (Militare, Tesoro, Diplomazia, Scienza, Legge, Spionaggio, Popolo, Costruzione)
- **8 strategie** drag-and-drop con prerequisiti dinamici
- **8 tipi di catastrofe** come eventi-decisione speciali
- **2-3 civiltà rivali** per era, presentate via ambasciatori narrativi + mini-mappa
- **1 trama mystery parallela** sbloccabile, con quest dedicate
- **6 finali** differenziati (Guerra, Prosperità, Scienza, Alleanza, Industria, Era Futura)
- **Ledger persistente** con lore + 3 artefatti + eventi sbloccabili tra run
- **Tutorial diegetico** nelle prime decisioni dentro la caverna paleolitica
- **Durata run**: 1-1.5 ore
- **Lingua**: italiano

> **Tutto ciò che non è nel MVP** vive nei doc come visione futura. Vedi `01-mvp-scope.md` per la gerarchia di tagli quando inevitabilmente serviranno.

## Vincoli produttivi

- **Team**: 2 persone (Tonio = `Ventus2202`, Peppe = `PeppeCarone`)
- **Engine**: Godot 4.6
- **Tempo**: 1-3 mesi
- **Contesto**: progetto universitario / esame
- **Asset**: prototipi medievali esistenti in `Assets/` (per Era 2 mitica), Era 1 paleolitica ancora da produrre — strategia in `05-art-audio.md`

## Domande aperte da chiudere nelle prossime iterazioni

- I 16 nomi/ritratti specifici (8 + 8) — definizione caso per caso, in `03-narrative.md`
- I 3 artefatti specifici del Ledger — quali effetti meccanici precisi
- La trama mystery: cos'è esattamente l'irruzione? Quale forma narrativa?
- I 6 testi degli epiloghi — outline al W6, scrittura W9
- L'identità visiva precisa delle 2-3 civiltà rivali

---

*Versione 0.2 — 2026-06-01.*

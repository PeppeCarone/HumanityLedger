# HumanityLedger — Overview

> One-pager del progetto. Documento di partenza che fissa visione, genere e scope.
> Tutti gli altri documenti (GDD, narrativa, architettura, roadmap) si riferiscono a questo.

---

## High concept

**HumanityLedger** è un gioco di simulazione politica narrativa in cui il giocatore guida un popolo dalla preistoria tribale alle ere moderne, prendendo decisioni che modificano in tempo reale economia, tecnologia, felicità, potenza militare e la trama stessa.

Le decisioni non si prendono cliccando su una risposta a tendina: il giocatore le esegue con **interazioni gestuali** (drag-and-drop, trascinamento di simboli sulla mappa) che traducono fisicamente l'intento politico in azione visibile.

A intervalli irregolari la cornice realista viene rotta da eventi **misteriosi, horror o fantasy** (catastrofi, presenze, tesori arcani) che il popolo deve affrontare con quest dedicate.

## Pilastri di design

1. **Decisione come gesto** — ogni scelta importante è un'azione visibile, non una voce di menu. Trascinare un soldato verso un confine = dichiarare guerra. Trascinare monete su un edificio = investire.
2. **Feedback narrativo immediato** — appena la decisione viene presa, il mondo (UI, stat, ambiente) cambia visibilmente entro pochi secondi.
3. **Realismo come base, fantastico come irruzione** — il tono di default è storico-credibile. Il fantastico arriva come crepa nella realtà, non come setting.
4. **Scelte irreversibili** — niente save scumming sistemico. Le conseguenze restano.

## Genere

Simulazione politica / strategia narrativa / management — con elementi di visual novel a innesti.

## Piattaforma target

- **Primaria**: PC (Windows, build da Godot 4.6)
- Secondaria: macOS / Linux (gratis come export Godot)
- **Fuori scope** per MVP: mobile, console, web

## Pubblico

Giocatori di simulazioni narrative tipo *Reigns*, *Suzerain*, *Frostpunk*, *Crusader Kings*, ma anche fan di *Papers Please* e *Spore* per la parte di crescita di una civiltà.

## Ispirazioni dichiarate

| Gioco | Cosa prendiamo |
|---|---|
| Papers Please | UI diegetica, tono morale, conseguenze pesanti |
| Expedition 33 | Atmosfera, stile narrativo, intreccio realismo/onirico |
| Lapse: A Forgotten Future | Decisioni come scelte gravi su una popolazione |
| Spore | Progressione attraverso ere, evoluzione del gruppo |
| Clash of Clans | Gestione visiva di un insediamento |
| Age of Empires | Sensazione di guidare una civiltà nel tempo |
| Pokémon Nero/Bianco | Atmosfera narrativa, scelte morali ambigue, mood |

## Scope: visione completa vs. MVP

### Visione completa (north star, non deadline)

- 7 ere storiche giocabili
- Sistema di alleanze e guerre con civiltà rivali
- Trame principali multiple con rami nascosti
- Boss fight per catastrofi soprannaturali
- Easter egg e segreti
- Più stat oltre alle 4 base

### MVP per la deadline universitaria (1-3 mesi)

- **1 era sola** (proposta: tribale / antica)
- **4 stat base**: Tecnologia, Felicità, Economia, Potenza Militare
- **1 trama principale lineare** con 2-3 biforcazioni
- **1 evento "irruzione" misterioso** (no boss fight giocabile, gestito narrativamente)
- **5-10 decisioni gesto** con interazione drag-and-drop
- **Civiltà rivali**: 1-2, gestite solo come stat, senza simulazione autonoma
- Niente multiplayer, niente save slot multipli

> **Tutto ciò che non è nel MVP va nei documenti di visione futura, non implementato in questa finestra.**

## Vincoli produttivi

- **Team**: 2 persone (Tonio = `Ventus2202`, Peppe = `PeppeCarone`)
- **Engine**: Godot 4.6
- **Tempo**: 1-3 mesi
- **Contesto**: progetto universitario / esame
- **Asset**: nessuno al momento — strategia in `05-art-audio.md`

## Domande aperte (da chiudere via interviste successive)

- Quale era specifica usiamo per l'MVP? (Tribale paleolitica? Bronzo? Antichità classica?)
- Il giocatore controlla un *leader-personaggio* (con nome, faccia, mortale) o un'entità astratta (lo "spirito del popolo")?
- Durata di una run completa MVP: 30 min? 1 ora? 3 ore?
- Lo stile artistico: pixel art, low-poly, illustrato 2D, silhouette/minimalista?
- Il gioco è completamente offline o vogliamo telemetria base?

---

*Versione 0.1 — 2026-06-01. Da rivedere a fine intervista di scoping.*

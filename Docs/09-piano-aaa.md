# 09 — Piano "verso AAA": audit visivo, juice e lezioni da Lapse

> Sintesi del 2026-06-12: audit ui-designer sugli screenshot reali + audit
> game-developer sul codice + ricerca su Lapse: A Forgotten Future.
> Obiettivo: eliminare progressivamente ogni "effetto prototipo" e dare a
> OGNI decisione un feedback visivo che si ripercuote nel gioco.

---

## 1. Lezioni da Lapse: A Forgotten Future (10M+ download)

Gioco di Cornago Stefano, stesso genere nostro (decisioni che muovono stat).
Cosa lo ha reso popolare e cosa ne prendiamo:

| Lapse | Cosa ne prendiamo per HumanityLedger |
|---|---|
| 4 stat con icone chiare; sotto i medaglioni, indicatori di "effetti duraturi" attivi | **Indicatori di effetto-duraturo sotto l'HUD stat** (es. artefatto equipaggiato, alleanza attiva, mystery): piccole icone persistenti che dicono "questo ti sta proteggendo/minacciando" |
| Oracolo (oggetto che rivela l'impatto delle scelte prima di sceglierle) | GIÀ FATTO: il nostro Occhio dello Spirito è esattamente questo. Conferma la direzione del ciclo artefatti |
| Personaggi ricorrenti che RICORDANO le scelte fatte (anche tra run) e ti puniscono/premiano per la coerenza | **Richiami narrativi**: decisioni successive che citano una scelta precedente del giocatore (es. il ferito del Bisonte curato ricompare in Era 2). Economico: solo testo |
| Il contatore degli anni avanza anche dopo la sconfitta: ogni run fa progredire la linea temporale | Il nostro Ledger fa già da memoria; rendere VISIBILE il numero di run/ere attraversate nel menu e nel Ledger ("Terza vita dello spirito") |
| 24 personaggi scoperti giocando, segreti e finali nascosti come motore del retry | Le card "???" del Ledger sono giuste; estendere il pattern: contatore "X/6 epiloghi visti" nel Ledger |
| Stat troppo ALTA = morte quanto stat a zero (tensione bilaterale) | Noi siamo "no game over" (D024): non lo adottiamo, ma la tensione si può evocare con avvisi dei consiglieri quando una stat domina troppo |
| Arte minimalista ma COERENTE + monetizzazione onesta | La coerenza di palette (bronzo/oro/seppia) vale più del dettaglio: vedi audit §2 |

Fonti: [Lapse Wiki](https://lapse.fandom.com/wiki/Lapse_(Game)), [Touch Tap Play — guida](https://www.touchtapplay.com/lapse-a-forgotten-future-tips-cheats-guide-to-rule-for-years/), [minireview](https://minireview.io/strategy/lapse-a-forgotten-future), [AppGrooves](https://appgrooves.com/android/com.cornago.stefano.lapse/lapse-a-forgotten-future/cornago-stefano/), [GameAnalytics — game juice](https://www.gameanalytics.com/blog/squeezing-more-juice-out-of-your-game-design), [itch.io — juicy effects](https://itch.io/blog/1059831/making-a-game-feel-juicy-with-simple-effects).

---

## 2. Audit visivo (ui-designer, su screenshot reali) — TOP 10

Ordinata per rapporto impatto/sforzo. [CODICE] = solo engine, [ASSET] = serve Lovable.

1. **[CODICE] Gerarchia tipografica nel pannello decisione** — nome consigliere Cinzel bold 18px oro `#E8C87A`, testo Alegreya 15px panna `#D4C4A0`, line spacing +4, separatore sottile tra nome e testo. È la schermata più vista del gioco. (~1h)
2. **[CODICE] HUD stat da "lista debug" a pannello comando** — larghezza ≥200px, font 14px, valore bold a destra, separatori bronzo alpha 0.3, sezione separata per Popolazione/Quest. (~2h)
3. **[CODICE] Vignette radiale riusabile** (shader canvas_item) su menu, villaggio e mappa — isola il soggetto, nasconde i bordi. Lo stesso shader serve 3 schermate. (~30m)
4. **[CODICE] Audit colori fuori palette** — glow verdi/acidi (fuoco, badge EQUIPAGGIATO del Ledger, zone influenza mappa troppo sature): tutto va riportato a bronzo/oro/ambra o desaturato 40-50%. (~30m, da verificare a schermo)
5. **[CODICE] Epilogo: scrim scuro sotto il testo + 3 livelli cromatici** (titolo oro `#E8C87A`, corpo panna `#F0E8D0`, istruzioni bronzo opaco `#8B7355`); il "Premi R/L" in un piccolo box bordato, non testo nudo. (~1h)
6. **[ASSET] Sfondo caverna più ricco per la vista decisione Era 1** — massimo ROI: appare a ogni decisione. Prompt: `ancient cave interior background, paleolithic era, warm firelight from below, cave paintings on walls, stalactites, atmospheric dark fantasy, wide horizontal composition, deep shadows, painterly style, game background art`
7. **[CODICE] Title card transizione: nero puro → quasi-nero `#070503`** + gradient radiale caldo al centro + film grain 3-5% + line spacing maggiore tra le 3 frasi. (~30m)
8. **[ASSET] Sfondo Ledger (oggi grigio piatto)** — Prompt: `ancient library background, dark fantasy, old stone walls with torch sconces, bookshelves with ancient tomes, warm amber light, painterly style, game background, moody atmosphere, horizontal wide format`
9. **[CODICE] Mappa mondo: vignette che sfuma i bordi nel buio** (via stesso shader del punto 3) + desaturare le zone di influenza (rosso mattone / verde oliva / indaco). (~45m)
10. **[CODICE] Ledger: vuoto trattato come mistero, non come bug** — "Nessuna lore" in corsivo bronzo, card eventi "???" con bordo tratteggiato; badge EQUIPAGGIATO in oro. (~30m)

Nota trasversale dell'audit: pulsanti menu troppo "widget di sistema" (gradient
verticale caldo + padding generoso), ritratti/edifici senza ombra di contatto
dove manca (menu OK, decisione da verificare), e una passata anti-debug
(label grezze, artefatti negli angoli degli sfondi).

---

## 3. Piano juice (game-developer, sul codice) — feedback per OGNI decisione

Requisito: ogni drop deve produrre una catena visibile: **flash/shake → conseguenza sul villaggio → pulse della stat nell'HUD → riga narrativa che si scrive**. Tier 1 = fare subito.

### Tier 1 (S, alto impatto)
- **J1 HUD pulse + freccia delta**: al cambio stat, il medaglione scala 1.12 con bounce e un label `+N`/`-N` colorato fa float-up e dissolve. (`main.gd`)
- **J4 Typewriter sul NarrativeLabel**: `RichTextLabel.visible_characters` animato ~45 char/s. Ogni feedback decisione "si scrive". (`main.gd` + nodo in `main.tscn`)
- **J5 Screen shake calibrato per tipo**: guerra/catastrofe 8-10px, costruzione 3px, neutro 0 — su `$UI.offset`. (`main.gd _on_item_dropped`)
- **J2 Preview drag inclinata** (-6°, scala 1.08) + ghosting della card sorgente. (`draggable_item.gd`)
- **J3 Drop zone che "respira"** quando la card compatibile è in aria (pulse del bordo accent). (`drop_zone.gd`)

### Tier 2 (M)
- **J6 Transizione decisione↔villaggio cinematica**: slide-in del fondale decisione, fade-out al ritorno (oggi il ritorno è un taglio netto).
- **J14 Ritratto consigliere reagisce all'hover del drop** (scala 1.08 + tinta calda = "il consigliere approva").
- **J10 Fumo ambient dal focolare** (CPUParticles2D via codice, ~8 particelle, zero asset).
- **J7 Conseguenze con intensità**: il delta maggiore dell'effetto scala dimensione/durata dell'FX; guerra colpisce un edificio, alleanza si diffonde su due slot.
- **J8 Rapporti civiltà animati nell'HUD** (righe persistenti + flash sul cambio, ingresso slide).

### Tier 3-4 (M/L, sistemici)
- **J11 Villaggio che riflette la prosperità** (popolo+tesoro → edifici desaturati in crisi / dorati nel benessere, fuoco più o meno vivo). Il singolo gap più grande verso il "mondo che reagisce".
- **J17 Particelle per era**: neve/cenere in Era 1, braci ascendenti in Era 2.
- **J12 Vignette animata della vista decisione** (shader, tinta viola se mystery).
- **J16 Ciclo giorno/notte legato allo step della quest** (overlay colore interpolato).
- **J15 Segni delle alleanze sul villaggio** (bandierine dagli asset ambasciatori esistenti).
- **J13 Slow-mo al drop**: rischioso (`Engine.time_scale`); fallback consigliato = solo flash bianco + micro-delay.

Avvertenza architetturale: ogni tween nuovo va killato al reset run (estendere il pattern `stat_tweens`).

---

## 4. Roadmap proposta (ondate)

1. **Ondata 1 — quick win [CODICE]** (1-2 sessioni): TOP audit #1-#5, #7, #10 + juice J1, J4, J5, J2, J3. Dopo questa ondata ogni decisione ha già la catena completa di feedback.
2. **Ondata 2 — [ASSET] Lovable**: sfondo caverna decisione (#6), sfondo Ledger (#8), icona Occhio (P6 già in 08-asset-prompts). Integrazione col solito flusso slice→smista→load().
3. **Ondata 3 — sistemici**: J11 (villaggio che riflette lo stato), J6+J14, vignette/grain ovunque (#3, #9), poi Tier 3-4 a scendere.
4. **Ondata 4 — da Lapse**: indicatori effetti-duraturi sotto l'HUD, contatore run/epiloghi nel Ledger, 2-3 richiami narrativi cross-decisione.

---

## Stato avanzamento

- **2026-06-12 (commit ecbf00f)** — Ondata 1 Tier 1 completa: J1, J2, J3, J4, J5, J6-light, J14 + audit #1 (tipografia decisione), #7 (title card alone caldo), rimossa VersionLabel debug.
- **2026-06-12 (secondo giro)** — audit #2 (HUD redesign: nome tenue a sinistra, valore bold a destra, separatore bronzo), #9 (zone mappa desaturate seppia, alpha 0.3→0.22), #10 (Ledger: vuoti in bronzo-mistero) + J10 (fumo CPUParticles2D dal focolare), J11 (prosperità: popolo+tesoro tingono gli edifici — crisi spenta / benessere dorato) + contatore meta "Epiloghi X/6 · Artefatti X/N" nel Ledger (lezione Lapse).
- **2026-06-15** — Ondata 4: **indicatori effetti-duraturi** sotto le stat dell'HUD (lezione Lapse). Striscia "Effetti duraturi" con badge persistenti e tooltip: artefatto equipaggiato (oro, con icona), Mistero desto (viola), Alleati ×N (verde), Ostili ×N (rosso, soglia rapporto ±2). Refresh agganciato a mystery/rapporti/reset. `main.gd` (`_refresh_effetti_duraturi`, `_crea_badge`). Verificato a schermo via `shot_era2`.
- **2026-06-15** — Ondata 4: **richiami narrativi cross-era** (3, lezione Lapse). Le scelte vengono registrate (`GameState.scelte`, persistite in save) e una decisione Era 2 cita la scelta presa nella decisione Era 1 corrispondente, come "memoria dello spirito" in label tenue sopra il consigliere (non nel pannello, per non invadere le scelte). Coppie: `d_con_01_bisonte`→`d_corte_04_impero`, `d_con_03_spie`→`d_corte_05_lega`, `d_con_06_ferito`→`d_corte_18_ribellione` (3 varianti ciascuna). `main.gd` (`RICHIAMI`, `_richiamo_per`, `_crea_richiamo_label`), `game_state.gd` (`registra_scelta`/`scelta_di`). Verificato via `shot_richiamo`.
- **Restano**: #3 vignette shader menu/mappa, #5 epilogo box istruzioni, #6 sfondo caverna [ASSET], #8 sfondo Ledger [ASSET], J7, J8, J12, J13, J15, J16, J17.

*File vivo: spuntare gli interventi man mano che vengono fatti.*

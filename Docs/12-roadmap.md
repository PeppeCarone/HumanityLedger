# 12 — Master roadmap: finire · implementare · aggiungere

> Sessione 2026-06-17. Piano unico e ordinato di tutto ciò che resta, dopo la
> rilettura completa del codice. Tre tronconi: **FINIRE** (chiudere il lavoro
> avviato), **AGGIUNGERE** (la feature-climax: L'Assedio, vedi `Docs/11-boss-fight.md`),
> **ESAME** (i deliverable del corso). Legenda: `[x]` fatto · `[~]` parziale · `[ ]` da
> fare · **[C]** solo codice · **[A]** serve arte (prompt in `Docs/08-asset-prompts.md`).
>
> Sequenza consigliata: **Sprint 1** chiude il polish (vittoria rapida, gioco "finito"
> a vista); **Sprint 2–4** costruiscono L'Assedio (il pezzo forte, anche per la
> relazione/video d'esame); **Sprint 5** confeziona la consegna.

---

## A. FINIRE — polish e juice rimasti (eredità audit `09`/`10`)

> **Redesign estetico (richiesta 2026-06-17):** sostituire l'"arte-codice" (cornici
> `StyleBoxFlat`, medaglioni/icone/`+`/stelle/barre disegnati) con un **UI kit + set
> icone** veri. Manifesto prompt completo in `Docs/08-asset-prompts.md` §P8–P9; mappa
> "codice→asset" e cablaggio in **`Docs/13-redesign-estetico.md`**. È il salto più
> grande verso "bel gioco". (Genera asset prioritari → helper `UiStyle` con fallback.)

Tutto **codice puro**, nessun blocco da arte. Rapporto impatto/sforzo alto: chiude
l'impressione "prototipo" sui pochi punti ancora deboli.

- [ ] **[C] Vignette shader riusabile** (`09` #3): unico shader `canvas_item` su
  menu, villaggio e mappa (oggi la vignette è una `TextureRect` a gradiente solo in
  `main`). Isola il soggetto, nasconde i bordi.
- [ ] **[C] Epilogo: box istruzioni** (`09` #5 / `10` #11): "Premi R/L" in un piccolo
  riquadro bordato bronzo, non testo nudo. (Lo scrim a 3 stop è già fatto.)
- [ ] **[C] Cornice pannello stat sinistro** (`10` #6): rifinire allineamento
  numeri/margini dell'HUDPanel.
- [ ] **[C] Cornici/ornamenti d'angolo** (`10` #12): su Ledger/Menu/Mappa → resa "tomo"
  via `StyleBox`/9-patch procedurale.
- [ ] **[C] Tabella costi nel modale build/upgrade** (`10` #1): righe costo allineate
  con icona risorsa + thumbnail edificio. (Scrim e tema bronzo già fatti.)
- [ ] **[C] J7 — Conseguenze con intensità**: il delta maggiore scala dimensione/durata
  dell'FX; la guerra colpisce un edificio, l'alleanza si diffonde su due slot.
- [ ] **[C] J8 — Rapporti civiltà animati**: flash sul cambio + slide d'ingresso delle
  righe (oggi statiche).
- [ ] **[C] J12 — Vignette animata vista decisione** (tinta viola se mystery) — dipende
  dallo shader del primo punto.
- [ ] **[C] J15 — Bandierine alleanza sul villaggio** (riusa gli sprite ambasciatori).
- [ ] **[C] J16 — Ciclo giorno/notte** legato allo step della quest (overlay colore).
- [ ] **[C] J13 — Micro slow-mo/flash al drop** (fallback sicuro: flash bianco +
  micro-delay, niente `Engine.time_scale`).
- [x] J17 particelle per era · J10 fumo · J11 prosperità · J1–J6/J14 · audit `10` #2/#3/#4/#5/#7/#8/#10 (vedi log `09`/`10`).

> Avvertenza ricorrente: ogni nuovo `Tween` va killato al reset run (pattern `stat_tweens`).

## B. AGGIUNGERE — L'Assedio (boss fight TD) · design in `Docs/11-boss-fight.md`

Feature-climax: fine era → difendi il villaggio da ondate + boss. **Le stat diventano
l'esercito.** No game over. Fasi (dettaglio e architettura nel doc 11):

- [x] **[C] Fase A — Scheletro giocabile**: `scripts/siege/` (siege/enemy/defender/
  projectile, istanziati via script — niente .tscn da editor), 1 corsia, nemici che
  marciano, villaggio con HP, difensore piazzabile che spara, win/lose, HUD bronzo.
  HP villaggio/budget/danno già derivati dalle stat (seme Fase B). Tasto debug **B**
  per provarlo. Verificato a schermo (`shot_assedio`). *Milestone "si vede funzionare" ✓*
- [x] **[C] Fase B — Stat → esercito**: `configura()` deriva HP villaggio (Costruzione+
  popolazione), budget Risorse (Tesoro/Risorse/Popolo) e i danni unità dalle stat; 3 corsie,
  9 piazzole, **4 unità** con skin per era (Cacciatore/Guerriero/Sciamana/Totem) scalate
  ognuna da una stat diversa (Militare/Costruzione/Scienza/Spionaggio); barra di selezione
  unità; **alleati** dai rapporti ≥soglia (truppa gratis) e **ostili** ≤−soglia (rinforzano i
  nemici). Verificato a schermo (`shot_assedio`). *Milestone "le stat sono l'esercito" ✓*
- [ ] **[C] Fase C — Boss + abilità**: barra HP, 2–3 abilità telegrafate, fasi, entrata
  cinematica.
- [ ] **[C] Fase D — Ondate complete**: `WaveData` per era, banner, pause, scaling,
  nemici per era.
- [ ] **[C] Fase E — Juice + UI bronzo**: shake, hit-flash, particelle, SFX, barre, esiti
  cinematici.
- [ ] **[C] Fase F — Integrazione + esiti**: hook in `main.gd` (gate transizione),
  ricompense, trofeo Ledger, conseguenze, save (`eraN_assedio_*`).
- [~] **[A] Fase G — Art**: **hook di caricamento sprite già cablati con fallback** per il
  sottoinsieme Fase B (campo, roccaforte, 4 `unit_*`, `enemy`, proiettili, icone barra — vedi
  §P7 righe ✓): basta droppare i PNG in `Assets/art/siege/` e l'Assedio li usa da solo
  (verificato end-to-end con segnaposto). Restano da generare gli asset veri + cablare
  boss/nemici-per-tipo/UI boss.
- [ ] **[C] Fase H — Balance + verifica**: tuning + check in `balance_sim.py` + shoot
  harness per ogni schermata d'assedio.

## C. OPZIONALE — Era 3 "Futuro" (asset già presenti)

Esistono già in `Assets/`: 4 consiglieri era3, sfondi era3 (insediamento/crescita/
metropoli), 6 icone decisioni era3. La struttura è data-driven: aggiungere Era 3
significa una terza voce in `QUEST_SEQUENZE`, decisioni/quest `.tres`, edifici era3, e
un terzo set Assedio (boss "Titano d'Acciaio"). **Grosso scope**: valutare solo dopo che
l'Assedio è solido su 2 ere. Non necessario per l'MVP/esame.

- [ ] **[C/A] Era 3 completa** (decisioni, quest, edifici, finali estesi, boss era3).

## D. ESAME — deliverable del corso (Sviluppo Videogiochi)

- [ ] **[C] Menu Opzioni**: volume musica/sfx (gli slider mancano), risoluzione/fullscreen,
  rigioca tutorial. (`AudioManager` esiste già; serve la UI.)
- [ ] **[C] Build Windows**: export preset `.exe` + zip; verifica che parta su macchina
  pulita (asset impacchettati).
- [ ] **Video di presentazione**: cattura le schermate forti (menu, decisione, villaggio,
  **Assedio**, epilogo, mappa). L'Assedio è il momento "wow" per il video.
- [ ] **Relazione**: architettura data-driven, scelte di design (no game over, stat→esercito),
  pipeline asset, riferimenti (Lapse, TD design). I doc `00`–`12` sono già la base.
- [ ] **[C] Pass anti-debug pre-consegna**: niente `_debug_input` attivo in release, niente
  label grezze, `OS.is_debug_build()` rispettato.

---

## Stato

- **2026-06-17** — Pushato tutto su `origin/main` (account PeppeCarone). Riletto l'intero
  codice; scritto il design dell'Assedio (`Docs/11-boss-fight.md`) e i prompt asset §P7
  (`Docs/08-asset-prompts.md`). Questo master plan creato.
- **2026-06-17 (2)** — **Fase A dell'Assedio implementata e verificata a schermo**:
  `scripts/siege/` (siege/enemy/defender/projectile), gate in `main.gd._avvia_prossima_quest`
  + `_avvia_assedio`/`_on_assedio_concluso`, tasto debug B, scatto `shot_assedio` in
  `tools/shoot.gd`. Boss Era 1 scelto: **dinosauro** (Fase C). Compila pulito (Godot 4.6.1),
  harness OK. **Non ancora committato/pushato.**
- **2026-06-17 (3)** — **Fase B dell'Assedio implementata e verificata a schermo** ("le stat
  diventano l'esercito"): `siege.gd` riscritto (3 corsie, 9 piazzole, roster 4 unità con skin
  per era + scaling per stat, barra di selezione, API pubbliche bersaglio/blocco/AoE/slow,
  alleati/ostili dai rapporti, HUD diplomazia); `enemy.gd` (corsia + ingaggio bloccatore +
  slow), `defender.gd` (4 ruoli + HP/segnale distrutto), `projectile.gd` (AoE). Import+validate
  puliti, `shot_assedio` aggiornato. **+ pass di rifinitura visiva** (villaggio fortificato con
  merli e porte allineate alle corsie, chevron direzionali, marcatore lato spawn, stendardo
  alleato radicato). **Restano fasi C–H. Non ancora committato/pushato.**
- **2026-06-17 (4)** — **Hook asset Assedio cablati (anticipo Fase G)**: `siege.gd`/`enemy.gd`/
  `defender.gd`/`projectile.gd` caricano sprite da `Assets/art/siege/era<N>/` (campo, roccaforte,
  `unit_<archetipo>`, `enemy`) e `fx/` (proiettili), + icone barra da `icons/siege/` via
  `UiStyle.icona`, tutto **fallback-safe**. Prompt §P7/§P9g in `Docs/08` riallineati alla Fase B
  (nomi-file esatti, righe "Fase B ✓"). Swap verificato a schermo con PNG segnaposto (poi rimossi).

*File vivo: spuntare man mano. Doc di dettaglio: `09` (juice/audit AAA), `10` (UI/villaggio),
`11` (Assedio).*

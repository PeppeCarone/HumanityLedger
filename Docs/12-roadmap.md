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
- [x] **[C] Tabella costi nel modale build/upgrade** (`10` #1): righe costo allineate
  con icona risorsa + thumbnail edificio (`main._riga_costo`/`_thumb_edificio`/`_tex_edificio`).
  Icona-edificio anche sui pulsanti del modale build. Verificato (`shot_upgrade_panel`/`shot_build_panel`).
- [x] **[C] J7 — Conseguenze con intensità**: il delta maggiore scala dimensione/durata
  dell'FX (`village_view.applica_conseguenza(tipo, intensita)` + `main._intensita_conseguenza`).
  *Resta opzionale: guerra che colpisce un edificio, alleanza su due slot.*
- [x] **[C] J8 — Rapporti civiltà animati**: flash colorato sul cambio + ingresso a cascata
  delle righe (`main._refresh_rapporti`, stato `_rapporti_prec`).
- [ ] **[C] J12 — Vignette animata vista decisione** (tinta viola se mystery) — dipende
  dallo shader del primo punto.
- [x] **[C] J15 — Bandierine alleanza sul villaggio**: uno stendardo radicato per civilta'
  alleata (rapporto >= soglia), col volto dell'ambasciatore nel medaglione. `village_view.mostra_bandiere_alleati`
  + `main._refresh_bandiere_alleati` (da `_refresh_rapporti`/`_aggiorna_sfondo_era`). Verificato (`shot_villaggio_alleati`).
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
- [x] **[C] Fase C — Boss + abilità**: `scripts/siege/boss.gd` (`SiegeBoss` estende `SiegeEnemy`),
  barra HP dedicata in alto, entrata cinematica (shake+banner), 3 abilità telegrafate — Pestone
  (AoE sui difensori), Ruggito (stun mitigato da Legge), Carica (dash che ignora i bloccatori) —
  e FURIA a metà HP. Hook arena: `difensori_in_area`/`danno_area_difensori`/`stordisci_difensori`/
  `scuoti_forte`. Verificato a schermo (`shot_assedio_boss`). Sprite opzionale `siege/era<N>/boss.png` (fallback a codice).
- [x] **[C] Fase D — Ondate complete**: 4 ondate per era (3 crescenti + boss) da tabella
  `NOMI_ONDATA`/`_prepara_ondate` (scaling era + civiltà ostili), **banner d'ondata** su cartiglio
  (§8i) con anteprima da Spionaggio, pause di rischieramento, contatore "Ondata N/M". Verificato
  (`shot_assedio`). *Nota: dati in tabella-codice; esternalizzazione in `WaveData.tres` resta opzionale.*
- [x] **[C] Fase E — Juice + UI bronzo**: barre HP (villaggio+boss) incorniciate col UI kit
  bronzo (`bar_frame` §8h via `_decora_barra`, fallback-safe), **poof di morte** dei nemici
  (`_morte_poof`), **flash rosso di danno** quando il villaggio incassa (`_flash_danno`), oltre a
  shake (`_scuoti`/`scuoti_forte`), hit-flash e SFX già presenti. Schermate esito stilizzate (Fase F).
  Verificato a schermo (`shot_assedio`/`shot_assedio_boss`).
- [x] **[C] Fase F — Integrazione + esiti**: gate già in `_avvia_prossima_quest`/`_avvia_assedio`/
  `_on_assedio_concluso`. Esiti graduati dall'HP villaggio (immacolata/trionfo/fatica/sopraffatto,
  `siege._esito_vittoria` + `ESITO_INFO`), ricompense+conseguenze no-game-over (`main._applica_esito_assedio`,
  `_danneggia_edificio_assedio`), **trofeo Ledger** (`lore_trofeo_assedio` + lore immacolata/sopraffatto),
  save `eraN_assedio_fatto/_esito`. Verificato a schermo (`shot_assedio_esito`).
- [~] **[A] Fase G — Art**: **hook di caricamento sprite già cablati con fallback** per il
  sottoinsieme Fase B (campo, roccaforte, 4 `unit_*`, `enemy`, proiettili, icone barra — vedi
  §P7 righe ✓): basta droppare i PNG in `Assets/art/siege/` e l'Assedio li usa da solo
  (verificato end-to-end con segnaposto). Restano da generare gli asset veri + cablare
  boss/nemici-per-tipo/UI boss.
- [x] **[C] Fase H — Balance + verifica**: aggiunto `assedio_check`/`assedio_report` a
  `balance_sim.py` (euristico mirror di `siege.gd`, no-game-over): i 6 finali restano raggiungibili
  e l'Assedio è "sfida" vincibile (profilo tipico ratio ~1.2, militare-trascurato ~0.92) per era 1/2.
  Schermate verificate via `shot_assedio`/`shot_assedio_boss`/`shot_assedio_esito`.

## C. OPZIONALE — Era 3 "Futuro" (asset già presenti)

Esistono già in `Assets/`: 4 consiglieri era3, sfondi era3 (insediamento/crescita/
metropoli), 6 icone decisioni era3. La struttura è data-driven: aggiungere Era 3
significa una terza voce in `QUEST_SEQUENZE`, decisioni/quest `.tres`, edifici era3, e
un terzo set Assedio (boss "Titano d'Acciaio"). **Grosso scope**: valutare solo dopo che
l'Assedio è solido su 2 ere. Non necessario per l'MVP/esame.

- [ ] **[C/A] Era 3 completa** (decisioni, quest, edifici, finali estesi, boss era3).

## D. ESAME — deliverable del corso (Sviluppo Videogiochi)

- [x] **[C] Menu Opzioni**: overlay `scenes/ui/options_menu.tscn` (+`scripts/ui/options_menu.gd`)
  con slider volume Musica/Effetti, "Silenzia tutto", "Schermo intero", risoluzione e "Rigioca il
  tutorial". Persistenza in `user://settings.cfg` (AudioManager: volumi + video, applicati all'avvio).
  Aperto da menu principale (pulsante "Opzioni") e pausa. Verificato (`shot_opzioni`).
- [~] **[C] Build Windows**: preset "Windows Desktop" pronto (`export_presets.cfg`, embed_pck,
  exclude tools/Docs/.md/Godot-exe). **Da fare a mano** (export templates non installati in questo
  ambiente): in Godot → *Project > Export > Add Windows Desktop > Export Project* su
  `exports/HumanityLedger.exe`, poi zippare la cartella `exports/`. Verifica su macchina pulita.
- [ ] **Video di presentazione**: cattura le schermate forti (menu, decisione, villaggio,
  **Assedio**, epilogo, mappa). L'Assedio è il momento "wow" per il video.
- [ ] **Relazione**: architettura data-driven, scelte di design (no game over, stat→esercito),
  pipeline asset, riferimenti (Lapse, TD design). I doc `00`–`12` sono già la base.
- [x] **[C] Pass anti-debug pre-consegna**: `_debug_input` (R/B/1-8) già dietro
  `OS.is_debug_build()` (inattivo in release); nessun `print()` di debug nei runtime script;
  nessuna label grezza always-on. Verificato 2026-06-18.

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
- **2026-06-17 (5)** — **PUSHATO su origin/main** (`7e294fb` codice Fase B+hook, `49da081` asset,
  `52569aa` polish). **Integrati ~55 asset generati dall'utente** (P0–P7): edifici villaggio
  era1+2 (12×3 stadi), terreni `.jpg`, sfondi scena, Assedio Era 1 (campo/roccaforte/unità/
  nemico/proiettili), 4 eventi paleolitici, artefatto Occhio (+`.tres`), icona spionaggio,
  fx conseguenze. Tutto verificato a schermo. **Polish:** corsie Assedio trasparenti sul campo
  dipinto, J7 (conseguenze con intensità), J8 (rapporti animati). **Manca arte:** Assedio Era 2,
  boss, UI kit §P8, icone §P9.
- **2026-06-18** — **Villaggio completato + L'Assedio finito (Fasi C–H).** Villaggio: vista
  gestionale (tasto V), tabella costi+thumbnail nei modali, **J15 bandierine alleanza**. Assedio:
  **Fase C** boss (`boss.gd`, 3 abilità telegrafate + furia), **Fase D** 4 ondate/era con banner su
  cartiglio + intel Spionaggio, **Fase E** juice (barre bronzo, poof morte, flash danno), **Fase F**
  esiti graduati (immacolata/trionfo/fatica/sopraffatto) + trofeo Ledger + no-game-over, **Fase H**
  check in `balance_sim.py` (Assedio "sfida" vincibile, 6 finali intatti). Tutto verificato a schermo
  (`shot_assedio`/`_boss`/`_esito`, `shot_villaggio_*`). **`Docs/08` aggiornato** con stato asset reale
  + prompt completi del mancante (boss, Assedio Era 2, icone unità, nemici per-tipo, §P10 stendardo).
  **Resta:** asset (vedi `08`), Sprint 5 esame (opzioni/build/anti-debug). **Non committato.**

*File vivo: spuntare man mano. Doc di dettaglio: `09` (juice/audit AAA), `10` (UI/villaggio),
`11` (Assedio).*

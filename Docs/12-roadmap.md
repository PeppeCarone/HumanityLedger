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

- [x] **[C] Vignette shader riusabile** (`09` #3): unico shader `canvas_item`
  (`Assets/shaders/vignette.gdshader`) via helper `UiStyle.crea_vignette(intensity, tint)`,
  cablato su **menu** (`main_menu`), **villaggio/decisione** (`main._crea_vignette`) e
  **mappa** (`world_map._crea_vignette_mappa`) — sostituite le 2 `GradientTexture2D` 512².
  Isola il soggetto, affonda bordi/letterbox nel buio. Verificato (`shot_menu`/`shot_era1`/
  `shot_worldmap`/`shot_era1_decision`).
- [x] **[C] Epilogo: box istruzioni** (`09` #5 / `10` #11): già fatto —
  `ending_screen._box_footer` mette "Premi R/L" in un cartiglio bronzo centrato.
- [ ] **[C] Cornice pannello stat sinistro** (`10` #6): allineamento numeri/margini già
  leggibile a schermo; rifinitura rimandata (nessun difetto evidente).
- [x] **[C] Cornici/ornamenti d'angolo** (`10` #12): **Ledger** incorniciato come "tomo"
  con i 4 `corner_*` (`ledger_screen._aggiungi_cornici`, fallback-safe). Menu/Mappa lasciati
  senza (sfondi dipinti già ricchi + ora vignette) per non competere col fondale. Verificato
  (`shot_ledger`).
- [x] **[C] Tabella costi nel modale build/upgrade** (`10` #1): righe costo allineate
  con icona risorsa + thumbnail edificio (`main._riga_costo`/`_thumb_edificio`/`_tex_edificio`).
  Icona-edificio anche sui pulsanti del modale build. Verificato (`shot_upgrade_panel`/`shot_build_panel`).
- [x] **[C] J7 — Conseguenze con intensità**: il delta maggiore scala dimensione/durata
  dell'FX (`village_view.applica_conseguenza(tipo, intensita)` + `main._intensita_conseguenza`).
  *Resta opzionale: guerra che colpisce un edificio, alleanza su due slot.*
- [x] **[C] J8 — Rapporti civiltà animati**: flash colorato sul cambio + ingresso a cascata
  delle righe (`main._refresh_rapporti`, stato `_rapporti_prec`).
- [x] **[C] J12 — Vignette animata vista decisione**: col mystery desto la vignette della
  decisione vira a un viola tenue (tween delle uniform `tint`/`intensity` dello shader,
  `main._vira_vignette`, agganciato a `_avvia/_ferma_idle_decisione`). Segnale ambientale
  "qualcosa non torna", senza testo.
- [x] **[C] J15 — Bandierine alleanza sul villaggio**: uno stendardo radicato per civilta'
  alleata (rapporto >= soglia), col volto dell'ambasciatore nel medaglione. `village_view.mostra_bandiere_alleati`
  + `main._refresh_bandiere_alleati` (da `_refresh_rapporti`/`_aggiorna_sfondo_era`). Verificato (`shot_villaggio_alleati`).
- [ ] **[C] J16 — Ciclo giorno/notte** legato allo step della quest (overlay colore).
- [x] **[C] J13 — Micro slow-mo/flash al drop**: lampo bianco full-rect (alpha 0.45→0 in
  ~130ms) + micro-pausa (~60ms) al drop risolto (`main._flash_drop`), **senza**
  `Engine.time_scale`. Dà peso d'impatto al gesto→conseguenza (il momento più guardato nel
  video, `Docs/15` seg.1).
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
- [x] **[A] Fase G — Art**: asset Assedio generati e cablati (campo, roccaforte, 4 `unit_*`,
  `enemy`, boss Era1/2, proiettili, `boss_bar`/`wave_banner`, icone unità). **2026-06-22: cablati
  anche i 7 sprite nemici per-tipo** (era1 cinghiale/iena/orso; era2 predone/scheletro/minotauro/
  golem) via `CREATURE_ONDATA`/`spawn` in `siege.gd` — prima erano in `Assets/` ma inutilizzati:
  ogni ondata mescola creature diverse e le pesanti (orso/minotauro/golem) entrano più grandi.
  + ombre di contatto su nemici/difensori e muzzle-flash di tiro (juice). Verificato a schermo
  (`shot_assedio`/`_boss`/`_era2`).
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
- [~] **Video di presentazione**: **script shot-by-shot pronto in `Docs/15-video-demo.md`**
  (scaletta ~3:30 con stati da seminare e inquadrature `shot_*`). Resta la cattura/montaggio
  a mano (OBS). L'Assedio è il momento "wow" per il video.
- [~] **Relazione**: **bozza completa in `Docs/14-relazione.md`** (architettura data-driven,
  scelte di design no game over/stat→esercito, pipeline asset, riferimenti Lapse/TD). Restano da
  completare solo le parti soggettive marcate `[DA COMPLETARE dal team]` (ruoli, ore, retrospettiva).
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

- **2026-06-18 (2)** — **Asset integrati + Sprint 5 + commit/push.** Tutti gli asset Assedio/UI
  generati dall'utente organizzati e cablati (boss Era1/2, set Era2, icone, cornici, stendardo;
  orientamento difensori/nemici corretto). **Menu Opzioni** completo + persistenza, **pass anti-debug**
  verificato, export preset rifinito (build `.exe` = passo manuale, templates non installati qui).
  Polish da playtest: pannello Opzioni allargato, onboarding schieramento Assedio. Doc `08`/`10`/`12`/`13`
  + README aggiornati. Rimosso `Consigliere.png`. **Committato e pushato su `upstream/main`** (PeppeCarone),
  commit `1767b34`. Resta opzionale: Era 3, §P9 medaglioni unificati, build `.exe` (manuale).

- **2026-06-18 (3)** — **Rifiniture da playtest (UX/accessibilità/wow).** Banner di transizione
  prima dell'Assedio (`main._mostra_card_assedio`); tooltip carte-unità coi numeri reali
  (`siege._stat_unita`/`_tooltip_unita`); simboli oltre al colore (✓/✗ sui costi, ▲/▼ sui rapporti
  in main e Assedio) per daltonismo; vittoria Assedio cinematografica (lampo dorato + titolo
  scale-pop + shake); testo decisioni più arioso. Verificato a schermo. Resta opzionale lato utente:
  rigenerare `roccaforte` Era 2 painterly (prompt §P7 7c).

- **2026-06-18 (4)** — **Animazione procedurale (pass 1) — "il gioco non è più statico".** Scelta:
  animare in-engine senza nuovi asset (shader/tween) invece di sprite a frame. Fatto: edifici del
  villaggio con **idle-sway** attorno alla base (ampiezza/durata random, desincronizzati,
  `village_view._idle_edificio`); vista decisione con **ritratto che respira** + **Ken Burns** sullo
  sfondo dipinto (`main._avvia/_ferma_idle_decisione`, azzerato nel villaggio per tenere il tabellone
  1:1). Verificato a schermo. Sfondi §P1 (caverna/accampamento/città-notte) integrati.
- **2026-06-18 (5)** — **Animazione procedurale (pass 2).** Assedio vivo: difensori con idle-bob
  (`defender.avvia_idle`), **boss che respira** (`boss._process` scale breathing, più marcato in
  furia). Villaggio: **braci** che salgono dal fuoco (`_avvia_braci`) + **shader di flicker** sul
  bagliore (`Assets/shaders/fire_flicker.gdshader`). Verificato a schermo, nessun errore shader.
  Restano (pass 3, opzionali): shimmer acqua/calore, vento-vertex su tetti/alberi, godrays caverna,
  parallax/nubi, mappa-mondo animata.
- **2026-06-18 (6)** — **Animazione procedurale (pass 3) — Assedio atmosferico.** Shader **heat-haze**
  sul campo di battaglia (`Assets/shaders/heat_haze.gdshader`, distorsione UV crescente verso il
  suolo, isolata allo sfondo) + **pulviscolo ambientale** che deriva sul campo (`siege._avvia_ambient`:
  braci arancioni Era 2 / polvere calda Era 1, dietro le entità). Verificato a schermo. Restano
  opzionali: vento-vertex su tetti/alberi, godrays caverna, parallax/nubi, mappa-mondo animata.
- **2026-06-18 (7)** — **Animazione procedurale (pass 4) — mappa-mondo viva.** Rotte con **flusso
  luminoso** (`Assets/shaders/flow.gdshader`, banda che scorre, oro commercio / rosso guerra),
  **pulse idle su tutti gli insediamenti** (`_idle_marker`, non solo la capitale), **ombre di nubi**
  che scorrono lente sulla terra (`_avvia_nubi`/`_soft_blob`). Verificato (`shot_worldmap`). Con questo
  tutte le schermate principali (villaggio, decisione, Assedio, mappa) sono animate; 3 shader riusabili
  (fire_flicker, heat_haze, flow). Restano marginali: vento-vertex, godrays caverna, transizioni viste.
- **2026-06-18 (8)** — **Animazione pass 5 + fix.** Corretto il Ken Burns della vista decisione: ora
  anima `decision_bg` (lo sfondo dipinto VISIBILE) invece di `scene_bg` (coperto) — prima non si vedeva.
  Aggiunti **godrays** nella caverna (fascio caldo che ondeggia, `main._crea_godray`, gated a `BG_CAVERNA`,
  riposizionato a destra fuori dal pannello proponente). Vento-vertex saltato (già coperto dal dondolio
  edifici). Verificato a schermo.

- **2026-06-20** — **Sessione consegna d'esame.** Focus su deliverable (gioco già
  feature-complete). **QA & de-risk**: import + `validate_scenes` (0 failure) + `balance_sim`
  (6/6 finali + Assedio vincibile) + `asset_audit` (nessun riferimento rotto) + screenshot di
  tutte le schermate riguardati. **Bug reale trovato e corretto**: `village_view._avvia_braci`
  aggiungeva una `CPUParticles2D` all'array tipizzato `Array[TextureRect]` `_edifici_nodi` →
  crash a ogni avvio Era 1; tipo allargato a `Array[Node]` (è una free-list). **Scritti i
  deliverable**: `Docs/14-relazione.md` (relazione completa, parti soggettive a placeholder) e
  `Docs/15-video-demo.md` (script video ~3:30). README aggiornato (indice doc 10–15, licenza).
  Resta manuale: build `.exe` (template export), cattura/montaggio video, compilare le sezioni
  `[DA COMPLETARE dal team]` della relazione.

- **2026-06-21** — **Sprint finale di rifinitura visiva (video-driven).** Chiusi gli ultimi
  item code-only della §A puntando alle schermate del video (`Docs/15`). **Vignette shader
  unificata**: `Assets/shaders/vignette.gdshader` + `UiStyle.crea_vignette` (4° shader
  riusabile), sostituite le 2 vignette `GradientTexture2D` e cablata anche su menu →
  inquadratura cinematografica coerente su menu/villaggio/decisione/mappa. **J12** vignette
  decisione viola col mystery (`_vira_vignette`). **J13** micro-flash+pausa al drop
  (`_flash_drop`, no `time_scale`). **Cornici "tomo"** sul Ledger (4 `corner_*`,
  `_aggiungi_cornici`). QA verde (import+validate 0 failure, balance 6/6+Assedio, audit
  pulito) e verifica a schermo di tutte le schermate toccate (`shot_menu`/`shot_era1`/
  `shot_worldmap`/`shot_era1_decision`/`shot_ledger`). Roadmap §A allineata (corretta la
  voce stale "Epilogo: box istruzioni", già fatta). Resta manuale: build `.exe`
  (templates non installati qui), cattura video, parti soggettive relazione.

- **2026-06-22** — **L'Assedio: da "TD funzionale" a "climax vivo" (sessione ripresa
  sviluppo).** Analisi completa del gioco (QA verde: validate 0 failure, balance 6/6 + Assedio
  vincibile, asset audit pulito; riguardate tutte le schermate). Scelta strategica: il boss
  fight è il centro del video ma la schermata leggeva "campo vuoto". Causa trovata: i **7 sprite
  nemici per-tipo erano in repo ma non cablati** (lo spawn usava solo `enemy.png`). Fatto, tutto
  in `scripts/siege/`: `CREATURE_ONDATA` per era + assegnazione creatura per spawn, sprite
  `enemy_<tipo>` con fallback, creature pesanti più grandi; ombre di contatto su nemici/difensori;
  muzzle-flash al tiro; helper `spawn_enemy_test` + seeding mandria mista nello `shoot.gd`
  (gli shot ora mostrano la battaglia, non un campo spoglio). Verificato a schermo. Piano di
  sessione in `Docs/16-piano-sessione.md`. Resta manuale: build `.exe`, video, parti soggettive
  relazione.
- **2026-06-22 (2)** — **Comportamento distinto per creatura** (profondità tattica, non solo
  estetica). `CREATURE_PROFILI` in `siege.gd`: ogni creatura ha HP/velocità/danno/taglia propri +
  **armatura** (golem, riduzione piatta + glifo d'acciaio) e **risurrezione** (scheletro, si rialza
  una volta a metà HP con scatto di scala). Iena veloce/fragile, orso/minotauro tank lenti che
  colpiscono forte, cinghiale caricatore. `enemy.gd`: campi `armatura`/`risorge` + logica in
  `subisci_danno` + cue visivi. Bilanciato per ondata e mirrorato in `balance_sim.py` (`WAVE_MULT`):
  verdetti tipica=sfida (era1 1.15 / era2 0.93), trascurato era1=sfida (0.90) / era2=duro (0.73,
  vincibile, no game over), 6/6 finali intatti. Compile pulito, verificato a schermo.
- **2026-06-22 (3)** — **Boss distinto per era** (archetipi diversi, non solo skin). `boss.gd`
  `imposta_era()` sceglie il kit: **Era 1 Il Colosso** = bruto a terra (Pestone AoE su punto +
  Carica che sfonda + Ruggito); **Era 2 Il Drago** = caster di fuoco a distanza (**Soffio** =
  lingua di fuoco sulla corsia che colpisce i difensori davanti senza raggiungerli + **Pioggia**
  = impatti multipli sparsi/area denial + Ruggito), furia anticipata a 0.45. Nuove abilità con
  telegrafo+esecuzione+`_draw` propri, riusano le API arena esistenti (`danno_area_difensori`/
  `fx_esplosione`/`scuoti_forte`) → **boss HP invariato, balance non tocco**. `shoot.gd` cattura
  il telegrafo del Drago (`spawn_boss_test(true)`). Verificato a schermo (`shot_assedio_boss`
  Colosso col Pestone, `shot_assedio_era2` Drago col Soffio).

*File vivo: spuntare man mano. Doc di dettaglio: `09` (juice/audit AAA), `10` (UI/villaggio),
`11` (Assedio), `16` (piano di sessione 2026-06-22).*

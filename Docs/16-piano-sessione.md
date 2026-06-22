# 16 — Piano di sviluppo (sessione 2026-06-22)

> Ripresa dello sviluppo dopo la sessione-consegna. Obiettivo della sessione: analisi
> completa del gioco, scelta autonoma dell'area più strategica, progettazione e prime
> migliorie, e questo piano. Lente fissa: **occhio del giocatore / "wow", mai prototipo**
> (vedi `feedback_player_lens`).

---

## 1. Analisi: dove siamo

Il gioco è **feature-complete e rifinito**. Verifica eseguita a inizio sessione:

- **QA verde**: `validate_scenes` 0 failure · `balance_sim` 6/6 finali raggiungibili +
  Assedio "sfida" vincibile (ratio ~1.2 tipico, ~0.92 militare-trascurato) su Era 1/2 ·
  `asset_audit` nessun riferimento statico rotto.
- **Schermate riguardate** (shot reali): menu, vista decisione, mappa-mondo, epilogo e
  Ledger reggono a livello "AAA-leaning" (painterly, atmosferici, animati). Arte vera
  ovunque, niente arte-codice residua nel flusso principale.
- **Contenuto**: Era 1 + Era 2, 40 decisioni, 7 quest, 6 finali, Ledger meta-persistente,
  4 artefatti, L'Assedio (boss fight) completo Fasi A–H, opzioni/pausa/audio, animazione
  procedurale su tutte le viste.

### Punto debole individuato (con la lente del giocatore)
La sola schermata-eroe che leggeva **sotto la barra del resto** era **L'Assedio**: il
campo appariva **vuoto** (poche entità, terreno dipinto largo). Ed è proprio il **momento
"wow" su cui è costruito il video** (`Docs/15`). Causa tecnica trovata: i **7 sprite
nemici per-tipo erano già in repo ma non cablati** — lo spawn caricava sempre il generico
`enemy.png` (`siege.gd`). Anche gli screenshot di test piazzavano solo difensori + boss,
mai la mandria: il "vuoto" era in parte un artefatto del seeding.

## 2. Decisione strategica

**Area scelta: elevare L'Assedio da "tower-defense funzionale" a "climax vivo", solo
codice, sfruttando l'arte già esistente.**

Perché questa e non altro:
- **Massimo impatto/sforzo**: è il centro del video e della relazione; alzarlo alza la
  percezione dell'intero progetto in sede d'esame.
- **Rischio basso**: modifiche localizzate a `scripts/siege/`, additive e fallback-safe;
  non tocca il loop gestionale già stabile a ridosso della consegna.
- **Autonomo**: nessun asset nuovo da generare (tutta l'arte Assedio è già in
  `Assets/art/siege/`). Coerente con "usare ogni asset al meglio".
- **Era già un item aperto**: "cablare nemici-per-tipo" (Fase G, `Docs/12`).

Scartate per ora: Era 3 (scope enorme, non necessaria all'MVP/esame); redesign UI §P9
(già coerente e finito); pura caccia-bug (QA automatica già verde, resa "wow" nulla).

## 3. Fatto in questa sessione

Tutto in `scripts/siege/` + `tools/shoot.gd`, verificato a schermo:

- **Nemici per-tipo cablati** (`siege.gd`): `CREATURE_ONDATA` per era assegna a ogni
  spawn una creatura; lo sprite `enemy_<tipo>` con fallback a `enemy`. Era 1 mescola
  cinghiale/iena/orso, Era 2 predone/scheletro/minotauro/golem. Le **creature pesanti**
  (orso/minotauro/golem) entrano **più grandi** (`CREATURE_GRANDI`, raggio 18→27),
  coerenti con le ondate lente ad alto HP.
- **Ombre di contatto** su nemici e difensori (`enemy.gd`/`defender.gd` `_draw`):
  le figure non "fluttuano" più sul campo dipinto.
- **Muzzle-flash** al tiro (`siege._muzzle_flash`): bagliore caldo all'origine del
  proiettile — peso d'impatto al combattimento.
- **Tooling shot** (`shoot.gd`): helper `spawn_enemy_test` + seeding di una mandria mista
  in `shot_assedio`/`_boss`/`_era2` → gli screenshot (e quindi il video) mostrano una
  battaglia, non un campo spoglio.

Risultato: il campo ora legge come un assedio reale (mandria varia sulle 3 corsie con
barre HP; in Era 2 roccaforte con stendardi vs drago sotto cielo rosso). QA ancora verde.

## 4. Backlog prioritato (prossimi passi)

Ordine consigliato; `[C]` solo codice, `[A]` serve arte (non necessaria all'esame),
`[M]` passo manuale dell'utente.

1. **[M] Deliverable d'esame (bloccanti, fuori dalla mia portata)**:
   - Build `.exe`: installare gli export templates 4.6.3 da editor (*Manage Export
     Templates*), poi *Project > Export* su `exports/HumanityLedger.exe`; test su macchina
     pulita. `export_presets.cfg` già pronto.
   - Cattura + montaggio **video** (OBS) seguendo `Docs/15` — l'Assedio rinnovato è il
     segmento clou.
   - Compilare le parti `[DA COMPLETARE dal team]` di `Docs/14-relazione.md` (ruoli, ore,
     retrospettiva).
2. **[C] Pass di robustezza del loop gestionale**: rilettura mirata di `main.gd` + autoload
   a caccia di crash latenti (classe del bug typed-array del 2026-06-20), che la QA
   automatica non esercita. Alto valore difensivo per la demo dal vivo.
3. ~~**[C] Polish composizione Assedio (2° giro)**: parapetto, orda lontana, punch banner,
   vignetta rossa FURIA.~~ **FATTO (2026-06-22 #2)** — vedi §6.
4. ~~**[C] Varietà di gameplay Assedio**: comportamento distinto per creatura.~~
   **FATTO (2026-06-22)**: `CREATURE_PROFILI` in `siege.gd` dà a ogni creatura HP/velocità/
   danno/taglia propri + due abilità — **armatura** (golem: riduzione danno piatta, glifo
   d'acciaio sulla barra) e **risurrezione** (scheletro: si rialza una volta a metà HP, con
   scatto di scala). Iena veloce/fragile, orso/minotauro tank lenti, cinghiale caricatore.
   I moltiplicatori HP si bilanciano per ondata; mirror in `balance_sim.py` (`WAVE_MULT`):
   verdetti attesi (tipica=sfida, trascurato era2=duro ma vincibile), 6/6 finali intatti.
5. **[A/C] Era 3 "Futuro"** (opzionale, post-esame): asset già in `Assets/`; richiede
   quest/decisioni/finali estesi + terzo set Assedio. Grosso scope.

## 5. Asset

I 7 nemici per-tipo erano già in repo. **Aggiunti i prompt §7l (parapetto primo piano) e
§7m (orda all'orizzonte) in `Docs/08`** per la profondità cinematografica del campo (vedi
§6): code-only cablato e fallback-safe, gli asset si generano quando si vuole.

## 6. Sessione #2 (2026-06-22) — i colpi finali al climax

Chiuso il punto 3 del backlog. Due audit (Explore) hanno stabilito la leva: il loop
gestionale è **già difensivo** (guard `is_inside_tree`/`is_instance_valid` dopo gli await),
quindi niente grande sprint di robustezza; la leva vera è il **climax dell'Assedio** (centro
del video). Fatto, tutto in `scripts/siege/siege.gd` salvo dove indicato:

- **A1 — punch banner d'ondata** (`_mostra_banner`): scale-pop `TRANS_BACK` + colpetto
  (`_scuoti`) al picco. Il banner "atterra".
- **A2 — vignetta rossa della FURIA** (`_vignetta_furia_attiva`/`_pulsa`/`_dissolvi`):
  riusa lo shader `vignette.gdshader` via `UiStyle.crea_vignette`, bordi rossi che pulsano
  all'ingresso furia e a ogni abilità del boss, si dissolvono alla morte. Verificato a
  schermo (boss Drago infuriato → bordi rossi, "IL DRAGO È INFURIATO").
- **A3 — finisher morte boss** (`_finisher_boss`): poof maggiorato + `fx_esplosione` + lampo
  bianco con breve hold (no `time_scale`, coerente J13).
- **A4 — profondità** (`_costruisci_scena`): strati fallback-safe `orda_orizzonte` (dietro,
  orizzonte) e `parapetto` (davanti alle entità, sopra la barra unità). Prompt §7l/§7m in `08`.
- **De-risk lieve**: `GameState.from_dict` ora valida i tipi di ogni campo (save vecchio/
  corrotto → degrada a partita pulita, mai crash); `village != null` → `is_instance_valid`
  in `main.gd` (4 siti, incl. post-await).

QA verde: `validate_scenes` failures=0, `balance_sim` 6/6 + Assedio invariato (estetica/
difesa, nessun valore di combattimento toccato), `asset_audit` nessun riferimento rotto,
26 screenshot renderizzati senza errori.

---

*File di sessione. Piano vivo principale: `Docs/12-roadmap.md`. Dettaglio Assedio:
`Docs/11-boss-fight.md`.*

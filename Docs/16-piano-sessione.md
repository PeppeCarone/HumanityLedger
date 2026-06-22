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
3. **[C] Polish composizione Assedio (2° giro, se c'è tempo)**: parapetto in primo piano
   + silhouette di orda lontana sull'orizzonte per profondità; punch del banner d'ondata;
   vignetta rossa ai bordi durante la FURIA del boss.
4. **[C] Varietà di gameplay Assedio**: dare ai nemici per-tipo un **comportamento**
   distinto (orso lento/coriaceo, iena veloce/fragile, scheletro che si rialza una volta)
   invece della sola estetica — profondità tattica reale.
5. **[A/C] Era 3 "Futuro"** (opzionale, post-esame): asset già in `Assets/`; richiede
   quest/decisioni/finali estesi + terzo set Assedio. Grosso scope.

## 5. Asset

**Nessun nuovo asset richiesto da questa sessione**: l'arte dell'Assedio (inclusi i
nemici per-tipo) era già in repo. I prompt per l'eventuale arte futura (parapetto,
silhouette orda) restano da scrivere in `Docs/08` solo se si affronta il punto 3 del
backlog.

---

*File di sessione. Piano vivo principale: `Docs/12-roadmap.md`. Dettaglio Assedio:
`Docs/11-boss-fight.md`.*

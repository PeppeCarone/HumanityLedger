# 11 — L'Assedio: boss fight tower-defense di fine era

> Sessione 2026-06-17. Nuova feature-climax: a fine di ogni era, raggiunti i
> requisiti per avanzare, il giocatore deve difendere il villaggio da ondate di
> nemici dell'era e da un **boss** (creatura mitologica/apex del tempo) in una
> **battaglia tower-defense orizzontale**. È il "rito di passaggio" verso l'era
> successiva. Idea dell'utente; design e piano qui sotto.
>
> Ricerca di riferimento (TD design + Godot): wave pacing "burst" e telegrafia del
> boss da [Sean Duggan — TD gameplay flow](https://medium.com/@sean.duggan/tower-defense-general-gameplay-flow-529b317a8ef9),
> [CraftMyGame — wave/spawn](https://craftmygame.com/features/wave-spawn),
> [Defender's Quest — focus & thinking](https://www.fortressofdoors.com/optimizing-tower-defense-for-focus-and-thinking-defenders-quest/);
> architettura Godot 4 (Path2D/PathFollow2D + spawner a Timer + Area2D range) da
> [Wayline — Godot TD guide](https://www.wayline.io/blog/godot-tower-defense-tutorial)
> e [quiver-dev/tower-defense-tutorial](https://github.com/quiver-dev/tower-defense-tutorial).

---

## 1. Concept: "L'Assedio"

Quando il giocatore ha completato tutte le quest dell'era e soddisfa i requisiti per
avanzare (oggi: flag `eraN_completata`), **prima** della title-card di transizione
parte *L'Assedio*. Il villaggio costruito durante l'era viene messo alla prova:
ondate di nemici marciano da destra verso il villaggio a sinistra; il giocatore
schiera l'esercito che lo protegge; all'ultima ondata arriva il **boss**.

Coerenza con il **"no game over" (D024)**: l'Assedio è sempre superabile, non esiste
schermata di morte. L'esito **modula le ricompense e una conseguenza narrativa**, non
blocca la progressione. Questo conserva sia la tensione del boss sia la filosofia del
gioco ("rovina → ricostruisci, non punizione che azzera", come le catastrofi).

## 2. Il gancio di design: **le tue statistiche diventano il tuo esercito**

È il punto che fa "quadrare" tutto il gioco. Le 8 stat coltivate nell'era e gli
edifici costruiti determinano la tua forza nell'Assedio:

| Stat | Effetto nell'Assedio |
|---|---|
| **Militare** | forza/numero dei combattenti, danno base delle unità |
| **Costruzione** | HP del villaggio + resistenza di mura e torri fisse |
| **Popolo** | numero di unità schierabili + ondate di rinforzi (riserva) |
| **Scienza** | sblocca unità/trappole speciali (fuoco, veleno, AoE) e upgrade |
| **Tesoro / Risorse** | valuta di schieramento durante la battaglia |
| **Diplomazia** | civiltà alleate (rapporto +) mandano truppe; ostili (rapporto −) **rinforzano il nemico** |
| **Spionaggio** | intel: vedi in anticipo la composizione dell'ondata e il punto debole del boss; può rallentarlo |
| **Legge** | morale: le tue unità resistono al "Ruggito" del boss (meno stun/paura) |

Chi ha gestito bene il villaggio entra forte; chi ha trascurato il militare deve
sudare — ma non perde mai del tutto. Rapporti con le civiltà e mystery acquisiscono
così un **peso meccanico concreto**, non solo narrativo.

## 3. Layout (orizzontale, 1920×1080)

```
┌───────────────────────────────────────────────────────────────────────┐
│  [Ondata 3/6]        [Risorse d'assedio: 24]        [BOSS ▆▆▆▆▆░░░]      │  ← HUD alto
│                                                                         │
│ ╔═════╗   · piazzola ·         · piazzola ·                   ◀── 🐺    │  corsia A
│ ║VILL.║◀──────────────·piazzola·───────────────────────────◀── 🐗      │  corsia B
│ ║ ▆▆▆ ║   · piazzola ·         · piazzola ·                   ◀── 🐺    │  corsia C
│ ╚═════╝                                                       (spawn) → │
│  HP villaggio                                                           │
│ [ Cacciatore ][ Guerriero ][ Sciamana ][ Totem ]   ← barra schieramento │  ← HUD basso
└───────────────────────────────────────────────────────────────────────┘
   sinistra: il villaggio da difendere          destra: i nemici entrano
```

- **Sinistra (~0–18%)**: il **villaggio fortificato** (cancello/mura) con barra **HP
  Villaggio**. È l'obiettivo. I nemici che lo raggiungono gli tolgono HP.
- **Campo (~18–90%)**: 3 **corsie** che convergono verso il villaggio. Lungo le corsie
  ci sono **piazzole di schieramento**: qui posizioni i difensori (l'"esercito intorno
  al villaggio" di cui parlava l'utente). Alcune torri fisse sulle mura sono già
  presenti in base alla Costruzione.
- **Destra (~90–100%)**: punto di spawn; le ondate entrano e marciano a sinistra.
- **HUD alto**: contatore ondata, Risorse d'assedio, e (da quando appare) **barra HP
  del Boss**.
- **HUD basso**: **carte-unità** trascinabili sulle piazzole — **riusa il drag-and-drop
  della decisione** (`draggable_item.tscn` + `drop_zone.tscn`): coerenza UX totale,
  niente nuovo paradigma di input da imparare.

## 4. Difensori (le "torri"/unità)

Archetipi costanti, skin per era (data-driven via `UnitData`):

| Archetipo | Ruolo | Scala con |
|---|---|---|
| **Tiratore** (arciere/lanciere) | danno a distanza sulla corsia | Militare |
| **Difensore** (muro di scudi) | blocca la corsia, alto HP, corpo a corpo | Costruzione + Militare |
| **Supporto** (sciamano/sacerdote) | rallenta i nemici / potenzia i vicini | Scienza / Diplomazia |
| **Trappola/Totem** | danno ad area, effetti (fuoco/veleno) | Scienza / Spionaggio |
| **Torre fissa** (sulle mura) | presente a inizio battaglia | Costruzione |

- **Era 1 (paleolitico)**: Cacciatore (lancia), Guerriero (clava+scudo di pelli),
  Sciamana (rito di gelo = slow), Totem del Fuoco (AoE), Torre di guardia in palizzata.
- **Era 2 (regno mitico)**: Arciere/Balestriere, Legionario (scudo), Sacerdote (buff/heal),
  Catapulta (AoE), Balista su torre.
- **Era 3 (futuro, se aggiunta)**: Fuciliere/drone, Mech corazzato, Hacker (EMP=slow),
  Torretta automatica, Cannone.

Schieramento: trascini la carta sulla piazzola; costa **Risorse d'assedio** (budget
iniziale + accumulo per nemico ucciso). Numero di piazzole e budget dipendono dalle
stat (Popolo/Tesoro).

## 5. Ondate (wave pacing)

Ritmo **"wave burst"** (gruppo → pausa → gruppo), ~**5–6 ondate** a difficoltà
crescente, con un breve **respiro** tra una e l'altra per (ri)schierare. Ogni ondata è
annunciata da un **banner** (telegrafia); con **Spionaggio** alto vedi in anticipo la
composizione. Definite per era in una Resource `WaveData`.

Nemici (marciano dx→sx, skin per era):
- **Era 1**: branchi di lupi/iene → mandrie di bestie → orsi delle caverne → **BOSS**.
- **Era 2**: predoni/scheletri → minotauri/golem → **BOSS** (Drago).
- **Era 3**: droni/soldati → mech d'assalto → **BOSS** (Titano).

## 6. Il Boss (ultima ondata)

Creatura **mitologica o apex** dell'era. Entrata cinematica (screen shake, ruggito,
breve zoom), **barra HP grande** in alto. **2–3 abilità a cooldown**, ognuna con
**telegraph** (segnale visivo prima del colpo — fondamentale per la leggibilità):

| Abilità | Effetto | Telegraph | Mitigazione |
|---|---|---|---|
| **Pestone** (AoE) | danno ai difensori in un'area | cerchio rosso a terra | posiziona unità sparse |
| **Carica** | scatta verso il villaggio saltando le difese | il boss arretra e ringhia | Difensore-blocco sulla corsia |
| **Ruggito** | stordisce/rallenta i difensori | onda sonora | **Legge** alta riduce lo stun |
| **Evoca** | chiama minion (solo fasi avanzate) | crepa/portale | — |

- **Fasi**: a ~50% HP il boss **infuria** (attacchi più frequenti o nuova abilità).
- **Punto debole** opzionale, rivelato da **Spionaggio** alto (danno bonus su un'area).

### Boss proposti (uno per era)

- **Era 1 — Paleolitico → "Il Colosso"**: bestia primordiale. Opzione coerente col
  tempo = **mammut-titano** o **grande orso delle caverne**; opzione "rule of cool"
  (come da esempio dell'utente) = **teropode/dinosauro**. *Raccomando il mammut-titano
  o l'orso (più credibile per il paleolitico), col dinosauro come variante sbloccabile.*
- **Era 2 — Regno Mitico → "Il Drago"**: wyrm sputafuoco, il mostro iconico del regno
  mitico. Alternative: Idra, Ciclope.
- **Era 3 — Futuro → "Il Titano d'Acciaio"**: mech-kaiju / IA-titano (se l'era verrà
  implementata; asset era3 già presenti).

## 7. Esito (no game over, D024)

| Esito | Condizione | Conseguenza |
|---|---|---|
| **Trionfo** | boss sconfitto, villaggio in piedi | ricompense piene: +Risorse, sblocco Ledger "Trofeo dell'Assedio", piccolo bonus stat in ingresso all'era successiva, narrazione epica |
| **Vittoria Immacolata** | boss sconfitto, **0 HP villaggio persi** | come sopra + bonus extra (artefatto/lore raro) |
| **Resistenza a fatica** | boss sconfitto ma villaggio molto danneggiato | passi, ricompensa ridotta, lieve perdita di popolazione |
| **Sopraffatto** | HP villaggio a 0 | il villaggio è travolto ma **lo spirito sopravvive**: avanzi "ferito" (perdita di popolazione, un edificio danneggiato di un livello, voce di lore cupa nel Ledger). Prima di accettare → opzione **"Riprova l'Assedio"** |

L'esito è salvato (flag `eraN_assedio_esito`) e **non si rigioca** al reload.

## 8. Architettura tecnica (Godot 4, fit col codice esistente)

Nuova scena **`scenes/siege/siege.tscn`** (root `Node2D`, script `scripts/siege/siege.gd`),
istanziata da `main.gd` al punto di transizione (vedi §9). Sotto-componenti:

- **Corsie**: `Path2D` (curva dal bordo destro al villaggio) × 3. I nemici sono
  `PathFollow2D` che incrementano `progress` in `_process` (velocità per tipo). Niente
  NavigationServer: percorsi fissi, leggeri e deterministici — coerente con l'approccio
  procedurale del gioco (il villaggio è già tutto posizionato a mano).
- **Nemico** — `scenes/siege/enemy.tscn` (`Area2D` + `Sprite2D` + barra HP piccola):
  espone `hp`, `velocita`, `danno_villaggio`; segnali `morto(ricompensa)` e
  `arrivato_al_villaggio(danno)`.
- **Difensore** — `scenes/siege/defender.tscn` (`Node2D` + `Area2D` range): targeting
  (primo nel range / più avanti verso il villaggio), spara su `Timer` di cooldown.
- **Proiettile** — `scenes/siege/projectile.tscn`: tween fino al bersaglio → applica
  danno (o effetto: slow/AoE).
- **Boss** — `scenes/siege/boss.tscn` (estende l'enemy): HP grande, macchina a stati
  (marcia / abilità / infuria), abilità da `BossData`.
- **Spawner** ondate: legge `WaveData` dell'era; `Timer` per gli intervalli; segnali
  `ondata_iniziata(n)`, `tutte_ondate_finite`.
- **Villaggio (base)**: `Area2D` a sinistra con `hp_villaggio` (da Costruzione +
  popolazione). Nemico che arriva → `-danno`. `hp <= 0` → esito "Sopraffatto".
- **Schieramento**: riusa `draggable_item.tscn` / `drop_zone.tscn`; valuta = Risorse
  d'assedio.
- **Init dalle stat**: `siege.gd._inizializza_da_stat()` costruisce roster, budget,
  HP villaggio, alleati/ostili leggendo `GameState`.
- **UI**: tema bronzo (`UiStyle`); barra ondata, barra risorse, barra HP boss, banner
  ondata — via codice come il resto del gioco.
- **Audio**: `AudioManager` — musica battaglia + sfx colpo/ruggito/vittoria (fallback su
  `era_transition` e sfx esistenti finché non ci sono tracce nuove).
- **Esito → main**: segnale `assedio_concluso(esito)`; `main.gd` applica
  ricompense/conseguenze e prosegue con la title-card di transizione.

### Resource data-driven (nuove)

```
scripts/data/unit_data.gd   (class_name UnitData)  # hp, danno, range, rateo, costo, tipo_bersaglio, effetto, sprite
scripts/data/wave_data.gd   (class_name WaveData)  # ondate: [{tipo, conteggio, intervallo, corsia}], per era
scripts/data/boss_data.gd   (class_name BossData)  # hp, velocita, abilita:[{tipo,cooldown,danno,raggio}], soglia_furia, sprite
```

### File nuovi (riassunto)

```
scenes/siege/siege.tscn · enemy.tscn · defender.tscn · projectile.tscn · boss.tscn
scripts/siege/siege.gd · enemy.gd · defender.gd · projectile.gd · boss.gd
scripts/data/unit_data.gd · wave_data.gd · boss_data.gd
data/siege/era1/ (waves.tres, boss.tres, units/*.tres)
data/siege/era2/ (waves.tres, boss.tres, units/*.tres)
```

## 9. Punto d'innesto in `main.gd`

Oggi `_avvia_prossima_quest()` quando non ci sono più quest e `era1_completata` è vero
chiama `_show_transizione_a_era2()`. Si inserisce qui:

```
_avvia_prossima_quest():
    ...nessuna quest...
    era 1 completata e assedio NON ancora fatto  → _avvia_assedio(1)
    era 2 completata e assedio NON ancora fatto  → _avvia_assedio(2)
    era 1 completata e assedio fatto             → _show_transizione_a_era2()  (come ora)
    era 2 completata e assedio fatto             → _show_ending()             (come ora)

_avvia_assedio(era):
    istanzia siege.tscn, _inizializza_da_stat(), collega assedio_concluso
on assedio_concluso(esito):
    GameState.set_flag("eraN_assedio_fatto"), salva esito, applica ricompense/conseguenze
    _avvia_prossima_quest()   # ora prosegue verso transizione/ending
```

Così l'Assedio è un "gate" della transizione senza toccare la logica di quest/ending.

## 10. Fasi di implementazione (incrementali, ognuna verificabile a schermo)

Filosofia: **giocabile prima, bello poi**. Ogni fase si verifica con lo shoot harness
(`tools/shoot.gd`, vedi [[reference-godot-testing]]) e idealmente avviando il gioco
(vedi [[feedback-verifica-a-schermo]]).

- **Fase A — Scheletro giocabile** [CODICE, placeholder art]: scena Assedio, 1 corsia,
  nemici-forma che marciano, villaggio con HP, 1 difensore piazzabile che spara,
  win/lose base. Da qui "si vede funzionare".
- **Fase B — Stat → esercito** [CODICE]: `_inizializza_da_stat()`, budget Risorse,
  3–4 tipi di unità, 3 corsie, alleati/ostili dai rapporti.
- **Fase C — Boss + abilità** [CODICE]: entità boss, barra HP, 2–3 abilità telegrafate,
  fasi, entrata cinematica.
- **Fase D — Ondate complete** [CODICE]: `WaveData` per era, banner, pause, difficoltà
  crescente, nemici per era.
- **Fase E — Juice + UI bronzo** [CODICE]: screen shake, hit-flash, particelle, SFX,
  barre stilizzate, schermate vittoria/sconfitta.
- **Fase F — Integrazione + esiti** [CODICE]: hook in `main.gd`, ricompense, trofei
  Ledger, conseguenze no-game-over, save.
- **Fase G — Art** [ASSET]: sostituzione placeholder con sprite (vedi prompt in
  `Docs/08-asset-prompts.md` §P7). **Tutto con fallback**: il gioco resta giocabile
  senza art.
- **Fase H — Balance + verifica** [CODICE]: tuning HP/danni/budget, check in
  `tools/balance_sim.py` (con stat "medie da fine era" l'Assedio è vincibile con
  sfida), screenshot di tutte le fasi.

## 11. Balance

L'Assedio **non deve rompere** il bilanciamento dei 6 finali (le sim non lo usano): è
una leva player-driven come il villaggio. Tuning di riferimento: stat medie di fine era
→ Assedio vincibile con un minimo di strategia; stat alte → comodo; stat basse → duro
ma mai impossibile (e comunque no-game-over). Aggiungere a `balance_sim.py` un check
"DPS difensori × durata ≥ HP totali nemici+boss" per i profili tipici.

---

*File vivo. Stato e checklist operativa nel master plan `Docs/12-roadmap.md`.*

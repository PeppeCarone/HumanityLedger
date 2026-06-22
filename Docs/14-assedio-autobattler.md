# 14 — L'Assedio 2.0: auto-battler a corsia singola (REDESIGN)

> Sessione 2026-06-22. Richiesta utente: **rifare completamente il boss fight**. Da
> tower-defense a 3 corsie (doc `11`) a un **auto-battler / line-battle a corsia singola**
> con economia a monete, evocazione illimitata, progressione profonda delle truppe, e boss
> con cambio-fase cinematografico. Questo doc è la spec di riferimento; il doc `11` resta
> come storia del TD precedente.
>
> **Vincolo asset (2026-06-22):** HiggsField connesso ma **0 crediti** → niente generazione.
> Si usa **arte-codice temporanea** (placeholder via `_draw`, come Fase A). Quando l'utente
> ricarica i crediti → genero gli sprite veri e li cablo (fallback già pronto).

---

## 1. Il campo: una strada sola

Niente più 3 corsie. **Una grande strada orizzontale**:
- **Sinistra (~0–20%)**: il **villaggio** con barra HP. Il tuo lato.
- **Centro–destra**: la strada dove gli eserciti si scontrano.
- **Destra (spawn)**: da dove entrano le ondate nemiche, marciando verso sinistra.

Le tue unità evocate si **auto-posizionano in formazione** sul lato **sinistro vicino al
villaggio**, occupando **tutta la larghezza della strada** in ranghi sensati (fronte che
ingaggia i nemici in arrivo; le nuove unità riempiono dietro/ai lati). Tengono la linea e
combattono: è un **line-battle**, non un TD a piazzole.

## 2. Economia: monete (∞ evocazioni)

- Hai delle **monete** (valuta d'assedio). Si guadagnano **uccidendo i nemici** a ogni ondata.
- Con le monete **evochi unità** (numero **illimitato** finché hai monete): clic sulla carta
  → l'unità appare e si schiera da sola in formazione.
- Le monete servono **anche a potenziare** le truppe (vedi §3).
- Budget iniziale + accumulo derivati dalle stat (Tesoro/Risorse/Popolo), come oggi.

## 3. Progressione truppe: Lv1 → Lv3 (abilità) → Lv5 (ascensione)

Ogni **tipo** di truppa (Tiratore/Bloccatore/Sciamano/Totem, skin per era) sale di livello
spendendo monete. Il potenziamento **migliora le statistiche** e, alle soglie:

| Livello | Cosa succede |
|---|---|
| **Lv1–2** | solo stat (danno/HP/raggio/cadenza crescono) |
| **Lv3** | **cambia aspetto** + sblocca una **nuova abilità** (attiva o passiva di tipo) |
| **Lv4** | altre stat |
| **Lv5 — ASCENSIONE** | **forma finale** (aspetto nuovo) + **abilità ultima** dedicata della truppa + un **effetto passivo** permanente |

- Ogni abilità/effetto ha un **tooltip bello e chiaro** (cosa fa, valori, come sfruttarla).
- Il potenziamento è **per-tipo** (potenzi "il Tiratore" → tutti i tiratori salgono) **oppure
  per-unità**? → *Decisione di design: per-TIPO* (più leggibile e strategico; evita micro-gestione
  di N unità infinite). Da confermare con l'utente se preferisce per-unità.

### Archetipi e progressione (Era 1, bozza)
- **Cacciatore (Tiratore)** — Lv3: *Freccia perforante* (colpo che attraversa più nemici).
  Lv5 *Pioggia di lance* (ultimate AoE) + passivo *Mira* (+crit sui nemici feriti).
- **Guerriero (Bloccatore)** — Lv3: *Scudo di pelli* (riduce danno area vicino). Lv5
  *Grido di guerra* (ultimate: stordisce i nemici davanti) + passivo *Roccia* (rigenera HP).
- **Sciamana (Supporto)** — Lv3: *Gelo* potenziato (slow più forte+area). Lv5 *Tempesta di
  ghiaccio* (ultimate: congela un'ondata) + passivo *Aura* (rallenta sempre i vicini).
- **Totem del Fuoco (AoE)** — Lv3: *Brace* (lascia fuoco a terra). Lv5 *Eruzione* (ultimate:
  colonna di fuoco) + passivo *Calore* (danno continuo ad area).

## 4. Ondate: 6 totali, dinamiche, con mini-boss e boss finale

- **6 ondate** per Assedio, più dinamiche: **eserciti spreddati** sulla strada (gruppi misti),
  **nemici con abilità** (caricatore, scudato, evocatore minion, risanatore, ecc.).
- **Ondata 3 → MINI-BOSS** (creatura intermedia, sua mini-meccanica).
- **Ondata 6 → BOSS FINALE** che **evoca anche lui un esercito** (rinforzi durante lo scontro).
- Banner d'ondata + intel da Spionaggio (come oggi).

## 5. Boss: cambio fase al 50% + ultimate cinematografica

Ogni boss (mini-boss e boss finale) ha un'**abilità ultima**:
- Si attiva **per la prima volta al 50% HP** (cambio fase): il boss **cambia aspetto**,
  **diventa più forte** (stat/abilità su), e **usa l'ultimate**.
- **Prima attivazione = cinematica**: il gioco si **ferma** (hitstop/slow), camera si
  **concentra sul boss** che si **arrabbia e si trasforma**, poi scatena l'ultimate.
- **Volte successive**: usa l'ultimate **normalmente** (niente cinematica), e **a scalare**
  (cooldown crescente / potenza calante) così **non vince per ripetizione**.
- Mantiene anche il kit base (telegrafi) + lo **stagger/VULNERABILE** già fatto (resta valido:
  finestra di burst per il giocatore).

## 6. Architettura tecnica (fit col codice esistente)

Si **evolve** `scripts/siege/` (non riscrittura da zero): riusa boss/nemico/proiettile/HUD/
esiti/integrazione `main.gd`. Cambiamenti chiave:
- **1 corsia**: `LANE_Y` → una banda; il villaggio occupa tutta l'altezza utile a sinistra.
- **Formazione auto**: nuovo sistema che dispone le unità in ranghi a sinistra (riempie la
  larghezza), invece delle piazzole. Le unità ingaggiano i nemici nel loro raggio.
- **Economia monete + evocazione ∞**: barra monete; carte-unità che evocano; niente limite
  piazzole.
- **Progressione per-tipo Lv1–5**: stato dei livelli + sblocco abilità/ascensione + tooltip.
  Nuove `class`/dati per le abilità.
- **Ondate 6 + mini-boss + boss-evoca-esercito**: estende `_prepara_ondate`.
- **Boss ultimate + cambio fase 50% cinematico**: estende `boss.gd` (nuovo stato "trasforma"
  con hitstop/zoom; ultimate per archetipo; scaling anti-ripetizione).
- **Nemici con abilità**: estende `enemy.gd` (caricatore/scudato/evocatore/risanatore).
- **Asset**: arte-codice temporanea ovunque; sprite veri agganciati per nome quando ci sono.

### Fasi di implementazione (incrementali, ognuna verificabile)
- **F1 — Scheletro corsia singola**: 1 strada, villaggio, spawn da destra, **evocazione a
  monete + auto-formazione** a sinistra, unità che combattono, win/lose. *"Si vede funzionare".*
- **F2 — Economia + progressione**: monete da kill, **upgrade per-tipo Lv1–5** con sblocco
  abilità Lv3 / ascensione Lv5 + **tooltip**. Effetti delle abilità.
- **F3 — Ondate 6 + nemici con abilità + mini-boss (w3)**.
- **F4 — Boss finale (w6) che evoca esercito + ultimate + cambio fase 50% cinematico**.
- **F5 — Juice/UI/bilanciamento** (playtest con `tools/playtest_assedio.tscn`) + asset veri
  quando ci sono i crediti HiggsField.

## 7. Bilanciamento (dal playtest 2026-06-22)

Il vecchio TD era **troppo facile** (difesa surclassa l'attacco, villaggio mai in pericolo).
Il nuovo modello deve avere **tensione reale**: gli eserciti nemici devono poter **sfondare**
se non evochi/posizioni/potenzi bene; il boss finale (con esercito + ultimate) è la prova
vera. No game over (D024): l'esito modula ricompense. Verificare ogni fase col playtest
automatico.

---

*File vivo. Doc storico del TD a 3 corsie: `11-boss-fight.md`.*

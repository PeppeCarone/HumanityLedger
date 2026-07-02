# HUMANITY LEDGER — Game Design Document

*Versione 1.0 — Consegna esame Sviluppo Videogiochi, luglio 2026*
*Engine: Godot 4.6 (GDScript) · Piattaforma: Windows Desktop*

---

## 1. Visione

**Pitch.** Sei lo *Spirito anonimo del popolo*: una coscienza senza nome che attraversa le ere
e guida una civiltà dalle pitture rupestri alle soglie del futuro. Non governi con i menù:
**prendi decisioni trascinando le strategie sui consiglieri che le sostengono**, e ogni scelta
resta scritta nel *Ledger* — il libro mastro dell'umanità.

**Genere.** Gestionale narrativo a decisioni (drag & drop) + city-builder leggero + **tower
defense auto-battler** (L'Assedio) come climax di fine era.

**Tono.** Mito e memoria: "tomo illuminato" — bronzo, oro, pergamena; solenne ma leggibile.

### 1.1 I tre pilastri
1. **Ogni scelta resta.** Le decisioni muovono 8 statistiche, aprono quest, richiamano
   conseguenze a distanza di ere, sbloccano lore permanente nel Ledger (meta-progressione).
2. **Il villaggio è il protagonista.** Cresce a vista (stile Clash of Clans), produce Risorse,
   e **arma la difesa**: ciò che costruisci è ciò con cui combatti.
3. **Nessun game over.** Perdere una battaglia non ferma la storia: ne cambia il tono, le
   ricompense e le cicatrici. Si va sempre avanti.

---

## 2. Core loop

```
DECISIONE (drag & drop su un consigliere)
   → conseguenze: ±stat, popolazione, rapporti, flag narrativi
   → PRODUZIONE Risorse (dagli edifici)
COSTRUISCI / MIGLIORA il villaggio (Risorse + gate Costruzione)
   → +stat tematica  → +bonus d'ASSEDIO (arsenale)
QUEST di era (catene narrative, catastrofi, mystery)
FINE ERA → L'ASSEDIO (tower defense: le stat diventano l'esercito)
   → Era successiva … → DUELLO FINALE: L'ULTIMO DIO → EPILOGO (6+1 finali)
```

---

## 3. Sistemi di gioco

### 3.1 Le 8 statistiche
Militare · Tesoro · Diplomazia · Scienza · Legge · Spionaggio · Popolo · Costruzione (0–100).
Sono la memoria meccanica delle scelte **e il generatore dell'esercito** nell'Assedio (§4.3).

### 3.2 Decisioni e consiglieri
- 2 ere giocabili (Paleolitico → Regno Mitico), ~40 decisioni data-driven (`.tres`), 8
  consiglieri per era con ritratto e archetipo.
- Ogni decisione offre 2–4 **strategie**: si gioca trascinando la carta-azione sul consigliere
  che la accetta (feedback di colore/accento per bersaglio).
- Prerequisiti su stat (opzioni bloccate con motivo), effetti su stat/popolazione/rapporti,
  richiami narrativi cross-era.

### 3.3 Villaggio, Risorse e ARSENALE
- **Risorse**: valuta prodotta a ogni decisione dagli edifici (base 2 + livelli, ×2 per gli
  edifici economici). Si spende per costruire (10) e migliorare (14/24, gate Costruzione 30/55).
- 6 lotti per era, edifici a 3 livelli con arte per stadio, traguardi con ricompense.
- **Arsenale** — ogni edificio arma l'Assedio (mostrato in pannelli, tooltip e nella card
  pre-battaglia "Il tuo villaggio ti arma"):

| Categoria | Effetto in battaglia | Era 1 | Era 2 |
|---|---|---|---|
| **muro** | +14 HP villaggio per livello | Palizzata | Torre, Mura |
| **monete** | +5 monete iniziali per livello | Essiccatoio | Mercato |
| **truppe** | 1 unità gratis ogni 3 livelli (max 4) | Tenda, Capanna | Tempio |
| **livello** | truppe partono di livello più alto (max +1) | Focolare, Totem | Fonderia, Archivio |

- Le Risorse avanzate valgono monete di guerra (÷4) → l'economia non muore mai.
- Catastrofi gravi possono far crollare di un livello un edificio (mai sotto Lv1).

### 3.4 Diplomazia, quest, Ledger
- 4 civiltà con rapporti [-5..+5]: alleati = truppe gratuite nell'Assedio; ostili = ondate
  rinforzate.
- Quest per era (7 catene), catastrofi (carestia, peste…), trama mystery sbloccabile.
- **Ledger** (meta, persistente tra le run): lore, artefatti equipaggiabili (bonus passivi),
  eventi; **NG+ "Eone"**: +15% minaccia e mura -5% per ciclo, con mutatori tematici e il
  **7° finale segreto** ("Il Cerchio Compiuto") come ricompensa nascosta.
- 3 difficoltà (Sereno / Equilibrato / Implacabile), persistite nelle opzioni.

---

## 4. L'ASSEDIO (tower defense auto-battler)

Una sola grande strada; il villaggio a sinistra, la minaccia da destra. Niente piazzole:
**evocazione illimitata** — clic sulla carta, l'unità esce dal cancello e si schiera da sola.

### 4.1 Economia
Monete iniziali da Tesoro/Popolo/Risorse (+arsenale). Bounty a uccisione. Nel duello finale
un *drip* passivo sostituisce il farming (niente add).

### 4.2 Roster (personaggi dell'era, per archetipo)
| Archetipo | Era 1 | Era 2 | Ruolo | Scala con |
|---|---|---|---|---|
| Tiratore | Cacciatore | Arciere | danno singolo a distanza | Militare |
| Bloccatore | Guerriero | Legionario | muro di mischia (HP) | Costruzione |
| Sciamano | Sciamano del Gelo | Sacerdote | rallenta ad area | Scienza |
| Caster | Piromante tribale | Mago del Fuoco | danno ad area | Scienza+Spionaggio |

### 4.3 Progressione per-tipo Lv1→Lv5
- Potenzia dalla carta (costo crescente); vale anche per le unità già in campo.
- **Lv3 = nuova abilità** (Freccia perforante, Scudo di pelli, Gelo, Brace).
- **Lv5 = ASCENSIONE**: nuovo sprite, **ultimate periodica** con callout a schermo e VFX
  dedicato (Pioggia di lance, Grido di guerra, Tempesta di ghiaccio, Eruzione) **+ passivo
  visibile** (crit oro della Mira, +N verde della Roccia, aura di gelo perenne, Calore).
- Le ultimate delle unità a tiro hanno **gittata doppia** e **mirano al nemico più vicino**.

### 4.4 Ondate e nemici
6 ondate: 2 leggere → **mini-boss caster** (bombardamento telegrafato, raffiche di minion via
portale) → 2 con nemici-abilità → **BOSS**. Abilità nemiche: caricatore (sfonda i bloccatori),
scudato, evocatore, risanatore, scheletro che risorge — ognuna con glifo leggibile.

### 4.5 Boss d'era
Colosso (Era 1, mischia sismica) e Drago (Era 2, fuoco a distanza): kit distinti, abilità
telegrafate su cerchio/zona, **tenuta/stagger** (finestra VULNERABILE che premia il burst),
3 fasi con barre piene, trasformazione **cinematografica** (hitstop, letterbox, title-card),
ultimate a zone evitabili con potenza calante. Anti-stallo berserk. FX per-archetipo.

### 4.6 Esiti
Immacolata / Trionfo / Fatica / Sopraffatto — modulano ricompense, Ledger e cicatrici.
Mai game over.

---

## 5. IL DUELLO FINALE — "L'Ultimo Dio caduto"

Dopo l'Assedio dell'Era 2, il mito che si rifiuta di morire sbarra la strada verso ciò che
non è ancora stato forgiato. **Duello puro**: nessuna ondata, solo il Dio — tarato
sull'arsenale del villaggio.

| Fase | Forma | Comportamento |
|---|---|---|
| **I — Il Verdetto** | Idolo di pietra e oro | marcia; Verdetto (zona ORO telegrafata), Monito, Lacrime di fuoco |
| **II — L'Idolo si erge** | **colosso a schermo pieno**, immobile a destra | +50% vita, +14 armatura; bombarda da lontano; **tutta l'armata lo colpisce ignorando la gittata** (i guerrieri scagliano lance) |
| **III — Il Crepuscolo** | spettro cosmico (più grande, aura dorata pulsante) | torna a marciare; nuova abilità **Lame del Crepuscolo** (2 fasce orizzontali telegrafate: cambia fila!) |

- **GIUDIZIO DIVINO** (ultimate): colonne di luce che calano dal cielo su zone telegrafate oro;
  alla morte del Dio il Giudizio cala su di lui.
- Vittoria → epilogo-soglia **"LA SOGLIA — continua…"** (gancio per il futuro del progetto);
  sconfitta → si prosegue comunque, nel buio.

---

## 6. UI / UX

- HUD: griglia 2×4 delle stat con barre animate e tooltip; barra Risorse; pannelli modali con
  cornice ornata 9-slice e margini disciplinati (il testo non tocca mai i fregi).
- Tooltip ricchi ovunque (edifici con effetto-Assedio, carte-unità con stat reali e sblocchi).
- Callout di battaglia (nomi delle abilità), numeri di danno accumulati (nessun colpo
  "sparisce"), banner d'ondata su cartiglio.
- **Post-processing globale**: vignette morbida + grade caldo + grana film + aberrazione ai
  bordi — il look "tomo illuminato" su ogni schermata.
- Intro cinematica skippabile (Ken Burns, 3 beat), menu con tagline ed Eone badge.

## 7. Arte & audio

- Arte generata con pipeline AI (Gemini/Nano Banana) su prompt d'art-direction interni
  (`Docs/08`), poi **rifinita a mano**: ritagli, ricentraggio sul baricentro, rimozione
  watermark/checker, cablaggio **fallback-safe** (se un PNG manca, il gioco disegna un
  placeholder coerente — mai crash).
- Palette: bronzo #99703D · oro #E8C87A · cuoio #1C1612.
- Musica originale per era + **musica dinamica** (tema teso nell'Assedio, dissolvenze).

## 8. Architettura tecnica

- **Autoload**: GameState (stat/flag/save-state), Ledger (meta+NG+), QuestManager, Diplomacy,
  NarrativeLog, SaveSystem (save.json), AudioManager (musica dinamica, difficoltà, settings),
  UiStyle (tema globale + 9-slice), PostFX (shader screen-space).
- **Data-driven**: decisioni/quest/strategie/personaggi/finali in `.tres` sotto `data/`;
  contenuti nuovi senza toccare codice.
- **Assedio**: `scripts/siege/` (siege.gd arena + enemy/defender/projectile/boss), tutto
  costruito via codice (niente .tscn), texture con prewarm anti-scatto.
- **QA automatica** (`tools/`): `validate_scenes` (integrità), `playtest_curve`
  (giocatore-attivo su 3 build × 2 ere), `playtest_assedio`, `playtest_finale` (duello),
  `shot_arsenale`/`shoot` (verifica visiva a screenshot). I playtest sono **isolati dallo
  stato utente** (NG+/difficoltà non falsano i numeri).
- Salvataggi in `user://`: `save.json` (run), `ledger.json` (meta), `settings.cfg`.

## 9. Finali

6 epiloghi guidati dalle stat dominanti e dalle scelte (Guerra, Prosperità, Scienza, Alleanza,
Industria, Futura) + **finale segreto** "Il Cerchio Compiuto" (Eone ≥1 + condizioni nascoste)
+ epilogo-soglia del Duello. Footer con Ricomincia / Nuovo Ciclo+ / Ledger.

## 10. Post-consegna (direzioni già progettate)
Era 3 "Futuro" (asset già presenti, sistema data-driven pronto) · modalità Assedio
Endless/Boss-Rush · lealtà e micro-archi dei 16 consiglieri · SFX/tema audio del duello.

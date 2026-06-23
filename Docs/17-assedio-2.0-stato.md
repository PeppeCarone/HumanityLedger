# 17 — L'Assedio 2.0: stato, guida e come testarlo

> Stato al 2026-06-23. Implementazione **completa F1→F5** della spec
> [`14-assedio-autobattler.md`](14-assedio-autobattler.md). Branch `claude/polish-grafico`,
> commit `f5f2123` (+ retheme truppe). Codice in `scripts/siege/`.

## 1. Cos'è
L'Assedio è la feature-climax di fine era: un **auto-battler / line-battle a corsia singola**
(redesign del vecchio tower-defense a 3 corsie, doc `11`). Una grande strada orizzontale: il
**villaggio** a sinistra (con HP), i **nemici** entrano da destra e marciano verso il villaggio.
Tu **evochi** unità con le **monete** e le tue **statistiche** alimentano l'esercito. Nessun
game over (D024): l'esito (immacolata / trionfo / fatica / sopraffatto) modula le ricompense.

## 2. Il loop di gioco
- **Campo a corsia singola**: una banda (`ROAD_TOP..ROAD_BOTTOM`), villaggio a sinistra, spawn
  a destra. I nemici si distribuiscono su tutta l'altezza (`N_FILE_SPAWN` file).
- **Economia a monete**: budget iniziale dalle stat (Tesoro/Risorse/Popolo); guadagni monete
  **uccidendo** i nemici. Le monete servono a **evocare** e a **potenziare**.
- **Evocazione illimitata**: clic su una carta → l'unità **esce dal villaggio camminando** e si
  mette in formazione. Niente piazzole, nessun limite (finché hai monete).
- **Auto-formazione che copre l'altezza**: i bloccatori formano il **fronte** (coprono tutta la
  corsia), tiratori/sciamani/piromanti il **retro**. La linea si riforma a ogni evocazione.
- **Combattimento per prossimità** (line-battle): i bloccatori fermano i nemici nella loro
  banda verticale; gli altri colpiscono a raggio.
- **Esiti**: sopravvivi a tutte le ondate → immacolata/trionfo/fatica secondo l'HP rimasto;
  HP a 0 → sopraffatto (con "Riprova").

## 3. Le truppe (4 archetipi · personaggi per era)
Le meccaniche sono costanti; cambia il **personaggio** per era (sono PERSONE, non oggetti).

| Archetipo | Ruolo | Scala con | Era 1 (Paleolitico) | Era 2 (Regno Mitico) |
|---|---|---|---|---|
| tiratore | colpisce a distanza | Militare | **Cacciatore** | **Arciere** |
| bloccatore | muro in mischia (HP) | Costruzione | **Guerriero** | **Legionario** |
| sciamano | rallenta in aura | Scienza | **Sciamano del Gelo** | **Sacerdote** |
| totem (caster d'area) | danno ad area | Scienza/Spionaggio | **Piromante tribale** | **Mago del Fuoco** |

> Nota: l'archetipo "totem" è l'id interno del **caster d'area**, ora un personaggio
> (Piromante/Mago). Carica l'arte `unit_caster` (vedi §8); finché manca → placeholder a figura.

### Progressione per-TIPO Lv1→Lv5 (F2)
Potenziando un tipo (pulsante **Potenzia** sulla carta) salgono **tutte** le unità di quel tipo,
anche già in campo. Lv1-2/4 = stat; **Lv3** = nuova abilità + nuovo aspetto (gemma); **Lv5 =
ASCENSIONE** = forma finale (corona+aura) + ultimate periodica + passivo. Tooltip con valori
reali e prossimo sblocco.

| Tipo | Lv3 abilità | Lv5 ultimate | Lv5 passivo |
|---|---|---|---|
| Cacciatore | Freccia perforante | Pioggia di lance | Mira (crit sui feriti) |
| Guerriero | Scudo di pelli | Grido di guerra (stordisce) | Roccia (rigen HP) |
| Sciamano | Gelo (più forte/ampio) | Tempesta di ghiaccio (congela) | Aura perenne |
| Piromante | Brace (fuoco a terra) | Eruzione | Calore (danno aura) |

## 4. Ondate, nemici con abilità, mini-boss (F3)
**6 ondate**: w1-w2 leggere → **w3 MINI-BOSS** → w4-w5 → **w6 BOSS finale**. Nemici con
abilità (glifi leggibili): **caricatore** (scatta e SFONDA la linea), **scudato** (scudo
frontale che si rompe), **evocatore** (chiama minion), **risanatore** (cura i vicini). Il
mini-boss (Era1 *Lo Stregone della Tribù*, Era2 *Il Tessitore d'Ossa*) evoca minion.

## 5. Boss finale 2.0 (F4)
Il boss (Era1 Colosso, Era2 Drago) **evoca un esercito** di rinforzi durante lo scontro, e al
**50% HP** fa un **cambio fase cinematografico** (hitstop + zoom + vignetta): cambia aspetto
(aura cremisi), diventa più forte e scatena l'**ULTIMATE** (devastazione a tutto campo). Le
volte successive l'ultimate torna a **potenza calante / cadenza crescente** (niente vittoria
per ripetizione). Mantiene il kit base (telegrafi), lo **stagger/VULNERABILE** e la frenesia.

## 6. Bilanciamento / tensione (F5)
Il vecchio TD era troppo facile (villaggio mai in pericolo). Ora i **caricatori sfondano**: chi
gioca **passivo** viene **sopraffatto**; chi **evoca/potenzia attivamente** vince ma **con
danni** (trionfo), finendo quasi senza monete (economia stretta). Verificato con
`playtest_curve` su build debole/medio/forte.

## 7. Come testarlo (Godot 4.6.1, vedi [[reference-godot-testing]])
Usare la **console exe** per catturare l'output.
- Compila/importa: `godot_console --headless --path . --import` (exit 0 = ok).
- Valida le scene: `godot_console --headless --path . --script res://tools/validate_scenes.gd` → `VALIDATE_DONE failures=0`.
- Playtest difficoltà (giocatore passivo forte): `godot_console --headless --path . tools/playtest_assedio.tscn` → `PLAYTEST_ESITO=...`.
- **Curva** (giocatore attivo, 3 build): `godot_console --headless --path . tools/playtest_curve.tscn` → `CURVA DEBOLE/MEDIO/FORTE -> ...`.
- In gioco: tasto **B** avvia l'Assedio dell'era corrente al volo (debug, `main.gd`).

## 8. Stato asset
Tutto è **arte-codice fallback-safe**: il codice usa forme/placeholder finché il PNG non c'è,
poi lo aggancia per nome. Mancano gli sprite dei **nuovi nemici F3**, del **caster d'area**
(Piromante/Mago) e dei **mini-boss**. **HiggsField è senza crediti** → vedi il brief asset
[`18-asset-brief-perplexity.md`](18-asset-brief-perplexity.md) (da mandare a Perplexity per i
prompt Nano Banana). Convenzione: `Assets/art/siege/era<N>/<nome>.png`, vista laterale, sfondo
trasparente; difensori guardano a **destra**, nemici a **sinistra**.

## 9. File / architettura
`scripts/siege/`: `siege.gd` (SiegeArena: campo/HUD/economia/ondate/formazione/fx/esiti),
`defender.gd` (4 ruoli + progressione + abilità), `enemy.gd` (marcia + abilità nemiche),
`boss.gd` (SiegeBoss: stati + cambio fase + ultimate), `projectile.gd` (pierce/brace).
Integrazione in `scripts/main.gd` (`_avvia_assedio`/`_on_assedio_concluso`).

## 10. Stato e cosa resta
- **F1→F5 implementate e verificate**, committate su `claude/polish-grafico`.
- **Resta**: asset veri (quando HiggsField ha crediti — brief in doc 18); fine-tuning ondate
  Era 2 (il playtest automatico è Era 1); sync di `tools/balance_sim.py` con le nuove ondate.

*File vivo. Spec di riferimento: [`14-assedio-autobattler.md`](14-assedio-autobattler.md).*

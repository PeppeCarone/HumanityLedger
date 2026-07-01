# Docs/20 — Arsenale del villaggio + Boss finale "L'Ultimo Dio caduto"

Documento di lavoro (agg. 2026-07-01). Tre cose:
1. **Arsenale**: Risorse + potenziamenti edifici resi *utili* (FATTO ✓).
2. **Boss finale** "L'Ultimo Dio caduto": duello puro TD di fine-contenuto (FATTO, codice ✓ — arte da generare).
3. **Prompt asset** perfetti + analisi (§3).

---

## 1. Arsenale del villaggio — FATTO e verificato

Ogni edificio, oltre alla stat, **arma l'Assedio** con un bonus concreto e mostrato.
Mappa `main.gd :: EDIFICIO_ASSEDIO_ERA`; effetti: **muro**→+HP villaggio (`ARS_HP_PER_LV=14`),
**monete**→+monete iniziali (`ARS_MONETE_PER_LV=5`), **truppe**→unità gratis (`somma_liv/3`, cap 4),
**livello**→truppe di partenza più alte (`1+somma_liv/4`, cap 3), **scorte**→Risorse÷4 come monete.
Si vede: riga "Assedio:" nei pannelli edificio/costruzione, tooltip edifici (hover), card
"— IL TUO VILLAGGIO TI ARMA —" prima di ogni battaglia. Verifica `tools/shot_arsenale.tscn`.

---

## 2. Boss finale — "L'Ultimo Dio caduto" (codice FATTO)

**Duello puro** dopo l'Assedio dell'Era 2, prima dell'epilogo. Nessuna ondata: solo il Dio, 3 fasi
cinematiche (riusa `SiegeBoss`), monete da drip, tarato sull'arsenale. Vincere → epilogo-soglia
"continua…". Codice: `main.gd` (`_avvia_boss_finale`/`_mostra_card_finale`/`_istanzia_finale`/
`_on_boss_finale_concluso`/`_mostra_epilogo_soglia`), `siege.gd` (flag `finale`, `_prepara_finale`,
redirect texture `finale/`, drip), `boss.gd` (`duello_puro`). Fallback-safe: senza arte il Dio è il
drago Era 2. **Restano: ARTE (§3) + balance del duello.**

### CONCEPT VISIVO scelto: **"L'Idolo che si desta"** — 3 fasi leggibili
Il mito che si rifiuta di morire = un **idolo colossale** del dio che si risveglia mentre muore.
- **Fase I — Il Verdetto:** IDOLO di pietra e oro annerito, semi-inghiottito dalla terra, *dormiente*
  ma con braci negli occhi. Monolitico, lento, schiacciante.
- **Fase II — L'Ira:** il guscio di pietra si **spacca**, luce d'oro fuso erompe dalle crepe, il volto
  vivo e adirato del dio brucia fuori dall'idolo. Radioso, terribile, più rapido.
- **Fase III — Il Crepuscolo:** il guscio si sgretola; il dio è ormai **luce morente e cenere che si
  disfa in stelle**, divinità che si dissolve con l'era del mito. Cosmico, disperato, a tutto campo.

Alternative (se preferisci, riadatto i prompt del boss): **B)** guardiano dai molti volti/braccia
(sereno→adirato→apocalittico); **C)** Dio-Sole morente (radioso→ira solare→eclissi/vuoto).

---

## 3. PROMPT ASSET — perfetti, pronti da incollare (Nano Banana)

**STILE COMUNE (metti in coda a ogni prompt sprite):** *"Painterly semi-realistic dark-fantasy
game art, dramatic cinematic rim lighting, tarnished bronze-gold with ash-grey palette, deep
shadows, high detail, SIDE PROFILE facing LEFT, full body, centered, transparent background, no
text, no watermark."* Sfondi = *matte painting 16:9, 1920×1080, no characters, no text*.
**Nomi-file ESATTI** → si cablano da soli (fallback all'Era 2 se manca). I `.import` sono gitignorati.

### 3.A — IL DIO, 3 fasi ★ OBBLIGATORI · `Assets/art/siege/finale/`
- **`boss.png`** (Fase I) — *"Colossal ancient idol of a forgotten god, hewn from cracked dark stone
  and tarnished gold, half-reclaimed by moss and earth, monumental and dormant — yet its carved eyes
  smolder with buried embers; broken halo, worn divine regalia, imposing silhouette."* + STILE COMUNE.
- **`boss_fase2.png`** (Fase II) — *"The same colossal god-idol AWAKENING: the stone shell splits
  along glowing seams as molten gold divine light bursts through, a wrathful radiant face and burning
  body breaking out of the cracked idol, halo reignited and blazing, heat-haze and rising embers,
  terrible and majestic."* + STILE COMUNE (più luce emissiva dorata).
- **`boss_fase3.png`** (Fase III) — *"The same god at the twilight of its existence: the stone shell
  shattered, its form now a tragic being of fading starlight and unraveling cosmic ash, divinity
  dissolving into constellations and embers, silhouette coming apart at the edges, a dying sun within,
  sorrowful and desperate."* + STILE COMUNE (luce oro-freddo + viola-vuoto).

### 3.B — ARENA ★ OBBLIGATORIA · `Assets/art/siege/finale/`
- **`campo.jpg`** — *"A liminal threshold at the edge of the world at twilight: a vast solemn ruined
  sanctum of a dying mythic age where reality frays toward an unwritten future — colossal broken
  divine architecture, toppled statues, a causeway of dim gold light fading into star-strewn darkness
  on the RIGHT (where the enemy comes from), brooding storm sky, cold and awe-inspiring."* Matte
  painting 16:9 1920×1080, palette bronzo-oro + indaco profondo, cinematic depth, no characters, no text.

### 3.C — CARD / KEY-ART (agganci già nel codice, fallback-safe)
- **`siege/finale/dio_keyart.png`** — key-art del Dio per la **card d'ingresso** ("L'ULTIMO DIO").
  *"Dramatic key-art of the last fallen god looming out of darkness toward the viewer — colossal deity
  of cracked stone and molten gold, wrathful yet sorrowful, broken halo, embers and ash swirling."*
  Cinematic splash, strong chiaroscuro, **inquadratura verticale/ritratto**, transparent or very dark
  background, no text. (Alto ~900–1200px.)
- **`finali/soglia.png`** — key-art dell'**epilogo "La Soglia"**. *"A luminous gateway/rift opening at
  the horizon beyond a small silhouetted village — a threshold onto an unwritten future, hopeful yet
  solemn, dawn-like gold glow piercing deep blue-black darkness, mythic wide vista."* Matte 16:9
  1920×1080, no text. (Mostrata velata dietro il testo.)

### 3.D — SCENA / DRESSING · `Assets/art/siege/finale/` (opzionali, fallback Era 2)
- **`roccaforte.png`** — *"The last bastion of a people at the world's edge: a battered but defiant
  stone-and-timber stronghold with tattered banners and small glowing braziers."* + STILE COMUNE.
- **`parapetto.png`** — *"A weathered stone parapet / low defensive wall section for a siege
  foreground, bronze-grey stone."* + STILE COMUNE.

### 3.E — FX · `Assets/art/siege/fx/` (opzionale, lo cablo io al carico)
- **`giudizio_divino.png`** — l'ultimate del Dio. *"A vertical pillar of blinding divine golden light
  striking down with a radiant rune-circle impact and sparks at the base, additive glow, centered on a
  pure transparent background, no scene."* Quadrato ~1024², transparent, no text.

### 3.F — UI / icone (opzionali)
- **`siege/finale/boss_bar.png`** — cornice barra-HP dedicata al Dio (oro annerito, rune). Se assente
  usa la barra condivisa. Lo cablo io.
- Icone arsenale `Assets/art/icons/siege/`: `bonus_muro`, `bonus_monete`, `bonus_truppe`,
  `bonus_livello` (32–64px, bronzo). Ora il testo basta; le renderebbero più belle.

### Analisi "serve altro?"
- **Unità del giocatore**: NO nuova arte — restano quelle dell'Era 2 (già fatte).
- **Nemici/add**: NESSUNO — è un duello puro (niente ondate).
- **Transizioni di fase**: già cinematiche via codice (letterbox + title-card + swap sprite
  `boss_fase2/3`). Un `fase{2,3}_splash.png` a tutto schermo sarebbe uno stretch — non necessario.
- **Audio**: un tema dedicato al duello sarebbe il tocco finale (ora usa `void_crown`). HiggsField/audio
  → in futuro; non blocca.

**Priorità minima per un finale "serio e bello": 3.A (Dio ×3) + 3.B (arena) + `dio_keyart` +
`soglia`.** Il resto è extra. Quando li carichi: li smisto, cablo FX/bar, e faccio il **balance del
duello** (HP Dio / drip / armatura) → poi push.

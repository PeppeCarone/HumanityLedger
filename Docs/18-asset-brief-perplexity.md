# 18 — Brief asset Assedio 2.0 (da incollare in Perplexity → prompt per Nano Banana)

> Stato 2026-06-23. Servono gli sprite dei contenuti nuovi dell'Assedio 2.0 (nemici con
> abilità F3, mini-boss, il caster d'area come personaggio). HiggsField è senza crediti, quindi
> li generi tu via Nano Banana. **Copia tutto il blocco "PROMPT PER PERPLEXITY" qui sotto e
> incollalo in Perplexity**: ti restituirà un prompt pronto per ogni asset. Poi metti i PNG nei
> percorsi indicati e il gioco li aggancia da solo (nessuna modifica al codice).

> Convenzioni del progetto (già nel codice): `Assets/art/siege/era<N>/<nome>.png`, sfondo
> **trasparente**, vista **laterale**, i **difensori (truppe tue) guardano a DESTRA**, i
> **nemici guardano a SINISTRA**. Stile coerente con gli asset esistenti (pittorico, semi-realistico).

---

## ✂️ PROMPT PER PERPLEXITY (copia da qui)

Sei un prompt-engineer esperto del modello di generazione immagini **Nano Banana**. Devo creare
gli sprite per un gioco strategico 2D a scorrimento laterale ("HumanityLedger"), ambientazione
**mitico-storica** che attraversa le ere (Era 1 = **Paleolitico/preistoria**; Era 2 = **Regno
Mitico**, medievale-fantasy). Per **ognuno** degli asset elencati sotto, generami **un prompt
pronto da incollare in Nano Banana** (in inglese, un paragrafo conciso), seguendo queste regole
di stile GLOBALI e poi le specifiche del singolo asset.

**Regole di stile globali (valgono per tutti):**
- Painterly, hand-painted 2D game art, semi-realistic, gritty, cinematic lighting, strong rim light, readable silhouette.
- **Single full-body character/creature, isolated on a FULLY TRANSPARENT background** (PNG alpha). No scene, no ground, no shadow plate, no text, no UI, no border.
- Vista laterale (profilo o 3/4). **Le TRUPPE del giocatore guardano a DESTRA**; i **NEMICI guardano a SINISTRA**.
- Inquadratura verticale, corpo intero, alta definizione (es. 832×1216), soggetto centrato.
- Palette coerente: Era 1 = ocra terrosi, pellicce, ossa, pietra, fuoco; Era 2 = acciaio, cuoio, toni cupi mitici, magia.
- Negative (per tutti): `no background, no text, no watermark, no frame, no multiple characters, no ground shadow`.

**Formato di output che voglio da te:** per ogni asset, una riga col **nome file** e sotto il
**prompt Nano Banana** pronto. Mantieni lo stile coerente tra tutti.

### Truppe del giocatore (PERSONAGGI, guardano a DESTRA)
1. `era1/unit_caster.png` — **Piromante tribale** (Era 1): sciamano-piromante del Paleolitico, una PERSONA che lancia braci/fuoco dalle mani, pelli e ossa, volto dipinto, NON un totem né un oggetto.
2. `era2/unit_caster.png` — **Mago del Fuoco** (Era 2): mago da regno mitico, una PERSONA in tunica che evoca fiamme, NON una catapulta né un oggetto.
3. `icons/siege/caster.png` — **icona** del caster d'area: glifo semplice di una fiamma stilizzata (icona piatta, leggibile in piccolo, su trasparente; non un personaggio).

### Nemici Era 1 — Paleolitico (CREATURE/PERSONE, guardano a SINISTRA)
4. `era1/enemy_bruto.png` — **Scudato**: bruto tribale con un grande scudo di pelli/ossa imbracciato sul davanti.
5. `era1/enemy_guaritore.png` — **Risanatore**: guaritore/medicine-man della tribù con erbe e amuleti, aura curativa verde tenue.
6. `era1/enemy_stregone.png` — **Evocatore**: stregone tribale oscuro che invoca spiriti, runa viola.
7. `era1/enemy_stregone_capo.png` — **MINI-BOSS "Lo Stregone della Tribù"**: sciamano-capo imponente e grande, copricapo con teschio cornuto, magia viola, minaccioso.
8. `era1/enemy_minion.png` — **Minion**: piccolo spirito/bestiola evocata, debole, rapido.

### Nemici Era 2 — Regno Mitico (guardano a SINISTRA)
9. `era2/enemy_scudiero.png` — **Scudato**: soldato corazzato con grande scudo di metallo.
10. `era2/enemy_sciamano_oscuro.png` — **Risanatore**: sciamano oscuro/chierico maligno che cura gli alleati.
11. `era2/enemy_negromante.png` — **Evocatore**: negromante incappucciato che rianima i non-morti.
12. `era2/enemy_tessitore.png` — **MINI-BOSS "Il Tessitore d'Ossa"**: grande tessitore di ossa, figura mitica fatta di ossa e fili oscuri, imponente.
13. `era2/enemy_minion.png` — **Minion**: piccolo scheletro/non-morto, debole, rapido.

(Fine del blocco da incollare in Perplexity.)

---

## Note per te (NON per Perplexity)
- Una volta generati i PNG, mettili nei percorsi sopra (cartelle già esistenti). Il gioco li
  carica per nome al prossimo avvio (fallback-safe: senza file usa i placeholder a codice).
- I vecchi `era1/unit_totem.png` (totem) ed `era2/unit_totem.png` (catapulta) sono **superati**
  dal nuovo `unit_caster`: puoi eliminarli quando vuoi (non sono più usati).
- Gli sprite truppe esistenti (Cacciatore/Guerriero/Arciere/Legionario/Sciamano) sono già buoni;
  rigenerali solo se vuoi uniformare lo stile.
- Boss (mammut Era 1, drago Era 2) e creature base (cinghiale/iena/orso, predone/scheletro/
  minotauro/golem) hanno già lo sprite.
- Dimensione a schermo gestita dal codice: conta la **leggibilità della silhouette** in piccolo.

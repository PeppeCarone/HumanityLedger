# 10 — Audit UI + Piano "villaggio attivo" e bellezza/giocabilità

> Sessione 2026-06-16. Ri-analisi visiva di tutte le schermate (screenshot reali via
> `tools/shoot.gd`) + audit art-direction + trasformazione del villaggio in gameplay
> attivo. Obiettivo: il gioco non deve essere solo "dialogo con scelte" ma avere
> gestione attiva del villaggio, ed essere **ordinato, bello e fluido**, oltre che funzionante.

---

## 1. Stato attuale (ri-analisi)

Il gioco è già **bello e coerente** (palette bronzo/oro/seppia painterly, font Cinzel+Alegreya).
Schermate forti: **menu**, **villaggio Era 1/2**, **epilogo**, **mappa-mondo**. Più deboli (look "prototipo"):
**pannelli modali** (build/upgrade: pulsanti grigi di default), **vista decisione** (molto spazio
vuoto scuro, testo piccolo), e mancanza di un **componente UI condiviso** (tema).

## 2. Fatto in questa sessione

- **Villaggio = builder attivo (D046)**: costruisci (lotto "+") e migliora (Lv1-3) edifici cliccabili;
  glow d'invito "potenziabile ora"; stelle/scala + lampo dorato.
- **Economia "Risorse"**: nuova valuta prodotta a ogni decisione (turno) dagli edifici (economici
  doppia); build/upgrade la spendono (gate Costruzione). Loop: decidi→produci→costruisci→produci di più.
- **Barra risorse** in alto (Risorse + produzione/turno) con "+N" che sale ogni turno.
- **Tema bronzo globale** (`UiStyle` autoload): tutti i Button coerenti, non più grigi.
- **Testo decisione** più grande (23px) e caldo; **scrim modale** più scuro (focus sul pannello).

## 3. Roadmap UI — TOP-12 (da audit art-direction, ordinata impatto/sforzo)

`[x]` fatto · `[~]` parziale · `[ ]` da fare. Tag: [STYLE] [LAYOUT] [ICON] [SMOOTH].

1. `[~]` **[STYLE] Componente modale bronzo condiviso** (build+upgrade): cornice pergamena, riga
   sotto il titolo, **pulsanti bronzo** (oro primario / outline secondario), tabella costi allineata
   con icone risorsa. *(scrim+tema fatti; resta la tabella costi + thumbnail edificio)*
2. `[x]` **[STYLE] Tutti i pulsanti in stile bronzo** (tema globale `UiStyle`).
3. `[ ]` **[LAYOUT] Ingrandire il cluster decisione +30-40% e centrarlo** verticalmente: lo spazio
   vuoto della caverna deve essere cornice, non maggioranza dello schermo.
4. `[x]` **[STYLE] Testo decisione ~23px off-white caldo**, leggibile.
5. `[ ]` **[ICON] Icone strategia = medaglioni circolari bronzo** (riusa lo stile dei medaglioni
   artefatto del Ledger, che è il miglior icon-work del gioco).
6. `[ ]` **[LAYOUT] Incorniciare il pannello stat di sinistra** (colonna pergamena ~300px, numeri
   allineati a destra, margini coerenti).
7. `[ ]` **[STYLE] Status chip (Inflazione/Conflitto) e Rapporti come badge bronzo** con icona/bordo.
8. `[x]` **[LAYOUT] Scrim modale più scuro** (0.72) + pannelli centrati.
9. `[ ]` **[SMOOTH] CTA "...ATTENDE IL TUO PARERE/DECIDI"** con riga bronzo + pulse; hover-glow
   coerente sulle piazzole costruibili.
10. `[ ]` **[STYLE] Stati "bloccati" del Ledger** (silhouette + lucchetto in medaglione) invece di "???";
    separatori verticali tra le colonne.
11. `[ ]` **[STYLE] Scrim dietro il testo** su schermate art-heavy (epilogo, cartiglio sul titolo mappa).
12. `[ ]` **[STYLE] Cornice/ornamenti d'angolo** sulle viste "pagina" (Ledger, Menu, Mappa) → tomo, non web.

**Smoothness trasversale**: fade 150-200ms su apertura/chiusura modali e transizioni; hover su ogni
elemento interattivo. (Tecniche: Theme unico, Tween set_trans/ease, modulate, StyleBoxFlat shadow.)

## 4. Roadmap gameplay villaggio (prossime fette)

1. **Scegli cosa costruire**: sul lotto vuoto, 2-3 edifici a scelta (vera agency da builder).
2. **Vista villaggio gestionale**: pannello con elenco edifici, produzione dettagliata, hover-info.
3. **Posta in gioco**: catastrofi che danneggiano edifici (rovina→ricostruisci); traguardi del
   villaggio che sbloccano bonus/eventi/lore (milestone stile Lapse/Clash).
4. **Bilanciamento**: verificare che l'economia Risorse non trivializzi i finali (oggi 6/6 ok).

## 5. Asset che serviranno (da generare — pipeline Perplexity→Nano Banana/Lovable)

> Claude NON può generarli (nessun tool immagini). Prompt nello stile di `Docs/08-asset-prompts.md`.

- **Edifici per-stadio** (il pezzo che mancava in D046): per ogni edificio, varianti Lv2/Lv3 più
  ricche. Hook già nel codice: `Assets/art/villaggio/era<N>/<TT>_lv<L>.png` (usato in automatico se esiste).
  Priorità: i 6 edifici Era 1 e i 6 Era 2 × 2 stadi.
- **Icona "Risorse/Materiali"** dedicata (ora si riusa l'icona Costruzione come proxy).
- **Medaglioni circolari** per le 8 icone strategia (per il punto UI #5), nello stile dei medaglioni
  artefatto del Ledger.
- **Cornici/ornamenti UI** (angoli, righe divisorie pergamena) per i punti #1, #6, #12.
- **Sfondo caverna decisione** più ricco e **sfondo Ledger** (già in `08-asset-prompts.md` §P0b/#6/#8).

## 6. Cosa si può fare ORA senza nuova arte (solo codice)

- Tutti i punti UI **[STYLE]/[LAYOUT]/[SMOOTH]** non-icona: #1(tabella costi), #3(layout decisione),
  #6(cornice stat), #7(badge), #8✓, #9(CTA+hover), #11(scrim), #12(cornici via StyleBox).
- Medaglioni strategia (#5/#10): si possono **approssimare via codice** (cornice circolare + sfondo
  bronzo dietro l'icona esistente) finché non arrivano i PNG dedicati.
- Tutta la roadmap gameplay villaggio (§4) è codice puro.
- Effetti/juice: fade transizioni, hover, pulse, particelle ambient — codice.

---

*File vivo: spuntare i punti man mano. La critica art-direction completa è nel log di sessione.*

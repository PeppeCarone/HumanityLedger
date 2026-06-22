# 15 — Script del video demo (3–5 min)

> Guida shot-by-shot per registrare il video di presentazione d'esame. Non è una
> cattura automatica: si registra a schermo (OBS) una run reale, seguendo la scaletta.
> Ogni segmento indica **cosa mostrare**, **durata**, **voce/sottotitolo** e **stato da
> seminare**. Le inquadrature di riferimento sono i `shot_*` prodotti da `tools/shoot.gd`
> (in `tools/_preview/`): usarli come storyboard per sapere "che cosa deve vedersi".
>
> **Arco**: identità → il gesto e la sua conseguenza → il mondo che reagisce → la
> transizione → l'Assedio (il "wow") → l'epilogo → la meta-progressione.
> **Target totale**: ~3:30 (limite 5:00). Risoluzione di cattura: 1920×1080, 60fps se
> possibile. Musica: lasciare l'audio di gioco; voce-over o sottotitoli per i testi qui sotto.

---

## Preparazione

- Build o editor a 1920×1080, finestra pulita (niente tasti debug: sono già dietro
  `OS.is_debug_build()`, in release non compaiono).
- Avere un **save a inizio Era 2** e uno **a ridosso di un Assedio** per non dover
  rigiocare un'ora in diretta (usare "Continua"). In alternativa, montare spezzoni.
- Riferimento inquadrature: rigenerare gli screenshot con
  `Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe --path . res://tools/shoot.tscn`.

---

## Scaletta

### 0. Title / Menu — 0:00–0:15 (15s) · rif. `shot_menu`
- **Mostra**: il menu principale sullo sfondo dipinto, titolo, musica. Hover sui pulsanti
  (Nuova Partita / Continua / Ledger / Opzioni).
- **Voce/sub**: *"HumanityLedger. Sei lo spirito di un popolo che attraversa le ere: non
  hai volto, esisti solo nelle decisioni che prendi."*

### 1. Il gesto e la sua conseguenza — 0:15–0:55 (40s) · rif. `shot_era1`, `shot_era1_decision`
- **Mostra (villaggio)**: la vista-villaggio viva (fuoco con braci, edifici che dondolano);
  un consigliere "arriva" e il pulsante *"Lyssa attende il tuo parere — Decidi"* lampeggia.
- **Mostra (decisione)**: si apre l'overlay; il consigliere pone la domanda, tre carte-opzione
  in basso. **Trascinare lentamente** una carta sul consigliere-bersaglio (hover verde),
  rilasciare.
- **Mostra (conseguenza)**: ritorno al villaggio → screen-shake/flash, l'edificio sorge o il
  burst d'effetto, **il medaglione della stat pulsa con `+N`**, la riga narrativa si scrive a
  macchina.
- **Voce/sub**: *"Ogni decisione è un gesto: trascini un'azione sul consigliere che la
  sostiene. Il mondo risponde subito — nei numeri e nel racconto."*

### 2. Profondità: prerequisiti, catastrofe, mystery — 0:55–1:25 (30s) · rif. `shot_carestia`, `shot_evento`, `shot_richiamo`
- **Mostra**: una carta-opzione **disabilitata** (prerequisito-stat non soddisfatto, tooltip
  del motivo); poi una **catastrofe** con la sua illustrazione; un breve cenno al **richiamo
  narrativo** ("↩ ricordi di una scelta passata").
- **Voce/sub**: *"Le strategie hanno prerequisiti: non puoi sempre fare ciò che vuoi.
  Catastrofi e una trama nascosta interrompono il flusso — e il gioco ricorda le tue scelte."*

### 3. La transizione tra le ere — 1:25–1:55 (30s) · rif. `shot_transizione`, `shot_worldmap`
- **Mostra**: la title-card cinematografica dell'era, poi la **mappa-mondo dipinta** che si
  trasforma (layer in crossfade, insediamenti che crescono, rotte luminose e zone d'influenza).
- **Voce/sub**: *"Completata l'era, lo spirito attraversa la soglia. La mappa del mondo si
  trasforma con lui: nuovi regni, rotte, alleanze e minacce."*

### 4. Era 2 — il Regno Mitico — 1:55–2:15 (20s) · rif. `shot_era2`, `shot_era2_decision`
- **Mostra**: il salto visivo (città mitica, consiglieri Era 2), una decisione rapida per far
  vedere che il sistema è lo stesso ma il contesto è cresciuto.
- **Voce/sub**: *"Stesse regole, mondo più grande: dal Paleolitico al Regno Mitico, con otto
  nuovi consiglieri e poste in gioco più alte."*

### 5. L'ASSEDIO — il climax — 2:15–3:00 (45s) · rif. `shot_assedio`, `shot_assedio_boss`, `shot_assedio_esito`
- **Mostra**: l'inizio dell'Assedio (banner d'ondata), lo **schieramento** delle 4 unità sulle
  corsie, i nemici che marciano, poi l'**entrata del boss** (mammut/drago) con la sua barra HP e
  un'**abilità telegrafata** (telegrafo a terra → pestone). Chiudere sull'esito graduato.
- **Voce/sub**: *"A fine era, le tue statistiche diventano il tuo esercito. Difendi il
  villaggio dalle ondate e dal boss: qui un'intera era di scelte arriva alla resa dei conti —
  ma senza game over, solo esiti diversi."*
- **Nota di regia**: è il momento "wow". Dargli più tempo, possibilmente un rallentamento sul
  pestone del boss.

### 6. L'epilogo — 3:00–3:20 (20s) · rif. `shot_ending`
- **Mostra**: la schermata di uno dei 6 finali (illustrazione fullscreen, titolo Cinzel, testo
  che appare, Ken Burns).
- **Voce/sub**: *"Sei stat dominanti e le tue scelte chiave determinano quale delle sei ere
  finali fiorirà: Guerra, Prosperità, Scienza, Alleanza, Industria… o un futuro che pochi
  intravedono."*

### 7. Il Ledger e il retry — 3:20–3:35 (15s) · rif. `shot_ledger`
- **Mostra**: il Ledger con lore/artefatti/eventi, il contatore "Epiloghi X/6 · Artefatti X/N",
  una card artefatto che si equipaggia.
- **Voce/sub**: *"Tutto resta scritto nel Ledger: lore, artefatti, segreti che cambiano la
  prossima vita dello spirito. Ogni run lascia qualcosa a quella dopo."*
- **Chiusura**: logo/titolo + crediti del team. *"HumanityLedger — un registro dell'umanità."*

---

## Checklist tecnica pre-registrazione

- [ ] Audio bilanciato (musica non copre la voce-over); provare i livelli su un breve test.
- [ ] Cursore visibile durante i drag (per far leggere il gesto).
- [ ] Nessun overlay di debug; finestra senza barre estranee.
- [ ] Una decisione mostrata per intero senza tagli (la catena di feedback è il punto).
- [ ] L'Assedio registrato due volte e montato il take migliore.
- [ ] Sottotitoli in italiano (coerente con la lingua del gioco) o voce-over pulita.
- [ ] Esportare a 1080p, bitrate alto; durata finale ≤ 5:00.

*Doc di consegna. Vedi anche `Docs/HumanityLedger_Pitch.pptx` per le slide del pitch.*

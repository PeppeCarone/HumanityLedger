# 07 — Decisions Log

> Registro cronologico delle decisioni di design e tecniche. Ogni voce ha un ID stabile, una motivazione, e uno stato (attiva/superata).
> Materiale prezioso per la relazione finale di esame: documenta il *perché* delle scelte.

---

## Convenzioni

- Ogni decisione ha un ID `D###` progressivo
- Quando una decisione viene revocata, NON va cancellata: si imposta `status: superata` e si linka alla decisione che la sostituisce
- Formato voce:

```
### Dxxx — Titolo breve
- **Data**: AAAA-MM-GG
- **Status**: attiva | superata da Dxxx
- **Decisione**: cosa
- **Motivazione**: perché
- **Implicazioni**: cosa cambia in pratica
- **Alternative considerate**: cosa abbiamo escluso e perché
```

---

## Decisioni iniziali (2026-06-01)

### D001 — Godot 4.6 come engine

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: usiamo Godot 4.6 stable.
- **Motivazione**: gratuito, open source, ottimo per 2D + UI, esporto rapido su PC, GDScript ha curva di apprendimento bassa.
- **Implicazioni**: tutto il codice in GDScript, asset in formato Godot-friendly, nessun vincolo di costo.
- **Alternative considerate**: Unity (più heavy, licensing ambiguo), Unreal (overkill per 2D), engine custom (impossibile nei tempi).

### D002 — GDScript, non C#

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: il codice è scritto in GDScript con type hints statici.
- **Motivazione**: iterazione più veloce, nessuna dipendenza .NET, meglio integrato con Godot, niente overhead di compilazione.
- **Implicazioni**: i programmatori devono usare GDScript anche se più abituati a C#.
- **Alternative considerate**: C# (build più lente, dipendenze, meno hot-reload).

### D003 — MVP a 1 sola era

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: l'MVP copre la sola era Tribale/Antica. Le altre 6 ere restano come visione futura.
- **Motivazione**: con 2 persone e 1-3 mesi, 7 ere sono ~12 mesi di lavoro a tempo pieno. Meglio 1 era polished che 7 abbozzate.
- **Implicazioni**: lo scope è ridotto del ~85%. La narrativa è auto-contenuta. La relazione di esame dovrà argomentare il taglio.
- **Alternative considerate**: 2-3 ere ridotte (rischio: nessuna sentita come completa), 1 era + transizione abbozzata a Era 2 (rischio: incompiuto visibile).

### D004 — Stile silhouette + texture carta

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: direzione artistica basata su silhouette con palette ristretta (6-8 colori) e texture stile pergamena su UI/sfondi.
- **Motivazione**: realizzabile senza un artista dedicato, coerente anche se semplice, comunica tono solenne/storico.
- **Implicazioni**: niente pixel art animata, niente 3D, niente illustrazioni complesse. Font serif antichi.
- **Alternative considerate**: pixel art (troppo tempo per animazioni decenti), low-poly 3D (overkill, allunga toolchain), illustrato 2D dettagliato (impossibile senza artista).

### D005 — Italiano only per MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: l'MVP è solo in italiano. Niente sistema di localizzazione.
- **Motivazione**: il target sono i valutatori del corso universitario (italofoni). Implementare `tr()` aggiunge overhead.
- **Implicazioni**: testi inline nelle Resource `.tres`. Refactor futuro se si vuole pubblicare.
- **Alternative considerate**: bilingue it/en (raddoppia il lavoro di scrittura), solo english (svantaggio sui valutatori).

### D006 — Niente boss fight nel MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: l'evento mystery è gestito come quest narrativa, non come boss fight giocabile.
- **Motivazione**: un battle system (anche minimal) è un sotto-gioco intero che richiederebbe 2-3 settimane di lavoro per balance, animazioni, feedback. Non compatibile con i tempi.
- **Implicazioni**: il mystery vive nei testi e in qualche cambio visivo (palette del fiume). L'utente lo *vive*, non lo *combatte*.
- **Alternative considerate**: minigioco di scelta a tempo (rischio: rompe il tono), boss fight stile turn-based (impossibile nei tempi), boss fight stile QTE (banale).

### D007 — Architettura data-driven con Resource `.tres`

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: quest, decisioni, effetti vivono come `.tres` editabili dall'editor di Godot. Lo script di gioco non contiene mai testo narrativo o numeri hardcoded.
- **Motivazione**: permette al designer di scrivere quest senza toccare codice; permette versionamento granulare; testing più semplice.
- **Implicazioni**: tempo iniziale per definire le classi Resource (W3). Dopo, contenuti aggiunti a costo basso.
- **Alternative considerate**: tutto in script (cresce a dismisura, conflitti git), JSON esterno (perde tipizzazione e editor di Godot), CSV (orribile per testi multilingua/lunghi).

### D008 — Decisioni come gesti drag-and-drop, mai click-su-menu

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: ogni decisione importante si esegue trascinando un'icona su un target visivo nella scena.
- **Motivazione**: pilastro di design (vedi `00-overview.md`). Differenzia il gioco da *Reigns* e simili.
- **Implicazioni**: la prima settimana va spesa per prototipare il sistema. Se non funziona, è un rischio grosso.
- **Alternative considerate**: click classico (perde l'identità), tastiera (escluso per UX), gesture su touch (escluso per scope PC).

### D009 — Save singolo, autosave dopo ogni decisione

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: un solo slot di salvataggio, salvataggio automatico dopo ogni decisione, niente save manuale.
- **Motivazione**: rafforza il pilastro "scelte irreversibili"; semplifica UI; riduce bug di gestione slot.
- **Implicazioni**: il file di save deve essere leggero e veloce da scrivere; se cresce, valutare buffer + flush.
- **Alternative considerate**: save multipli (incentiva save scumming, rompe il tono), niente save (run sole, irrealistico per 30-60 min).

### D010 — Solo PC Windows come piattaforma target MVP

- **Data**: 2026-06-01
- **Status**: attiva
- **Decisione**: MVP esporta solo Windows 64-bit.
- **Motivazione**: i valutatori useranno PC Windows. macOS/Linux sono export gratuiti ma non vengono testati.
- **Implicazioni**: nessun test su altre piattaforme. Se serve a fine progetto, export aggiuntivo richiede solo qualche ora.
- **Alternative considerate**: multi-piattaforma (overhead di QA), web (limitazioni di Godot 4 per HTML5), mobile (UI da rifare).

---

## Decisioni future (template vuoto)

Aggiungere qui sotto man mano. ID prossimo libero: **D011**.

```
### D011 — ...

- **Data**:
- **Status**: attiva
- **Decisione**:
- **Motivazione**:
- **Implicazioni**:
- **Alternative considerate**:
```

---

*Versione 0.1 — 2026-06-01. File vivo: aggiornare a ogni decisione di rilievo.*

# 24 — Pass di integrità visiva (sessione 2026-10-04)

> Ripresa dello sviluppo dopo la consegna d'esame (luglio). Lente fissa: **occhio del
> giocatore, mai prototipo**. Per la prima volta il gioco è stato renderizzato e
> fotografato in un ambiente pulito (Godot 4.6.1 + Xvfb, GL Compatibility), schermata per
> schermata: ne è uscita una classe di difetti visivi che a schermo si vedeva subito e che
> nessuno dei controlli automatici poteva intercettare.

---

## 1. Cosa si vedeva

| Schermata | Difetto |
|---|---|
| Assedio, barra del boss | l'arte ornata `boss_bar.png` ridotta a una riga sottile, capi deformati |
| Assedio, banner d'ondata | cartello `wave_banner.png` schiacciato in una striscia, testo che debordava |
| Assedio, barra del villaggio | doppia riga di cornice *dentro* la barra (`bar_frame.png` stirato) |
| Toast "Traguardo" | cornice dei modali compressa in 80px, testo sopra i fregi |
| Pausa, Opzioni, modali villaggio | titoli e pulsanti sopra la filigrana della cornice |
| Pausa, Opzioni, modali, Assedio | pulsanti **grigi di sistema** con contorno bianco di focus |
| Menu principale, "Continua" (disabilitato) | scacchiera di "finta trasparenza" dentro il pulsante |
| Tutti i pulsanti ornati | capi a foglia deformati in base alla larghezza |
| Tooltip | un nastrino di pergamena nell'angolo, ripetuto/stirato |
| Decisioni Era 2 (8 eventi) | **didascalie inglesi stampate** ("Famine", "Religious Conflict"…) e strisce di mappa |
| Ritratto di Lena (Era 2) | lettere "Ar" della didascalia e la stella del generatore sotto i piedi |
| Ritratto di Murr (Era 1) | il bastone col teschio e la mano della Sciamana accanto; braccio tagliato |
| Ritratto di Lyssa (Era 1) | senza il suo bastone (finito nella cella di Murr) |
| Icona strategia "pergamena" | l'arco dell'oggetto sotto, dal foglio sorgente |

## 2. Causa comune

I PNG generati stanno su **tele con ampio padding trasparente** (es. `boss_bar.png` 1280×512
con l'arte in 1079×248; `panel.png` 500×500 con 38-40px di bordo vuoto) e i loro ornamenti
non sono angoli piccoli ma capi grandi. Il 9-slice (`NinePatchRect`/`StyleBoxTexture`) usava
margini "a occhio" che includevano il vuoto: la cornice visibile risultava più piccola del
pannello, i capi venivano schiacciati in verticale e il contenuto finiva sopra i fregi.

Secondo meccanismo, indipendente: **un `CanvasLayer` interrompe l'eredità del tema** dalla
finestra. Il tema bronzo era montato solo su `root.theme`, quindi tutto ciò che vive in un
`CanvasLayer` (pausa, opzioni, modali del villaggio, Assedio) usava i pulsanti di default.

Per gli asset: i fogli sorgente non erano a griglia regolare (`scenari_catastrofi.png`) o i
soggetti non stavano al centro della loro cella (`consiglieri.png`), e lo slicing a griglia
fissa portava dentro didascalie e pezzi dei vicini.

## 3. Cosa è stato fatto

**Codice (fallback-safe: senza i PNG resta la resa a colori di prima).**

- **`CorniceDipinta`** (`scripts/ui/cornice_dipinta.gd`): disegna solo il bbox opaco della
  texture in *fasce orizzontali*: le fisse (capi, stemmi) scalano con l'altezza, le elastiche
  si allungano. Opzionale un *canale* di riempimento (HP) sotto o sopra l'arte e un'area
  *interna* (pergamena) dove mettere il testo. Le misure dei PNG reali stanno in
  `UiStyle.SPEC_DIPINTE`; `UiStyle.cornice_dipinta(path)` la costruisce.
  Usata per: barra del boss, banner d'ondata (a misura del testo, titolo + riga Spionaggio
  dentro la pergamena), barra del villaggio, toast Traguardo (cartiglio).
- **`StyleBoxDipinto`** (`scripts/ui/style_box_dipinto.gd`): StyleBox a capsula per i
  pulsanti ornati, capi proporzionali all'altezza. Il *disabled* è il *normal* spento
  (`button_disabled.png` ha la scacchiera stampata). `UiStyle.stile_bottone_compatto()` per
  i pulsanti bassi ("Potenzia" sulle carte dell'Assedio).
- **Cornice dei modali e tooltip**: `region_rect` sul bbox reale + margini misurati
  (`PANEL_REGIONE`, angoli 128px, contenuto 54/50/44; `TOOLTIP_REGIONE`).
- **Tema anche sotto i CanvasLayer**: stili di Button/Tooltip copiati nel tema di default
  dell'engine (`ThemeDB.get_default_theme().merge_with`), solo quei tipi.

**Asset (riproducibili dagli script).**

- `tools/slice_assets.py · slice_events()`: bordi dei pannelli misurati sul foglio, via le
  fasce delle didascalie, upscale 2× Lanczos (a schermo l'illustrazione è larga 250px).
- `tools/fix_ritratti.py` (nuovo): finestre su misura per Murr e Lyssa (con pulizia della
  scacchiera rimasta chiusa dentro la figura), frammenti staccati via da Lena e dall'icona
  `pergamena`. Idempotente.
- `Assets/art/ui/tooltip.png`: lato destro rifatto specchiando il sinistro (via il nastrino).

**Strumenti.**

- `tools/shot_ui.gd/.tscn` (nuovo): scatti mirati degli stati in cui l'arte dipinta si vede
  davvero (banner al picco, boss ferito, toast, modali, decisioni con illustrazione).
- `tools/asset_audit.py`: tolti due falsi allarmi (codice letto come `illustrazione_id`;
  i `.png.import` contati come immagini non usate), riconosciute le chiamate letterali agli
  helper di texture, cartelle caricate da helper marcate "verificare a mano".

## 4. Verifica

- Import pulito, `validate_scenes` **0 failure**, `balance_sim` **6/6 finali** + Assedio
  "sfida" invariato, `asset_audit` nessun riferimento rotto.
- `playtest_curve` / `playtest_finale` / `playtest_assedio`: esiti dentro l'envelope noto
  (nessun valore di combattimento toccato: solo resa della HUD).
- 28 scatti di `shoot.gd` + 14 di `shot_ui.gd` riguardati uno per uno.

## 5. Regola per i prossimi asset dipinti

1. Misura il bbox opaco (`PIL: Image.getbbox()` sull'alpha) e dove stanno capi/canale/area
   interna; scrivili in `UiStyle.SPEC_DIPINTE` (cornici/barre/cartigli) o come regione in
   `UiStyle` (pannelli/pulsanti).
2. Mai 9-slice su una tela con padding: o `region_rect`, o `CorniceDipinta`.
3. Se l'elemento può stare in un `CanvasLayer`, controllalo in quel contesto (`shot_ui`).
4. Slicing da fogli: misura i bordi reali, non assumere griglie; togli didascalie e vicini.

*Comandi: vedi `Docs/23-note-tecniche.md`. Scatti: `godot --path . res://tools/shot_ui.tscn`
(con contesto di rendering; su Linux senza schermo: `xvfb-run -a ... --rendering-driver opengl3`).*

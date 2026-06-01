# 05 — Arte e audio

> Direzione artistica e strategia per acquisire gli asset senza farci uccidere dai tempi.

---

## Vincolo di partenza

2 persone, 1-3 mesi, nessun artista dedicato. Non possiamo permetterci pixel art animata frame-by-frame, né 3D modellato, né concept art elaborata. Lo stile deve essere **veloce da produrre e coerente anche se imperfetto**.

## Direzione artistica proposta

**Stile silhouette + colore piatto + texture carta**

- Personaggi: silhouette nere o sepia con dettagli minimi (occhi, accessori), su sfondi a colori piatti
- Edifici: silhouette geometriche con texture di pergamena/carta sopra
- UI: cornici stile pergamena, font serif antico
- Palette ristretta: 6-8 colori totali per tutto il gioco (es. sepia, ocra, rosso ruggine, blu notte, bianco, nero, grigio caldo, verde muschio)

**Riferimenti visivi**:
- *Reigns* (Nerial) — silhouette espressive, palette ristretta
- *Inside* (Playdead) — illuminazione + silhouette
- *Year Walk* (Simogo) — texture di carta, atmosfera antica
- *Pyre* / *Hades* (Supergiant) — limitatamente, per le illustrazioni dei consiglieri

**Stile UI**: pergamena ingiallita con cornici stilizzate. Font: scelta tra **EB Garamond** (Google Fonts, OFL), **Cinzel** (OFL), o **IM Fell English** (OFL).

## Asset inventory necessario per MVP

### Visivi

| Categoria | Quantità | Note |
|---|---|---|
| Icone gesto | 5-7 | Soldato, monete, pergamena, pane, torcia, ramo, pugnale |
| Ritratti consiglieri | 5 | Murr, Lyssa, Tev, Brann, Straniero |
| Sprite edifici | 6-8 | Capanna, fuoco, idolo, granaio, mura, tempio, mercato |
| Sfondo villaggio | 2-3 stati | Atto 1 (piccolo), Atto 2 (sviluppato), Atto 3 (sotto crisi) |
| Cornici UI | 3-4 | Pannello decisione, HUD, finestra epilogo |
| Schermata menu | 1 illustrazione | Idolo + paesaggio |
| Schermate finale | 4 | Una per epilogo |

### Audio

| Categoria | Quantità | Note |
|---|---|---|
| Musica di sottofondo | 3 tracce | Calma (Atto 1), tesa (Atto 2), risoluzione (Atto 3) |
| SFX decisioni | 5-7 | Click gesto, drag pickup, drop conferma, drop annulla, transizione stat |
| SFX ambiente | 3-4 | Fuoco crepita, vento, fiume, voci villaggio |
| Stinger narrativo | 2-3 | Per momenti di rivelazione (sogno, fiume rosso) |

## Strategia di acquisizione

### 1. Asset gratuiti CC0 (priorità massima)

Fonti affidabili:

| Sito | Cosa cercare | Licenza |
|---|---|---|
| [Kenney.nl](https://kenney.nl) | UI kit, icone, fantasy assets | CC0 |
| [OpenGameArt.org](https://opengameart.org) | Sprite, illustrazioni, audio | CC0/CC-BY (filtrare) |
| [itch.io free assets](https://itch.io/game-assets/free) | Asset pack tematici | varia (controllare) |
| [Freesound.org](https://freesound.org) | SFX | CC0/CC-BY |
| [Pixabay Music](https://pixabay.com/music/) | Musica | gratuita uso commerciale |
| [ccMixter](http://ccmixter.org) | Musica | CC vari |
| [Google Fonts](https://fonts.google.com) | Font | OFL / Apache |

**Regola**: per ogni asset usato salviamo in `assets/CREDITS.md` autore, fonte, licenza, link. Anche per CC0 (buona pratica per la relazione).

### 2. Generazione AI (uso prudente)

Per **ritratti dei consiglieri** e **illustrazioni di sfondo** può valere usare un generatore di immagini (es. Stable Diffusion locale, o tool web). Vincoli:

- Solo per asset 2D statici, mai per loghi o tipografia
- Verificare la policy dell'università sull'uso di AI nel progetto — alcune sono restrittive
- Documentare l'uso nella relazione e nel `CREDITS.md` (modello usato, prompt, post-edit eventuali)
- Post-processing manuale (palette unificata, contorno) per coerenza stilistica

> Se l'università vieta AI generativa: ripiegare su silhouette disegnate a mano in 30 minuti ciascuna. La direzione artistica silhouette è scelta apposta per essere realizzabile senza skill di disegno.

### 3. Asset originali (solo dove necessario)

- Logo del gioco (titolo): essenziale farlo nostro
- Icone gesti: meglio farle a mano per coerenza (svg semplici)
- Cornici UI: idem

## Pipeline tecnica

- **Formato sprite**: PNG con trasparenza, ottimizzato (TinyPNG o oxipng) prima del commit
- **Risoluzione di lavoro**: ritratti 512×512, sprite edifici 256×256, icone 128×128
- **Risoluzione gioco**: 1920×1080 (vedi `04-architecture.md`)
- **Audio**: OGG Vorbis q5 per musica, WAV per SFX corti
- **Repo size**: tenere `assets/` sotto i 200 MB. Se serve di più: Git LFS (vedi `CONTRIBUTING.md`)

## Cosa NON fare

- Niente animazione frame-by-frame complessa: usare al massimo 2-3 frame per loop ambientali
- Niente font commerciali a pagamento (rischio licenza per la consegna)
- Niente asset da fonti dubbie (Pinterest, Google Images senza filtro): violazione di copyright = bocciatura
- Niente Sketchfab/modelli 3D anche gratuiti se non li serviamo davvero (sono 3D, noi siamo 2D)

## Pianificazione asset (sintesi)

| Settimana | Output asset minimo |
|---|---|
| 1 | Palette definita, font scelti, cornice UI base, 2 icone gesto |
| 2 | Sfondo villaggio Atto 1, 3 silhouette personaggi, 5 icone gesto |
| 3 | Sfondi Atto 2 e Atto 3, 5 silhouette edifici, 1 brano musicale |
| 4 | Ritratti restanti, SFX completi, 2 brani musicali |
| 5+ | Polish, illustrazioni finale, eventuali asset extra |

---

*Versione 0.1 — 2026-06-01. Da rivedere appena scelto definitivamente lo stile.*

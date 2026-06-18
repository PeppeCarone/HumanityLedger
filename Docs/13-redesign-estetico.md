# 13 — Redesign estetico: da "arte-codice" a gioco rifinito

> Sessione 2026-06-17. Obiettivo richiesto: il gioco deve sembrare **un vero gioco
> bello e interattivo**, non un prototipo. Oggi troppe parti dell'interfaccia (cornici,
> medaglioni, icone, "+", stelle, barre, le forme del boss fight) sono **disegnate via
> codice** (`StyleBoxFlat`, `_draw`, dischi-gradiente) → look "engine di default".
> Qui: la mappa completa "cosa-è-codice → quale-asset-lo-sostituisce" e le modifiche di
> codice per **usare** l'arte. Tutti i prompt sono in `Docs/08-asset-prompts.md` (P0–P9).

---

## 1. Principio: integrazione graduale con fallback

Stesso pattern già usato per terreni/edifici: il codice **prova a caricare il PNG** e,
se non c'è, **ripiega sulla resa attuale**. Così si integra un asset alla volta senza
mai rompere il gioco.

- Helper nuovo in `UiStyle` (autoload): `ui_panel() -> StyleBox|NinePatch`, `icona(nome)`,
  `cornice(nome)` che caricano da `Assets/art/ui/` e `Assets/art/icons/` con fallback.
- I `NinePatchRect` sostituiscono i pannelli/pulsanti `StyleBoxFlat` (margini di patch
  impostati una volta nell'helper).
- Le icone (medaglioni) sostituiscono i `TextureRect`+cerchio disegnato.

## 2. Mappa: arte-codice → asset → dove si tocca

| Elemento UI | Oggi (codice) | Asset (prompt) | File da modificare |
|---|---|---|---|
| **Pannelli modali/HUD** | `StyleBoxFlat` bronzo | **§8a** panel 9-slice | `ui_style.gd`, `main.gd` (`_stile_pannello`), pannelli edificio/build, `siege.gd` |
| **Pulsanti** | `UiStyle` StyleBox | **§8b** button 4 stati | `ui_style.gd` |
| **Badge rapporti / effetti** | pannelli a codice | **§8c** chip + bordi tinti | `main.gd` (`_crea_badge`, `_refresh_rapporti`) |
| **Tooltip** | StyleBox | **§8d** | `ui_style.gd` |
| **Divisori** | `ColorRect` 1px | **§8e** filigrana | `main.gd`, `ledger_screen.gd` |
| **Cornici d'angolo (tomo)** | assenti | **§8f** 4 angoli | `ledger_screen.gd`, `main_menu`, `world_map.gd` |
| **Medaglioni icone** | cerchio disegnato | **§8g** holder | `main.gd` (icone strategia), `ledger_screen.gd` |
| **Barre (HP/risorse/progress)** | `ColorRect` | **§8h** frame+fill | barra risorse `main.gd`, `siege.gd` |
| **Cartiglio titoli / banner** | Label nuda | **§8i** | era card `main.gd`, titolo `world_map.gd`, banner ondata `siege.gd` |
| **Fondo pergamena modali/pagine** | colore piatto | **§8j** | `ledger_screen.gd`, modali `main.gd` |
| **Anelli "+"/glow/affordance** | dischi-gradiente | **§8k** | `village_view.gd` (`_disc_texture`, plot, glow), `siege.gd` |
| **8 icone stat** | PNG ok (coerenti?) | **§9a** (opz. rifare unificate) | `Assets/art/stats/` |
| **9 strategie** | 7 PNG + medaglione-codice; spionaggio placeholder | **§9b** token finiti | `data/strategie/*.tres`, `main.gd` |
| **Icona Risorse** | proxy `costruzione.png` | **§9c** | barra risorse `main.gd`, `siege.gd` |
| **"+" / stelle livello / freccia upgrade / lucchetto** | testo/`_draw` | **§9d** azioni | `village_view.gd`, `main.gd`, `ledger_screen.gd` |
| **Icone categoria Ledger** | testo/codice | **§9e** | `ledger_screen.gd` |
| **Glifi tasti** | testo "ESC/L" | **§9f** (opz.) | `main.gd` HUD |
| **Boss fight: tutto** | forme `_draw` | **§P7** + **§9g** | `scripts/siege/*` (Fase G) |

> Sfondi, ritratti, edifici, vignette finali sono **già arte vera** (vedi "Già a posto"
> in `08`). Il redesign riguarda **UI kit + icone + assedio**, non i fondali.

## 3. Convenzioni di path (il codice aggancia da qui, con fallback)

```
Assets/art/ui/      panel.png · button_normal|hover|pressed|disabled.png · chip.png
                    chip_ally|hostile|gold.png · tooltip.png · divider.png
                    corner_tl|tr|bl|br.png · medallion.png · medallion_glow.png
                    bar_frame.png · bar_fill.png · cartouche.png · parchment.png
                    ring_select.png · plot_pad.png · ring_upgrade.png · ring_focus.png
Assets/art/icons/   stats/<stat>.png · strategie/<id>.png · risorse.png
                    action/build|upgrade|star|lock|check|coin|pop|tempo.png
                    ledger/lore|artefatto|evento|epilogo|run.png · keys/<k>.png
                    siege/<unit>.png
```

## 4. Priorità (impatto/sforzo) — ordine consigliato di generazione+cablaggio

1. **§8a Pannello + §8b Pulsanti** → ~70% del "feel": appaiono in ogni schermata.
2. **§8g Medaglioni + §9b Strategie + §9c Risorse** → la vista decisione e l'HUD (le più viste).
3. **§8h Barre + §8i Cartiglio + §8k Affordance** → villaggio, era card, assedio.
4. **§8f Angoli + §8j Pergamena** → Ledger/Menu/Mappa diventano "tomo".
5. **§9d Azioni + §9e Ledger + §8c/8d/8e rifiniture**.
6. **§P7 + §9g** → arte dell'Assedio (quando arriva alla Fase G).

## 5. Lavoro di cablaggio (codice — dopo che arrivano i PNG)

- [ ] **Helper `UiStyle`**: `panel_nine()`, `button_theme()` da `NinePatchRect`/Theme con
  texture; `icona(categoria, nome)` e `cornice(nome)` con cache + fallback.
- [ ] **Migrare i pannelli** a `NinePatchRect` (modali edificio/build, HUDPanel, resource
  bar, decision panel, pannelli assedio).
- [ ] **Migrare le icone**: strategia (medaglioni reali al posto del cerchio a codice),
  stat (se rigenerate), Risorse, azioni (+/stelle/freccia/lock).
- [ ] **Villaggio**: `_disc_texture`/glow/plot → texture §8k; stelle livello → §9d star.
- [ ] **Ledger/Menu/Mappa**: ornamenti d'angolo §8f + pergamena §8j + cartiglio §8i.
- [ ] **Assedio (Fase G)**: sprite nemici/boss/difensori/campo + barre/banner §8h/8i.
- [ ] Verifica a schermo di ogni schermata via `tools/shoot.gd` ([[reference-godot-testing]],
  [[feedback-verifica-a-schermo]]).

---

## Stato

- **2026-06-17** — Scritto il manifesto completo (UI Kit §P8 + Icone §P9 in `08`) e
  questa mappa di redesign + cablaggio. Prossimo: generare gli asset prioritari (1–2) e
  introdurre l'helper `UiStyle` con fallback. Nessun cablaggio fatto ancora.
- **2026-06-18** — **UI-kit generato e cablato.** `Assets/art/ui/` contiene panel, button (5
  stati), chip, 4 corner, divider, medallion(+glow), `bar_frame`/`bar_fill`, cartouche, parchment,
  `ring_select`/`ring_upgrade`/`ring_focus`, `plot_pad`, `chip_{ally,hostile,gold}`. In uso via
  `UiStyle` (pannelli/pulsanti/tooltip globali, medaglioni, anelli villaggio) e nell'Assedio
  (`bar_frame`/`boss_bar` per le barre, `cartouche`/`wave_banner` per i banner). Icone stat (8) e
  strategie (9) presenti in `art/stats|strategie`. Restano opzionali: §P9 medaglioni "unificati"
  (icons/stats|strategie/...) e glifi tasti §9f — il set attuale è già coerente e finito.

*File vivo. Prompt: `Docs/08-asset-prompts.md` (P0–P9).*

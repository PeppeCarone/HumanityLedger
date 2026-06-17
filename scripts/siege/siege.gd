extends CanvasLayer
class_name SiegeArena

# L'Assedio — Fase B ("le tue statistiche diventano il tuo esercito").
# Vedi Docs/11-boss-fight.md. Villaggio a sinistra (HP da Costruzione+popolazione); i
# nemici marciano da destra su 3 corsie. Schieri 4 tipi di unità sulle piazzole, ognuna
# scalata da una stat diversa; il budget di schieramento (Risorse) viene da Tesoro/Risorse.
# Le civiltà amiche (rapporto alto) mandano truppe gratis; quelle ostili rinforzano il
# nemico. Vinci sopravvivendo a tutte le ondate; "Sopraffatto" se l'HP del villaggio va
# a 0 (no game over D024: in integrazione completa si avanza comunque).
#
# Fase B = solo codice, niente boss (Fase C) e ondate complete data-driven (Fase D).
# Tutto disegnato via _draw / Control: nessun asset richiesto.

signal assedio_concluso(esito: String)   # "trionfo" | "sopraffatto"

const VILLAGGIO_X: float = 300.0
const SPAWN_X: float = 1830.0
const LANE_Y: Array[float] = [388.0, 566.0, 744.0]
const COL_X: Array[float] = [600.0, 900.0, 1200.0]
# Cartella asset dell'Assedio (tutto fallback-safe: il codice usa forme/colori finché il
# PNG non esiste). Convenzione nomi in Docs/08-asset-prompts.md §P7.
const SIEGE_DIR: String = "res://Assets/art/siege/"

# Soglia/etichette civiltà: rispecchiano main.gd (i rapporti hanno chiavi per civ_id).
const SOGLIA_RAPPORTO: int = 2
const CIV_LABELS: Dictionary = {
	"popolo_nebbie": "Popolo delle Nebbie",
	"clan_bisonte": "Clan del Bisonte",
	"impero_sole": "Impero del Sole",
	"lega_coste": "Lega delle Coste",
}

# Archetipi (meccaniche costanti). Le skin per era stanno in SKIN.
const ORDINE: Array[String] = ["tiratore", "bloccatore", "sciamano", "totem"]
const ROSTER: Dictionary = {
	"tiratore":   {"ruolo": "ranged", "costo": 4, "raggio": 250.0, "cadenza": 0.8,  "desc": "Tiro a distanza"},
	"bloccatore": {"ruolo": "blocco", "costo": 5, "raggio": 0.0,   "cadenza": 0.9,  "desc": "Blocca la corsia"},
	"sciamano":   {"ruolo": "slow",   "costo": 5, "raggio": 190.0, "cadenza": 0.0,  "desc": "Rallenta i nemici"},
	"totem":      {"ruolo": "aoe",    "costo": 7, "raggio": 230.0, "cadenza": 1.5,  "desc": "Danno ad area"},
}
const SKIN: Dictionary = {
	1: {
		"tiratore":   {"nome": "Cacciatore", "colore": Color(0.55, 0.8, 0.95)},
		"bloccatore": {"nome": "Guerriero",  "colore": Color(0.78, 0.6, 0.4)},
		"sciamano":   {"nome": "Sciamana",   "colore": Color(0.62, 0.9, 0.95)},
		"totem":      {"nome": "Totem del Fuoco", "colore": Color(0.95, 0.55, 0.3)},
	},
	2: {
		"tiratore":   {"nome": "Arciere",    "colore": Color(0.6, 0.82, 0.95)},
		"bloccatore": {"nome": "Legionario", "colore": Color(0.82, 0.7, 0.45)},
		"sciamano":   {"nome": "Sacerdote",  "colore": Color(0.85, 0.85, 1.0)},
		"totem":      {"nome": "Catapulta",  "colore": Color(0.9, 0.6, 0.35)},
	},
}

var era: int = 1
var hp_villaggio_max: int = 100
var hp_villaggio: int = 100
var risorse: int = 8

var _skin: Dictionary = {}
var _alleati_civ: Array[String] = []
var _ostili_civ: Array[String] = []
var _unita_selezionata: String = "tiratore"

var _world: Node2D = null
var _ui: Control = null
var _villaggio_panel: PanelContainer = null
var _villaggio_label: Label = null
var _tex_cache: Dictionary = {}
var _enemies: Array[SiegeEnemy] = []
var _blocchi: Array[SiegeDefender] = []
var _spawn_queue: Array = []          # [{t, hp, vel, bounty, danno, corsia}]
var _plot_pos: Array[Vector2] = []
var _plot_corsia: Array[int] = []
var _plot_markers: Array[Control] = []
var _plot_occupato: Array[bool] = []
var _card_panels: Dictionary = {}     # tipo -> PanelContainer
var _tempo: float = 0.0
var _attivo: bool = false
var _concluso: bool = false

var _hp_fill: ColorRect = null
var _hp_label: Label = null
var _risorse_label: Label = null
var _info_label: Label = null
var _ondata_label: Label = null
var _diplo_label: Label = null


# Chiamare PRIMA di add_child: alimenta la difesa dalle statistiche della run
# ("le tue statistiche diventano il tuo esercito", Docs/11-boss-fight.md §2).
func configura(e: int) -> void:
	era = e
	_skin = SKIN.get(e, SKIN[1])
	hp_villaggio_max = 70 + GameState.get_stat("costruzione") + int(GameState.popolazione / 4.0)
	hp_villaggio = hp_villaggio_max
	risorse = 8 + int(GameState.risorse / 4.0) + int(GameState.tesoro / 22.0) + int(GameState.get_stat("popolo") / 18.0)
	_calcola_diplomazia()


func _calcola_diplomazia() -> void:
	_alleati_civ.clear()
	_ostili_civ.clear()
	for civ_id in GameState.rapporti_civilta.keys():
		var v: int = int(GameState.rapporti_civilta[civ_id])
		var nome: String = CIV_LABELS.get(civ_id, str(civ_id))
		if v >= SOGLIA_RAPPORTO:
			_alleati_civ.append(nome)
		elif v <= -SOGLIA_RAPPORTO:
			_ostili_civ.append(nome)


# --- Caricamento asset (fallback-safe) --------------------------------------

func _carica_tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex


# Sprite dell'era corrente: Assets/art/siege/era<N>/<nome>.png (null se assente).
func _siege_tex(nome: String) -> Texture2D:
	return _carica_tex(SIEGE_DIR + "era%d/%s.png" % [era, nome])


# Sfondo campo: accetta campo.jpg o campo.png (null se assenti).
func _siege_bg_tex() -> Texture2D:
	var j: String = SIEGE_DIR + "era%d/campo.jpg" % era
	if ResourceLoader.exists(j):
		return _carica_tex(j)
	return _carica_tex(SIEGE_DIR + "era%d/campo.png" % era)


# Effetto/proiettile condiviso: Assets/art/siege/fx/<nome>.png.
func _fx_tex(nome: String) -> Texture2D:
	return _carica_tex(SIEGE_DIR + "fx/%s.png" % nome)


func _ready() -> void:
	layer = 20
	if _skin.is_empty():
		_skin = SKIN[1]
	_costruisci_scena()
	_schiera_alleati()
	_prepara_ondate()
	AudioManager.play_sfx("era_transition")
	_attivo = true


func _process(delta: float) -> void:
	if not _attivo or _concluso:
		return
	_tempo += delta
	while not _spawn_queue.is_empty() and _tempo >= float(_spawn_queue[0]["t"]):
		var d: Dictionary = _spawn_queue.pop_front()
		_spawn_enemy(d)
	_pulisci_enemies()
	_aggiorna_ondata_label()
	if _spawn_queue.is_empty() and _enemies.is_empty():
		_termina("trionfo")


# --- Costruzione scena (placeholder) ---------------------------------------

func _costruisci_scena() -> void:
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_STOP   # cattura i click: niente clic al villaggio sotto
	add_child(_ui)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.06, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(bg)

	# Sfondo dipinto del campo (se presente): sopra il fondo scuro, sotto le corsie.
	var bg_tex: Texture2D = _siege_bg_tex()
	if bg_tex != null:
		var sfondo: TextureRect = TextureRect.new()
		sfondo.texture = bg_tex
		sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
		sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sfondo.modulate = Color(0.82, 0.82, 0.82, 1.0)   # smorzato: le corsie restano leggibili
		sfondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(sfondo)

	# Le 3 corsie. Con lo sfondo dipinto la banda è solo un velo scuro (l'arte traspare);
	# senza sfondo è piena, così le corsie restano leggibili sul fondo nero.
	for y in LANE_Y:
		var terra: ColorRect = ColorRect.new()
		terra.color = Color(0.10, 0.07, 0.05, 0.34) if bg_tex != null else Color(0.16, 0.12, 0.09, 0.95)
		terra.position = Vector2(VILLAGGIO_X, y - 24.0)
		terra.size = Vector2(SPAWN_X - VILLAGGIO_X + 40.0, 48.0)
		terra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(terra)

	# Villaggio (cancello) a sinistra: copre tutte le corsie.
	var villaggio: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.08, 0.98)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	villaggio.add_theme_stylebox_override("panel", sb)
	villaggio.position = Vector2(20.0, LANE_Y[0] - 70.0)
	villaggio.size = Vector2(VILLAGGIO_X - 50.0, LANE_Y[2] - LANE_Y[0] + 140.0)
	villaggio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(villaggio)
	_villaggio_panel = villaggio
	var vlbl: Label = Label.new()
	vlbl.text = "VILLAGGIO"
	vlbl.add_theme_font_size_override("font_size", 22)
	vlbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.55))
	vlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	villaggio.add_child(vlbl)
	_villaggio_label = vlbl

	# Sprite roccaforte (se presente): rimpiazza pannello+etichetta+merli/porte a codice.
	var rocca: Texture2D = _siege_tex("roccaforte")
	if rocca != null:
		var trasp: StyleBoxFlat = StyleBoxFlat.new()
		trasp.bg_color = Color(0, 0, 0, 0)
		villaggio.add_theme_stylebox_override("panel", trasp)
		vlbl.visible = false
		var rimg: TextureRect = TextureRect.new()
		rimg.texture = rocca
		rimg.position = Vector2(0.0, LANE_Y[0] - 120.0)
		rimg.size = Vector2(VILLAGGIO_X + 30.0, LANE_Y[2] - LANE_Y[0] + 240.0)
		rimg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rimg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		rimg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(rimg)

	_crea_decoro()

	# Mondo (entità: nemici, difensori, proiettili).
	_world = Node2D.new()
	add_child(_world)

	_crea_piazzole()
	_crea_hud()
	_crea_barra_unita()


func _crea_piazzole() -> void:
	# 3 corsie × 3 colonne. slot = corsia*3 + colonna.
	for corsia in range(LANE_Y.size()):
		for col in range(COL_X.size()):
			var pos: Vector2 = Vector2(COL_X[col], LANE_Y[corsia])
			var slot: int = _plot_pos.size()
			_plot_pos.append(pos)
			_plot_corsia.append(corsia)
			_plot_occupato.append(false)
			var holder: Control = Control.new()
			holder.size = Vector2(76.0, 76.0)
			holder.position = pos - holder.size * 0.5
			holder.mouse_filter = Control.MOUSE_FILTER_STOP
			holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var s: int = slot
			var p: Vector2 = pos
			holder.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
					_on_plot(s, p))
			var disc: TextureRect = TextureRect.new()
			disc.texture = _disc_texture()
			disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			disc.stretch_mode = TextureRect.STRETCH_SCALE
			disc.set_anchors_preset(Control.PRESET_FULL_RECT)
			disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			disc.modulate = Color(0.98, 0.84, 0.46, 0.32)
			holder.add_child(disc)
			var plus: Label = Label.new()
			plus.text = "+"
			plus.add_theme_font_size_override("font_size", 40)
			plus.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
			plus.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.95))
			plus.add_theme_constant_override("outline_size", 5)
			plus.set_anchors_preset(Control.PRESET_FULL_RECT)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(plus)
			_ui.add_child(holder)
			_plot_markers.append(holder)
			var tw: Tween = holder.create_tween()
			tw.set_loops()
			tw.set_trans(Tween.TRANS_SINE)
			tw.tween_property(disc, "modulate:a", 0.55, 0.9)
			tw.tween_property(disc, "modulate:a", 0.26, 0.9)


# Decoro del campo (tutto in _ui, sotto le entità e le piazzole): villaggio fortificato
# con porte allineate alle corsie, chevron che indicano il verso d'avanzata, lato spawn.
func _crea_decoro() -> void:
	var ha_campo: bool = _siege_bg_tex() != null
	# Col campo dipinto i bordi-corsia si fanno bronzo (definiscono la pista senza coprirla).
	var bordo: Color = Color(0.55, 0.42, 0.26, 0.5) if ha_campo else Color(0.3, 0.22, 0.14, 0.7)
	var chev: Color = Color(0.42, 0.32, 0.2, 0.22)
	for y in LANE_Y:
		for dy in [-24.0, 24.0]:
			var linea: ColorRect = ColorRect.new()
			linea.color = bordo
			linea.position = Vector2(VILLAGGIO_X - 16.0, y + dy - 1.0)
			linea.size = Vector2(SPAWN_X - VILLAGGIO_X + 56.0, 2.0)
			linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_ui.add_child(linea)
		var x: float = SPAWN_X - 80.0
		while x > VILLAGGIO_X + 150.0:
			_ui.add_child(_chevron(x, y, chev))
			x -= 120.0

	# Lato spawn (destra): da dove entrano i nemici.
	var spawn: ColorRect = ColorRect.new()
	spawn.color = Color(0.6, 0.28, 0.24, 0.4)
	spawn.position = Vector2(SPAWN_X + 8.0, LANE_Y[0] - 70.0)
	spawn.size = Vector2(5.0, LANE_Y[2] - LANE_Y[0] + 140.0)
	spawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(spawn)

	# Villaggio fortificato a codice solo se non c'è lo sprite roccaforte.
	if _siege_tex("roccaforte") == null:
		_decoro_villaggio()


# Merli in cima + porte (allineate alle corsie) con architrave — fallback senza sprite.
func _decoro_villaggio() -> void:
	var top: float = LANE_Y[0] - 70.0
	var left: float = 20.0
	var right: float = VILLAGGIO_X - 30.0
	var pietra: Color = Color(0.18, 0.14, 0.1, 1.0)
	var mx: float = left
	while mx < right - 4.0:
		var merlo: ColorRect = ColorRect.new()
		merlo.color = pietra
		merlo.position = Vector2(mx, top - 18.0)
		merlo.size = Vector2(15.0, 18.0)
		merlo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(merlo)
		mx += 26.0
	for y in LANE_Y:
		var porta: ColorRect = ColorRect.new()
		porta.color = Color(0.05, 0.035, 0.03, 1.0)
		porta.position = Vector2(right - 22.0, y - 22.0)
		porta.size = Vector2(28.0, 44.0)
		porta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(porta)
		var lintello: ColorRect = ColorRect.new()
		lintello.color = Color(0.5, 0.38, 0.22, 0.9)
		lintello.position = Vector2(right - 24.0, y - 26.0)
		lintello.size = Vector2(32.0, 4.0)
		lintello.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(lintello)


func _chevron(x: float, y: float, col: Color) -> Line2D:
	var l: Line2D = Line2D.new()
	l.points = PackedVector2Array([Vector2(x, y - 9.0), Vector2(x - 13.0, y), Vector2(x, y + 9.0)])
	l.width = 2.0
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	return l


func _crea_hud() -> void:
	var titolo: Label = Label.new()
	titolo.text = "L'ASSEDIO — Difendi il villaggio"
	titolo.add_theme_font_size_override("font_size", 30)
	titolo.add_theme_color_override("font_color", Color(0.93, 0.82, 0.5))
	titolo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	titolo.add_theme_constant_override("outline_size", 5)
	titolo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titolo.offset_top = 18.0
	titolo.offset_bottom = 56.0
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(titolo)

	# Riga diplomazia (alleati/ostili dai rapporti) sotto il titolo.
	_diplo_label = Label.new()
	_diplo_label.add_theme_font_size_override("font_size", 16)
	_diplo_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.62))
	_diplo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_diplo_label.add_theme_constant_override("outline_size", 3)
	_diplo_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_diplo_label.offset_top = 56.0
	_diplo_label.offset_bottom = 80.0
	_diplo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_diplo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_diplo_label)

	# Barra HP villaggio (in alto a sinistra).
	var cornice: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	cornice.add_theme_stylebox_override("panel", sb)
	cornice.position = Vector2(40.0, 92.0)
	cornice.size = Vector2(360.0, 60.0)
	cornice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(cornice)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	cornice.add_child(vb)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 15)
	_hp_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.72))
	vb.add_child(_hp_label)
	var track: ColorRect = ColorRect.new()
	track.color = Color(0.2, 0.12, 0.12, 0.9)
	track.custom_minimum_size = Vector2(330.0, 16.0)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(track)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.8, 0.32, 0.3)
	_hp_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_hp_fill)

	# Risorse + ondata (in alto a destra).
	_risorse_label = Label.new()
	_risorse_label.add_theme_font_size_override("font_size", 22)
	_risorse_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.5))
	_risorse_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_risorse_label.add_theme_constant_override("outline_size", 4)
	_risorse_label.position = Vector2(1480.0, 96.0)
	_risorse_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_risorse_label)
	_ondata_label = Label.new()
	_ondata_label.add_theme_font_size_override("font_size", 16)
	_ondata_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.6))
	_ondata_label.position = Vector2(1480.0, 132.0)
	_ondata_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_ondata_label)

	# Suggerimento + messaggi transitori.
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 18)
	_info_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.66))
	_info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_info_label.add_theme_constant_override("outline_size", 4)
	_info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_info_label.offset_top = -176.0
	_info_label.offset_bottom = -140.0
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_info_label)

	_aggiorna_hp()
	_aggiorna_risorse()
	_aggiorna_ondata_label()
	_aggiorna_diplo()


# --- Barra di selezione delle unità ----------------------------------------

func _crea_barra_unita() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -126.0
	bar.offset_bottom = -22.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(bar)

	for tipo in ORDINE:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(196.0, 96.0)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.add_theme_stylebox_override("panel", _card_style(false, true))
		var t: String = tipo
		card.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				_seleziona(t))
		var cvb: VBoxContainer = VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 2)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cvb)
		var ic: Texture2D = UiStyle.icona("siege", tipo)
		if ic != null:
			var iw: TextureRect = TextureRect.new()
			iw.texture = ic
			iw.custom_minimum_size = Vector2(0.0, 34.0)
			iw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			iw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			iw.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(iw)
		var nl: Label = Label.new()
		nl.text = _skin[tipo]["nome"]
		nl.add_theme_font_size_override("font_size", 19)
		nl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(nl)
		var dl: Label = Label.new()
		dl.text = ROSTER[tipo]["desc"]
		dl.add_theme_font_size_override("font_size", 13)
		dl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.62))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(dl)
		var col: Label = Label.new()
		col.text = "Costo  %d" % int(ROSTER[tipo]["costo"])
		col.add_theme_font_size_override("font_size", 15)
		col.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
		col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(col)
		bar.add_child(card)
		_card_panels[tipo] = card

	_seleziona("tiratore")


func _seleziona(tipo: String) -> void:
	_unita_selezionata = tipo
	_aggiorna_cards()
	if _info_label != null:
		_info_label.text = "Schieri: %s (costo %d) — clicca una piazzola ✦" % [
			_skin[tipo]["nome"], int(ROSTER[tipo]["costo"])]
		_info_label.modulate = Color.WHITE


func _aggiorna_cards() -> void:
	for tipo in _card_panels.keys():
		var sel: bool = tipo == _unita_selezionata
		var ok: bool = risorse >= int(ROSTER[tipo]["costo"])
		var card: PanelContainer = _card_panels[tipo]
		card.add_theme_stylebox_override("panel", _card_style(sel, ok))


func _card_style(selezionata: bool, accessibile: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.09, 0.96) if selezionata else Color(0.1, 0.08, 0.07, 0.9)
	sb.border_color = Color(0.95, 0.78, 0.42) if selezionata else Color(0.5, 0.38, 0.24)
	sb.set_border_width_all(3 if selezionata else 2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	if not accessibile:
		sb.bg_color = Color(0.08, 0.06, 0.05, 0.85)
		sb.border_color = Color(0.4, 0.3, 0.22)
	return sb


# --- Ondate / nemici --------------------------------------------------------

func _prepara_ondate() -> void:
	# Fase B: 2 raffiche distribuite sulle 3 corsie, rinforzate dalle civiltà ostili
	# (scaling completo data-driven in Fase D). Ritmo "wave burst".
	var fattore_hp: float = 1.0 + 0.12 * float(_ostili_civ.size())
	var extra: int = _ostili_civ.size()
	var corsia: int = 0
	var t: float = 1.6
	for i in range(5 + extra):
		_spawn_queue.append({"t": t, "hp": int(round(18 * fattore_hp)), "vel": 70.0, "bounty": 2, "danno": 8, "corsia": corsia})
		corsia = (corsia + 1) % LANE_Y.size()
		t += 1.0
	t += 3.5   # respiro tra le ondate
	for i in range(6 + extra):
		_spawn_queue.append({"t": t, "hp": int(round(28 * fattore_hp)), "vel": 82.0, "bounty": 3, "danno": 10, "corsia": corsia})
		corsia = (corsia + 1) % LANE_Y.size()
		t += 0.95


func _spawn_enemy(d: Dictionary) -> void:
	var e: SiegeEnemy = SiegeEnemy.new()
	e.hp_max = int(d["hp"])
	e.hp = e.hp_max
	e.velocita = float(d["vel"])
	e.bounty = int(d.get("bounty", 2))
	e.danno_villaggio = int(d.get("danno", 8))
	e.danno_melee = maxi(4, int(e.danno_villaggio / 2))
	e.villaggio_x = VILLAGGIO_X
	e.corsia = int(d.get("corsia", 0))
	e.arena = self
	e.sprite = _siege_tex("enemy")
	_world.add_child(e)
	e.global_position = Vector2(SPAWN_X, LANE_Y[e.corsia])
	e.morto.connect(func(b: int) -> void: _on_enemy_morto(e, b))
	e.arrivato.connect(func(dn: int) -> void: _on_enemy_arrivato(e, dn))
	_enemies.append(e)


func _on_enemy_morto(e: SiegeEnemy, bounty: int) -> void:
	_enemies.erase(e)
	risorse += bounty
	_aggiorna_risorse()


func _on_enemy_arrivato(e: SiegeEnemy, danno: int) -> void:
	_enemies.erase(e)
	hp_villaggio = maxi(0, hp_villaggio - danno)
	_aggiorna_hp()
	_scuoti()
	AudioManager.play_sfx("stat_down")
	if hp_villaggio <= 0:
		_termina("sopraffatto")


func _pulisci_enemies() -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_enemies[i]):
			_enemies.remove_at(i)


# --- API usate da difensori/nemici/proiettili (disaccoppiamento) ------------

func bersaglio_per(da: Vector2, raggio: float) -> SiegeEnemy:
	# Nemico più avanzato (x minore = più vicino al villaggio) entro il raggio.
	var best: SiegeEnemy = null
	var best_x: float = INF
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		if da.distance_to(e.global_position) <= raggio and e.global_position.x < best_x:
			best_x = e.global_position.x
			best = e
	return best


func nemico_per_blocco(corsia: int, x: float, reach: float) -> SiegeEnemy:
	# Nemico sulla stessa corsia, alla destra del bloccatore, entro la portata.
	var best: SiegeEnemy = null
	var best_x: float = INF
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo() or e.corsia != corsia:
			continue
		var ex: float = e.global_position.x
		if ex >= x and ex - x <= reach and ex < best_x:
			best_x = ex
			best = e
	return best


func cerca_blocco(corsia: int, x: float) -> SiegeDefender:
	# Bloccatore più vicino davanti (x minore) sulla corsia del nemico.
	var best: SiegeDefender = null
	var best_x: float = -INF
	for i in range(_blocchi.size() - 1, -1, -1):
		var d: SiegeDefender = _blocchi[i]
		if d == null or not is_instance_valid(d) or not d.vivo():
			_blocchi.remove_at(i)
			continue
		if d.corsia == corsia and d.global_position.x < x and d.global_position.x > best_x:
			best_x = d.global_position.x
			best = d
	return best


func nemici_in_area(pos: Vector2, raggio: float) -> Array:
	var out: Array = []
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		if pos.distance_to(e.global_position) <= raggio:
			out.append(e)
	return out


func lancia_proiettile(da: Vector2, bersaglio: SiegeEnemy, danno: int, aoe_raggio: float = 0.0) -> void:
	var p: SiegeProjectile = SiegeProjectile.new()
	p.bersaglio = bersaglio
	p.danno = danno
	p.aoe_raggio = aoe_raggio
	p.arena = self
	p.sprite = _fx_tex("proiettile_aoe") if aoe_raggio > 0.0 else _fx_tex("proiettile")
	_world.add_child(p)
	p.global_position = da + Vector2(0.0, -28.0)
	AudioManager.play_sfx("drop_success")


func fx_esplosione(pos: Vector2, raggio: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(1.0, 0.6, 0.25, 0.6)
	var base: float = raggio * 2.0 / 64.0
	s.scale = Vector2(base * 0.4, base * 0.4)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "scale", Vector2(base, base), 0.25)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
	t.tween_callback(s.queue_free)


# --- Schieramento difensori -------------------------------------------------

func _on_plot(slot: int, pos: Vector2) -> void:
	if _concluso:
		return
	if slot < 0 or slot >= _plot_occupato.size() or _plot_occupato[slot]:
		return
	var costo: int = int(ROSTER[_unita_selezionata]["costo"])
	if risorse < costo:
		_flash_info("Risorse insufficienti per %s" % _skin[_unita_selezionata]["nome"])
		AudioManager.play_sfx("stat_down")
		return
	risorse -= costo
	_aggiorna_risorse()
	_piazza(_unita_selezionata, slot, pos, _plot_corsia[slot])
	AudioManager.play_sfx("quest_complete")


func _piazza(tipo: String, slot: int, pos: Vector2, corsia: int, alleato: bool = false) -> void:
	var d: SiegeDefender = _crea_unita(tipo)
	d.corsia = corsia
	d.slot = slot
	d.alleato = alleato
	if d.ruolo == "blocco":
		_blocchi.append(d)
		d.distrutto.connect(_on_blocco_distrutto)
	_world.add_child(d)
	d.global_position = pos
	if slot >= 0:
		_plot_occupato[slot] = true
		if slot < _plot_markers.size() and is_instance_valid(_plot_markers[slot]):
			_plot_markers[slot].visible = false


# Costruisce un'unità con parametri SCALATI dalle statistiche della run.
func _crea_unita(tipo: String) -> SiegeDefender:
	var def: Dictionary = ROSTER[tipo]
	var skin: Dictionary = _skin[tipo]
	var d: SiegeDefender = SiegeDefender.new()
	d.arena = self
	d.ruolo = def["ruolo"]
	d.nome = skin["nome"]
	d.colore = skin["colore"]
	d.sprite = _siege_tex("unit_" + tipo)
	d.costo = int(def["costo"])
	d.cadenza = float(def["cadenza"])
	d.raggio_tiro = float(def["raggio"])
	match tipo:
		"tiratore":
			d.danno = 6 + int(GameState.get_stat("militare") / 9.0)
		"bloccatore":
			d.hp_max = 45 + int(GameState.get_stat("costruzione") * 1.3) + int(GameState.get_stat("militare") * 0.3)
			d.hp = d.hp_max
			d.danno = 4 + int(GameState.get_stat("militare") / 14.0)
		"sciamano":
			d.slow_fattore = clampf(0.62 - float(GameState.get_stat("scienza")) / 420.0, 0.34, 0.62)
			d.slow_durata = 0.7
		"totem":
			d.danno = 6 + int(float(GameState.get_stat("scienza") + GameState.get_stat("spionaggio")) / 14.0)
			d.aoe_raggio = 80.0 + float(GameState.get_stat("scienza")) / 3.0
	return d


func _on_blocco_distrutto(slot: int) -> void:
	if slot >= 0 and slot < _plot_occupato.size():
		_plot_occupato[slot] = false
		if slot < _plot_markers.size() and is_instance_valid(_plot_markers[slot]):
			_plot_markers[slot].visible = true
	AudioManager.play_sfx("stat_down")


# Le civiltà amiche schierano truppe gratuite; le ostili sono già nei rinforzi nemici.
func _schiera_alleati() -> void:
	for i in range(_alleati_civ.size()):
		var corsia: int = i % LANE_Y.size()
		var pos: Vector2 = Vector2(450.0, LANE_Y[corsia])
		var d: SiegeDefender = _crea_unita("tiratore")
		d.alleato = true
		d.corsia = corsia
		d.slot = -1
		d.colore = Color(0.55, 0.92, 0.6)
		d.danno = maxi(5, d.danno - 1)
		_world.add_child(d)
		d.global_position = pos


# Usato dallo shoot harness per popolare lo screenshot senza click reali.
func schiera_unita_test(slot: int, tipo: String) -> void:
	if slot >= 0 and slot < _plot_pos.size() and not _plot_occupato[slot]:
		_piazza(tipo, slot, _plot_pos[slot], _plot_corsia[slot])


# Compatibilità con la Fase A (shoot harness): piazza un tiratore.
func schiera_difensore_test(slot: int) -> void:
	schiera_unita_test(slot, "tiratore")


# --- Esito ------------------------------------------------------------------

func _termina(esito: String) -> void:
	if _concluso:
		return
	_concluso = true
	_attivo = false
	_mostra_esito(esito)


func _mostra_esito(esito: String) -> void:
	var trionfo: bool = esito == "trionfo"
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(dim)

	var box: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.085, 0.07, 0.96)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(26)
	box.add_theme_stylebox_override("panel", sb)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -300.0
	box.offset_right = 300.0
	box.offset_top = -150.0
	box.offset_bottom = 150.0
	dim.add_child(box)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)

	var t1: Label = Label.new()
	t1.text = "TRIONFO" if trionfo else "VILLAGGIO SOPRAFFATTO"
	t1.add_theme_font_size_override("font_size", 38)
	t1.add_theme_color_override("font_color", Color(0.95, 0.84, 0.5) if trionfo else Color(0.9, 0.5, 0.45))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)

	var t2: Label = Label.new()
	t2.text = ("Il villaggio resiste all'assalto.\nLo spirito può attraversare l'era." if trionfo
		else "Le difese cedono, ma lo spirito sopravvive.\nSi attraversa l'era, feriti.")
	t2.add_theme_font_size_override("font_size", 17)
	t2.add_theme_color_override("font_color", Color(0.85, 0.8, 0.68))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)

	var continua: Button = Button.new()
	continua.text = "Continua"
	continua.pressed.connect(func() -> void: assedio_concluso.emit(esito))
	vb.add_child(continua)

	if not trionfo:
		var riprova: Button = Button.new()
		riprova.text = "Riprova l'Assedio"
		riprova.pressed.connect(func() -> void:
			dim.queue_free()
			_riprova())
		vb.add_child(riprova)

	AudioManager.play_sfx("ledger_unlock" if trionfo else "stat_down")


func _riprova() -> void:
	for c in _world.get_children():
		c.queue_free()
	_enemies.clear()
	_blocchi.clear()
	_spawn_queue.clear()
	for i in range(_plot_occupato.size()):
		_plot_occupato[i] = false
		if i < _plot_markers.size() and is_instance_valid(_plot_markers[i]):
			_plot_markers[i].visible = true
	configura(era)
	_tempo = 0.0
	_schiera_alleati()
	_prepara_ondate()
	_aggiorna_hp()
	_aggiorna_risorse()
	_aggiorna_diplo()
	_concluso = false
	_attivo = true


# --- HUD refresh / fx -------------------------------------------------------

func _aggiorna_hp() -> void:
	if _hp_label != null:
		_hp_label.text = "Villaggio  %d / %d" % [hp_villaggio, hp_villaggio_max]
	if _hp_fill != null:
		var frac: float = clampf(float(hp_villaggio) / float(maxi(hp_villaggio_max, 1)), 0.0, 1.0)
		_hp_fill.anchor_right = frac
		_hp_fill.color = Color(0.8, 0.32, 0.3) if frac > 0.35 else Color(0.9, 0.4, 0.25)


func _aggiorna_risorse() -> void:
	if _risorse_label != null:
		_risorse_label.text = "Risorse: %d" % risorse
	_aggiorna_cards()


func _aggiorna_ondata_label() -> void:
	if _ondata_label != null:
		_ondata_label.text = "Nemici in arrivo: %d  ·  in campo: %d" % [_spawn_queue.size(), _enemies.size()]


func _aggiorna_diplo() -> void:
	if _diplo_label == null:
		return
	var parti: Array[String] = []
	if not _alleati_civ.is_empty():
		parti.append("Alleati: %s" % ", ".join(_alleati_civ))
	if not _ostili_civ.is_empty():
		parti.append("Ostili: %s" % ", ".join(_ostili_civ))
	_diplo_label.text = "   ·   ".join(parti)
	_diplo_label.visible = not parti.is_empty()


func _flash_info(msg: String) -> void:
	if _info_label == null:
		return
	_info_label.text = msg
	_info_label.modulate = Color(1.0, 0.6, 0.5)
	var t: Tween = create_tween()
	t.tween_property(_info_label, "modulate", Color.WHITE, 0.8)


func _scuoti() -> void:
	var t: Tween = create_tween()
	for i in range(4):
		t.tween_property(self, "offset", Vector2(randf_range(-7, 7), randf_range(-4, 4)), 0.05)
	t.tween_property(self, "offset", Vector2.ZERO, 0.08)


func _disc_texture() -> GradientTexture2D:
	var g: Gradient = Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex

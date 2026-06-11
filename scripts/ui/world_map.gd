extends CanvasLayer

# Schermata "stato del mondo" mostrata nei momenti chiave (transizione d'era).
# Impila i 4 layer-mappa e anima un crossfade da `_da_era` a `_a_era`:
# i confini e le regioni emergono sulla terra mentre la civilta' cresce.
# Sopra i layer compaiono gli INSEDIAMENTI (sprite isometrici di map_transformation):
# in Era 1 sono primitivi, nella transizione crescono in citta'/regni con un pulse
# d'energia (live_feedback) sulla capitale, tinto dall'approccio dominante della run.
# Chiamare `configura()` PRIMA di add_child() (gli @onready si risolvono in _ready).

signal chiuso

const LAYER_PATHS: Dictionary = {
	"terrain": "res://Assets/art/map/layers/terrain_layer.png",
	"base": "res://Assets/art/map/layers/base_continent.png",
	"regions": "res://Assets/art/map/layers/region_and_province.png",
	"political": "res://Assets/art/map/layers/political_overlay.png",
}

# Alpha di ogni layer per era: il mondo "cresce" politicamente avanzando.
const ALPHA_PER_ERA: Dictionary = {
	1: {"terrain": 1.0, "base": 0.35, "regions": 0.0, "political": 0.0},
	2: {"terrain": 1.0, "base": 1.0, "regions": 0.6, "political": 0.85},
}

const FADE_LAYER_SEC: float = 1.6
const CINZEL_PATH: String = "res://Assets/fonts/Cinzel.ttf"

# Aspetto reale del continente dipinto: serve per fittare i marker sulla terra
# qualunque sia la risoluzione (i TextureRect usano KEEP_ASPECT_CENTERED).
const MAP_NATIVE: Vector2 = Vector2(1264, 848)

const TRANSFORM_PATH: String = "res://Assets/art/map/map_transformation/%02d.png"
const FEEDBACK_PATH: String = "res://Assets/art/map/live_feedback/%02d.png"
const DL_PATH: String = "res://Assets/art/map/dynamic_lines/%s.png"

# Civilta' rivali: zona d'influenza colorata vicino al bordo + rotta dalla capitale.
# La rotta e' commerciale (oro) o di guerra (rossa) a seconda del rapporto in
# GameState.rapporti_civilta. popolo_nebbie compare solo a mystery attiva.
const CIV_ZONES: Array[Dictionary] = [
	{"civ": "impero_sole", "pos": Vector2(0.82, 0.23), "zona": "zone_red", "scala": 1.05},
	{"civ": "lega_coste", "pos": Vector2(0.16, 0.74), "zona": "zone_green", "scala": 1.0},
	{"civ": "popolo_nebbie", "pos": Vector2(0.87, 0.74), "zona": "zone_purple", "scala": 0.9, "solo_mystery": true},
]

# Insediamenti: posizione normalizzata sul continente (0-1, ancorati in basso-centro),
# sprite primitivo (Era 1) -> evoluto (Era 2), scala. Posizioni scelte sulla terraferma
# della dorsale centrale, evitando i laghi.
const MARKER_SITES: Array[Dictionary] = [
	{"pos": Vector2(0.50, 0.42), "era1": 2, "era2": 0, "scala": 0.95, "capitale": true},
	{"pos": Vector2(0.33, 0.34), "era1": 6, "era2": 1, "scala": 0.75, "capitale": false},
	{"pos": Vector2(0.66, 0.31), "era1": 3, "era2": 1, "scala": 0.70, "capitale": false},
	{"pos": Vector2(0.44, 0.63), "era1": 5, "era2": 3, "scala": 0.72, "capitale": false},
	{"pos": Vector2(0.61, 0.58), "era1": 6, "era2": 1, "scala": 0.78, "capitale": false},
]

# Effetto-pulse sulla capitale, scelto dall'approccio dominante del giocatore.
const FEEDBACK_PER_STAT: Dictionary = {
	"militare": 0,      # fiamma
	"tesoro": 1,        # spirale verde (crescita/ricchezza)
	"diplomazia": 4,    # onda cyan (calma)
	"scienza": 3,       # cristallo blu
	"legge": 4,         # onda cyan
	"spionaggio": 2,    # corruzione viola
	"popolo": 1,        # spirale verde
	"costruzione": 3,   # cristallo blu
}

var _da_era: int = 1
var _a_era: int = 2
var _titolo: String = ""
var _sottotitolo: String = ""
var _pronto: bool = false

# {sito_index: {"primitivo": TextureRect, "evoluto": TextureRect, "fx": TextureRect|null}}
var _markers: Array[Dictionary] = []
# Zone d'influenza + rotte da far comparire con l'emergere della politica (Era 2).
var _diplomazia_nodi: Array[Control] = []

@onready var root: Control = $Root
@onready var terrain: TextureRect = $Root/MapRoot/Terrain
@onready var base: TextureRect = $Root/MapRoot/Base
@onready var regions: TextureRect = $Root/MapRoot/Regions
@onready var political: TextureRect = $Root/MapRoot/Political
@onready var map_root: Control = $Root/MapRoot
@onready var titolo_label: Label = $Root/Header/Titolo
@onready var sottotitolo_label: Label = $Root/Header/Sottotitolo
@onready var footer_label: Label = $Root/Footer
@onready var background: ColorRect = $Root/Background


func configura(da_era: int, a_era: int, titolo: String, sottotitolo: String) -> void:
	_da_era = da_era
	_a_era = a_era
	_titolo = titolo
	_sottotitolo = sottotitolo


func _layer_node(nome: String) -> TextureRect:
	match nome:
		"terrain": return terrain
		"base": return base
		"regions": return regions
		"political": return political
	return null


func _ready() -> void:
	for nome in LAYER_PATHS:
		var path: String = LAYER_PATHS[nome]
		if ResourceLoader.exists(path):
			_layer_node(nome).texture = load(path)

	if ResourceLoader.exists(CINZEL_PATH):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(CINZEL_PATH)
		fv.variation_opentype = {"wght": 700}
		titolo_label.add_theme_font_override("font", fv)

	# contorno per leggibilità sopra mappe chiare
	for lab in [titolo_label, sottotitolo_label, footer_label]:
		lab.add_theme_constant_override("outline_size", 6 if lab == titolo_label else 4)
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))

	titolo_label.text = _titolo
	sottotitolo_label.text = _sottotitolo
	footer_label.text = "Premi INVIO per continuare"

	background.modulate.a = 0.0
	titolo_label.modulate.a = 0.0
	sottotitolo_label.modulate.a = 0.0
	footer_label.modulate.a = 0.0

	var da: Dictionary = ALPHA_PER_ERA.get(_da_era, ALPHA_PER_ERA[1])
	var a: Dictionary = ALPHA_PER_ERA.get(_a_era, ALPHA_PER_ERA[2])
	for nome in LAYER_PATHS:
		_layer_node(nome).modulate.a = da.get(nome, 0.0)

	_crea_markers()

	var t: Tween = create_tween()
	# fase 1: sfondo + titoli appaiono insieme
	t.tween_property(background, "modulate:a", 1.0, 0.6)
	t.parallel().tween_property(titolo_label, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(sottotitolo_label, "modulate:a", 1.0, 1.0)
	# gli insediamenti primitivi compaiono con i titoli
	t.parallel().tween_callback(_mostra_markers_iniziali)
	# fase 2: il mondo si trasforma - i layer fanno crossfade in parallelo tra loro,
	# ma come blocco sequenziale DOPO la fase 1
	var primo: bool = true
	for nome in LAYER_PATHS:
		if is_equal_approx(da.get(nome, 0.0), a.get(nome, 0.0)):
			continue  # alpha invariato: niente tween inutile
		var step: Tween = t if primo else t.parallel()
		step.tween_property(
			_layer_node(nome), "modulate:a", a.get(nome, 0.0), FADE_LAYER_SEC
		).set_trans(Tween.TRANS_SINE)
		primo = false
	# fase 2b: gli insediamenti crescono mentre emergono i confini
	t.tween_callback(_cresci_insediamenti)
	# fase 3: prompt
	t.tween_interval(0.3)
	t.tween_property(footer_label, "modulate:a", 1.0, 0.5)
	t.tween_callback(func() -> void: _pronto = true)


# --- Insediamenti -----------------------------------------------------------

func _fitted_rect() -> Rect2:
	# Rettangolo effettivo del continente dentro MapRoot (KEEP_ASPECT_CENTERED).
	var avail: Vector2 = get_viewport().get_visible_rect().size
	var scala: float = minf(avail.x / MAP_NATIVE.x, avail.y / MAP_NATIVE.y)
	var dim: Vector2 = MAP_NATIVE * scala
	var off: Vector2 = (avail - dim) * 0.5
	return Rect2(off, dim)


func _tex_transform(idx: int) -> Texture2D:
	var path: String = TRANSFORM_PATH % idx
	return load(path) if ResourceLoader.exists(path) else null


func _crea_markers() -> void:
	var contenitore: Control = Control.new()
	contenitore.name = "Markers"
	contenitore.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenitore.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_root.add_child(contenitore)

	var rect: Rect2 = _fitted_rect()
	# zone d'influenza + rotte vanno DIETRO gli insediamenti (aggiunte per prime)
	if _a_era >= 2:
		_crea_diplomazia(contenitore, rect)
	for sito in MARKER_SITES:
		var punto: Vector2 = rect.position + sito["pos"] * rect.size
		var primitivo: TextureRect = _crea_sprite(sito["era1"], sito["scala"], punto)
		var evoluto: TextureRect = _crea_sprite(sito["era2"], sito["scala"], punto)
		evoluto.modulate.a = 0.0
		var fx: TextureRect = null
		if sito.get("capitale", false):
			fx = _crea_fx(punto, sito["scala"])
		# ordine di disegno: glow (fx) DIETRO, poi insediamento sopra
		if fx != null:
			contenitore.add_child(fx)
		if primitivo != null:
			contenitore.add_child(primitivo)
		if evoluto != null:
			contenitore.add_child(evoluto)
		_markers.append({"primitivo": primitivo, "evoluto": evoluto, "fx": fx})


func _crea_diplomazia(contenitore: Control, rect: Rect2) -> void:
	var mapscala: float = rect.size.x / MAP_NATIVE.x
	var capitale: Vector2 = rect.position + MARKER_SITES[0]["pos"] * rect.size
	for civ in CIV_ZONES:
		if civ.get("solo_mystery", false) and not GameState.mystery_attiva:
			continue
		var centro: Vector2 = rect.position + civ["pos"] * rect.size
		var rapporto: int = int(GameState.rapporti_civilta.get(civ["civ"], 0))
		# rotta dalla capitale verso la civilta' (sotto la zona)
		var rotta: TextureRect = _crea_rotta(capitale, centro, rapporto, mapscala)
		if rotta != null:
			contenitore.add_child(rotta)
			_diplomazia_nodi.append(rotta)
		# zona d'influenza colorata
		var zona: TextureRect = _crea_zona(civ["zona"], centro, civ.get("scala", 1.0), mapscala)
		if zona != null:
			contenitore.add_child(zona)
			_diplomazia_nodi.append(zona)


func _crea_zona(nome: String, centro: Vector2, scala: float, mapscala: float) -> TextureRect:
	var path: String = DL_PATH % nome
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * mapscala * scala
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	tr.position = centro - dim * 0.5
	tr.modulate = Color(1, 1, 1, 0.0)
	tr.set_meta("alpha_target", 0.3)
	return tr


func _crea_rotta(da: Vector2, a: Vector2, rapporto: int, mapscala: float) -> TextureRect:
	var nome: String = "route_war" if rapporto < 0 else "route_trade"
	var path: String = DL_PATH % nome
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var aspetto: float = float(tex.get_height()) / float(tex.get_width())
	var dist: float = da.distance_to(a)
	# la rotta-texture e' un arco orizzontale: larghezza = distanza, altezza proporzionale (appiattita)
	var larghezza: float = dist
	var altezza: float = larghezza * aspetto * 0.55
	tr.size = Vector2(larghezza, altezza)
	tr.pivot_offset = Vector2(0, altezza * 0.5)  # ancora a sinistra-centro (sulla capitale)
	tr.position = da - Vector2(0, altezza * 0.5)
	tr.rotation = (a - da).angle()
	tr.modulate = Color(1, 1, 1, 0.0)
	tr.set_meta("alpha_target", 0.75)
	return tr


func _crea_sprite(idx: int, scala: float, punto_base: Vector2) -> TextureRect:
	var tex: Texture2D = _tex_transform(idx)
	if tex == null:
		return null
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * scala
	tr.size = dim
	tr.pivot_offset = Vector2(dim.x * 0.5, dim.y)  # ancora basso-centro
	# posiziona la base dello sprite sul punto-terra
	tr.position = punto_base - Vector2(dim.x * 0.5, dim.y)
	return tr


func _crea_fx(punto_base: Vector2, scala: float) -> TextureRect:
	var stat: String = GameState.stat_dominante()
	var idx: int = FEEDBACK_PER_STAT.get(stat, 4)
	var path: String = FEEDBACK_PATH % idx
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * scala * 0.55
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	# glow centrato sul corpo dell'insediamento (sopra la base), non occludente
	tr.position = punto_base - Vector2(dim.x * 0.5, dim.y * 0.5 + 60.0)
	tr.modulate = Color(1, 1, 1, 0.0)
	return tr


func _mostra_markers_iniziali() -> void:
	# Gli insediamenti primitivi sfumano in vista insieme ai titoli.
	for m in _markers:
		var primitivo: TextureRect = m["primitivo"]
		if primitivo == null:
			continue
		primitivo.modulate.a = 0.0
		var t: Tween = create_tween()
		t.tween_interval(randf() * 0.3)
		t.tween_property(primitivo, "modulate:a", 1.0, 0.6)


func _cresci_insediamenti() -> void:
	# Crossfade primitivo -> evoluto solo se l'era di arrivo e' >= 2.
	var cresce: bool = _a_era >= 2
	var ritardo: float = 0.0
	for m in _markers:
		var primitivo: TextureRect = m["primitivo"]
		var evoluto: TextureRect = m["evoluto"]
		var fx: TextureRect = m["fx"]
		if cresce and evoluto != null:
			var t: Tween = create_tween()
			t.tween_interval(ritardo)
			t.tween_property(evoluto, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.parallel().tween_property(evoluto, "scale", Vector2.ONE * 1.06, 0.7).from(Vector2.ONE * 0.85)
			if primitivo != null:
				t.parallel().tween_property(primitivo, "modulate:a", 0.0, 0.5)
			ritardo += 0.18
		if fx != null:
			_avvia_pulse(fx)
	_mostra_diplomazia()


func _mostra_diplomazia() -> void:
	# Zone d'influenza e rotte emergono con la politica (alpha diversi: zone tenui,
	# rotte piu' marcate). Le rotte sono TextureRect ruotate -> niente tween su scale.
	var ritardo: float = 0.2
	for nodo in _diplomazia_nodi:
		var bersaglio: float = float(nodo.get_meta("alpha_target", 0.5))
		var t: Tween = create_tween()
		t.tween_interval(ritardo)
		t.tween_property(nodo, "modulate:a", bersaglio, 0.9).set_trans(Tween.TRANS_SINE)
		ritardo += 0.15


func _avvia_pulse(fx: TextureRect) -> void:
	var t: Tween = create_tween()
	t.tween_property(fx, "modulate:a", 0.6, 0.8)
	var loop: Tween = create_tween()
	loop.set_loops()
	loop.set_trans(Tween.TRANS_SINE)
	loop.tween_property(fx, "scale", Vector2.ONE * 1.12, 1.4)
	loop.parallel().tween_property(fx, "modulate:a", 0.4, 1.4)
	loop.tween_property(fx, "scale", Vector2.ONE * 0.96, 1.4)
	loop.parallel().tween_property(fx, "modulate:a", 0.62, 1.4)


func _unhandled_input(event: InputEvent) -> void:
	if not _pronto:
		return
	var chiudi: bool = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			chiudi = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chiudi = true
	if chiudi:
		get_viewport().set_input_as_handled()
		_chiudi()


func _chiudi() -> void:
	_pronto = false
	set_process_unhandled_input(false)
	var t: Tween = create_tween()
	t.tween_property(root, "modulate:a", 0.0, 0.4)
	t.tween_callback(func() -> void:
		chiuso.emit()
		queue_free()
	)

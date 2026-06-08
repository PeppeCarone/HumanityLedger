extends CanvasLayer

# Schermata "stato del mondo" mostrata nei momenti chiave (transizione d'era).
# Impila i 4 layer-mappa e anima un crossfade da `_da_era` a `_a_era`:
# i confini e le regioni emergono sulla terra mentre la civilta' cresce.
# Chiamare `configura()` PRIMA di add_child() (gli @onready si risolvono in _ready).

signal chiuso

const LAYER_PATHS: Dictionary = {
	"terrain": "res://Assets/terrain_layer.png",
	"base": "res://Assets/base_continent.png",
	"regions": "res://Assets/region_and_province.png",
	"political": "res://Assets/political_overlay.png",
}

# Alpha di ogni layer per era: il mondo "cresce" politicamente avanzando.
const ALPHA_PER_ERA: Dictionary = {
	1: {"terrain": 1.0, "base": 0.35, "regions": 0.0, "political": 0.0},
	2: {"terrain": 1.0, "base": 1.0, "regions": 0.6, "political": 0.85},
}

const FADE_LAYER_SEC: float = 1.6
const CINZEL_PATH: String = "res://Assets/fonts/Cinzel.ttf"

var _da_era: int = 1
var _a_era: int = 2
var _titolo: String = ""
var _sottotitolo: String = ""
var _pronto: bool = false

@onready var root: Control = $Root
@onready var terrain: TextureRect = $Root/MapRoot/Terrain
@onready var base: TextureRect = $Root/MapRoot/Base
@onready var regions: TextureRect = $Root/MapRoot/Regions
@onready var political: TextureRect = $Root/MapRoot/Political
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

	var t: Tween = create_tween()
	# fase 1: sfondo + titoli appaiono insieme
	t.tween_property(background, "modulate:a", 1.0, 0.6)
	t.parallel().tween_property(titolo_label, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(sottotitolo_label, "modulate:a", 1.0, 1.0)
	# fase 2: il mondo si trasforma - i layer fanno crossfade in parallelo tra loro,
	# ma come blocco sequenziale DOPO la fase 1
	var primo: bool = true
	for nome in LAYER_PATHS:
		if is_equal_approx(da.get(nome, 0.0), a.get(nome, 0.0)):
			continue  # alpha invariato: niente tween inutile
		var tw: PropertyTweener = t.tween_property(
			_layer_node(nome), "modulate:a", a.get(nome, 0.0), FADE_LAYER_SEC
		).set_trans(Tween.TRANS_SINE)
		if not primo:
			tw.set_parallel(true)
		primo = false
	# fase 3: prompt
	t.tween_property(footer_label, "modulate:a", 1.0, 0.5)
	t.tween_callback(func() -> void: _pronto = true)


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

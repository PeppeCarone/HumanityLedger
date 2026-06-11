extends Control
class_name VillageView

# Fondale vivo: il villaggio del popolo che cresce a ogni decisione.
# Sta dietro ai pannelli UI (traslucidi). Mostra una fila di edifici isometrici
# su una linea di terra; ogni decisione di costruzione ne fa sorgere uno nuovo con
# animazione, le altre decisioni mostrano un effetto (guerra/alleanza/scienza...).
# Riusa map_transformation (edifici) e live_feedback (effetti).

const VILLAGGIO: String = "res://Assets/art/villaggio/era%d/%02d.png"
const FEEDBACK: String = "res://Assets/art/map/live_feedback/%02d.png"
const TERRENO: String = "res://Assets/art/terreni/era%d.png"

# Sequenza di edifici per era (indici dei sprite in Assets/art/villaggio/era<N>/):
# era1: 0 tenda, 1 capanna, 2 totem, 3 focolare, 4 essiccatoio, 5 palizzata
# era2: 0 tempio, 1 mercato, 2 torre, 3 fonderia, 4 mura, 5 archivio
const EDIFICI_ERA: Dictionary = {
	1: [3, 0, 1, 4, 2, 5],
	2: [0, 1, 2, 5, 3, 4],
}

# Tableau del villaggio per era: slot con posizione normalizzata e scala relativa.
# Le file dietro sono piu' in alto e piu' piccole (profondita'). Era 2 sta sulla
# fascia bassa (lo sfondo e' un panorama: la "terra" utile e' il primo piano),
# evitando la zona del CallButton (x 0.40-0.72, y > 0.81).
const SLOTS_ERA: Dictionary = {
	1: [
		{"x": 0.50, "y": 0.620, "s": 0.85},
		{"x": 0.36, "y": 0.660, "s": 0.92},
		{"x": 0.65, "y": 0.660, "s": 0.92},
		{"x": 0.24, "y": 0.740, "s": 1.00},
		{"x": 0.78, "y": 0.740, "s": 1.00},
		{"x": 0.58, "y": 0.780, "s": 1.05},
	],
	2: [
		{"x": 0.47, "y": 0.800, "s": 0.82},
		{"x": 0.34, "y": 0.840, "s": 0.90},
		{"x": 0.66, "y": 0.840, "s": 0.90},
		{"x": 0.22, "y": 0.910, "s": 1.00},
		{"x": 0.80, "y": 0.910, "s": 1.00},
		{"x": 0.33, "y": 0.960, "s": 1.02},
	],
}
const SCALA_EDIFICIO: float = 0.78

# Tabellone (D046): quando esiste il terreno dedicato dell'era, gli edifici si
# dispongono sulle piazzole della radura/spianata come in un board di strategia.
# Il fronte-centro resta libero per il CallButton (x 0.40-0.72, y > 0.81).
const SLOTS_BOARD: Array[Dictionary] = [
	{"x": 0.50, "y": 0.560, "s": 0.90},
	{"x": 0.33, "y": 0.620, "s": 0.95},
	{"x": 0.67, "y": 0.620, "s": 0.95},
	{"x": 0.25, "y": 0.780, "s": 1.05},
	{"x": 0.75, "y": 0.780, "s": 1.05},
	{"x": 0.50, "y": 0.820, "s": 1.08},
]

# Effetto + tinta per tipo di conseguenza.
const FX_CONSEGUENZA: Dictionary = {
	"guerra":      {"idx": 0, "col": Color(1.0, 0.5, 0.35)},
	"alleanza":    {"idx": 1, "col": Color(0.6, 1.0, 0.7)},
	"scienza":     {"idx": 3, "col": Color(0.6, 0.85, 1.0)},
	"costruzione": {"idx": 4, "col": Color(1.0, 0.92, 0.7)},
	"ricchezza":   {"idx": 1, "col": Color(1.0, 0.88, 0.5)},
	"neutro":      {"idx": 4, "col": Color(0.9, 0.85, 1.0)},
}

var _era: int = 1
var _slot_usati: int = 0
var _edifici_nodi: Array[TextureRect] = []
@onready var _suolo: Control = $Suolo
@onready var _fx: Control = $Fx


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _baseline() -> Vector2:
	var s: Vector2 = size if size.x > 0 else get_viewport().get_visible_rect().size
	return s


func _tex(idx: int) -> Texture2D:
	var p: String = VILLAGGIO % [_era, idx]
	return load(p) if ResourceLoader.exists(p) else null


# Ricostruisce il villaggio per l'era data, con `n` edifici, senza animazione.
func sincronizza(era: int, n: int) -> void:
	_era = era
	for nodo in _edifici_nodi:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_edifici_nodi.clear()
	_slot_usati = 0
	var quanti: int = mini(n, _slots().size())
	for i in quanti:
		_posa_edificio(false)
	_fuoco_centrale()


# Bagliore caldo pulsante dietro l'edificio centrale (focolare/tempio): il segno
# che il villaggio e' vivo. Si rigenera a ogni sincronizza.
func _fuoco_centrale() -> void:
	if _slot_usati == 0:
		return
	var p: String = FEEDBACK % 4
	if not ResourceLoader.exists(p):
		return
	var slot: Dictionary = _slots()[0]
	var s: Vector2 = _baseline()
	var tex: Texture2D = load(p)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * 0.65
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	tr.position = Vector2(float(slot["x"]) * s.x - dim.x * 0.5,
		float(slot["y"]) * s.y - dim.y * 0.72)
	tr.modulate = Color(1.0, 0.85, 0.55, 0.3)
	_suolo.add_child(tr)
	_suolo.move_child(tr, 0)
	_edifici_nodi.append(tr)
	var t: Tween = tr.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(tr, "modulate:a", 0.5, 1.4)
	t.tween_property(tr, "modulate:a", 0.25, 1.4)


func _slots() -> Array:
	# Col terreno-tabellone si usano le piazzole; senza, il layout adattato
	# alle scene dipinte (fallback pre-D046).
	if ResourceLoader.exists(TERRENO % _era):
		return SLOTS_BOARD
	return SLOTS_ERA.get(_era, SLOTS_ERA[1])


func _base_y() -> float:
	return 0.80 if _era >= 2 else 0.68


# Aggiunge un edificio al prossimo slot. Se animato, sorge dal terreno con polvere.
func costruisci() -> void:
	_posa_edificio(true)


func _posa_edificio(animato: bool) -> TextureRect:
	if _slot_usati >= _slots().size():
		return null
	var seq: Array = EDIFICI_ERA.get(_era, EDIFICI_ERA[1])
	var idx: int = seq[_slot_usati % seq.size()]
	var tex: Texture2D = _tex(idx)
	if tex == null:
		return null
	var slot: Dictionary = _slots()[_slot_usati]
	var s: Vector2 = _baseline()
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * SCALA_EDIFICIO * float(slot["s"])
	tr.size = dim
	tr.pivot_offset = Vector2(dim.x * 0.5, dim.y)
	var px: float = float(slot["x"]) * s.x
	var py: float = float(slot["y"]) * s.y
	tr.position = Vector2(px - dim.x * 0.5, py - dim.y)
	var ombra: TextureRect = _ombra(px, py, dim.x, animato)
	_suolo.add_child(tr)
	_edifici_nodi.append(tr)
	if ombra != null:
		_edifici_nodi.append(ombra)
	_slot_usati += 1
	if animato:
		tr.modulate.a = 0.0
		tr.scale = Vector2(0.6, 0.2)  # schiacciato, sorge
		var t: Tween = create_tween()
		t.tween_property(tr, "modulate:a", 1.0, 0.5)
		t.parallel().tween_property(tr, "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_polvere(Vector2(px, py))
	return tr


# Ombra di contatto ellittica sotto l'edificio: lo ancora al terreno.
func _ombra(px: float, py: float, larghezza: float, animata: bool) -> TextureRect:
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.42), Color(0, 0, 0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var dim: Vector2 = Vector2(larghezza * 1.05, larghezza * 0.34)
	tr.size = dim
	tr.position = Vector2(px - dim.x * 0.5, py - dim.y * 0.58)
	_suolo.add_child(tr)
	if animata:
		tr.modulate.a = 0.0
		var t: Tween = create_tween()
		t.tween_property(tr, "modulate:a", 1.0, 0.6)
	return tr


func _polvere(base: Vector2) -> void:
	# breve sbuffo di "polvere" alla base dell'edificio che sorge
	var p: String = FEEDBACK % 6
	if not ResourceLoader.exists(p):
		return
	var tex: Texture2D = load(p)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(140, 90)
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	tr.position = base - Vector2(dim.x * 0.5, dim.y * 0.7)
	tr.modulate = Color(0.85, 0.78, 0.65, 0.0)
	_fx.add_child(tr)
	var t: Tween = create_tween()
	t.tween_property(tr, "modulate:a", 0.7, 0.2)
	t.tween_property(tr, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(tr, "scale", Vector2.ONE * 1.4, 0.8)
	t.tween_callback(tr.queue_free)


# Mostra l'effetto della conseguenza al centro del villaggio.
func applica_conseguenza(tipo: String) -> void:
	var dati: Dictionary = FX_CONSEGUENZA.get(tipo, FX_CONSEGUENZA["neutro"])
	if tipo == "costruzione":
		costruisci()
		return
	var p: String = FEEDBACK % int(dati["idx"])
	if not ResourceLoader.exists(p):
		return
	var s: Vector2 = _baseline()
	var tex: Texture2D = load(p)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * 0.9
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	tr.position = Vector2(s.x * 0.5 - dim.x * 0.5, _base_y() * s.y - dim.y * 0.62)
	tr.modulate = Color(dati["col"].r, dati["col"].g, dati["col"].b, 0.0)
	_fx.add_child(tr)
	var t: Tween = create_tween()
	t.tween_property(tr, "modulate:a", 0.85, 0.35)
	t.parallel().tween_property(tr, "scale", Vector2.ONE * 1.15, 1.1).from(Vector2.ONE * 0.7)
	t.tween_interval(0.5)
	t.tween_property(tr, "modulate:a", 0.0, 0.7)
	t.tween_callback(tr.queue_free)

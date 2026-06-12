extends Control
class_name VillageView

# Fondale vivo: il villaggio del popolo che cresce a ogni decisione.
# Sta dietro ai pannelli UI (traslucidi). Mostra una fila di edifici isometrici
# su una linea di terra; ogni decisione di costruzione ne fa sorgere uno nuovo con
# animazione, le altre decisioni mostrano un effetto (guerra/alleanza/scienza...).
# Riusa map_transformation (edifici) e live_feedback (effetti).

const VILLAGGIO: String = "res://Assets/art/villaggio/era%d/%02d.png"
const FEEDBACK: String = "res://Assets/art/map/live_feedback/%02d.png"
const FX: String = "res://Assets/art/fx/%02d.png"
const TERRENO: String = "res://Assets/art/terreni/era%d.jpg"

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

# Effetto + tinta per tipo di conseguenza (sprite painterly in art/fx:
# 0 = vortice di braci, 1 = nebbia viola, 2 = alone dorato).
const FX_CONSEGUENZA: Dictionary = {
	"guerra":      {"idx": 0, "col": Color(1.0, 0.85, 0.8)},
	"alleanza":    {"idx": 2, "col": Color(0.75, 1.0, 0.8)},
	"scienza":     {"idx": 1, "col": Color(0.65, 0.85, 1.0)},
	"costruzione": {"idx": 2, "col": Color(1.0, 0.92, 0.7)},
	"ricchezza":   {"idx": 2, "col": Color(1.0, 0.9, 0.55)},
	"neutro":      {"idx": 1, "col": Color(1.0, 0.95, 1.0)},
}

var _era: int = 1
var _slot_usati: int = 0
var _edifici_nodi: Array[TextureRect] = []
var _edifici_sprite: Array[TextureRect] = []  # solo gli edifici (per la tinta prosperita')
var _fumo: CPUParticles2D = null
var _tinta_prosperita: Color = Color.WHITE
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
	_edifici_sprite.clear()
	_slot_usati = 0
	var quanti: int = mini(n, _slots().size())
	for i in quanti:
		_posa_edificio(false)
	_fuoco_centrale()
	_avvia_fumo()


# Bagliore caldo pulsante dietro l'edificio centrale (focolare/tempio): il segno
# che il villaggio e' vivo. Si rigenera a ogni sincronizza.
func _fuoco_centrale() -> void:
	if _slot_usati == 0:
		return
	var p: String = FX % 2
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
	tr.modulate = _tinta_prosperita
	_suolo.add_child(tr)
	_edifici_nodi.append(tr)
	_edifici_sprite.append(tr)
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


# Filo di fumo dal focolare/tempio centrale: il villaggio respira anche da fermo.
func _avvia_fumo() -> void:
	if _fumo != null and is_instance_valid(_fumo):
		_fumo.queue_free()
	_fumo = null
	if _slot_usati == 0:
		return
	var slot: Dictionary = _slots()[0]
	var s: Vector2 = _baseline()
	_fumo = CPUParticles2D.new()
	_fumo.position = Vector2(float(slot["x"]) * s.x, float(slot["y"]) * s.y - 64.0)
	_fumo.amount = 10
	_fumo.lifetime = 3.4
	_fumo.preprocess = 2.5
	_fumo.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_fumo.emission_sphere_radius = 6.0
	_fumo.direction = Vector2(0, -1)
	_fumo.spread = 16.0
	_fumo.gravity = Vector2(5, -26)
	_fumo.initial_velocity_min = 6.0
	_fumo.initial_velocity_max = 13.0
	_fumo.scale_amount_min = 0.35
	_fumo.scale_amount_max = 0.8
	var soft: Gradient = Gradient.new()
	soft.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	soft.offsets = PackedFloat32Array([0.0, 1.0])
	var soft_tex: GradientTexture2D = GradientTexture2D.new()
	soft_tex.gradient = soft
	soft_tex.fill = GradientTexture2D.FILL_RADIAL
	soft_tex.fill_from = Vector2(0.5, 0.5)
	soft_tex.fill_to = Vector2(1.0, 0.5)
	soft_tex.width = 32
	soft_tex.height = 32
	_fumo.texture = soft_tex
	var ramp: Gradient = Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.78, 0.73, 0.66, 0.22), Color(0.7, 0.68, 0.66, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	_fumo.color_ramp = ramp
	_suolo.add_child(_fumo)


# Lo stato del regno si legge sugli edifici: crisi = spenti, benessere = dorati.
func aggiorna_prosperita(popolo: int, tesoro: int) -> void:
	var p: float = clampf(float(popolo + tesoro) / 120.0, 0.0, 1.0)
	var tinta: Color = Color.WHITE
	if p < 0.25:
		tinta = Color(0.72, 0.68, 0.62)
	elif p > 0.66:
		tinta = Color(1.06, 1.01, 0.90)
	if tinta == _tinta_prosperita:
		return
	_tinta_prosperita = tinta
	for nodo in _edifici_sprite:
		if is_instance_valid(nodo):
			var t: Tween = nodo.create_tween()
			t.tween_property(nodo, "modulate", tinta, 1.2)


# Mostra l'effetto della conseguenza al centro del villaggio.
func applica_conseguenza(tipo: String) -> void:
	var dati: Dictionary = FX_CONSEGUENZA.get(tipo, FX_CONSEGUENZA["neutro"])
	if tipo == "costruzione":
		costruisci()
		return
	var p: String = FX % int(dati["idx"])
	if not ResourceLoader.exists(p):
		return
	var s: Vector2 = _baseline()
	var tex: Texture2D = load(p)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# normalizza l'altezza (gli sprite fx hanno dimensioni native diverse)
	var dim: Vector2 = Vector2(tex.get_size()) * minf(1.0, 340.0 / float(tex.get_height()))
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

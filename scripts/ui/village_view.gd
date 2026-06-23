extends Control
class_name VillageView

# Emesso quando il giocatore clicca un edificio costruito (per migliorarlo).
signal edificio_cliccato(slot: int)
# Emesso quando il giocatore clicca il lotto vuoto "costruisci qui".
signal plot_cliccato(slot: int)

# Fondale vivo: il villaggio del popolo che cresce a ogni decisione.
# Sta dietro ai pannelli UI (traslucidi). Mostra una fila di edifici isometrici
# su una linea di terra; ogni decisione di costruzione ne fa sorgere uno nuovo con
# animazione, le altre decisioni mostrano un effetto (guerra/alleanza/scienza...).
# Riusa map_transformation (edifici) e live_feedback (effetti).

const VILLAGGIO: String = "res://Assets/art/villaggio/era%d/%02d.png"
# Variante per-stadio opzionale: se esiste, sostituisce lo sprite base al salire
# di livello (es. era1/05_lv2.png). Altrimenti resta lo sprite base + stelle.
const VILLAGGIO_LV: String = "res://Assets/art/villaggio/era%d/%02d_lv%d.png"
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
const SCALA_EDIFICIO: float = 0.66

# Tabellone (D046): quando esiste il terreno dedicato dell'era, gli edifici si
# dispongono sulle piazzole della radura/spianata come in un board di strategia.
# Il fronte-centro resta libero per il CallButton (x 0.40-0.72, y > 0.81).
const SLOTS_BOARD: Array[Dictionary] = [
	{"x": 0.49, "y": 0.600, "s": 1.05},
	{"x": 0.33, "y": 0.620, "s": 0.95},
	{"x": 0.67, "y": 0.620, "s": 0.95},
	{"x": 0.25, "y": 0.780, "s": 1.05},
	{"x": 0.75, "y": 0.780, "s": 1.05},
	{"x": 0.50, "y": 0.820, "s": 1.08},
]

# Effetto + tinta per tipo di conseguenza (sprite painterly in art/fx:
# 0 = vortice di braci, 1 = nebbia viola, 2 = alone dorato).
# Tinte ancorate alla palette bronzo/oro/ambra e desaturate ~45% (audit AAA #4):
# niente verdi/blu acidi che stonano col fondale painterly. La guerra vira al
# brace, l'alleanza a un salvia-oro tenue, la scienza a un acciaio freddo ma muto.
const FX_CONSEGUENZA: Dictionary = {
	"guerra":      {"idx": 0, "col": Color(0.95, 0.62, 0.45)},
	"alleanza":    {"idx": 2, "col": Color(0.80, 0.86, 0.62)},
	"scienza":     {"idx": 1, "col": Color(0.68, 0.80, 0.88)},
	"costruzione": {"idx": 2, "col": Color(0.98, 0.88, 0.62)},
	"ricchezza":   {"idx": 2, "col": Color(1.0, 0.86, 0.5)},
	"neutro":      {"idx": 1, "col": Color(0.92, 0.88, 0.80)},
}

# --- Villaggio Vivo (P11): diorama atmosferico. Tutto fallback-safe ----------
# Decorazioni e attori compaiono SOLO se lo sprite esiste (assenza elegante, mai
# placeholder). Meteo è procedurale (texture opzionale in fx/meteo migliora la resa).
const DECO: String = "res://Assets/art/villaggio/deco/era%d/%s.png"
const VITA: String = "res://Assets/art/villaggio/vita/era%d/%s.png"
const METEO: String = "res://Assets/art/fx/meteo/%s.png"

# Props sparsi sul board, lontani dalla zona del CallButton (x 0.40-0.72, y>0.81)
# e dagli slot edificio. {n: nome-file, x/y: posizione normalizzata, s: scala, sway: dondolio}
const DECORAZIONI_ERA: Dictionary = {
	1: [
		{"n": "albero_secco", "x": 0.08, "y": 0.55, "s": 0.85, "sway": true},
		{"n": "masso",        "x": 0.14, "y": 0.67, "s": 0.55},
		{"n": "pelli",        "x": 0.17, "y": 0.80, "s": 0.55},
		{"n": "erba",         "x": 0.44, "y": 0.69, "s": 0.42, "sway": true},
		{"n": "ossa",         "x": 0.71, "y": 0.70, "s": 0.42},
		{"n": "cespuglio",    "x": 0.89, "y": 0.63, "s": 0.50, "sway": true},
		{"n": "idolo",        "x": 0.93, "y": 0.55, "s": 0.55},
		{"n": "catasta",      "x": 0.84, "y": 0.81, "s": 0.52},
		{"n": "pozza",        "x": 0.13, "y": 0.90, "s": 0.70},
	],
	2: [
		{"n": "statua",   "x": 0.09, "y": 0.62, "s": 0.85},
		{"n": "casse",    "x": 0.15, "y": 0.78, "s": 0.55},
		{"n": "lampione", "x": 0.20, "y": 0.62, "s": 0.80, "sway": true},
		{"n": "fioriera", "x": 0.45, "y": 0.72, "s": 0.42},
		{"n": "panca",    "x": 0.72, "y": 0.73, "s": 0.50},
		{"n": "pozzo",    "x": 0.90, "y": 0.64, "s": 0.62},
		{"n": "carretto", "x": 0.85, "y": 0.83, "s": 0.58},
		{"n": "lampione", "x": 0.86, "y": 0.60, "s": 0.80, "sway": true},
		{"n": "fontana",  "x": 0.30, "y": 0.69, "s": 0.62},
		{"n": "fontana_acqua", "x": 0.12, "y": 0.92, "s": 0.72},
	],
}

# Attori della vita ambientale per era. Persone/animali camminano; uccelli volano a timer.
const VITA_ERA: Dictionary = {
	1: {"persone": ["abitante1", "abitante2", "anziano"], "bambino": "bambino",
		"animali": ["cane", "cervo"], "uccelli": "corvi"},
	2: {"persone": ["mercante", "guardia", "studioso"], "bambino": "bambino",
		"animali": ["cavallo", "gatto"], "uccelli": "colombe"},
}

var _era: int = 1
var _slot_usati: int = 0
var _edifici_nodi: Array[Node] = []  # tutti i nodi da liberare alla resync (TextureRect, particelle, ombre)
var _edifici_sprite: Array[TextureRect] = []  # solo gli edifici (per la tinta prosperita')
var _slot_tipo: Array[int] = []  # tipo-edificio per ogni slot (indice = slot)
var _potenziabili: Array[int] = []  # slot attualmente migliorabili (glow d'invito)
var _marker_costruibile: Control = null  # lotto vuoto "costruisci qui"
var _bandiere: Array[Control] = []  # stendardi degli alleati ai margini (J15)
var _attori: Array[Control] = []  # camminatori della vita ambientale (per le reazioni)
var _fumo: CPUParticles2D = null
var _tinta_prosperita: Color = Color.WHITE
@onready var _suolo: Control = $Suolo
@onready var _fx: Control = $Fx


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.edificio_migliorato.connect(_on_edificio_migliorato)


func tipo_at(slot: int) -> int:
	if slot < 0 or slot >= _slot_tipo.size():
		return -1
	return _slot_tipo[slot]


func slot_count() -> int:
	return _edifici_sprite.size()


func slot_max() -> int:
	return _slots().size()


# Tipo-edificio che verrebbe piazzato sul prossimo lotto vuoto (per il pannello build).
func tipo_previsto(slot: int) -> int:
	var seq: Array = EDIFICI_ERA.get(_era, EDIFICI_ERA[1])
	if seq.is_empty():
		return -1
	return int(seq[slot % seq.size()])


# Marker pulsante "costruisci qui" sul prossimo lotto libero (uno solo: i lotti si
# riempiono in sequenza). Sparisce quando il villaggio è pieno.
func _aggiorna_plot_costruibile() -> void:
	if _marker_costruibile != null and is_instance_valid(_marker_costruibile):
		_marker_costruibile.queue_free()
	_marker_costruibile = null
	var slots: Array = _slots()
	if _slot_usati >= slots.size():
		return
	var slot: Dictionary = slots[_slot_usati]
	var s: Vector2 = _baseline()
	var pad_w: float = 120.0
	var holder: Control = Control.new()
	holder.name = "PlotCostruibile"
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	holder.size = Vector2(pad_w, pad_w)
	holder.position = Vector2(float(slot["x"]) * s.x - pad_w * 0.5,
		float(slot["y"]) * s.y - pad_w * 0.6)
	var next_slot: int = _slot_usati
	holder.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			plot_cliccato.emit(next_slot))
	var pad: TextureRect = TextureRect.new()
	# Anello dorato a terra (asset §8k) invece del disco-gradiente che sembrava un falò.
	var ring: Texture2D = UiStyle.ui_texture("ring_select")
	pad.texture = ring if ring != null else _disc_texture()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pad.stretch_mode = TextureRect.STRETCH_SCALE
	pad.size = Vector2(pad_w, pad_w * 0.52)
	pad.position = Vector2(0, pad_w * 0.46)
	pad.modulate = Color(1, 1, 1, 0.75) if ring != null else Color(0.98, 0.84, 0.46, 0.35)
	holder.add_child(pad)
	var plus: Label = Label.new()
	plus.text = "+"
	plus.add_theme_font_size_override("font_size", 44)
	plus.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	plus.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.95))
	plus.add_theme_constant_override("outline_size", 6)
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(plus)
	_suolo.add_child(holder)
	var t: Tween = holder.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(pad, "modulate:a", 0.65, 0.85)
	t.tween_property(pad, "modulate:a", 0.3, 0.85)


func _on_edificio_migliorato(era: int, slot: int, _lv: int) -> void:
	if era != _era:
		return
	_aggiorna_livello_edificio(slot)
	_pop_upgrade(slot)


# Aspetto dell'edificio in base al livello (1..3): scala leggermente crescente +
# stelle dorate sopra. Lo "stacco" visivo dice "migliorato" senza nuovi asset.
func _aggiorna_livello_edificio(slot: int) -> void:
	if slot < 0 or slot >= _edifici_sprite.size():
		return
	var tr: TextureRect = _edifici_sprite[slot]
	if not is_instance_valid(tr):
		return
	var lv: int = GameState.livello_edificio(_era, slot)
	# Se esiste arte dedicata per lo stadio, usala (altrimenti sprite base + stelle).
	var tipo: int = _slot_tipo[slot] if slot < _slot_tipo.size() else -1
	if tipo >= 0:
		var lv_path: String = VILLAGGIO_LV % [_era, tipo, lv]
		if ResourceLoader.exists(lv_path):
			tr.texture = load(lv_path)
	tr.scale = Vector2.ONE * (1.0 + 0.07 * float(lv - 1))
	var vecchio: Node = tr.get_node_or_null("LvBadge")
	if vecchio != null:
		vecchio.queue_free()
	if lv <= 1:
		return
	var badge: Label = Label.new()
	badge.name = "LvBadge"
	badge.text = "★".repeat(lv - 1)
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	badge.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.9))
	badge.add_theme_constant_override("outline_size", 5)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.position = Vector2(tr.size.x * 0.5 - float(lv - 1) * 11.0, -30.0)
	tr.add_child(badge)


func danneggia(slot: int) -> void:
	# Sciagura: l'edificio cala di livello con scuotimento, lampo rosso e polvere.
	if slot < 0 or slot >= _edifici_sprite.size():
		return
	var tr: TextureRect = _edifici_sprite[slot]
	if not is_instance_valid(tr):
		return
	_aggiorna_livello_edificio(slot)  # meno stelle, scala minore
	var base_pos: Vector2 = tr.position
	var t: Tween = tr.create_tween()
	for i in range(5):
		t.tween_property(tr, "position",
			base_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-3.0, 3.0)), 0.04)
	t.tween_property(tr, "position", base_pos, 0.06)
	tr.modulate = Color(1.0, 0.5, 0.45)
	var flash: Tween = tr.create_tween()
	flash.tween_property(tr, "modulate", _tinta_prosperita, 0.55).set_trans(Tween.TRANS_SINE)
	_polvere(tr.position + Vector2(tr.size.x * 0.5, tr.size.y * 0.45))


func _pop_upgrade(slot: int) -> void:
	if slot < 0 or slot >= _edifici_sprite.size():
		return
	var tr: TextureRect = _edifici_sprite[slot]
	if not is_instance_valid(tr):
		return
	var target: Vector2 = tr.scale
	var t: Tween = tr.create_tween()
	t.tween_property(tr, "scale", target * 1.18, 0.12) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(tr, "scale", target, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_polvere(tr.position + Vector2(tr.size.x * 0.5, 0.0))
	# Lampo dorato che si espande dalla base: l'upgrade "sboccia".
	var flash: TextureRect = TextureRect.new()
	flash.texture = _disc_texture()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flash.stretch_mode = TextureRect.STRETCH_SCALE
	var w: float = tr.size.x * 1.1
	flash.size = Vector2(w, w)
	flash.pivot_offset = flash.size * 0.5
	flash.position = tr.position + Vector2(tr.size.x * 0.5 - w * 0.5, tr.size.y - w * 0.62)
	flash.modulate = Color(1.0, 0.86, 0.45, 0.9)
	_fx.add_child(flash)
	var ft: Tween = flash.create_tween()
	ft.set_parallel()
	ft.tween_property(flash, "scale", Vector2.ONE * 1.6, 0.6).from(Vector2.ONE * 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ft.tween_property(flash, "modulate:a", 0.0, 0.6)
	ft.chain().tween_callback(flash.queue_free)


# Glow d'invito "potenziabile ora" alla base degli edifici migliorabili (stile RTS).
func segna_potenziabili(slots: Array) -> void:
	_potenziabili.clear()
	for s in slots:
		_potenziabili.append(int(s))
	for i in range(_edifici_sprite.size()):
		_aggiorna_glow_affordance(i)


func _aggiorna_glow_affordance(slot: int) -> void:
	if slot < 0 or slot >= _edifici_sprite.size():
		return
	var tr: TextureRect = _edifici_sprite[slot]
	if not is_instance_valid(tr):
		return
	var ring: TextureRect = tr.get_node_or_null("AffordGlow")
	var vuole: bool = slot in _potenziabili
	if vuole and ring == null:
		ring = TextureRect.new()
		ring.name = "AffordGlow"
		# Anello "potenziabile" (asset §8k) a terra: chiaro, non un alone di fuoco.
		var up: Texture2D = UiStyle.ui_texture("ring_upgrade")
		ring.texture = up if up != null else _disc_texture()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ring.stretch_mode = TextureRect.STRETCH_SCALE
		var w: float = tr.size.x * 0.9
		ring.size = Vector2(w, w * 0.5)
		ring.position = Vector2(tr.size.x * 0.5 - w * 0.5, tr.size.y - w * 0.36)
		ring.modulate = Color(1, 1, 1, 0.0)
		tr.add_child(ring)
		tr.move_child(ring, 0)  # dietro la sagoma dell'edificio
		var t: Tween = ring.create_tween()
		t.set_loops()
		t.set_trans(Tween.TRANS_SINE)
		t.tween_property(ring, "modulate:a", 0.85, 0.8)
		t.tween_property(ring, "modulate:a", 0.4, 0.8)
		ring.set_meta("tw", t)
	elif not vuole and ring != null:
		var t: Variant = ring.get_meta("tw", null)
		if t != null and (t as Tween).is_valid():
			(t as Tween).kill()
		ring.queue_free()


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
	_slot_tipo.clear()
	_attori.clear()
	for b in _bandiere:
		if is_instance_valid(b):
			b.queue_free()
	_bandiere.clear()
	_slot_usati = 0
	var quanti: int = mini(n, _slots().size())
	_posa_decorazioni(era)
	for i in quanti:
		_posa_edificio(false)
	_fuoco_centrale()
	_avvia_fumo()
	_avvia_meteo(era)
	_avvia_vita_ambientale(era)
	_aggiorna_plot_costruibile()


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
	# Flicker organico via shader (oltre al pulse di alpha): la luce del fuoco vibra.
	var sh_path: String = "res://Assets/shaders/fire_flicker.gdshader"
	if ResourceLoader.exists(sh_path):
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = load(sh_path)
		tr.material = mat
	_suolo.add_child(tr)
	_suolo.move_child(tr, 0)
	_edifici_nodi.append(tr)
	var t: Tween = tr.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(tr, "modulate:a", 0.5, 1.4)
	t.tween_property(tr, "modulate:a", 0.25, 1.4)
	_avvia_braci(Vector2(float(slot["x"]) * s.x, float(slot["y"]) * s.y - 30.0))


# Braci/scintille che salgono dal fuoco centrale: il cuore del villaggio è vivo.
func _avvia_braci(pos: Vector2) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.amount = 16
	p.lifetime = 1.7
	p.preprocess = 1.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.direction = Vector2(0, -1)
	p.spread = 24.0
	p.gravity = Vector2(5, -44)
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.13
	p.texture = _disc_texture()
	var ramp: Gradient = Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 0.78, 0.35, 0.95), Color(0.85, 0.3, 0.12, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = ramp
	_suolo.add_child(p)
	_edifici_nodi.append(p)   # ripulito alla prossima sincronizza


func _slots() -> Array:
	# Col terreno-tabellone si usano le piazzole; senza, il layout adattato
	# alle scene dipinte (fallback pre-D046).
	if ResourceLoader.exists(TERRENO % _era):
		return SLOTS_BOARD
	return SLOTS_ERA.get(_era, SLOTS_ERA[1])


func _base_y() -> float:
	return 0.80 if _era >= 2 else 0.68


# Aggiunge un edificio al prossimo slot. Se animato, sorge dal terreno con polvere.
func costruisci(tipo_forzato: int = -1) -> void:
	_posa_edificio(true, tipo_forzato)
	_aggiorna_plot_costruibile()


func _posa_edificio(animato: bool, tipo_forzato: int = -1) -> TextureRect:
	if _slot_usati >= _slots().size():
		return null
	var seq: Array = EDIFICI_ERA.get(_era, EDIFICI_ERA[1])
	var idx: int = tipo_forzato if tipo_forzato >= 0 else int(seq[_slot_usati % seq.size()])
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
	# Edificio interattivo: cliccabile per essere migliorato (stile Clash of Clans).
	var slot_idx: int = _slot_usati
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.set_meta("slot", slot_idx)
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tr.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			edificio_cliccato.emit(slot_idx))
	_suolo.add_child(tr)
	_edifici_nodi.append(tr)
	_edifici_sprite.append(tr)
	_slot_tipo.append(idx)
	if ombra != null:
		_edifici_nodi.append(ombra)
	_slot_usati += 1
	_aggiorna_livello_edificio(slot_idx)
	if animato:
		tr.modulate.a = 0.0
		tr.scale = Vector2(0.6, 0.2)  # schiacciato, sorge
		var t: Tween = create_tween()
		t.tween_property(tr, "modulate:a", 1.0, 0.5)
		t.parallel().tween_property(tr, "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_polvere(Vector2(px, py))
		t.tween_callback(_idle_edificio.bind(tr))
	else:
		_idle_edificio(tr)
	return tr


# Respiro/oscillazione idle dell'edificio: lieve dondolio attorno alla base (pivot in
# basso), come mosso dal vento. Ampiezza/durata random per desincronizzare gli edifici
# → il villaggio sembra "vivo" senza nuovi asset. La rotazione non tocca scale/modulate
# (usati da livello/prosperità/upgrade), quindi non confligge.
func _idle_edificio(tr: TextureRect) -> void:
	if not is_instance_valid(tr):
		return
	var amp: float = deg_to_rad(randf_range(0.5, 1.2))
	var dur: float = randf_range(2.1, 3.3)
	tr.rotation = randf_range(-amp, amp)   # fase iniziale random
	var t: Tween = tr.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(tr, "rotation", amp, dur)
	t.tween_property(tr, "rotation", -amp, dur)


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


# --- Villaggio Vivo (P11): decorazioni, meteo, vita ambientale ---------------

# Props sparsi che riempiono il board, dietro agli edifici. Solo-se-asset
# (assenza elegante, nessun placeholder). Fuori dalla zona del CallButton.
func _posa_decorazioni(era: int) -> void:
	var lista: Array = DECORAZIONI_ERA.get(era, [])
	var s: Vector2 = _baseline()
	for d in lista:
		var path: String = DECO % [era, str(d["n"])]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var scala: float = float(d.get("s", 0.5))
		var dim: Vector2 = Vector2(tex.get_size()) * SCALA_EDIFICIO * scala
		var px: float = float(d["x"]) * s.x
		var py: float = float(d["y"]) * s.y
		var ombra: TextureRect = _ombra(px, py, dim.x, false)
		var tr: TextureRect = TextureRect.new()
		tr.texture = tex
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = dim
		tr.pivot_offset = Vector2(dim.x * 0.5, dim.y)
		tr.position = Vector2(px - dim.x * 0.5, py - dim.y)
		tr.modulate = _tinta_prosperita
		_suolo.add_child(tr)
		_edifici_nodi.append(tr)
		if ombra != null:
			_edifici_nodi.append(ombra)
		if bool(d.get("sway", false)):
			_idle_edificio(tr)


# Meteo per era: neve che scende (Era 1) o brace/cenere che sale (Era 2). Procedurale;
# usa fx/meteo/<nome>.png se presente, altrimenti un puntino soft (fallback-safe).
func _avvia_meteo(era: int) -> void:
	var s: Vector2 = _baseline()
	var neve: bool = era < 2
	var p: CPUParticles2D = CPUParticles2D.new()
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(s.x * 0.55, 30.0)
	p.spread = 12.0
	var nome: String = "neve" if neve else "brace"
	var mpath: String = METEO % nome
	p.texture = load(mpath) if ResourceLoader.exists(mpath) else _disc_texture()
	if neve:
		p.position = Vector2(s.x * 0.5, -20.0)
		p.amount = 55
		p.lifetime = 9.0
		p.direction = Vector2(0.25, 1)
		p.gravity = Vector2(7, 22)
		p.initial_velocity_min = 18.0
		p.initial_velocity_max = 40.0
		p.scale_amount_min = 0.05
		p.scale_amount_max = 0.14
		var rn: Gradient = Gradient.new()
		rn.colors = PackedColorArray([
			Color(0.95, 0.97, 1.0, 0.0), Color(0.95, 0.97, 1.0, 0.8),
			Color(0.9, 0.93, 1.0, 0.0)])
		rn.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		p.color_ramp = rn
	else:
		p.position = Vector2(s.x * 0.5, s.y * 1.02)
		p.amount = 38
		p.lifetime = 6.5
		p.direction = Vector2(0, -1)
		p.gravity = Vector2(4, -18)
		p.initial_velocity_min = 14.0
		p.initial_velocity_max = 34.0
		p.scale_amount_min = 0.04
		p.scale_amount_max = 0.12
		var re: Gradient = Gradient.new()
		re.colors = PackedColorArray([
			Color(1.0, 0.7, 0.3, 0.0), Color(1.0, 0.6, 0.25, 0.85),
			Color(0.7, 0.2, 0.1, 0.0)])
		re.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		p.color_ramp = re
	p.preprocess = p.lifetime
	_fx.add_child(p)
	_edifici_nodi.append(p)


# Vita ambientale: abitanti/animali camminano, uccelli attraversano il cielo. Conteggio
# legato a Popolazione (riusa GameState.popolo). Tutto solo-se-asset.
func _avvia_vita_ambientale(era: int) -> void:
	if _slot_usati == 0:
		return
	var cfg: Dictionary = VITA_ERA.get(era, VITA_ERA[1])
	var popolo: int = GameState.popolo
	var persone: Array = cfg.get("persone", [])
	var n_persone: int = clampi(int(popolo / 14.0) + 1, 1, 4)
	for i in range(n_persone):
		if persone.is_empty():
			break
		_posa_camminatore(era, str(persone[i % persone.size()]),
			randf_range(0.60, 0.80), randf_range(0.55, 0.85))
	if popolo >= 20 and cfg.has("bambino"):
		_posa_camminatore(era, str(cfg["bambino"]), randf_range(0.66, 0.82), 0.5, true)
	var animali: Array = cfg.get("animali", [])
	if not animali.is_empty():
		_posa_camminatore(era, str(animali[randi() % animali.size()]),
			randf_range(0.70, 0.86), 0.62)
	if cfg.has("uccelli"):
		_avvia_uccelli(era, str(cfg["uccelli"]))


# Un camminatore: holder (ombra + sprite) che va avanti/indietro con flip di direzione
# e leggero bob. Default sprite rivolto a destra (asset §11c/d).
func _posa_camminatore(era: int, nome: String, banda_y: float, scala: float,
		veloce: bool = false) -> void:
	var path: String = VITA % [era, nome]
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var s: Vector2 = _baseline()
	var dim: Vector2 = Vector2(tex.get_size()) * SCALA_EDIFICIO * 0.42 * scala
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var py: float = banda_y * s.y
	var xa: float = randf_range(0.16, 0.40) * s.x
	var xb: float = randf_range(0.60, 0.88) * s.x
	holder.position = Vector2(randf_range(minf(xa, xb), maxf(xa, xb)), py)
	# Ombra di contatto come blob soft figlio del holder (segue il camminatore).
	var shdim: Vector2 = Vector2(dim.x * 0.7, dim.x * 0.24)
	var sh: TextureRect = TextureRect.new()
	sh.texture = _disc_texture()
	sh.modulate = Color(0, 0, 0, 0.3)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sh.stretch_mode = TextureRect.STRETCH_SCALE
	sh.size = shdim
	sh.position = Vector2(-shdim.x * 0.5, -shdim.y * 0.5)
	holder.add_child(sh)
	var sp: TextureRect = TextureRect.new()
	sp.texture = tex
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp.size = dim
	sp.pivot_offset = Vector2(dim.x * 0.5, dim.y)
	sp.position = Vector2(-dim.x * 0.5, -dim.y)
	sp.modulate = _tinta_prosperita
	holder.add_child(sp)
	_suolo.add_child(holder)
	_edifici_nodi.append(holder)
	_attori.append(holder)
	var vel: float = 70.0 if veloce else 42.0
	var dur: float = maxf(2.0, absf(xb - xa) / vel)
	var t: Tween = holder.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_face.bind(sp, true))
	t.tween_property(holder, "position:x", maxf(xa, xb), dur)
	t.tween_callback(_face.bind(sp, false))
	t.tween_property(holder, "position:x", minf(xa, xb), dur)
	var base_y: float = sp.position.y
	var b: Tween = sp.create_tween()
	b.set_loops()
	b.set_trans(Tween.TRANS_SINE)
	b.tween_property(sp, "position:y", base_y - 4.0, 0.4)
	b.tween_property(sp, "position:y", base_y, 0.4)


func _face(sp: TextureRect, destra: bool) -> void:
	if not is_instance_valid(sp):
		return
	var a: float = absf(sp.scale.x)
	if a == 0.0:
		a = 1.0
	sp.scale.x = a if destra else -a


# Uccelli che attraversano il cielo a intervalli (uno stormo per volta).
func _avvia_uccelli(era: int, nome: String) -> void:
	var path: String = VITA % [era, nome]
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var timer: Timer = Timer.new()
	timer.wait_time = randf_range(8.0, 14.0)
	timer.autostart = true
	timer.timeout.connect(func() -> void: _vola_stormo(tex))
	_suolo.add_child(timer)
	_edifici_nodi.append(timer)
	_vola_stormo(tex)


func _vola_stormo(tex: Texture2D) -> void:
	var s: Vector2 = _baseline()
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var dim: Vector2 = Vector2(tex.get_size()) * 0.22
	tr.size = dim
	var dir: int = 1 if randf() < 0.5 else -1
	var y0: float = randf_range(0.10, 0.30) * s.y
	var x_start: float = -dim.x if dir > 0 else s.x + dim.x
	var x_end: float = s.x + dim.x if dir > 0 else -dim.x
	tr.position = Vector2(x_start, y0)
	tr.scale.x = float(dir)
	tr.modulate = Color(1, 1, 1, 0.85)
	_fx.add_child(tr)
	var dur: float = randf_range(5.0, 8.0)
	var t: Tween = tr.create_tween()
	t.tween_property(tr, "position:x", x_end, dur).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(tr.queue_free)
	var w: Tween = tr.create_tween()
	w.set_loops()
	w.set_trans(Tween.TRANS_SINE)
	w.tween_property(tr, "position:y", y0 - 10.0, 0.7)
	w.tween_property(tr, "position:y", y0, 0.7)


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


# Gli abitanti reagiscono alla conseguenza: un saltello con flash di tinta (guerra = rosso/
# fuga più alta, alleanza/festa = oro, neutro = lieve). Hop sulla position:y del holder
# (indipendente dal walk su position:x e dal bob sullo sprite) → niente conflitti di tween.
func _reazione_attori(tipo: String) -> void:
	if _attori.is_empty():
		return
	var spaventa: bool = tipo in ["guerra", "neutro"]
	var col: Color = Color(1.35, 0.7, 0.6) if tipo == "guerra" else Color(1.2, 1.12, 0.7)
	var salto: float = 18.0 if spaventa else 11.0
	for h in _attori:
		if not is_instance_valid(h):
			continue
		var base_y: float = h.position.y
		var ht: Tween = h.create_tween()
		ht.tween_property(h, "position:y", base_y - salto, 0.13) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ht.tween_property(h, "position:y", base_y, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var sp: Node = h.get_child(1) if h.get_child_count() > 1 else null
		if sp is TextureRect:
			var ft: Tween = sp.create_tween()
			ft.tween_property(sp, "modulate", col, 0.15)
			ft.tween_property(sp, "modulate", _tinta_prosperita, 0.55)


# Mostra l'effetto della conseguenza al centro del villaggio. `intensita` (≈0.8–1.6,
# dal delta-stat maggiore della scelta) scala dimensione e durata del burst: J7 — una
# svolta forte "pesa" di più a schermo di un aggiustamento minore.
func applica_conseguenza(tipo: String, intensita: float = 1.0) -> void:
	var dati: Dictionary = FX_CONSEGUENZA.get(tipo, FX_CONSEGUENZA["neutro"])
	_reazione_attori(tipo)
	if tipo == "costruzione":
		costruisci()
		return
	var p: String = FX % int(dati["idx"])
	if not ResourceLoader.exists(p):
		return
	var fattore: float = clampf(intensita, 0.75, 1.6)
	var s: Vector2 = _baseline()
	var tex: Texture2D = load(p)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# normalizza l'altezza (gli sprite fx hanno dimensioni native diverse) × intensità
	var dim: Vector2 = Vector2(tex.get_size()) * minf(1.5, 320.0 * fattore / float(tex.get_height()))
	tr.size = dim
	tr.pivot_offset = dim * 0.5
	tr.position = Vector2(s.x * 0.5 - dim.x * 0.5, _base_y() * s.y - dim.y * 0.62)
	tr.modulate = Color(dati["col"].r, dati["col"].g, dati["col"].b, 0.0)
	_fx.add_child(tr)
	var t: Tween = create_tween()
	t.tween_property(tr, "modulate:a", 0.85, 0.35)
	t.parallel().tween_property(tr, "scale", Vector2.ONE * (1.0 + 0.18 * fattore), 1.1).from(Vector2.ONE * 0.7)
	t.tween_interval(0.4 + 0.45 * fattore)
	t.tween_property(tr, "modulate:a", 0.0, 0.55 + 0.35 * fattore)
	t.tween_callback(tr.queue_free)


# J15 — Stendardi degli alleati radicati ai margini del villaggio: la diplomazia si
# vede a casa. Uno per civilta' alleata (rapporto >= soglia), col volto dell'ambasciatore
# nel medaglione. Riusa gli sprite di Assets/art/ambasciatori/<civ_id>.png.
func mostra_bandiere_alleati(civ_ids: Array) -> void:
	for b in _bandiere:
		if is_instance_valid(b):
			b.queue_free()
	_bandiere.clear()
	if civ_ids.is_empty():
		return
	var s: Vector2 = _baseline()
	# Ancore che fiancheggiano il board, ben visibili sul terreno, fuori dalla zona del
	# CallButton (x 0.40-0.72) e dalla figura in basso a sinistra.
	var ancore: Array = [
		Vector2(0.86, 0.52), Vector2(0.63, 0.40),
		Vector2(0.40, 0.40), Vector2(0.93, 0.70),
	]
	var i: int = 0
	for civ in civ_ids:
		if i >= ancore.size():
			break
		var a: Vector2 = ancore[i]
		_posa_bandiera(str(civ), Vector2(a.x * s.x, a.y * s.y))
		i += 1


func _posa_bandiera(civ_id: String, pos: Vector2) -> void:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = pos
	holder.pivot_offset = Vector2.ZERO  # base a terra: cresce verso l'alto
	_suolo.add_child(holder)
	_bandiere.append(holder)
	# Se esiste lo sprite dello stendardo (asset §P10), usalo col volto nel medaglione.
	var sten_path: String = "res://Assets/art/villaggio/stendardo_alleato.png"
	if ResourceLoader.exists(sten_path):
		_posa_bandiera_sprite(holder, civ_id, load(sten_path))
		return
	const H: float = 132.0  # altezza asta
	# Ombra di contatto a terra.
	var ombra: ColorRect = ColorRect.new()
	ombra.color = Color(0, 0, 0, 0.28)
	ombra.size = Vector2(34, 9)
	ombra.position = Vector2(-17, -6)
	ombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ombra)
	# Asta + traversa in cima (da cui pende il gonfalone).
	var pole: ColorRect = ColorRect.new()
	pole.color = Color(0.28, 0.19, 0.11)
	pole.size = Vector2(6, H)
	pole.position = Vector2(-3, -H)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(pole)
	var crossbar: ColorRect = ColorRect.new()
	crossbar.color = Color(0.34, 0.24, 0.13)
	crossbar.size = Vector2(52, 6)
	crossbar.position = Vector2(-26, -H)
	crossbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(crossbar)
	# Gonfalone: bordo scuro + telo tinto alleanza, ondeggia appeso dalla traversa.
	var swing: Control = Control.new()  # pivot in alto: oscilla solo il telo
	swing.position = Vector2(0, -H + 6)
	swing.pivot_offset = Vector2.ZERO
	swing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(swing)
	var bordo: ColorRect = ColorRect.new()
	bordo.color = Color(0.16, 0.12, 0.07, 0.96)
	bordo.size = Vector2(54, 80)
	bordo.position = Vector2(-27, 0)
	bordo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swing.add_child(bordo)
	var cloth: ColorRect = ColorRect.new()
	cloth.color = Color(0.78, 0.67, 0.33, 0.97)
	cloth.size = Vector2(48, 74)
	cloth.position = Vector2(-24, 3)
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swing.add_child(cloth)
	# Banda alta più scura (resa araldica) + medaglione col volto dell'ambasciatore.
	var banda: ColorRect = ColorRect.new()
	banda.color = Color(0.55, 0.40, 0.18, 0.9)
	banda.size = Vector2(48, 16)
	banda.position = Vector2(-24, 3)
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swing.add_child(banda)
	var face_path: String = "res://Assets/art/ambasciatori/%s.png" % civ_id
	if ResourceLoader.exists(face_path):
		var face: TextureRect = TextureRect.new()
		face.texture = load(face_path)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.size = Vector2(34, 34)
		face.position = Vector2(-17, 28)  # centrato sul telo
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swing.add_child(face)
		var ring_tex: Texture2D = UiStyle.ui_texture("medallion")
		if ring_tex != null:
			var ring: TextureRect = TextureRect.new()
			ring.texture = ring_tex
			ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ring.stretch_mode = TextureRect.STRETCH_SCALE
			ring.size = Vector2(46, 46)
			ring.position = Vector2(-23, 22)
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			swing.add_child(ring)
	# Ingresso: lo stendardo sorge dal terreno.
	holder.scale = Vector2(1.0, 0.0)
	var t: Tween = holder.create_tween()
	t.tween_property(holder, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ondeggio lento del telo (il villaggio respira anche da fermo).
	var w: Tween = swing.create_tween()
	w.set_loops()
	w.set_trans(Tween.TRANS_SINE)
	w.tween_property(swing, "rotation", deg_to_rad(3.0), 1.6)
	w.tween_property(swing, "rotation", deg_to_rad(-3.0), 1.6)


# Variante con sprite §P10: gonfalone dipinto + volto dell'ambasciatore sul medaglione.
func _posa_bandiera_sprite(holder: Control, civ_id: String, tex: Texture2D) -> void:
	const W: float = 80.0
	const H: float = 120.0
	var sprite: TextureRect = TextureRect.new()
	sprite.texture = tex
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = Vector2(W, H)
	sprite.position = Vector2(-W * 0.5, -H)
	sprite.pivot_offset = Vector2(W * 0.5, 0.0)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sprite)
	# Volto dell'ambasciatore sul medaglione del gonfalone (~46% dall'alto).
	var face_path: String = "res://Assets/art/ambasciatori/%s.png" % civ_id
	if ResourceLoader.exists(face_path):
		var face: TextureRect = TextureRect.new()
		face.texture = load(face_path)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var fs: float = W * 0.38
		face.size = Vector2(fs, fs)
		face.position = Vector2(-fs * 0.5, -H + H * 0.46 - fs * 0.5)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.add_child(face)
	holder.scale = Vector2(1.0, 0.0)
	var t: Tween = holder.create_tween()
	t.tween_property(holder, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sw: Tween = sprite.create_tween()
	sw.set_loops()
	sw.set_trans(Tween.TRANS_SINE)
	sw.tween_property(sprite, "rotation", deg_to_rad(2.5), 1.7)
	sw.tween_property(sprite, "rotation", deg_to_rad(-2.5), 1.7)

extends Control

@export var item_id: String = ""
@export var label_text: String = "Item"
@export var icon_texture: Texture2D
@export var icon_color: Color = Color(0.2, 0.15, 0.1, 0.85)
@export var stat_to_modify: String = ""
@export var stat_delta: int = 0
@export var feedback_text: String = ""
@export var target_text: String = ""
@export var target_color: Color = Color(0.55, 0.88, 0.6)
@export var hint_text: String = ""
@export var stat_hint_text: String = ""
@export var descrizione_strategia: String = ""   # "Nome — natura" della carta (tooltip ricco)

@onready var bg: Panel = $Background
@onready var icon_rect: TextureRect = $IconTexture
@onready var lbl: Label = $Label
@onready var target_lbl: Label = $Target
@onready var stat_hint_lbl: Label = $StatHint

const COL_LABEL_NORMALE: Color = Color(0.97, 0.92, 0.8)
const COL_LABEL_DISABILITATO: Color = Color(0.85, 0.5, 0.42)

var _consumed: bool = false
var _disabled: bool = false
var _disabled_reason: String = ""
var _med: Control = null
var _hover_tween: Tween = null


func _ready() -> void:
	_crea_medaglione()
	_refresh()
	# Affordance "prendimi": al passaggio del mouse la carta si solleva e il medaglione
	# si accende d'oro. Niente durante il drag o se è bloccata/usata.
	mouse_entered.connect(_hover_in)
	mouse_exited.connect(_hover_out)
	pivot_offset = custom_minimum_size * Vector2(0.5, 0.5)


# Medaglione circolare bronzo dietro l'icona: i token strategia diventano emblemi
# coerenti coi medaglioni-artefatto del Ledger (audit UI #5), senza nuova arte.
func _crea_medaglione() -> void:
	if has_node("Medaglione") or _med != null:
		return
	var node: Control
	var tex: Texture2D = UiStyle.ui_texture("medallion")
	if tex != null:
		# Anello bronzo dipinto (§8g) al posto del cerchio a codice.
		var tr: TextureRect = TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node = tr
	else:
		var med: Panel = Panel.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.17, 0.12, 0.08, 0.94)
		sb.border_color = Color(0.66, 0.49, 0.27)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(62)
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 7
		med.add_theme_stylebox_override("panel", sb)
		node = med
	node.name = "Medaglione"
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.offset_left = -64.0
	node.offset_right = 64.0
	node.offset_top = 12.0
	node.offset_bottom = 140.0
	add_child(node)
	move_child(node, 1)
	_med = node


func _refresh() -> void:
	if bg != null:
		# Backing della card reso discreto: il medaglione circolare è il protagonista.
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.08, 0.06, 0.45)
		sb.border_color = Color(0.5, 0.38, 0.22, 0.5)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(10)
		bg.add_theme_stylebox_override("panel", sb)
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
	if lbl != null:
		lbl.text = label_text
	if target_lbl != null:
		target_lbl.text = target_text
		target_lbl.visible = target_text != ""
		target_lbl.add_theme_color_override("font_color", target_color)
	if stat_hint_lbl != null:
		stat_hint_lbl.text = stat_hint_text
		stat_hint_lbl.visible = stat_hint_text != ""
	if _disabled:
		modulate = Color(0.78, 0.74, 0.7, 0.92)
		if lbl != null:
			lbl.add_theme_color_override("font_color", COL_LABEL_DISABILITATO)
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		tooltip_text = _disabled_reason
	elif _consumed:
		modulate = Color(1, 1, 1, 0.4)
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		tooltip_text = ""
	else:
		modulate = Color.WHITE
		if lbl != null:
			lbl.add_theme_color_override("font_color", COL_LABEL_NORMALE)
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		# Tooltip ricco: nome+natura della strategia, poi l'affordance "Trascina su X".
		var tip: String = descrizione_strategia
		if hint_text != "":
			tip = (tip + "\n" + hint_text) if tip != "" else hint_text
		tooltip_text = tip


func _attivabile() -> bool:
	return not _disabled and not _consumed and not get_viewport().gui_is_dragging()


func _hover_in() -> void:
	if not _attivabile():
		return
	pivot_offset = size * 0.5
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel()
	_hover_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.13) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _med != null:
		_hover_tween.tween_property(_med, "self_modulate", Color(1.35, 1.18, 0.82), 0.13)


func _hover_out() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel()
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
	if _med != null:
		_hover_tween.tween_property(_med, "self_modulate", Color.WHITE, 0.16)


func set_disabled(value: bool, reason: String = "") -> void:
	_disabled = value
	_disabled_reason = reason
	_refresh()


func is_disabled() -> bool:
	return _disabled


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _consumed or _disabled:
		return null
	AudioManager.play_sfx("drag_pickup")
	set_drag_preview(_build_preview())
	# Ghost della card sorgente mentre la sua copia e' in aria.
	modulate = Color(1, 1, 1, 0.5)
	return {
		"item_id": item_id,
		"label": label_text,
		"icon_texture": icon_texture,
		"stat": stat_to_modify,
		"delta": stat_delta,
		"feedback": feedback_text,
		"source": self,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_refresh()


func _build_preview() -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = size
	c.rotation = deg_to_rad(-5.0)
	c.scale = Vector2(1.08, 1.08)
	var rect: ColorRect = ColorRect.new()
	rect.color = icon_color
	rect.modulate = Color(1, 1, 1, 0.85)
	rect.size = size
	c.add_child(rect)
	if icon_texture != null:
		var tr: TextureRect = TextureRect.new()
		tr.texture = icon_texture
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = size
		c.add_child(tr)
	return c


func consume() -> void:
	_consumed = true
	_refresh()


func reset() -> void:
	_consumed = false
	_disabled = false
	_disabled_reason = ""
	_refresh()

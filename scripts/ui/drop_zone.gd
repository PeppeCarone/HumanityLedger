extends Control

@export var zone_id: String = ""
@export var label_text: String = "Consigliere"
@export var portrait_texture: Texture2D
@export var bg_color: Color = Color(0.14, 0.115, 0.10, 0.96)
@export var hover_color: Color = Color(0.4, 0.75, 0.4, 0.55)
@export var fail_flash_color: Color = Color(0.85, 0.25, 0.25, 0.55)
@export var accepted_item_ids: Array[String] = []
@export var accent_color: Color = Color(0.5, 0.38, 0.22, 0.9)

@onready var bg: Panel = $Background
@onready var hover: ColorRect = $HoverHighlight
@onready var portrait_rect: TextureRect = $PortraitTexture
@onready var lbl: Label = $Label

signal item_dropped(data: Dictionary)

var _is_hovering: bool = false
var _last_can_drop: bool = false
var _hover_tween: Tween = null
var _portrait_tween: Tween = null
var _ring: TextureRect = null
var _ring_tween: Tween = null


func _ready() -> void:
	_setup_ring()
	_refresh()


# Alone-anello verde (ring_focus.png) attorno alla piazzola: appare quando una carta
# compatibile e' in aria, rendendo ovvio "lascia qui". Fallback-safe (niente se manca il PNG).
func _setup_ring() -> void:
	var tex: Texture2D = UiStyle.ui_texture("ring_focus")
	if tex == null:
		return
	_ring = TextureRect.new()
	_ring.name = "FocusRing"
	_ring.texture = tex
	_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring.offset_left = -18.0
	_ring.offset_top = -18.0
	_ring.offset_right = 18.0
	_ring.offset_bottom = 18.0
	_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ring.stretch_mode = TextureRect.STRETCH_SCALE
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.modulate = Color(0.45, 0.9, 0.45, 0.0)
	add_child(_ring)
	move_child(_ring, 0)


func _refresh() -> void:
	if bg != null:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = bg_color
		sb.border_color = accent_color
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		bg.add_theme_stylebox_override("panel", sb)
	if hover != null:
		hover.color = hover_color
		hover.modulate.a = 0.0
	if portrait_rect != null:
		portrait_rect.texture = portrait_texture
		portrait_rect.visible = portrait_texture != null
	if lbl != null:
		lbl.text = label_text


func set_portrait(tex: Texture2D) -> void:
	portrait_texture = tex
	_refresh()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var ok: bool = _accepts(data.get("item_id", ""))
	_last_can_drop = ok
	if ok and not _is_hovering:
		_is_hovering = true
		_animate_hover(true)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	_is_hovering = false
	_animate_hover(false)
	item_dropped.emit(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _is_hovering:
			_is_hovering = false
			_animate_hover(false)
		# drop rilasciato sopra questa zona ma rifiutato -> feedback rosso
		if not _last_can_drop and get_global_rect().has_point(get_global_mouse_position()):
			flash_fail()
		_last_can_drop = false


func _accepts(item_id: String) -> bool:
	if accepted_item_ids.is_empty():
		return true
	return item_id in accepted_item_ids


func _animate_hover(active: bool) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	if active:
		# La zona "respira" finche' la card compatibile e' in aria. Fill tenue: il
		# protagonista del feedback e' l'alone-anello, il ritratto resta leggibile.
		_hover_tween.set_loops()
		_hover_tween.set_trans(Tween.TRANS_SINE)
		_hover_tween.tween_property(hover, "modulate:a", 0.6, 0.35)
		_hover_tween.tween_property(hover, "modulate:a", 0.34, 0.45)
	else:
		_hover_tween.tween_property(hover, "modulate:a", 0.0, 0.12)
	# Alone-anello sincronizzato col respiro del fill.
	if _ring != null:
		if _ring_tween != null and _ring_tween.is_valid():
			_ring_tween.kill()
		_ring_tween = create_tween()
		if active:
			_ring_tween.set_loops()
			_ring_tween.set_trans(Tween.TRANS_SINE)
			_ring_tween.tween_property(_ring, "modulate:a", 1.0, 0.35)
			_ring_tween.tween_property(_ring, "modulate:a", 0.6, 0.45)
		else:
			_ring_tween.tween_property(_ring, "modulate:a", 0.0, 0.12)
	# Il consigliere reagisce: leggero scale-up e luce calda sul ritratto.
	if portrait_rect != null:
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		portrait_rect.pivot_offset = portrait_rect.size * 0.5
		_portrait_tween = create_tween()
		_portrait_tween.set_parallel()
		_portrait_tween.tween_property(
			portrait_rect, "scale", Vector2(1.06, 1.06) if active else Vector2.ONE, 0.15) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_portrait_tween.tween_property(
			portrait_rect, "modulate",
			Color(1.10, 1.05, 0.92) if active else Color.WHITE, 0.15)


func flash_fail() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	var original: Color = hover.color
	hover.color = fail_flash_color
	hover.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(hover, "modulate:a", 0.0, 0.35)
	await tween.finished
	hover.color = original

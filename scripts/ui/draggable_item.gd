extends Control

@export var item_id: String = ""
@export var label_text: String = "Item"
@export var icon_texture: Texture2D
@export var icon_color: Color = Color(0.2, 0.15, 0.1, 0.85)
@export var stat_to_modify: String = ""
@export var stat_delta: int = 0
@export var feedback_text: String = ""

@onready var bg: ColorRect = $Background
@onready var icon_rect: TextureRect = $IconTexture
@onready var lbl: Label = $Label

var _consumed: bool = false
var _disabled: bool = false
var _disabled_reason: String = ""


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if bg != null:
		bg.color = icon_color
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
	if lbl != null:
		lbl.text = label_text
	if _disabled:
		modulate = Color(1, 1, 1, 0.4)
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		tooltip_text = _disabled_reason
	elif _consumed:
		modulate = Color(1, 1, 1, 0.35)
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		tooltip_text = ""
	else:
		modulate = Color.WHITE
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		tooltip_text = ""


func set_disabled(value: bool, reason: String = "") -> void:
	_disabled = value
	_disabled_reason = reason
	_refresh()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _consumed or _disabled:
		return null
	set_drag_preview(_build_preview())
	return {
		"item_id": item_id,
		"label": label_text,
		"icon_texture": icon_texture,
		"stat": stat_to_modify,
		"delta": stat_delta,
		"feedback": feedback_text,
		"source": self,
	}


func _build_preview() -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = size
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
